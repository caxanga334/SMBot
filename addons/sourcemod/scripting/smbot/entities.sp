enum TFAmmo
{
    TFAmmo_Primary = 1,
    TFAmmo_Secondary = 2,
    TFAmmo_Metal = 3
}

methodmap CBaseObject < CBaseCombatCharacter
{
    public CBaseObject(int entity)
    {
        return view_as<CBaseObject>(entity);
    }

    public static bool IsBaseObject(int entity)
    {
        return HasEntProp(entity, Prop_Send, "m_iObjectType");
    }

    // Gets the object health
    public int GetHealth()
    {
        return this.GetProp(Prop_Send, "m_iHealth");
    }

    // Gets the object max health
    public int GetMaxHealth()
    {
        return this.GetProp(Prop_Send, "m_iMaxHealth");
    }

    // Is the object sapped
    public bool IsSapped()
    {
        return this.GetProp(Prop_Send, "m_bHasSapper") == 1;
    }

    // Is the object disabled
    public bool IsDisabled()
    {
        return this.GetProp(Prop_Send, "m_bDisabled") == 1;
    }

    public bool IsPlasmaDisable()
    {
        return this.GetProp(Prop_Send, "m_bPlasmaDisable") == 1;
    }

    public bool IsBeingPlaced()
    {
        return this.GetProp(Prop_Send, "m_bPlacing") == 1;
    }

    public bool IsBeingCarried()
    {
        return this.GetProp(Prop_Send, "m_bCarried") == 1;
    }

    public bool IsFullyConstructed()
    {
        return this.GetPropFloat(Prop_Send, "m_flPercentageConstructed") >= 0.99;
    }

    public int GetConstructionPercent()
    {
        return RoundToNearest(this.GetPropFloat(Prop_Send, "m_flPercentageConstructed") * 100.0);
    }

    public int GetBuilder()
    {
        return this.GetPropEnt(Prop_Send, "m_hBuilder");
    }

    public int GetUpgradeLevel()
    {
        return this.GetProp(Prop_Send, "m_iUpgradeLevel");
    }

    public int GetMaxUpgradeLevel()
    {
        return this.GetProp(Prop_Send, "m_iHighestUpgradeLevel");
    }

    public TFObjectType GetType()
    {
        return TF2_GetObjectType(this.index);
    }

    public TFObjectMode GetMode()
    {
        return TF2_GetObjectMode(this.index);
    }

    public bool IsMiniBuilding()
    {
        return this.GetProp(Prop_Send, "m_bMiniBuilding") == 1;
    }

    public bool IsDisposableBuilding()
    {
        return this.GetProp(Prop_Send, "m_bDisposableBuilding") == 1;
    }

    public TFTeam GetTeam()
    {
        return  view_as<TFTeam>(this.GetProp(Prop_Send, "m_iTeamNum"));
    }
}

methodmap CObjectSentrygun < CBaseObject
{
    public CObjectSentrygun(int entity)
    {
        return view_as<CObjectSentrygun>(entity);
    }

    public static bool IsSentryGun(int entity)
    {
        return HasEntProp(entity, Prop_Send, "m_hEnemy");
    }

    public int GetEnemy()
    {
        return this.GetPropEnt(Prop_Send, "m_hEnemy");
    }

    public void GetAmmo(int &shells, int &rockets)
    {
        shells = this.GetProp(Prop_Send, "m_iAmmoShells");
        rockets = this.GetProp(Prop_Send, "m_iAmmoRockets");
    }
}

methodmap CObjectTeleporter < CBaseObject
{
    public CObjectTeleporter(int entity)
    {
        return view_as<CObjectTeleporter>(entity);
    }

    public static bool IsTeleporter(int entity)
    {
        return HasEntProp(entity, Prop_Send, "m_flYawToExit");
    }

    // Gets the matching teleporter by accessing the teleporter internal m_hMatchingTeleporter member.
    //
    // @return Entity index to the matching teleporter or -1 if no matching teleporter.
    public int GetMatchingTeleporter()
    {
        return GetEntDataEnt2(this.index, g_offset_hmatchingteleporter);
    }

    public bool IsEntrance()
    {
        return this.GetMode() == TFObjectMode_Entrance;
    }

    public bool IsExit()
    {
        return this.GetMode() == TFObjectMode_Exit;
    }

    public int GetState()
    {
        return this.GetProp(Prop_Send, "m_iState");
    }

    public float GetRechargeTime()
    {
        return this.GetPropFloat(Prop_Send, "m_flRechargeTime") - GetGameTime();
    }

    public bool IsReadyToUse()
    {
        return this.GetState() == 2 && this.GetRechargeTime() <= 0.0;
    }
}

methodmap CObjectDispenser < CBaseObject
{
    public CObjectDispenser(int entity)
    {
        return view_as<CObjectDispenser>(entity);
    }

    public static bool IsDispenser(int entity)
    {
        return HasEntProp(entity, Prop_Send, "m_iAmmoMetal");
    }

    public int GetStoredMetal()
    {
        return this.GetProp(Prop_Send, "m_iAmmoMetal");
    }
}

enum TFGameType
{
	TFGameType_UNDEFINED = 0,
	TFGameType_CTF, // Capture the Flag
	TFGameType_CP, // Control Points
	TFGameType_ESCORT, // Payload
	TFGameType_ARENA, // Arena
	TFGameType_MVM, // Mann vs Machine
	TFGameType_RD, // Robot Destruction
	TFGameType_PASSTIME, // Passtime
	TFGameType_PD, // Player Destruction

	TFGameType_COUNT // Maximum number of know game types
}

methodmap CTFGameRules
{
    public static RoundState GetRoundState()
    {
        return GameRules_GetRoundState();
    }

    public static bool InWaitingForPlayers()
    {
        return GameRules_GetProp("m_bInWaitingForPlayers") == 1;
    }

    public static bool InOverTime()
    {
        return GameRules_GetProp("m_bInOvertime") == 1;
    }

    public static bool IsInSetup()
    {
        return GameRules_GetProp("m_bInSetup") == 1;
    }

    public static bool IsPlayingMannVsMachine()
    {
        return GameRules_GetProp("m_bPlayingMannVsMachine") == 1;
    }

    public static bool IsPlayingKOTH()
    {
        return GameRules_GetProp("m_bPlayingKoth") == 1;
    }

    public static bool IsMedievalModeActive()
    {
        return GameRules_GetProp("m_bPlayingMedieval") == 1;
    }

    public static bool IsPlayingHybridCTFCP()
    {
        return GameRules_GetProp("m_bPlayingHybrid_CTF_CP") == 1;
    }

    public static bool IsPlayingSpecialDelivery()
    {
        return GameRules_GetProp("m_bPlayingSpecialDeliveryMode") == 1;
    }

    public static bool IsPlayingRobotDestruction()
    {
        return GameRules_GetProp("m_bPlayingRobotDestructionMode") == 1;
    }

    public static void ClientSettingsChanged(int player)
    {
        ClientSettingsChanged(player);
    }

    public static TFGameType GetGameType()
    {
        return view_as<TFGameType>(GameRules_GetProp("m_nGameType"));
    }

    public static bool IsPlayerReady(int player)
    {
        return GameRules_GetProp("m_bPlayerReady", .element = player) == 1;
    }

    public static CTeamRoundTimer GetREDKOTHTimer()
    {
        return CTeamRoundTimer(GameRules_GetPropEnt("m_hRedKothTimer"));
    }

    public static CTeamRoundTimer GetBLUKOTHTimer()
    {
        return CTeamRoundTimer(GameRules_GetPropEnt("m_hBlueKothTimer"));
    }

    public static bool IsTruceActive()
    {
        return GameRules_GetProp("m_bTruceActive") == 1;
    }

    public static TFTeam GetOpposingTeam(TFTeam other)
    {
        if (other == TFTeam_Blue)
            return TFTeam_Red

        if (other == TFTeam_Red)
            return TFTeam_Blue

        return TFTeam_Unassigned;
    }

    public static CTeamTrainWatcher GetPayloadToPush(TFTeam team)
    {
        int watcher = 0;
        for(;;)
        {
            watcher = FindEntityByClassname(watcher, "team_train_watcher");

            if (!CTeamTrainWatcher.IsValidTrainWatcher(watcher))
                break;

            CTeamTrainWatcher ttw = CTeamTrainWatcher(watcher);

            if (ttw.IsDisabled())
                continue;

            if (ttw.GetTeam() == team)
                break;
        }

        return CTeamTrainWatcher(watcher);
    }

    public static CTeamTrainWatcher GetPayloadToBlock(TFTeam team)
    {
        int watcher = 0;
        for(;;)
        {
            watcher = FindEntityByClassname(watcher, "team_train_watcher");

            if (!CTeamTrainWatcher.IsValidTrainWatcher(watcher))
                break;

            CTeamTrainWatcher ttw = CTeamTrainWatcher(watcher);

            if (ttw.IsDisabled())
                continue;

            if (ttw.GetTeam() == CTFGameRules.GetOpposingTeam(team))
                break;
        }

        return CTeamTrainWatcher(watcher);
    }

    // Returns a flag for the bot of the given team to capture
    // @param team Bot team
    public static CCaptureFlag GetFlagToCapture(TFTeam team)
    {
        int entity = 0;
        for(;;)
        {
            entity = FindEntityByClassname(entity, "item_teamflag");

            CCaptureFlag flag = CCaptureFlag(entity);

            if (!flag.IsValidCaptureFlag())
                break;

            if (flag.IsDisabled()) // Ignore disabled flags
                continue;

            if (flag.IsStolen()) // Ignore flags already being carried by my team
                continue;

            if (flag.GetTeam() != team)
                break;
        }

        return CCaptureFlag(entity);
    }

    // Returns an active flag capture zone for the given team
    // @param team      Team to get capture zone for
    public static CBaseEntity GetFlagCaptureZone(TFTeam team)
    {
        int entity = -1;

        while((entity = FindEntityByClassname(entity, "func_capturezone")) != -1)
        {
            if (GetEntProp(entity, Prop_Send, "m_bDisabled") == 1)
                continue;

            if (GetEntProp(entity, Prop_Send, "m_iTeamNum") != view_as<int>(team))
                continue;

            return CBaseEntity(entity);
        }

        return CBaseEntity(-1);
    }
}

enum TFFlagStatus
{
    FlagStatus_Home = 0, // Flag is home
    FlagStatus_Stolen = (1 << 0), // Flag is stolen
    FlagStatus_Dropped = (1 << 1) // Flag is dropped
}

methodmap CCaptureFlag < CBaseAnimating
{
    public CCaptureFlag(int entity)
    {
        return view_as<CCaptureFlag>(entity);
    }

    public static bool IsTeamFlag(int entity)
    {
        return HasEntProp(entity, Prop_Send, "m_nFlagStatus");
    }

    public bool IsValidCaptureFlag()
    {
        return this.IsValid() && this.HasProp(Prop_Send, "m_nFlagStatus");
    }

    public bool IsDisabled()
    {
        return this.GetProp(Prop_Send, "m_bDisabled") == 1;
    }

    public TFFlagStatus GetStatus()
    {
        return view_as<TFFlagStatus>(this.GetProp(Prop_Send, "m_nFlagStatus"));
    }

    public bool IsHome()
    {
        return this.GetStatus() == FlagStatus_Home;
    }

    public bool IsStolen()
    {
        return this.GetStatus() == FlagStatus_Stolen;
    }

    public bool IsDropped()
    {
        return this.GetStatus() == FlagStatus_Dropped;
    }

    public int GetOwner()
    {
        return this.GetProp(Prop_Send, "m_hOwnerEntity");
    }

    public TFTeam GetTeam()
    {
        return view_as<TFTeam>(this.GetProp(Prop_Send, "m_iTeamNum"));
    }

    public void GetPosition(float position[3])
    {
        int owner = this.GetOwner();

        if (CTFPlayer.IsPlayerEntity(owner))
        {
            CTFPlayer TFPlayer = CTFPlayer(owner);
            TFPlayer.GetAbsOrigin(position);
            return;
        }
        else
        {
            this.GetAbsOrigin(position);
        }
    }
}

methodmap CTeamControlPoint < CBaseAnimating
{
    public CTeamControlPoint(int entity)
    {
        return view_as<CTeamControlPoint>(entity);
    }

    public int GetIndex()
    {
        return this.GetProp(Prop_Data, "m_iPointIndex");
    }

    public bool IsLocked()
    {
        return this.GetProp(Prop_Data, "m_bLocked") == 1;
    }

    public TFTeam GetDefaultOwningTeam()
    {
        return view_as<TFTeam>(this.GetProp(Prop_Data, "m_iDefaultOwner"));
    }

    public TFTeam GetOwningTeam()
    {
        return view_as<TFTeam>(this.GetProp(Prop_Data, "m_iTeamNum"));
    }
}

methodmap CTeamTrainWatcher < CBaseEntity
{
    public CTeamTrainWatcher(int entity)
    {
        return view_as<CTeamTrainWatcher>(entity);
    }

    public static bool IsValidTrainWatcher(int entity)
    {
        return IsValidEntity(entity) && HasEntProp(entity, Prop_Send, "m_iTrainSpeedLevel");
    }

    public int GetTrain()
    {
        char trainName[64];
        this.GetPropString(Prop_Data, "m_iszTrain", trainName, sizeof(trainName));
        return CGlobalEntityList.FindEntityByName(NULL_ENTITY, trainName);
    }

    public bool IsDisabled()
    {
        return this.GetProp(Prop_Data, "m_bDisabled") == 1;
    }

    public TFTeam GetTeam()
    {
        return view_as<TFTeam>(this.GetProp(Prop_Send, "m_iTeamNum"));
    }
}

enum TFTeamRoles
{
	TEAM_ROLE_NONE = 0,
	TEAM_ROLE_DEFENDERS,
	TEAM_ROLE_ATTACKERS,

	MAX_TEAM_ROLES
}

methodmap CTFTeam < CBaseEntity
{
    public CTFTeam(int entity)
    {
        return view_as<CTFTeam>(entity);
    }


    public TFTeam GetTeam()
    {
        return view_as<TFTeam>(this.GetProp(Prop_Send, "m_iTeamNum"));
    }

    public TFTeamRoles GetRole()
    {
        return view_as<TFTeamRoles>(this.GetProp(Prop_Send, "m_iRole"));
    }

    public int GetFlagCaptures()
    {
        return this.GetProp(Prop_Send, "m_nFlagCaptures");
    }

    public int GetLeader()
    {
        return this.GetPropEnt(Prop_Send, "m_hLeader");
    }
}

methodmap CTeamRoundTimer < CBaseEntity
{
    public CTeamRoundTimer(int entity)
    {
        return view_as<CTeamRoundTimer>(entity);
    }

    public bool IsValidRoundTimer()
    {
        return this.IsValid() && this.HasProp(Prop_Send, "m_nSetupTimeLength");
    }

    // Gets the time remaining for the current round or setup
    public float GetTimeRemaining()
    {
        return this.GetPropFloat(Prop_Send, "m_flTimerEndTime") - GetGameTime();
    }

    public float GetSetupLength()
    {
        return this.GetPropFloat(Prop_Send, "m_nSetupTimeLength");
    }

    public bool IsPaused()
    {
        return this.GetProp(Prop_Send, "m_bTimerPaused") == 1;
    }
}

methodmap CTFWeaponBase < CBaseAnimating
{
    public CTFWeaponBase(int entity)
    {
        return view_as<CTFWeaponBase>(entity);
    }

    public static bool IsTFWeapon(int entity)
    {
        return TF2Util_IsEntityWeapon(entity);
    }

    public bool IsValidTFWeapon()
    {
        return this.IsValid() && TF2Util_IsEntityWeapon(this.index);
    }

    public int GetOwner()
    {
        return this.GetPropEnt(Prop_Send, "m_hOwner");
    }

    public int GetWeaponID()
    {
        return TF2Util_GetWeaponID(this.index);
    }

    public bool IsWeapon(int weaponID)
    {
        return this.GetWeaponID() == weaponID;
    }

    public int GetWeaponMaxClip()
    {
        return TF2Util_GetWeaponMaxClip(this.index);
    }

    public int GetSlot()
    {
        return TF2Util_GetWeaponSlot(this.index);
    }

    public int GetPrimaryClip()
    {
        return this.GetProp(Prop_Send, "m_iClip1");
    }

    public int GetSecondaryClip()
    {
        return this.GetProp(Prop_Send, "m_iClip2");
    }

    public int GetPrimaryAmmoType()
    {
        return this.GetProp(Prop_Send, "m_iPrimaryAmmoType");
    }

    public int GetSecondaryAmmoType()
    {
        return this.GetProp(Prop_Send, "m_iSecondaryAmmoType");
    }

    public bool UsesPrimaryAmmo()
    {
        return this.GetPrimaryAmmoType() >= 0;
    }

    public bool UsesSecondaryAmmo()
    {
        return this.GetSecondaryAmmoType() >= 0;
    }

    public bool HasAmmo()
    {
        CTFPlayer TFPlayer = CTFPlayer(this.GetOwner());

        if (TFPlayer.index != -1)
        {
            return this.GetPrimaryClip() > 0 || TFPlayer.GetAmmoOfType(this.GetPrimaryAmmoType()) > 0 || \
            this.GetSecondaryClip() > 0 || TFPlayer.GetAmmoOfType(this.GetSecondaryAmmoType()) > 0;
        }

        return this.GetPrimaryClip() > 0 || this.GetSecondaryClip() > 0;
    }

    public bool IsMeleeWeapon()
    {
        return TF2Util_GetWeaponSlot(this.index) == TFWeaponSlot_Melee;
    }

    public static bool WeaponID_IsSniperRifle(int id)
    {
        return id == TF_WEAPON_SNIPERRIFLE || id == TF_WEAPON_SNIPERRIFLE_CLASSIC || id == TF_WEAPON_SNIPERRIFLE_DECAP;
    }
}

methodmap CItem < CBaseAnimating
{
    public CItem(int entity)
    {
        return view_as<CItem>(entity);
    }

    public bool HasEffect(int effect)
    {
        return this.GetProp(Prop_Send, "m_fEffects") & effect != 0;
    }

    public TFTeam GetTeam()
    {
        return view_as<TFTeam>(this.GetProp(Prop_Send, "m_iTeamNum"));
    }

    public bool CanBePickedByTeam(TFTeam team)
    {
        return this.GetTeam() == TFTeam_Unassigned || this.GetTeam() == team;
    }

    public bool CanBePicked()
    {
        return !this.HasEffect(EF_NODRAW);
    }
}

methodmap CFuncRegenerate < CBaseEntity
{
    public CFuncRegenerate(int entity)
    {
        return view_as<CFuncRegenerate>(entity);
    }

    public TFTeam GetTeam()
    {
        return view_as<TFTeam>(this.GetProp(Prop_Send, "m_iTeamNum"));
    }

    public bool CanBeUsedByTeam(TFTeam team)
    {
        return this.GetTeam() == TFTeam_Unassigned || this.GetTeam() == team;
    }

    public bool IsDisabled()
    {
        return this.GetProp(Prop_Data, "m_bDisabled") == 1;
    }
}