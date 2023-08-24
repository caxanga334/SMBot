

void RegisterDetour(GameData gd, const char[] fnName, DHookCallback pre, DHookCallback post)
{
	DynamicDetour detour;
	detour = DynamicDetour.FromConf(gd, fnName);
	if (!detour)
	{
		SetFailState("Failed to detour \"%s\"!", fnName);
	}
	else
	{
		detour.Enable(Hook_Pre, pre);
		detour.Enable(Hook_Post, post);
	}
	
	delete detour;
}

void SetupDetours(GameData gamedata)
{
    RegisterDetour(gamedata, "CTFBot::GetNextSpawnClassname", GetNextSpawnClassnamePre, GetNextSpawnClassnamePost);
    // RegisterDetour(gamedata, "CTFBot::AllocatePlayerEntity", AllocatePlayerEntityPre, AllocatePlayerEntityPost);
    RegisterDetour(gamedata, "CTFPlayer::CreatePlayer", CreatePlayerPre, CreatePlayerPost);
}

/**
 * CTFBot::GetNextSpawnClassname is detoured to prevent conflict between TFBot and SMBot change class behavior
 */

MRESReturn GetNextSpawnClassnamePre(int pThis, DHookReturn hReturn)
{
    if (SMBot.IsSMBot(pThis) && SMBot.IsPlayerEntity(pThis))
    {
        SMBot bot = SMBot(pThis);
        char classname[16];
        TFClassType class = bot.GetDesiredClass();
        UTIL_TF2ClassTypeToName(class, classname, sizeof(classname));
        hReturn.SetString(classname);
        return MRES_Supercede;
    }

    return MRES_Ignored;
}

MRESReturn GetNextSpawnClassnamePost(int pThis, DHookReturn hReturn)
{
    if (SMBot.IsSMBot(pThis) && SMBot.IsPlayerEntity(pThis))
    {
        SMBot bot = SMBot(pThis);
        char classname[16];
        TFClassType class = bot.GetDesiredClass();
        UTIL_TF2ClassTypeToName(class, classname, sizeof(classname));
        hReturn.SetString(classname);
        return MRES_Supercede;
    }

    return MRES_Ignored;
}


/* MRESReturn AllocatePlayerEntityPre(DHookReturn hReturn, DHookParam hParams)
{
    return MRES_Ignored;
}

MRESReturn AllocatePlayerEntityPost(DHookReturn hReturn, DHookParam hParams)
{
    return MRES_Ignored;
} */

// Overrides the entity created when a new player joins the game.
// Allows spawning the bot entity without overriding the TFBot entity.

MRESReturn CreatePlayerPre(DHookReturn hReturn, DHookParam hParams)
{
    if (g_bSpawningSMBot == true)
    {
        hParams.SetString(1, "sm_bot");
        return MRES_ChangedHandled;
    }

    return MRES_Ignored;
}

MRESReturn CreatePlayerPost(DHookReturn hReturn, DHookParam hParams)
{
    if (g_bSpawningSMBot == true)
    {
        hParams.SetString(1, "sm_bot");
        return MRES_ChangedHandled;
    }

    return MRES_Ignored;
}