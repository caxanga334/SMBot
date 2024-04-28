// standard SDK Calls

Handle g_hlookupbone;
Handle g_hgetboneposition;
// Handle g_hsnapeyeangles;
// Handle g_hweaponswitch;
Handle g_hclientsettingsupdated;
Handle g_hfindentitybyname;
Handle g_hfindentityinsphere;
// Handle g_hcreateentitybyname;
// Handle g_hctfplayercreateplayer;
Handle g_hctfbotupdatelooking;
int g_offset_hmatchingteleporter;
int g_offset_percentinvisible;

/**
 * Gets the offset
 * 
 * @param class      classname
 * @param prop       Property name
 * @param offset     base offset
 * @return           property offset + base offset
 */
int FindOffset(const char[] class, const char[] prop, int offset)
{
    int propoffset = FindSendPropInfo(class, prop);

    if (propoffset < 0)
    {
        ThrowError("Class \"%s\" does not have property \"%s\"", class, prop);
    }

    LogMessage("Found offset for %s::%s -> %i", class, prop, propoffset);

    return propoffset + offset;
}

void SetupSDKCalls(GameData gamedata)
{
    int offset = 0;
    bool fail = false;

    // int CBaseAnimating::LookupBone( const char *szName )
    StartPrepSDKCall(SDKCall_Entity);
    PrepSDKCall_SetFromConf(gamedata, SDKConf_Signature, "CBaseAnimating::LookupBone");
    PrepSDKCall_AddParameter(SDKType_String, SDKPass_Pointer);
    PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
    if ((g_hlookupbone = EndPrepSDKCall()) == null)
    {
        LogError("Failed to setup SDKCall for int CBaseAnimating::LookupBone( const char *szName )");
        fail = true;
    }

    // void CBaseAnimating::GetBonePosition ( int iBone, Vector &origin, QAngle &angles )
    StartPrepSDKCall(SDKCall_Entity);
    PrepSDKCall_SetFromConf(gamedata, SDKConf_Signature, "CBaseAnimating::GetBonePosition");
    PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
    PrepSDKCall_AddParameter(SDKType_Vector, SDKPass_ByRef, .encflags = VENCODE_FLAG_COPYBACK);
    PrepSDKCall_AddParameter(SDKType_QAngle, SDKPass_ByRef, .encflags = VENCODE_FLAG_COPYBACK);
    if ((g_hgetboneposition = EndPrepSDKCall()) == null)
    {
        LogError("Failed to setup SDKCall for void CBaseAnimating::GetBonePosition ( int iBone, Vector &origin, QAngle &angles )");
        fail = true;
    }

    // void CBasePlayer::SnapEyeAngles( const QAngle &viewAngles )
    // StartPrepSDKCall(SDKCall_Player);
    // PrepSDKCall_SetFromConf(gamedata, SDKConf_Signature, "CBasePlayer::SnapEyeAngles");
    // PrepSDKCall_AddParameter(SDKType_QAngle, SDKPass_ByRef);
    // if ((g_hsnapeyeangles = EndPrepSDKCall()) == null)
    // {
    //     LogError("Failed to setup SDKCall for void CBasePlayer::SnapEyeAngles( const QAngle &viewAngles )");
    //     fail = true;
    // }

    // bool CTFPlayer::Weapon_Switch( CBaseCombatWeapon *pWeapon, int viewmodelindex )
    // StartPrepSDKCall(SDKCall_Player);
    // PrepSDKCall_SetFromConf(gamedata, SDKConf_Virtual, "CTFPlayer::Weapon_Switch");
    // PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer);
    // PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
    // PrepSDKCall_SetReturnInfo(SDKType_Bool, SDKPass_Plain);
    // if ((g_hweaponswitch = EndPrepSDKCall()) == null)
    // {
    //     LogError("Failed to setup SDKCall for bool CTFPlayer::Weapon_Switch( CBaseCombatWeapon *pWeapon, int viewmodelindex )");
    //     fail = true;
    // }

    // void CTFGameRules::ClientSettingsChanged( CBasePlayer *pPlayer )
    StartPrepSDKCall(SDKCall_GameRules);
    PrepSDKCall_SetFromConf(gamedata, SDKConf_Virtual, "CTFGameRules::ClientSettingsChanged");
    PrepSDKCall_AddParameter(SDKType_CBasePlayer, SDKPass_Pointer);
    if ((g_hclientsettingsupdated = EndPrepSDKCall()) == null)
    {
        LogError("Failed to setup SDKCall for void CTFGameRules::ClientSettingsChanged( CBasePlayer *pPlayer )");
        fail = true;
    }

    // See: https://cs.alliedmods.net/hl2sdk-tf2/source/game/server/entitylist.cpp#621
    StartPrepSDKCall(SDKCall_EntityList);
    PrepSDKCall_SetFromConf(gamedata, SDKConf_Signature, "CGlobalEntityList::FindEntityByName");
    PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer, VDECODE_FLAG_ALLOWNULL|VDECODE_FLAG_ALLOWWORLD);     // CBaseEntity *pStartEntity
    PrepSDKCall_AddParameter(SDKType_String, SDKPass_Pointer);                                                          // const char *szName
    PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer, VDECODE_FLAG_ALLOWNULL|VDECODE_FLAG_ALLOWWORLD);     // CBaseEntity *pSearchingEntity
    PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer, VDECODE_FLAG_ALLOWNULL|VDECODE_FLAG_ALLOWWORLD);     // CBaseEntity *pActivator
    PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer, VDECODE_FLAG_ALLOWNULL|VDECODE_FLAG_ALLOWWORLD);     // CBaseEntity *pCaller
    PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_ByValue);                                                    // IEntityFindFilter *pFilter
    PrepSDKCall_SetReturnInfo(SDKType_CBaseEntity, SDKPass_Pointer);
    if ((g_hfindentitybyname = EndPrepSDKCall()) == null)
    {
        LogError("Failed to setup SDKCall for void CGlobalEntityList::FindEntityByName");
        fail = true;
    }

    // See: https://cs.alliedmods.net/hl2sdk-tf2/source/game/server/entitylist.cpp#728
    StartPrepSDKCall(SDKCall_EntityList);
    PrepSDKCall_SetFromConf(gamedata, SDKConf_Signature, "CGlobalEntityList::FindEntityInSphere");
    PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer, VDECODE_FLAG_ALLOWNULL|VDECODE_FLAG_ALLOWWORLD);     // CBaseEntity *pStartEntity
    PrepSDKCall_AddParameter(SDKType_Vector, SDKPass_ByRef);                                                            // const Vector &vecCenter
    PrepSDKCall_AddParameter(SDKType_Float, SDKPass_ByValue);                                                           // float flRadius
    PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_ByValue);                                                    // IEntityFindFilter *pFilter
    PrepSDKCall_SetReturnInfo(SDKType_CBaseEntity, SDKPass_Pointer);
    if ((g_hfindentityinsphere = EndPrepSDKCall()) == null)
    {
        LogError("Failed to setup SDKCall for void CGlobalEntityList::FindEntityInSphere");
        fail = true;
    }

    // StartPrepSDKCall(SDKCall_Static);
    // PrepSDKCall_SetFromConf(gamedata, SDKConf_Signature, "CreateEntityByName");
    // PrepSDKCall_AddParameter(SDKType_String, SDKPass_Pointer);
    // PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_ByValue);
    // PrepSDKCall_SetReturnInfo(SDKType_CBaseEntity, SDKPass_Pointer);
    // if((g_hcreateentitybyname = EndPrepSDKCall()) == null)
    // {
    //     LogError("Failed to setup SDKCall for CreateEntityByName!");
    //     fail = true;
    // }

    // StartPrepSDKCall(SDKCall_Static);
    // PrepSDKCall_SetFromConf(gamedata, SDKConf_Signature, "CTFPlayer::CreatePlayer");
    // PrepSDKCall_AddParameter(SDKType_String, SDKPass_Pointer);
    // PrepSDKCall_AddParameter(SDKType_Edict, SDKPass_Pointer);
    // PrepSDKCall_SetReturnInfo(SDKType_CBasePlayer, SDKPass_Pointer, VDECODE_FLAG_ALLOWNULL|VDECODE_FLAG_ALLOWNOTINGAME);
    // if ((g_hctfplayercreateplayer = EndPrepSDKCall()) == null)
    // {
    //     LogError("Failed to setup SDKCall for CTFPlayer::CreatePlayer!");
    //     fail = true;
    // }

    StartPrepSDKCall(SDKCall_Player);
    PrepSDKCall_SetFromConf(gamedata, SDKConf_Signature, "CTFBot::UpdateLookingAroundForIncomingPlayers");
    PrepSDKCall_AddParameter(SDKType_Bool, SDKPass_ByValue);
    if ((g_hctfbotupdatelooking = EndPrepSDKCall()) == null)
    {
        LogError("Failed to setup SDKCall for CTFBot::UpdateLookingAroundForIncomingPlayers!");
        fail = true;
    }

    offset = gamedata.GetOffset("CObjectTeleporter::m_hMatchingTeleporter");
    g_offset_hmatchingteleporter = FindOffset("CObjectTeleporter", "m_bMatchBuilding", offset);
    LogMessage("Calculated offset %i for CObjectTeleporter::m_hMatchingTeleporter", g_offset_hmatchingteleporter);

    g_offset_percentinvisible = FindOffset("CTFPlayer", "m_flInvisChangeCompleteTime", -8);
    LogMessage("CTFPlayer percent invisible offset %i", g_offset_percentinvisible);

    if (fail)
        SetFailState("SetupSDKCalls reports failure!");
}

/**
 * Look up a bone index from the given entity
 * 
 * @param entity     Entity index
 * @param name       Bone name
 * @return           Bone index or -1 if not found
 */
int LookUpBone(int entity, const char[] name)
{
    int bone = -1;
    bone = SDKCall(g_hlookupbone, entity, name);
    return bone;
}

/**
 * Gets a bone position from the given entity model
 * 
 * @param entity     Entity index
 * @param bone       Bone ID (Use LookUpBone)
 * @param origin     Buffer to store the bone origin
 * @param angles     Buffer to store the bone angles
 */
void GetBonePosition(int entity, int bone, float origin[3], float angles[3])
{
    SDKCall(g_hgetboneposition, entity, bone, origin, angles);
}

/**
 * Sets the player view angle
 * 
 * @param player     Player index
 * @param angles     Angle to set
 */
// void SnapEyeAngles(int player, float angles[3])
// {
//     SDKCall(g_hsnapeyeangles, player, angles);
// }

/**
 * Switches to the given weapon (providing it has ammo)
 * 
 * @param player             Player index
 * @param weapon             Weapon entity index
 * @param viewmodelindex     ???
 * @return                   true is switch suceeded
 */
// bool Weapon_Switch(int player, int weapon, int viewmodelindex = 0)
// {
//     return SDKCall(g_hweaponswitch, player, weapon, viewmodelindex);
// }

/**
 * Informs that the client settings has changed
 * 
 * @param player     Player index
 */
void ClientSettingsChanged(int player)
{
    SDKCall(g_hclientsettingsupdated, player);
}

methodmap CGlobalEntityList
{
    // Finds an entity by name
    //
    // @param startentity Entity index to start the search from, can be NULL_ENTITY
    // @param name Name of the entity to find
    // @param searchingentity Unknown
    // @param activator Activator entity if this was called from an input handler or Use handler. 
    // @param caller Probably caller, see activator
    // @note For more information about searchingentity, activator and caller, see FindEntityProcedural
    // @note https://cs.alliedmods.net/hl2sdk-tf2/source/game/server/entitylist.cpp#553
    public static int FindEntityByName(int startentity, const char[] name, int searchingentity = NULL_ENTITY, int activator = NULL_ENTITY, int caller = NULL_ENTITY)
    {
        return SDKCall(g_hfindentitybyname, startentity, name, searchingentity, activator, caller, 0);
    }

    // Finds an entity in sphere
    //
    // @param startentity Entity index to start the search from, can be null (0)
    // @param vector Vector of the sphere center
    // @param radius Sphere radius
    // @return       Entity index or -1 if invalid
    public static int FindEntityInSphere(int startentity, const float vector[3], float radius)
    {
        return SDKCall(g_hfindentityinsphere, startentity, vector, radius, 0);
    }
}

// int CreateEntityByNameEx(const char[] classname, int forcedindex = -1)
// {
//     return SDKCall(g_hcreateentitybyname, classname, forcedindex);
// }

// int CreatePlayer(const char[] classname, int edict)
// {
//     return SDKCall(g_hctfplayercreateplayer, classname, edict);
// }