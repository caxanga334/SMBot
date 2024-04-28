ConVar tf_bot_difficulty = null;
ConVar sm_smbot_vis_search_increment = null;
ConVar sm_smbot_nav_danger_decay_rate = null;

void SetupConVars()
{
    CreateConVar("sm_smbot_version", PLUGIN_VERSION, "SMBot plugin version.", FCVAR_DONTRECORD|FCVAR_NOTIFY|FCVAR_REPLICATED);

    tf_bot_difficulty = FindConVar("tf_bot_difficulty");
    if (tf_bot_difficulty == null)
    {
        SetFailState("Failed to find convar \"tf_bot_difficulty\"!");
    }

    AutoExecConfig_SetFile("smbot.plugins");
    
    sm_smbot_vis_search_increment = AutoExecConfig_CreateConVar("sm_smbot_vis_search_increment", "64", "The AI vision search should increment by this amount on each frame.\nHigher values are more performance intensive!", FCVAR_NONE, true, 4.0, true, 256.0);
    sm_smbot_nav_danger_decay_rate = AutoExecConfig_CreateConVar("sm_smbot_nav_danger_decay_rate", "0.10", "Nav danger decay rate per second.", FCVAR_NONE, true, 0.0, true, 50.0);

    AutoExecConfig_ExecuteFile();
    AutoExecConfig_CleanFile();
}

