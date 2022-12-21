

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