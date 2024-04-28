
enum TFBotDifficulty
{
    Easy = 0,
    Normal,
    Hard,
    Expert,

    Num_Difficulties
}

enum SMBotPathType
{
    FASTEST_PATH = 0, // Prefer the fastest path, ignoring danger
    SAFEST_PATH, // Gets the fastest path while taking danger in consideration 
    FLANK_PATH, // Fastest alternative paths

    MAX_SMBOT_PATH_TYPES
}

enum CanBuildObjects
{
    CB_Object_SentryGun,
    CB_Object_Dispenser,
    CB_Object_Teleporter,

    CB_Max_Objects
}

// globals
char g_szBehaviorDebug[TF_MAXPLAYERS][512];
float g_flNextCommandTime[TF_MAXPLAYERS];
bool g_smbot[TF_MAXPLAYERS]; // is a smbot bot
TFBotDifficulty g_difficulty[TF_MAXPLAYERS];
SMBotPathType g_PathType[TF_MAXPLAYERS];
TFClassType g_iDesiredClass[TF_MAXPLAYERS];
float g_flIgnoreEnemiesTime[TF_MAXPLAYERS];
int g_iVisionSearchLastIndex[TF_MAXPLAYERS];
float g_flNextChangeClassTime[TF_MAXPLAYERS];
Path g_hCurrentPath[TF_MAXPLAYERS];
int g_iCurrentUsedNode[TF_MAXPLAYERS];
int g_hMySentryGun[TF_MAXPLAYERS];
int g_hMyDispenser[TF_MAXPLAYERS];
int g_hMyTeleEntrance[TF_MAXPLAYERS];
int g_hMyTeleExit[TF_MAXPLAYERS];
CNavArea g_HomeArea[TF_MAXPLAYERS];

int g_iBotButtonsBits[TF_MAXPLAYERS];
CountdownTimer g_ButtonTimers[TF_MAXPLAYERS][MAX_BUTTONS];

// client globals
bool g_bClientDebugging[TF_MAXPLAYERS];
float g_flDebugHudTimer[TF_MAXPLAYERS];

/* Enum of buttons the bot can press, the button ID must match the IN_* buttons from entity_prop_stocks.inc */
enum BotButtons
{
    BOTBUTTON_ATTACK = 0,
    BOTBUTTON_JUMP,
    BOTBUTTON_DUCK,
    BOTBUTTON_FORWARD,
    BOTBUTTON_BACK,
    BOTBUTTON_USE,
    BOTBUTTON_MOVELEFT = 9,
    BOTBUTTON_MOVERIGHT,
    BOTBUTTON_ATTACK2,
    BOTBUTTON_RELOAD,
    BOTBUTTON_ATTACK3 = 25,

    MAX_BUTTONS = 26
}

static CEntityFactory EntityFactory;

methodmap CTFPlayer < CBaseCombatCharacter
{
    public CTFPlayer(int entIndex)
    {
        return view_as<CTFPlayer>(entIndex);
    }

    public static bool IsPlayerEntity(int entIndex)
    {
        return entIndex > 0 && entIndex <= MaxClients;
    }

    public int GetHealth()
    {
        return GetClientHealth(this.index);
    }

    public float GetHealthPercent()
    {
        int health = GetClientHealth(this.index);
        int maxhealth = TF2Util_GetEntityMaxHealth(this.index);
        return float(health)/float(maxhealth);
    }

    public void GetEyePosition(float eye[3])
    {
        GetClientEyePosition(this.index, eye);
    }

    public void GetEyeAngles(float angles[3])
    {
        GetClientEyeAngles(this.index, angles);
    }

    public TFTeam GetTeam()
    {
        return TF2_GetClientTeam(this.index);
    }

    public TFTeam GetOpposingTeam()
    {
        if (this.IsFromTeam(TFTeam_Red))
        {
            return TFTeam_Blue;
        }
        else if (this.IsFromTeam(TFTeam_Blue))
        {
            return TFTeam_Red;
        }

        return TFTeam_Unassigned;
    }

    public bool IsFromTeam(TFTeam team)
    {
        return this.GetTeam() == team;
    }

    public TFClassType GetClass()
    {
        return TF2_GetPlayerClass(this.index);
    }

    public bool IsClass(TFClassType class)
    {
        return this.GetClass() == class;
    }

    public void ChangeTeam(TFTeam newTeam)
    {
        TF2_ChangeClientTeam(this.index, newTeam);
    }

    public void ChangeClass(TFClassType newClass)
    {
        TF2_SetPlayerClass(this.index, newClass);
    }

    // Gets the current number of healers
    public int GetNumHealers()
    {
        return this.GetProp(Prop_Send, "m_nNumHealers");
    }

    // Gets a healer index
    // @param healer    Healer array index
    public int GetHealerOfIndex(int healer)
    {
        return TF2Util_GetPlayerHealer(this.index, healer);
    }

    public bool IsInSpawnRoom()
    {
        return this.GetProp(Prop_Send, "m_iSpawnRoomTouchCount") > 0;
    }

    public bool IsInCondition(TFCond cond)
    {
        return TF2_IsPlayerInCondition(this.index, cond);
    }

    public int LookUpBone(const char[] bone)
    {
        return LookUpBone(this.index, bone);
    }

    public void GetBonePosition(int bone, float origin[3], float angles[3])
    {
        GetBonePosition(this.index, bone, origin, angles);
    }

    public bool WeaponSwitch(int weapon)
    {
        TF2Util_SetPlayerActiveWeapon(this.index, weapon);
    }

    public bool IsAlive()
    {
        return IsPlayerAlive(this.index)
    }

    public bool IsInGame()
    {
        return IsClientInGame(this.index);
    }

    public bool IsPlaying()
    {
        return this.IsInGame() && GetClientTeam(this.index) >= view_as<int>(TFTeam_Red);
    }

    public float GetPercentInvisible()
    {
        return GetEntDataFloat(this.index, g_offset_percentinvisible);
    }

    public bool IsFullyInvisible()
    {
        return this.GetPercentInvisible() >= 0.99;
    }

    // Checks if the player is in any condition that makes them invisible
    public bool IsVisible()
    {
        if (this.IsInCondition(TFCond_CloakFlicker) || this.IsInCondition(TFCond_Bleeding) || this.IsInCondition(TFCond_OnFire) || this.IsInCondition(TFCond_Jarated) || \
        this.IsInCondition(TFCond_Milked) || this.IsInCondition(TFCond_Gas) || this.IsInCondition(TFCond_GrappledByPlayer))
        {
            return true;
        }

        return !(this.IsInCondition(TFCond_Cloaked) || this.IsInCondition(TFCond_Stealthed) || this.IsInCondition(TFCond_StealthedUserBuffFade) || this.IsFullyInvisible())
    }

    public int GetMaxAmmo(int type, TFClassType class = TFClass_Unknown)
    {
        return TF2Util_GetPlayerMaxAmmo(this.index, type, class);
    }

    public int GetAmmoOfType(int type)
    {
        if (type < 0 || type > 31) // invalid ammo type
            return -1;

        return this.GetProp(Prop_Send, "m_iAmmo", .element = type);
    }

    // Gets the bot active weapon
    public CTFWeaponBase GetActiveWeapon()
    {
        return CTFWeaponBase(this.GetPropEnt(Prop_Send, "m_hActiveWeapon"));
    }

    // Gets the bot weapon at a specific slot
    public CTFWeaponBase GetWeaponOfSlot(int slot)
    {
        return CTFWeaponBase(TF2Util_GetPlayerLoadoutEntity(this.index, slot, true));
    }

    public bool IsDisguised()
    {
        return TF2_IsPlayerInCondition(this.index, TFCond_Disguised);
    }

    public TFTeam GetDisguiseTeam()
    {
        return view_as<TFTeam>(this.GetProp(Prop_Send, "m_nDisguiseTeam"));
    }

    public TFClassType GetDisguiseClass()
    {
        return view_as<TFClassType>(this.GetProp(Prop_Send, "m_nDisguiseClass"));
    }

    public void Disguise(TFTeam team, TFClassType class)
    {
        TF2_DisguisePlayer(this.index, team, class);
    }

    public void DisguiseAs(TFTeam team, TFClassType class, CTFPlayer target)
    {
        TF2_DisguisePlayer(this.index, team, class, target.index);
    }

    public float GetCloakMeterPercent()
    {
        return this.GetPropFloat(Prop_Send, "m_flCloakMeter");
    }

    public CBaseEntity GetItem()
    {
        return CBaseEntity(this.GetPropEnt(Prop_Send, "m_hItem"));
    }

    public int GetCurrency()
    {
        return this.GetProp(Prop_Send, "m_nCurrency");
    }

    public float GetRageMeter()
    {
        return this.GetPropFloat(Prop_Send, "m_flRageMeter");
    }

    public bool IsRageMeterFull()
    {
        return this.GetRageMeter() >= 100.0;
    }

    public bool HasParachute()
    {
        return this.GetProp(Prop_Send, "m_bParachuteEquipped") == 1;
    }

    public int GetObserverTarget()
    {
        return this.GetPropEnt(Prop_Send, "m_hObserverTarget");
    }

    public bool IsMiniBoss()
    {
        return this.GetProp(Prop_Send, "m_bIsMiniBoss") == 1;
    }
}

methodmap NextBotPlayer < CTFPlayer
{
    public NextBotPlayer(int entIndex)
    {
        return view_as<NextBotPlayer>(entIndex);
    }

    public PlayerBody GetPlayerBody()
    {
        return view_as<PlayerBody>(this.MyNextBotPointer().GetBodyInterface());
    }

    public void ReleaseAllButtons()
    {
        for(int bt = 0; bt < view_as<int>(MAX_BUTTONS); bt++)
        {
            g_ButtonTimers[this.index][bt].Invalidate();
        }

        g_iBotButtonsBits[this.index] = 0;
    }

    public void PressButton(BotButtons button, float duration = -1.0)
    {
        g_iBotButtonsBits[this.index] |= (1 << view_as<int>(button));
        g_ButtonTimers[this.index][view_as<int>(button)].Start(duration);
    }

    public void ReleaseButton(BotButtons button)
    {
        g_iBotButtonsBits[this.index] &= ~(1 << view_as<int>(button));
        g_ButtonTimers[this.index][view_as<int>(button)].Invalidate();
    }

    public void ProcessButtons(int &buttons, bool &changed)
    {
        if (g_iBotButtonsBits[this.index] != 0)
        {
            changed = true;
        }

        buttons = g_iBotButtonsBits[this.index]; // copy first
        g_iBotButtonsBits[this.index] = 0; // clear

        for(int buttonIndex = 0; buttonIndex < view_as<int>(MAX_BUTTONS); buttonIndex++)
        {
            if (!g_ButtonTimers[this.index][buttonIndex].IsElapsed())
            {
                buttons |= (1 << buttonIndex);
                changed = true;
            }
        }
    }
}

methodmap SMBot < NextBotPlayer
{
    public SMBot(int entIndex)
    {
        return view_as<SMBot>(entIndex);
    }

    // Checks if the given entity is a SMBot bot
    //
    // @param index Entity index
    // @note This performs client index bound check
    public static bool IsSMBot(int index)
    {
        if (index <= 0 || index > MaxClients)
            return false;

        return g_smbot[index];
    }

    public static void Initialize()
    {
        InitBehavior();

        // Hijack TF2's default bot.
        EntityFactory = new CEntityFactory("sm_bot", OnCreate, OnRemove);
        EntityFactory.DeriveFromClass("tf_bot");
        EntityFactory.AttachNextBot(ToolsNextBotPlayer_Factory)
        EntityFactory.SetInitialActionFactory(SMBotMainAction.GetFactory());
        EntityFactory.BeginDataMapDesc();
        EntityFactory.EndDataMapDesc();
        EntityFactory.Install();
    }

    public static void AllocateSMBotPlayer()
    {
        char name[MAX_NAME_LENGTH];
        // Until a name list is added
        FormatEx(name, sizeof(name), "SMBot %i", GetRandomInt(0, 9999));
        CreateFakeClient(name);
    }

    public TFBotDifficulty GetDifficulty()
    {
        return g_difficulty[this.index];
    }

    property float nextchangeclasstime
    {
        public get()
        {
            return g_flNextChangeClassTime[this.index];
        }
        public set(float value)
        {
            g_flNextChangeClassTime[this.index] = GetGameTime() + value;
        }
    }

    // To-do: implement
    public TFClassType SelectClassToPlay()
    {
        if (this.nextchangeclasstime > GetGameTime())
            return TFClass_Unknown;
        
        this.nextchangeclasstime = Math_GetRandomFloat(120.0, 360.0);

        if (CTFGameRules.IsPlayingMannVsMachine())
        {
            g_mvmclassroster.SetTargetClient(this.index);
            g_mvmclassroster.Compute();
            return g_mvmclassroster.SelectClass();
        }
        else
        {
            g_defaultclassroster.SetTargetClient(this.index);
            g_defaultclassroster.Compute();
            return g_defaultclassroster.SelectClass();
        }
    }

    public TFClassType GetDesiredClass()
    {
        return g_iDesiredClass[this.index];
    }

    // Sets the bot desired class.
    // @param class     Desired class
    public void SetDesiredClass(TFClassType class)
    {
        if (class == TFClass_Unknown)
            return; // keep the current class

        g_iDesiredClass[this.index] = class;
    }

    public void ClientCommandThrottled(const char[] command)
    {
        if (g_flNextCommandTime[this.index] <= GetGameTime())
        {
            ClientCommand(this.index, command);
            g_flNextCommandTime[this.index] = GetGameTime() + 0.125;
        }
    }

    // Updates the bot client settings.
    // @param autoreload        Enables TF2 auto reload.
    // @param autoheal          Enables TF2 auto heal (Doesn't need to hold primary).
    // @param autorezoom        Enables TF2 sniper rifle auto rezoom.
    public void UpdateSettings(bool autoreload, bool autoheal, bool autorezoom)
    {
        SetFakeClientConVar(this.index, "cl_autoreload", autoreload ? "1" : "0");
        SetFakeClientConVar(this.index, "cl_autorezoom", autorezoom ? "1" : "0");
        SetFakeClientConVar(this.index, "tf_medigun_autoheal", autoheal ? "1" : "0");

        CTFGameRules.ClientSettingsChanged(this.index);
    }

    public void SetMySentryGun(int entity)
    {
        if (CObjectSentrygun.IsSentryGun(entity))
        {
            g_hMySentryGun[this.index] = EntIndexToEntRef(entity);
        }
    }

    public CObjectSentrygun GetMySentryGun()
    {
        int entity = EntRefToEntIndex(g_hMySentryGun[this.index]);
        return CObjectSentrygun(entity);
    }

    public void SetMyDispenser(int entity)
    {
        if (CObjectDispenser.IsDispenser(entity))
        {
            g_hMyDispenser[this.index] = EntIndexToEntRef(entity);
        }
    }

    public CObjectDispenser GetMyDispenser()
    {
        int entity = EntRefToEntIndex(g_hMyDispenser[this.index])
        return CObjectDispenser(entity);
    }

    // Sets the bot teleporter
    // @param entity        Teleporter entity index
    // @param isexit        Is the teleporter a teleporter exit
    public void SetMyTeleporter(int entity, bool isexit)
    {
        if (CObjectTeleporter.IsTeleporter(entity))
        {
            if (isexit == true)
            {
                g_hMyTeleExit[this.index] = EntIndexToEntRef(entity);
            }
            else
            {
                g_hMyTeleEntrance[this.index] = EntIndexToEntRef(entity);
            } 
        }
    }

    public CObjectTeleporter GetMyTeleporter(bool isexit)
    {
        int entity = -1;

        if (isexit == true)
        {
            entity = EntRefToEntIndex(g_hMyTeleExit[this.index])
        }
        else
        {
            entity = EntRefToEntIndex(g_hMyTeleEntrance[this.index])
        }

        return CObjectTeleporter(entity);
    }

    // Updates the bot buildings
    public void UpdateMyBuildings()
    {
        if (!this.IsClass(TFClass_Engineer))
        {
            g_hMySentryGun[this.index] = -1;
            g_hMyDispenser[this.index] = -1;
            g_hMyTeleEntrance[this.index] = -1;
            g_hMyTeleExit[this.index] = -1;
            return;
        }

        int entity = -1;
        while((entity = FindEntityByClassname(entity, "obj_sentrygun")) != -1)
        {
            CBaseObject baseobject = CBaseObject(entity);

            if (baseobject.GetBuilder() == this.index)
            {
                this.SetMySentryGun(entity);
                break;
            }
        }

        entity = -1;
        while((entity = FindEntityByClassname(entity, "obj_dispenser")) != -1)
        {
            CBaseObject baseobject = CBaseObject(entity);

            if (baseobject.GetBuilder() == this.index)
            {
                this.SetMyDispenser(entity);
                break;
            }
        }

        entity = -1;
        bool hasexit = false;
        bool hasentrance = false;
        while((entity = FindEntityByClassname(entity, "obj_teleporter")) != -1)
        {
            CBaseObject baseobject = CBaseObject(entity);

            if (baseobject.GetBuilder() == this.index && baseobject.GetMode() == TFObjectMode_Entrance && !hasentrance)
            {
                this.SetMyTeleporter(entity, false);
                hasentrance = true;
            }
            else if(baseobject.GetBuilder() == this.index && baseobject.GetMode() == TFObjectMode_Exit && !hasexit)
            {
                this.SetMyTeleporter(entity, true);
                hasexit = true;
            }

            if (hasentrance && hasexit)
            {
                break;
            }
        }
    }

    // The nav area where the bot first spawned
    property CNavArea homearea
    {
        public get()
        {
            return g_HomeArea[this.index];
        }
        public set(CNavArea value)
        {
            g_HomeArea[this.index] = value;
        }
    }

    // The hint node the bot is currently using
    property int hintnode
    {
        public get()
        {
            return g_iCurrentUsedNode[this.index];
        }
        public set(int value)
        {
            g_iCurrentUsedNode[this.index] = value;
        }
    }

    // Clears the hint node this bot was using and marks it as available for other bots.
    public void ClearHintNode()
    {
        CNode node = CNode(this.hintnode);

        if (node.IsValid())
        {
            node.ChangeAvailableStatus(false);
        }

        this.hintnode = INVALID_NODE_ID;
    }

    // Stores the bot current path via sourcemod globals
    // @note Mostly used for debugging
    public void SetCurrentPath(const Path path)
    {
        g_hCurrentPath[this.index] = path;
    }

    public Path GetCurrentPath()
    {
        return g_hCurrentPath[this.index];
    }

    public void DestroyPath()
    {
        g_hCurrentPath[this.index] = view_as<Path>(0);
    }

    // Checks if the given entity is this bot enemy
    // @param other     Entity index to check
    // @return          True if enemy
    public bool MyIsEnemy(int other)
    {
        TFTeam theirteam;

        if (other == this.index)
            return false;

        if (CTFPlayer.IsPlayerEntity(other))
        {
            CTFPlayer TFPlayer = CTFPlayer(other);

            if (!TFPlayer.IsVisible())
                return false;

            if (TFPlayer.GetTeam() != this.GetTeam())
                return false;
        }

        if (CBaseObject.IsBaseObject(other))
        {
            CBaseObject baseobject = CBaseObject(other);

            if (baseobject.GetTeam() != this.GetTeam())
                return true;

            return false;
        }

        if (HasEntProp(other, Prop_Send, "m_iTeamNum"))
        {
            theirteam = view_as<TFTeam>(GetEntProp(other, Prop_Send, "m_iTeamNum"));

            if (theirteam != this.GetTeam())
                return true;
        }

        return false;
    }

    // Checks if the given entity is an ally
    // @param other     Entity index to check
    // @return          True if ally
    public bool IsAlly(int other)
    {
        TFTeam theirteam;

        if (HasEntProp(other, Prop_Send, "m_iTeamNum"))
        {
            theirteam = view_as<TFTeam>(GetEntProp(other, Prop_Send, "m_iTeamNum"));

            if (theirteam == this.GetTeam())
                return true;
        }

        return false;
    }

    // Checks if the bot has enough metal to build the given object type
    // @param building        Object type
    // @return              True if the bot has enough metal to build
    public bool CanBuildObject(CanBuildObjects building)
    {
        switch(building)
        {
            case CB_Object_SentryGun:
            {
                return this.GetAmmoOfType(view_as<int>(TFAmmo_Metal)) >= 130;
            }
            case CB_Object_Dispenser:
            {
                return this.GetAmmoOfType(view_as<int>(TFAmmo_Metal)) >= 100;
            }
            case CB_Object_Teleporter:
            {
                return this.GetAmmoOfType(view_as<int>(TFAmmo_Metal)) >= 50;
            }
        }

        return false;
    }

    // Collects visible teammates to heal
    // @param patients      Array to store visible patients
    // @param size          Patients array size
    // @return              Number of visible patients
    public int CollectHealTargets(int[] patients, int size)
    {
        int num_patients = 0;
        INextBot bot = this.MyNextBotPointer();
        IVision vision = bot.GetVisionInterface();

        for(int client = 1; client <= MaxClients; client++)
        {
            CTFPlayer TFPlayer = CTFPlayer(client);
            
            if (!TFPlayer.IsPlaying()) // checks if client in in game and on either RED or BLU team
                continue;

            if (!TFPlayer.IsAlive())
                continue;

            if (TFPlayer.GetTeam() == this.GetTeam() && vision.IsLineOfSightClearToEntity(client))
            {
                if (num_patients < size)
                {
                    patients[num_patients] = client;
                    num_patients++;
                }
            }
        }

        return num_patients;
    }

    // This function handles the bot vision for detecting other players
    public void UpdateVisiblePlayers()
    {
        INextBot bot = this.MyNextBotPointer();
        IVision vision = bot.GetVisionInterface();

        if (!this.IsAlive() || !this.IsPlaying())
            return;

        for(int client = 1; client <= MaxClients; client++)
        {
            CTFPlayer TFPlayer = CTFPlayer(client);

            if (!TFPlayer.IsPlaying()) // checks if client in in game and on either RED or BLU team
                continue;

            if (!TFPlayer.IsAlive())
                continue;

            if (this.MyIsEnemy(TFPlayer.index))
            {
                float position[3];

                TFPlayer.WorldSpaceCenter(position);

                if (vision.IsLineOfSightClear(position))
                {
                    vision.AddKnownEntity(TFPlayer.index);
                    continue;
                }

                TFPlayer.GetEyePosition(position);

                if (vision.IsLineOfSightClear(position))
                {
                    vision.AddKnownEntity(TFPlayer.index);
                    continue;
                }

                TFPlayer.GetAbsOrigin(position);

                if (vision.IsLineOfSightClear(position))
                {
                    vision.AddKnownEntity(TFPlayer.index);
                    continue;
                }
            }
        }
    }

    // This function handles bot vision for non player entities such as Nextbot NPCs, sentry guns, etc.
    public void UpdateVision()
    {
        INextBot bot = this.MyNextBotPointer();
        IVision vision = bot.GetVisionInterface();

        for(int entity = g_iVisionSearchLastIndex[this.index]; entity <= g_iVisionSearchLastIndex[this.index]; entity++)
        {
            if (entity >= MAX_EDICTS)
            {
                g_iVisionSearchLastIndex[this.index] = MaxClients + 1;
                break; // reset
            }

            // CBaseCombatCharacter derived entity
            if (HasEntProp(entity, Prop_Send, "m_hActiveWeapon"))
            {
                if (this.MyIsEnemy(entity))
                {
                    if (vision.IsAbleToSeeTarget(entity, USE_FOV))
                    {
                        vision.AddKnownEntity(entity);
                    }

                    continue;
                }
            }
            else
            {
                // To-do: add storage for non CBaseCombatCharacter entities
            }
        }

        g_iVisionSearchLastIndex[this.index] += sm_smbot_vis_search_increment.IntValue;
    }

    public void SelectBestWeaponForThreat(CBaseCombatCharacter threat)
    {
        INextBot me = this.MyNextBotPointer();
        float range = me.GetRangeTo(threat.index);
        CTFWeaponBase myWeapon = this.GetActiveWeapon();

        if (myWeapon.GetWeaponID() == TF_WEAPON_FLAMETHROWER ||
        myWeapon.GetWeaponID() == TF_WEAPON_FLAMETHROWER_ROCKET ||
        myWeapon.GetWeaponID() == TF_WEAPON_ROCKETLAUNCHER)
        {
            if (range < 400.0)
            {
                int secondary = TF2Util_GetPlayerLoadoutEntity(this.index, TFWeaponSlot_Secondary, true);

                if (secondary != -1)
                {
                    this.WeaponSwitch(secondary);
                }
            }
        }
    }

    public void ResetDecoratedDebugString()
    {
        strcopy(g_szBehaviorDebug[this.index], sizeof(g_szBehaviorDebug[]), "");
    }

    public NextBotAction GetTopOfStack(NextBotAction first)
    {
        NextBotAction next = first;
        NextBotAction child = first.ActiveChild;
        NextBotAction buried = first.ActionBuriedUnderMe;

        for(;;)
        {
            child = next.ActiveChild;
            buried = next.ActionBuriedUnderMe;

            if (view_as<int>(child) != 0)
            {
                next = child;
                continue;
            }

            if (view_as<int>(buried) != 0)
            {
                next = buried;
                continue;
            }

            return next;
        }
    }

    // Builds a decorated debug string containg the bot current actions
    //
    // @param action This should be the first bot action
    // @note The result is stored in g_szBehaviorDebug[bot index]
    //
    public void BuildDecoratedDebugString(NextBotAction action)
    {
        const int size = sizeof(g_szBehaviorDebug[]);
        NextBotAction child = action.ActiveChild;
        NextBotAction buried = action.ActionBuriedUnderMe;
        char buffer[128];

        action.GetName(buffer, sizeof(buffer));
        StrCat(g_szBehaviorDebug[this.index], size, buffer);

        if (view_as<int>(child) != 0)
        {
            StrCat(g_szBehaviorDebug[this.index], size, "( ");
            this.BuildDecoratedDebugString(child);
            StrCat(g_szBehaviorDebug[this.index], size, " )");
        }

        if (view_as<int>(buried) != 0)
        {
            StrCat(g_szBehaviorDebug[this.index], size, "<<");
            this.BuildDecoratedDebugString(buried);
        }
    }

    // Type of path to use for the cost function
    property SMBotPathType pathtype
    {
        public get()
        {
            return g_PathType[this.index];
        }
        public set(SMBotPathType value)
        {
            g_PathType[this.index] = value;
        }
    }

    // Ignore aiming at enemies for a while
    //
    // @param duration      How long to ignore enemies for  
    public void IgnoreEnemies(float duration = 0.5)
    {
        if (duration <= 0.0)
            g_flIgnoreEnemiesTime[this.index] = -1.0;

        g_flIgnoreEnemiesTime[this.index] = GetGameTime() + duration;
    }

    public bool ShouldIgnoreEnemies()
    {
        return g_flIgnoreEnemiesTime[this.index] > GetGameTime();
    }

    // Looks around and aim at enemies
    public void UpdateLookingAround()
    {
        INextBot bot = this.MyNextBotPointer();
        IVision vision = bot.GetVisionInterface();
        IIntention intention = bot.GetIntentionInterface();
        PlayerBody body = this.GetPlayerBody();
        CKnownEntity threat = vision.GetPrimaryKnownThreat(true);
        float aimTarget[3];

        if (threat != NULL_KNOWN_ENTITY && !this.ShouldIgnoreEnemies())
        {
            intention.SelectTargetPoint(threat.GetEntity(), aimTarget);
            body.AimTowards(aimTarget, CRITICAL, 1.0, "Aiming at known threat");

            if (g_iDebugBotTarget == this.index)
            {
                float eyes[3];
                float targetPos[3];
                GetClientEyePosition(this.index, eyes);
                CBaseEntity targetent = CBaseEntity(threat.GetEntity());
                targetent.WorldSpaceCenter(targetPos);
                UTIL_DrawLaser(-1, eyes, aimTarget, {255,0,0,255}, 0.125);
                UTIL_DrawLaser(-1, eyes, targetPos, {0,0,255,255}, 0.125);
            }

            return;
        }
        else
        {
            this.UpdateLookingAroundForIncomingPlayers(true);
        }
    }

    // Checks conditions and fire at the enemy if possible
    // This function does not aim at enemies, see UpdateLookingAround()
    public void FireWeaponAtEnemy()
    {
        if (!this.IsAlive())
            return;

        if (this.IsInCondition(TFCond_Taunting))
            return;

        if (this.ShouldIgnoreEnemies())
            return;

        CTFWeaponBase myWeapon = this.GetActiveWeapon();
        INextBot bot = this.MyNextBotPointer();
        IVision vision = bot.GetVisionInterface();
        CKnownEntity threat = vision.GetPrimaryKnownThreat(true);

        if (threat == NULL_KNOWN_ENTITY)
            return;

        if (!myWeapon.IsValidTFWeapon())
            return;

        if (myWeapon.IsWeapon(TF_WEAPON_MEDIGUN))
            return; // Healing is handled elsewhere

        if (myWeapon.GetPrimaryClip() <= 0)
        {
            this.PressButton(BOTBUTTON_RELOAD);
            return;
        }

        if (this.IsClass(TFClass_Heavy) && bot.GetIntentionInterface().ShouldHurry() != ANSWER_YES)
        {
            const float spinTime = 3.0;
            if (vision.GetTimeSinceVisible(view_as<int>(this.GetOpposingTeam())) < spinTime)
            {
                this.PressButton(BOTBUTTON_ATTACK2, 0.5);
            }
        }

        if (!threat.IsVisibleRecently())
            return;

        CBaseEntity target = CBaseEntity(threat.GetEntity())

        if (!target.IsValid())
            return;

        float origin[3];
        float center[3];
        float eyes[3];

        target.GetAbsOrigin(origin);
        target.WorldSpaceCenter(center);
        GetEyePosition(target.index, eyes);

        if (!vision.IsLineOfSightClear(eyes))
        {
            if (!vision.IsLineOfSightClear(center))
            {
                if (!vision.IsLineOfSightClear(origin))
                    return;
            }
        }

        float finalAimVector[3];
        float myEyes[3];
        GetClientEyePosition(this.index, myEyes);
        bot.GetIntentionInterface().SelectTargetPoint(target.index, finalAimVector);

        if (UTIL_QuickSimpleTraceLine(myEyes, finalAimVector, MASK_SHOT))
            return;

        this.PressButton(BOTBUTTON_ATTACK, 0.2);
        return;
    }

    public void UpdateLookingAroundForIncomingPlayers(bool lookforenemies)
    {
        SDKCall(g_hctfbotupdatelooking, this.index, lookforenemies);
    }

    public bool IsAmmoLow()
    {
        CTFWeaponBase myWeapon = this.GetActiveWeapon();

        if (!myWeapon.IsValidTFWeapon())
            return false;

        if (myWeapon.IsWeapon(TF_WEAPON_WRENCH))
        {
            return this.GetAmmoOfType(view_as<int>(TFAmmo_Metal)) <= 0;
        }

        if (myWeapon.IsWeapon(TF_WEAPON_MEDIGUN))
        {
            return false;
        }

        if (myWeapon.IsMeleeWeapon())
        {
            return false;
        }

        if (!myWeapon.UsesPrimaryAmmo())
        {
            return false;
        }

        int ammotype = myWeapon.GetPrimaryAmmoType();

        float ratio = float(this.GetAmmoOfType(ammotype))/float(this.GetMaxAmmo(ammotype));

        if (ratio < 0.3) // To-do add configuration and different ratios for secondary weapon ammo
        {
            return true;
        }

        return false;
    }

    public bool IsAmmoFull()
    {
        bool primaryfull = this.GetAmmoOfType(view_as<int>(TFAmmo_Primary)) >= this.GetMaxAmmo(view_as<int>(TFAmmo_Primary));
        bool secondaryfull = this.GetAmmoOfType(view_as<int>(TFAmmo_Secondary)) >= this.GetMaxAmmo(view_as<int>(TFAmmo_Secondary));

        if (this.IsClass(TFClass_Engineer))
        {
            bool metalfull = this.GetAmmoOfType(view_as<int>(TFAmmo_Metal)) >= this.GetMaxAmmo(view_as<int>(TFAmmo_Metal));
            return metalfull && primaryfull && secondaryfull;
        }

        return primaryfull && secondaryfull;
    }

    public bool IsHealthLow()
    {
        float health = float(GetClientHealth(this.index));
        float maxhealth = float(TF2Util_GetEntityMaxHealth(this.index));
        float ratio = health/maxhealth;

        if (ratio < 0.5)
            return true;

        if (this.IsInCondition(TFCond_OnFire) || this.IsInCondition(TFCond_Bleeding))
            return true;

        return false;
    }

    public int CollectKnownEntities(CKnownEntity[] knownlist, int size, int start = 1, int searchrange = 2048)
    {
        INextBot bot = this.MyNextBotPointer();
        IVision vision = bot.GetVisionInterface();
        CKnownEntity known = NULL_KNOWN_ENTITY;
        int counter = 0;

        for(int i = start; i < searchrange; i++)
        {
            known = vision.GetKnown(i);

            if (counter >= size)
                break;

            if (known != NULL_KNOWN_ENTITY)
            {
                knownlist[counter] = known;
                counter++;
            }
        }

        return counter;
    }
}

static void OnCreate(SMBot ent)
{
    if (ent.index > 0)
    {
        g_smbot[ent.index] = true;
        SDKHook(ent.index, SDKHook_SpawnPost, OnSpawnPost);
        SDKHook(ent.index, SDKHook_ThinkPost, OnThinkPost);
        LogMessage("SMBot entity #%i created.", ent.index);
    }
}

static void OnRemove(SMBot ent)
{
    if (ent.index > 0)
    {
        g_smbot[ent.index] = false;
        SDKUnhook(ent.index, SDKHook_SpawnPost, OnSpawnPost);
        SDKUnhook(ent.index, SDKHook_ThinkPost, OnThinkPost);
    }
}

static void OnSpawnPost(int entity)
{
    SMBot bot = SMBot(entity);
    bot.UpdateSettings(true, true, true);

    int difficulty = tf_bot_difficulty.IntValue;
    difficulty = Math_Clamp(difficulty, 0, 3);
    g_difficulty[entity] = view_as<TFBotDifficulty>(difficulty);

    if (difficulty == 3)
    {
        INextBot nb = bot.MyNextBotPointer();
        IVision vision = nb.GetVisionInterface();
        vision.SetFieldOfView(150.0);
    }

    if (bot.GetTeam() <= TFTeam_Spectator)
    {
        FakeClientCommand(entity, "jointeam auto");
    }

    CreateTimer(0.5, Timer_OnSpawnPost, GetClientSerial(entity), TIMER_FLAG_NO_MAPCHANGE);
}

static void OnThinkPost(int entity)
{
    SMBot bot = SMBot(entity);

    if (!IsFakeClient(entity))
    {
        g_smbot[entity] = false;
        SDKUnhook(entity, SDKHook_ThinkPost, OnThinkPost);
        return;
    }

    bot.UpdateVisiblePlayers();
    bot.UpdateVision();
}

Action Timer_OnSpawnPost(Handle timer, any data)
{
    int client = GetClientFromSerial(data);

    if (client > 0 && SMBot.IsSMBot(client))
    {
        SMBot bot = SMBot(client);
        bot.SetDesiredClass(bot.SelectClassToPlay());
        bot.UpdateLastKnownArea();
        bot.homearea = bot.GetLastKnownArea();

        if (bot.GetClass() != bot.GetDesiredClass())
        {
            bot.ChangeClass(bot.GetDesiredClass());
            TF2_RespawnPlayer(client);
        }
    }

    return Plugin_Stop;
}

methodmap CClient
{
    public CClient(int index)
    {
        return view_as<CClient>(index);
    }

    property int index
    {
        public get()
        {
            return view_as<int>(this);
        }
    }

    property bool debugging
    {
        public get()
        {
            return g_bClientDebugging[this.index];
        }
        public set(bool value)
        {
            g_bClientDebugging[this.index] = value;
        }
    }

    property float debughudtimer
    {
        public get()
        {
            return g_flDebugHudTimer[this.index];
        }
        public set(float value)
        {
            g_flDebugHudTimer[this.index] = GetGameTime() + value;
        }
    }

    public bool IsValid()
    {
        return this.index > 0 && this.index <= MaxClients;
    }
}