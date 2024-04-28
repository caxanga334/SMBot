/**
 * SMBot utility functions
 */

/* https://developer.valvesoftware.com/wiki/TFBot_Technicalities#Rosters */

#define MAX_TF_CLASSES 10 // array size to hold data for each class definition

/**
 * Easy print a vector
 * 
 * @param name       Vector name for identification
 * @param vector     Vector value
 */
stock void PrintVectorToServer(const char[] name, const float vector[3])
{
    PrintToServer("Vector %s (%.2f, %.2f, %.2f)", name, vector[0], vector[1], vector[2]);
}

/**
 * Copies a vector
 * 
 * @param a     Vector to be copied
 * @param b     Vector to store the copy
 */
void VectorCopy(float a[3], float b[3])
{
    b[0] = a[0];
    b[1] = a[1];
    b[2] = a[2];
}

/**
 * Copies a vector
 * 
 * @param a        Vector to be copied
 * @param b        Vector to store the copy
 * @param size     Size of the two vectors
 */
void VectorCopyEx(any[] a, any[] b, int size)
{
    for(int i = 0;i < size;i++)
    {
        b[i] = a[i];
    }
}

/**
 * Propagates a custom event to all NextBots
 * 
 * @param event     Event name
 */
void PropagateCustomEvent(const char[] event)
{
    for(int i = 1; i <= MaxClients; i++)
    {
        if (!IsClientInGame(i))
            continue;

        if (!IsFakeClient(i))
            continue;

        INextBot bot = CBaseNPC_GetNextBotOfEntity(i);

        if (bot == NULL_NEXT_BOT)
            continue;

        if (!SMBot.IsSMBot(i))
            continue;

        bot.OnCommandString(event);
    }
}

/**
 * Propagates a custom event to a specific NextBot
 * 
 * @param entity    Bot entity index
 * @param event     Event name
 * 
 */
void PropagateCustomEventEx(int entity, const char[] event)
{
    INextBot bot = CBaseNPC_GetNextBotOfEntity(entity);

    if (bot == NULL_NEXT_BOT)
        return;
    
    if (!SMBot.IsSMBot(entity))
        return;

    bot.OnCommandString(event);
}

// Struct simulating the game CBaseHandle class
enum struct CBaseHandle
{
    int reference;

    void Init(int entity)
    {
        this.reference = EntIndexToEntRef(entity);
    }

    int GetEntity()
    {
        return EntRefToEntIndex(this.reference);
    }

    bool IsValid()
    {
        return EntRefToEntIndex(this.reference) != -1;
    }
}

/**
 * Gets the entity eye position
 * 
 * @param entity     Param description
 * @param buffer     Param description
 * @return           Return description
 */
bool GetEyePosition(int entity, float buffer[3])
{
    if (!HasEntProp(entity, Prop_Send, "m_vecViewOffset"))
        return false;

    CBaseEntity baseent = CBaseEntity(entity);
    float origin[3];

    GetEntPropVector(entity, Prop_Send, "m_vecViewOffset", buffer);
    baseent.GetAbsOrigin(origin);
    buffer[0] = origin[0];
    buffer[1] = origin[1];
    buffer[2] = buffer[2] + origin[2];
    return true;
}

/**
 * 
 * 
 * @param pitch     Param description
 * @return          Return description
 */
float NormalizeViewPitch(float pitch)
{
    if (pitch > 90.0)
    {
        pitch -= 360.0;
    }
    else if (pitch < -90.0)
    {
        pitch += 360.0;
    }

    return pitch;
}

// Simple trace filter that hits worldspawn only
bool TraceFilter_WorldOnly(int entity, int contentsMask)
{
    if (entity == 0)
        return true;

    return false;
}

/**
 * Performs a simple trace line between start and end
 * 
 * @param start     Start position vector
 * @param end       End position/angle vector
 * @param mask      Mask to use
 * @param type      Ray Type
 * @return          true if hit
 */
bool UTIL_QuickSimpleTraceLine(const float start[3], const float end[3], const int mask = MASK_PLAYERSOLID, const RayType type = RayType_EndPoint)
{
    Handle trace = TR_TraceRayFilterEx(start, end, mask, type, TraceFilter_WorldOnly);
    bool didhit = TR_DidHit(trace);
    delete trace;
    return didhit;
}

/**
 * Utility function to draw a laser beam between two points
 * 
 * @param client       Client index to send the laser to or -1 to send to all clients in range of the start position
 * @param start        Start position vector
 * @param end          End position vector
 * @param colors       Laser color vector (red, green, blue, alpha)
 * @param lifetime     Laser life time
 * @param width        Laser width
 */
void UTIL_DrawLaser(const int client, const float start[3], const float end[3], const int colors[4] = { 255, 255, 255, 255 }, const float lifetime = 1.0, const float width = 1.0)
{
    TE_SetupBeamPoints(start, end, g_iLaserSprite, g_iHaloSprite, 0, 0, lifetime, width, width, 1, 0.0, colors, 0);

    if (client <= 0 || client > MaxClients)
    {
        TE_SendToAllInRange(start, RangeType_Visibility, 0.1);
    }
    else
    {
        TE_SendToClient(client, 0.1);
    }
}

void UTIL_GetMapName(char[] name, int size)
{
    char buffer[128];
    GetCurrentMap(buffer, sizeof(buffer));
    GetMapDisplayName(buffer, name, size);
}

/**
 * Approuches a target value at a given speed
 * 
 * @param target     Target value to approuch
 * @param value      Value that will approuch the target
 * @param speed      Approuch speed
 * @return           Value closer to target
 * @note             See https://cs.alliedmods.net/hl2sdk-tf2/source/mathlib/mathlib_base.cpp#3303
 */
stock float UTIL_Approach(float target, float value, float speed)
{
    float delta = target - value;

    if ( delta > speed )
        value += speed;
    else if ( delta < -speed )
        value -= speed;
    else 
        value = target;

    return value;
}

void UTIL_PathDrawColors(const SegmentType type, int colors[4])
{
    switch(type)
    {
        case DROP_DOWN:
        {
            colors = { 255, 0, 0, 255 };
        }
        case JUMP_OVER_GAP:
        {
            colors = { 0, 255, 0, 255 };
        }
        case CLIMB_UP:
        {
            colors = { 0, 0, 255, 255 };
        }
        default:
        {
            colors = { 255, 255, 255, 255 };
        }
    }
}

void UTIL_TF2ClassTypeToName(const TFClassType class, char[] buffer, int size)
{
    switch(class)
    {
        case TFClass_Scout: strcopy(buffer, size, "scout");
        case TFClass_Soldier: strcopy(buffer, size, "soldier");
        case TFClass_Pyro: strcopy(buffer, size, "pyro");
        case TFClass_DemoMan: strcopy(buffer, size, "demoman");
        case TFClass_Heavy: strcopy(buffer, size, "heavyweapons");
        case TFClass_Engineer: strcopy(buffer, size, "engineer");
        case TFClass_Medic: strcopy(buffer, size, "medic");
        case TFClass_Sniper: strcopy(buffer, size, "sniper");
        case TFClass_Spy: strcopy(buffer, size, "spy");
        default: strcopy(buffer, size, "soldier");
    }
}

/**
 * Counts the number of players in each TF class
 *
 * @param ignore         (Optional) client index to exclude
 * @param class_count    Array to store the class count
 * @param team           (Optional) team filter
 */
void UTIL_CountClassCount(const int ignore = -1, int class_count[MAX_TF_CLASSES], const TFTeam team)
{
    for(int client = 1; client <= MaxClients; client++)
    {
        if (ignore == client)
            continue;

        if (!IsClientInGame(client))
            continue;

        if (team != TFTeam_Unassigned && TF2_GetClientTeam(client) != team)
            continue;

        TFClassType class = TF2_GetPlayerClass(client);
        class_count[view_as<int>(class)]++;
    }
}

enum struct SMBotClassRoster
{
    // static data
    int minTeamSize[MAX_TF_CLASSES]; // min number of players on the team for the class to be selected
    int playerrate[MAX_TF_CLASSES]; // must have 1 for every N number of players in the team
    int minimum[MAX_TF_CLASSES]; // must have at least this number in the team
    int maximum[MAX_TF_CLASSES]; // class count cannot exceed this
    // data for selection
    bool available[MAX_TF_CLASSES];
    int numinclass[MAX_TF_CLASSES];
    TFTeam team;
    int client;

    void Init(int minTeamSize[MAX_TF_CLASSES], int playerrate[MAX_TF_CLASSES], int minimum[MAX_TF_CLASSES], int maximum[MAX_TF_CLASSES])
    {
        this.minTeamSize = minTeamSize;
        this.playerrate = playerrate;
        this.minimum = minimum;
        this.maximum = maximum;
    }

    void SetTargetClient(int client)
    {
        this.client = client;
        this.team = TF2_GetClientTeam(client);
    }

    void Compute()
    {
        int numInTeam = GetTeamClientCount(this.client);
        UTIL_CountClassCount(-1, this.numinclass, this.team);

        for(int cls = 1; cls < MAX_TF_CLASSES; cls++)
        {
            if (this.minTeamSize[cls] < numInTeam)
            {
                this.available[cls] = false;
            }
            else if (this.numinclass[cls] > this.maximum[cls])
            {
                this.available[cls] = false;
            }
            else
            {
                this.available[cls] = true;
            }
        }
    }

    TFClassType SelectClass()
    {
        int availableindexes[MAX_TF_CLASSES] = { 0, ... };
        int maxindex = 0;
        int numInTeam = GetTeamClientCount(this.client);

        for(int cls = 1; cls < MAX_TF_CLASSES; cls++)
        {
            if (this.numinclass[cls] < this.minimum[cls])
            {
                return view_as<TFClassType>(cls);
            }

            if (this.playerrate[cls] > 0)
            {
                int minrate = numInTeam/this.playerrate[cls];

                if (this.numinclass[cls] < minrate)
                {
                    return view_as<TFClassType>(cls);
                }
            }

            availableindexes[maxindex] = cls;
            maxindex++;
        }

        return view_as<TFClassType>(availableindexes[GetRandomInt(0, maxindex - 1)]);
    }
}

SMBotClassRoster g_defaultclassroster;
SMBotClassRoster g_mvmclassroster;

void UTIL_SetupClassRosters()
{
    // order is undefined (unused), scout, sniper, soldier, demo, medic, heavy, pyro, spy, engineer

    int defaultMinTeamSize[MAX_TF_CLASSES] = { 0, 3, 6, 0, 0, 0, 0, 0, 6, 3 };
    int defaultPlayerrate[MAX_TF_CLASSES] = { 0, 0, 0, 0, 0, 4, 0, 0, 0, 6 };
    int defaultMinimum[MAX_TF_CLASSES] = { 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 };
    int defaultMaximum[MAX_TF_CLASSES] = { 0, 0, 3, 0, 0, 0, 3, 0, 2, 2 };

    int mvmMinTeamSize[MAX_TF_CLASSES] = { 0, 3, 3, 0, 0, 0, 0, 0, 3, 0 };
    int mvmPlayerrate[MAX_TF_CLASSES] = { 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 };
    int mvmMinimum[MAX_TF_CLASSES] = { 0, 0, 1, 0, 0, 1, 0, 0, 0, 1 };
    int mvmMaximum[MAX_TF_CLASSES] = { 0, 0, 2, 0, 0, 0, 2, 0, 2, 2 };

    g_defaultclassroster.Init(defaultMinTeamSize, defaultPlayerrate, defaultMinimum, defaultMaximum);
    g_mvmclassroster.Init(mvmMinTeamSize, mvmPlayerrate, mvmMinimum, mvmMaximum);
}

#define MAX_WEAPONS_DATA 3 // array size of weapons that we care about (prim, sec, melee)

// How the bot identifies a weapon
enum SMBotWeaponType
{
    BotWeaponType_CombatWeapon = 0, // Default type, a weapon that when fired damages enemies
    BotWeaponType_Healing, // This weapon primary function is healing teammates
    BotWeaponType_Buff, // This weapon provides a buff for the bot and/or teammates
    BotWeaponType_Food, // This weapons heal the user when used
    BotWeaponType_Thrown, // Projectile weapons that can be thrown at enemies
    BotWeaponType_Cosmetic, // This weapon is cosmetic and doesn't have any function

    BotWeaponType_Max, // Max types
};

enum struct SMBotWeaponManager
{
    bool canbeused[MAX_WEAPONS_DATA]; // can the weapon be used
    SMBotWeaponType type[MAX_WEAPONS_DATA]; // how the bot identifies this weapon
    float minrange[MAX_WEAPONS_DATA]; // minimum range
    float maxrange[MAX_WEAPONS_DATA]; // maximum range

    void ResetWeaponInfo()
    {
        for(int weaponIndex = 0; weaponIndex < MAX_WEAPONS_DATA; weaponIndex++)
        {
            this.canbeused[weaponIndex] = true;
            this.type[weaponIndex] = BotWeaponType_CombatWeapon;
            this.minrange[weaponIndex] = -1.0;
            this.maxrange[weaponIndex] = -1.0;
        }
    }

    void UpdateWeaponInfo(int slot, bool canbeused = true, SMBotWeaponType type = BotWeaponType_CombatWeapon, float minrange = -1.0, float maxrange = -1.0)
    {
        this.canbeused[slot] = true;
        this.type[slot] = type;
        this.minrange[slot] = minrange;
        this.maxrange[slot] = maxrange;
    }

    /**
     * Given a distance to a threat, select the first best weapon for it
     * 
     * @param rangeTO range to the threat
     * @return slot of the best weapon or -1 if no weapon
     * @note This performs very basic checks
     */
    int SelectBestWeaponForThreat(const float rangeTo)
    {
        for(int slot = 0; slot < MAX_WEAPONS_DATA; slot++)
        {
            if (this.canbeused[slot] == false)
                continue;

            if (this.type[slot] != BotWeaponType_CombatWeapon)
                continue;

            if (this.minrange[slot] >= rangeTo)
                continue;
            
            if (this.maxrange[slot] >= rangeTo)
                continue;
            
            return slot; // always return the first best since we start from the primary slot
        }

        return -1; // no best weapon
    }

    int SelectOpportunisticWeapon(const float healthPercent, const bool threat, const float rangeTo)
    {
        for(int slot = 0; slot < MAX_WEAPONS_DATA; slot++)
        {
            if (this.canbeused[slot] == false)
                continue;

            // Use self healing weapons when below 50% health and we don't have a visible threat
            if (this.type[slot] == BotWeaponType_Food && healthPercent >= 0.50 || threat == true)
                continue;

            // Never use these without a visible threat
            if ((this.type[slot] == BotWeaponType_Buff || this.type[slot] == BotWeaponType_Thrown) && threat == false)

            if (this.minrange[slot] >= rangeTo)
                continue;
            
            if (this.maxrange[slot] >= rangeTo)
                continue;
            
            return slot; // always return the first best since we start from the primary slot
        }

        return -1;
    }
}