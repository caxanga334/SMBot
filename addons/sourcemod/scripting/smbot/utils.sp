/**
 * SMBot utility functions
 */

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