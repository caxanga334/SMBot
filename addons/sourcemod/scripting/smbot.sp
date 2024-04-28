#include <sourcemod>
#include <sdkhooks>
#include <sdktools>
#include <dhooks>
#include <tf2>
#include <tf2_stocks>
#include <tf2utils>
#include <smlib/math>
#include <cbasenpc>
#include <cbasenpc/util>
#include <cbasenpc/tf/nav>
#include <autoexecconfig>
#include <vscript>

#include "smbot/sdktimers"

#pragma newdecls required
#pragma semicolon 1

#define PLUGIN_VERSION "0.0.1-alpha"
#define MAX_CONTROL_POINTS 8
#define NULL_ENTITY 0 // passes a NULL entity for SDK calls
#define TF_MAXPLAYERS 102
#define MAX_EDICTS 2048
#define PITCH 0
#define YAW 1
#define ROLL 2

public Plugin myinfo =
{
    name = "[TF2] SMBot",
    author = "caxanga334",
    description = "Player Bot for Team Fortress 2 developed using the NextBot Framework.",
    version = PLUGIN_VERSION,
    url = "https://github.com/caxanga334/SMBot"
};

// GLOBALS
Handle g_hDebugHUD1;
Handle g_hDebugHUD2;
int g_iDebugBotTarget;
int g_iLaserSprite;
int g_iHaloSprite;
bool g_bSpawningSMBot; // when true, enable our detour on CTFPlayer::CreatePlayer
float g_flSpawnBotDelay;

#include "smbot/utils.sp"
#include "smbot/vscript.sp"
#include "smbot/gameevents.sp"
#include "smbot/cvars.sp"
#include "smbot/navdata.sp"
#include "smbot/detours.sp"
#include "smbot/sdkcalls.sp"
#include "smbot/nodes.sp"
#include "smbot/entities.sp"
#include "smbot/body.sp"
#include "smbot/methodmaps.sp"
#include "smbot/path.sp"
#include "smbot/behavior/mainaction.sp"

public void OnPluginStart()
{
    SMBot.Initialize();
    g_bSpawningSMBot = false;

    RegAdminCmd("sm_smbot_add_bot", Cmd_AddBot, ADMFLAG_ROOT, "Adds a new bot to the game.");
    RegAdminCmd("sm_smbot_toggle_debug", Cmd_toggledebug, ADMFLAG_ROOT, "Toggles bot debugging information.");
    RegAdminCmd("sm_smbot_set_debug_target", Cmd_setdebugtarget, ADMFLAG_ROOT, "Sets the bot to debug.");
    RegAdminCmd("sm_smbot_print_bot_actions", Cmd_printbotactions, ADMFLAG_ROOT, "Prints all bot actions.");
    RegAdminCmd("sm_smbot_vscript_test", Cmd_VscriptTest, ADMFLAG_ROOT, "Generic vscript test command.");
    RegAdminCmd("sm_smbot_test", Cmd_test, ADMFLAG_ROOT, "Generic feature test command.");
    RegAdminCmd("sm_smbot_node_edit", Cmd_nodeedit, ADMFLAG_ROOT, "Toggles node edit mode.");
    RegAdminCmd("sm_smbot_node_save", Cmd_nodesave, ADMFLAG_ROOT, "Saves the current nodes to file.");
    RegAdminCmd("sm_smbot_node_add", Cmd_nodeadd, ADMFLAG_ROOT, "Adds a new node.");
    RegAdminCmd("sm_smbot_node_remove", Cmd_noderemove, ADMFLAG_ROOT, "Removes the nearest node.");
    RegAdminCmd("sm_smbot_node_checkvis", Cmd_nodecheckvis, ADMFLAG_ROOT, "Shows all visible nodes for the nearest node.");
    RegAdminCmd("sm_smbot_node_goto", Cmd_nodegoto, ADMFLAG_ROOT, "Teleports you to a specific node.");
    RegAdminCmd("sm_smbot_node_update", Cmd_nodeupdate, ADMFLAG_ROOT, "Updates an existing node.");
    RegAdminCmd("sm_smbot_node_drawall", Cmd_nodedrawall, ADMFLAG_ROOT, "Draws all nearby nodes.");
    RegAdminCmd("sm_smbot_node_dumpinfo", Cmd_nodedumpinfo, ADMFLAG_ROOT, "Dump information about a single node.");

    GameData gamedata = new GameData("smbot.games");
    SetupDetours(gamedata);
    SetupSDKCalls(gamedata);
    delete gamedata;

    SetupConVars();
    SetupGameEvents();

    g_hDebugHUD1 = CreateHudSynchronizer();
    g_hDebugHUD2 = CreateHudSynchronizer();

    LoadTranslations("common.phrases");

    TheNodes.BuildNodeDirectory();

    UTIL_SetupClassRosters();

    CreateTimer(1.0, Timer_NavDataUpdate, _, TIMER_REPEAT);
}

public void OnAllPluginsLoaded()
{
    LogMessage("SMBot version %s loaded!", PLUGIN_VERSION);
}

void ResetGlobals(int index)
{
    g_bIsLooking[index] = false;
    g_flNextCommandTime[index] = 0.0;
    g_flLookAtTime[index] = 0.0;
    g_iLookPriority[index] = BORING;
    g_flIgnoreEnemiesTime[index] = -1.0;
    for (int bt = 0; bt < view_as<int>(MAX_BUTTONS); bt++)
    {
        g_ButtonTimers[index][bt].Invalidate();
    }

    g_bClientDebugging[index] = false;
    g_iVisionSearchLastIndex[index] = MaxClients + 1;
    g_hCurrentPath[index] = view_as<Path>(0);
    g_flNextChangeClassTime[index] = 0.0;
    g_HomeArea[index] = NULL_AREA;
    g_iCurrentUsedNode[index] = INVALID_NODE_ID;
    g_hMySentryGun[index] = -1;
    g_hMyDispenser[index] = -1;
    g_hMyTeleEntrance[index] = -1;
    g_hMyTeleExit[index] = -1;
}

public void Precache()
{
    g_iLaserSprite = PrecacheModel("materials/sprites/laserbeam.vmt");
    g_iHaloSprite = PrecacheModel("materials/sprites/halo01.vmt");
}

public void OnMapStart()
{
    Precache();

    // Reset some variables, important to reset all time based variables since GetGameTime resets
    for(int i = 1; i <= MaxClients; i++)
    {
        ResetGlobals(i);
    }

    TheNodes.ClearMapData();
    TheNodes.LoadNodes();
    CSMBotNavData.OnRoundRestart();

    g_flSpawnBotDelay = 0.0;
}

public void OnClientPutInServer(int client)
{
    ResetGlobals(client);

    if (!IsFakeClient(client))
    {
        g_smbot[client] = false;
        SDKHook(client, SDKHook_PostThinkPost, OnClientPostThink);
    }
}

public void OnClientDisconnect(int client)
{
    ResetGlobals(client);
    g_smbot[client] = false;

    if (g_iDebugBotTarget == client)
        g_iDebugBotTarget = -1;

    if (TheNodes.GetEditor() == client)
    {
        TheNodes.ClearEditor();
    }

    if (!IsFakeClient(client))
    {
        SDKUnhook(client, SDKHook_PostThinkPost, OnClientPostThink);
    }
}

public Action OnPlayerRunCmd(int client, int& buttons, int& impulse, float vel[3], float angles[3], int& weapon, int& subtype, int& cmdnum, int& tickcount, int& seed, int mouse[2])
{
    if (!CTFPlayer.IsPlayerEntity(client))
        return Plugin_Continue;

    if (!SMBot.IsSMBot(client))
        return Plugin_Continue;

    SMBot bot = SMBot(client);
    PlayerBody body = bot.GetPlayerBody();
    bool changed = false;

    if (!bot.IsPlaying())
        return Plugin_Continue;

    if (!bot.IsAlive())
    {
        if (body.IsLooking())
        {
            body.MyReset();
            bot.ReleaseAllButtons();
        }

        return Plugin_Continue;
    }

    if (body.IsLooking())
    {
        body.RunLook(angles);
        changed = true;
    }

    bot.ProcessButtons(buttons, changed);

    return changed ? Plugin_Changed : Plugin_Continue;
}

/* SDK HOOKS */

// Post think for non bot clients
void OnClientPostThink(int client)
{
    CClient botclient = CClient(client);
    CTFPlayer TFPlayer = CTFPlayer(client);
    int target = TFPlayer.GetObserverTarget();
    SMBot smbot = SMBot(target);

    if (botclient.debugging && botclient.debughudtimer <= GetGameTime() && SMBot.IsSMBot(target) && TheNodes.GetEditor() != client)
    {
        botclient.debughudtimer = 1.0;
        SetHudTextParams(0.1, 0.20, 1.0, 255, 255, 0, 255);
        ShowSyncHudText(client, g_hDebugHUD1, "Debugging %N", target);
        SetHudTextParams(0.1, 0.25, 1.0, 255, 255, 0, 255);
        ShowSyncHudText(client, g_hDebugHUD2, "%s", g_szBehaviorDebug[target]);

        Path path = smbot.GetCurrentPath();

        if (path != view_as<Path>(0) && smbot.IsAlive())
        {
            Segment first = path.FirstSegment();
            Segment next = NULL_PATH_SEGMENT;

            if (first != NULL_PATH_SEGMENT)
            {
                next = path.NextSegment(first);
                float start[3], end[3];
                int colors[4];

                while(first != NULL_PATH_SEGMENT && next != NULL_PATH_SEGMENT)
                {
                    path = smbot.GetCurrentPath();
                    if (path == view_as<Path>(0))
                        break;

                    first.GetPosition(start);
                    next.GetPosition(end);
                    UTIL_PathDrawColors(first.type, colors);
                    UTIL_DrawLaser(client, start, end, colors, 1.5);
                    first = next;
                    next = path.NextSegment(first);
                }
            }
        }
    }
    else if (TheNodes.GetEditor() == client)
    {
        float origin[3];
        GetClientAbsOrigin(client, origin);
        CNode node = TheNodes.GetNearestNode(origin);

        if (node.IsValid())
        {
            if (TheNodes.ShouldDraw())
            {
                float pos[3];
                float vector[3];
                char hintname[16];
                char teamname[8];

                node.GetOrigin(pos);
                node.GetHintVector(vector);
                node.GetHintName(hintname, sizeof(hintname));
                node.Draw(0.400);

                switch(node.team)
                {
                    case TFTeam_Blue: strcopy(teamname, sizeof(teamname), "BLU");
                    case TFTeam_Red: strcopy(teamname, sizeof(teamname), "RED");
                    default: strcopy(teamname, sizeof(teamname), "None");
                }

                SetHudTextParams(0.1, 0.20, 1.0, 255, 255, 0, 255);
                ShowSyncHudText(client, g_hDebugHUD1, "Node #%i (%.1f, %.1f, %.1f) - (%.1f, %.1f, %.1f)", node.index, pos[0], pos[1], pos[2], vector[0], vector[1], vector[2]);
                SetHudTextParams(0.1, 0.25, 1.0, 255, 255, 0, 255);
                ShowSyncHudText(client, g_hDebugHUD2, "Hint: %s - Team: %s", hintname, teamname);

                TheNodes.SetNextDrawTime(0.250);
            }
        }
    }
}

/* COMMANDS */

Action Cmd_AddBot(int client, int args)
{
    if (g_flSpawnBotDelay >= GetGameTime())
    {
        ReplyToCommand(client, "SMBot: Add bot is in cooldown.");
        return Plugin_Handled;
    }

    if (g_bSpawningSMBot == true)
    {
        ReplyToCommand(client, "SMBot: Add bot is in cooldown.");
        return Plugin_Handled;
    }

    g_bSpawningSMBot = true;
    g_flSpawnBotDelay = GetGameTime() + 1.0;
    RequestFrame(Frame_AddBot);

    return Plugin_Handled;
}

void Frame_AddBot()
{
    SMBot.AllocateSMBotPlayer();
    CreateTimer(0.5, Timer_AddBot, _, TIMER_FLAG_NO_MAPCHANGE);
}

Action Timer_AddBot(Handle timer)
{
    g_bSpawningSMBot = false;
    return Plugin_Stop;
}

Action Cmd_toggledebug(int client, int args)
{
    CClient botclient = CClient(client);

    if (!botclient.IsValid())
    {
        ReplyToCommand(client, "This command can only be used in-game!");
        return Plugin_Handled;
    }

    botclient.debugging = !botclient.debugging;
    ReplyToCommand(client, "Bot debugging is %s.", botclient.debugging ? "enabled" : "disabled");
    
    return Plugin_Handled;
}

Action Cmd_setdebugtarget(int client, int args)
{
    if (args < 1)
    {
        ReplyToCommand(client, "[SM] Usage: sm_smbot_set_debug_target <bot name>");
        return Plugin_Handled;
    }

    char arg1[MAX_NAME_LENGTH];
    GetCmdArg(1, arg1, sizeof(arg1));
    char target_name[MAX_TARGET_LENGTH];
    int target_list[MAXPLAYERS + 1], target_count;
    bool tn_is_ml;

    if ((target_count = ProcessTargetString(arg1, client, target_list, target_count, COMMAND_FILTER_CONNECTED|COMMAND_FILTER_NO_MULTI, target_name, sizeof(target_name), tn_is_ml)) <= 0)
    {
        ReplyToTargetError(client, target_count);
        return Plugin_Handled;
    }

    if (target_count >= 2)
    {
        ReplyToTargetError(client, -7);
        return Plugin_Handled;
    }

    for(int i = 0; i < target_count; i++)
    {
        if (SMBot.IsSMBot(target_list[i]))
        {
            g_iDebugBotTarget = target_list[i];
            break;
        }
    }
    
    if (tn_is_ml)
    {
        ShowActivity2(client, "[SMBot] ", "Set debug target to %t.", target_name);
    }
    else
    {
        ShowActivity2(client, "[SMBot] ", "Set debug target to %s.", target_name);
    }

    return Plugin_Handled;
}

Action Cmd_printbotactions(int client, int args)
{
    for(int bot = 1; bot <= MaxClients; bot++)
    {
        if (SMBot.IsSMBot(bot))
        {
            PrintToChatAll("Action for %N", bot);
            PrintToChatAll(g_szBehaviorDebug[bot]);
        }
    }

    return Plugin_Handled;
}

Action Cmd_test(int client, int args)
{
    CClient botclient = CClient(client);

    if (!botclient.IsValid())
    {
        ReplyToCommand(client, "This command can only be used in-game!");
        return Plugin_Handled;
    }

    int offset = FindOffset("CTFPlayer", "m_flInvisChangeCompleteTime", -8);
    float vis = GetEntDataFloat(client, offset);

    PrintToChat(client, "Percent Invisible: %.1f", vis);
    
    return Plugin_Handled;
}

Action Cmd_VscriptTest(int client, int args)
{
    CClient botclient = CClient(client);

    if (!botclient.IsValid())
    {
        ReplyToCommand(client, "This command can only be used in-game!");
        return Plugin_Handled;
    }

    return Plugin_Handled;
}

Action Cmd_nodeedit(int client, int args)
{
    CClient botclient = CClient(client);

    if (!botclient.IsValid())
    {
        ReplyToCommand(client, "This command can only be used in-game!");
        return Plugin_Handled;
    }

    if (TheNodes.IsEditing())
    {
        TheNodes.ClearEditor();
        ReplyToCommand(client, "[SMBot] Node editing disabled.");
    }
    else
    {
        TheNodes.SetEditor(client);
        ReplyToCommand(client, "[SMBot] Node editing enabled.");
    }
    
    return Plugin_Handled;
}

Action Cmd_nodesave(int client, int args)
{
    CClient botclient = CClient(client);

    if (!botclient.IsValid())
    {
        ReplyToCommand(client, "This command can only be used in-game!");
        return Plugin_Handled;
    }

    g_bHasVisibilityData = false; // force vis data to be rebuilt
    TheNodes.SaveNodes();
    ReplyToCommand(client, "Nodes saved!");
    
    return Plugin_Handled;
}

Action Cmd_nodeadd(int client, int args)
{
    CClient botclient = CClient(client);

    if (!botclient.IsValid())
    {
        ReplyToCommand(client, "This command can only be used in-game!");
        return Plugin_Handled;
    }

    if (args < 2)
    {
        ReplyToCommand(client, "Usage: sm_smbot_node_add <hint> <team>");
        return Plugin_Handled;
    }

    if (TheNodes.GetEditor() != client)
    {
        ReplyToCommand(client, "You don't have editing rights!");
        return Plugin_Handled;
    }

    char arg1[32];
    char arg2[16];

    GetCmdArg(1, arg1, sizeof(arg1));
    GetCmdArg(2, arg2, sizeof(arg2));

    NodeHint hint = TheNodes.GetNodeHintByName(arg1);
    TFTeam team = TFTeam_Unassigned;
    
    if (hint == NodeHint_Unknown)
    {
        char hintnames[256];
        TheNodes.GetAllAvailableHintsString(hintnames, sizeof(hintnames));
        ReplyToCommand(client, "Error: Unknown node hint of type \"%s\"", arg1);
        ReplyToCommand(client, "Valid hints: %s", hintnames);
        return Plugin_Handled;
    }

    if (strncmp(arg2, "red", 3, false) == 0)
    {
        team = TFTeam_Red;
    }
    else if (strncmp(arg2, "blu", 3, false) == 0)
    {
        team = TFTeam_Blue;
    }
    else if (strncmp(arg2, "blue", 4, false) == 0)
    {
        team = TFTeam_Blue;
    }
    else if (strncmp(arg2, "none", 4, false) == 0)
    {
        team = TFTeam_Unassigned;
    }
    else if (strncmp(arg2, "auto", 4, false) == 0)
    {
        team = TF2_GetClientTeam(client);
    }
    else if (strncmp(arg2, "my", 2, false) == 0)
    {
        team = TF2_GetClientTeam(client);
    }
    else
    {
        ReplyToCommand(client, "Error: Unknown team \"%s\"", arg2);
        ReplyToCommand(client, "Valid teams are: red blu blue none auto my");
        return Plugin_Handled;
    }

    TheNodes.AddNode(client, team, hint);
    
    return Plugin_Handled;
}

Action Cmd_noderemove(int client, int args)
{
    CClient botclient = CClient(client);

    if (!botclient.IsValid())
    {
        ReplyToCommand(client, "This command can only be used in-game!");
        return Plugin_Handled;
    }

    if (TheNodes.GetEditor() != client)
    {
        ReplyToCommand(client, "You don't have editing rights!");
        return Plugin_Handled;
    }

    TheNodes.RemoveNode(client);
    
    return Plugin_Handled;
}

Action Cmd_nodecheckvis(int client, int args)
{
    CClient botclient = CClient(client);

    if (!botclient.IsValid())
    {
        ReplyToCommand(client, "This command can only be used in-game!");
        return Plugin_Handled;
    }

    if (TheNodes.GetEditor() != client)
    {
        ReplyToCommand(client, "You don't have editing rights!");
        return Plugin_Handled;
    }

    float origin[3], mid1[3], mid2[3];
    float dist;
    GetClientAbsOrigin(client, origin);
    CNode node1 = TheNodes.GetNearestNode(origin);
    
    if (node1.IsValid())
    {
        node1.GetMiddlePoint(mid1);

        int visible = 0;

        for(int i = 0; i < MAX_NODES; i++)
        {
            if (i == node1.index)
                continue;

            CNode node2 = CNode(i);
            
            if (TheNodes.IsVisible(node1, node2))
            {
                node2.GetMiddlePoint(mid2);
                UTIL_DrawLaser(client, mid1, mid2, { 0,0,255,255 }, 20.0);
                dist = GetVectorDistance(origin, mid2, true);
                ReplyToCommand(client, "[SMBot] Distance from node #%i to node #%i -- %.4f", node1.index, node2.index, dist);
                visible++;
            }
        }

        ReplyToCommand(client, "[SMBot] Node #%i is visible to %i nodes.", node1.index, visible);
    }

    return Plugin_Handled;
}

Action Cmd_nodegoto(int client, int args)
{
    CClient botclient = CClient(client);

    if (!botclient.IsValid())
    {
        ReplyToCommand(client, "This command can only be used in-game!");
        return Plugin_Handled;
    }

    if (TheNodes.GetEditor() != client)
    {
        ReplyToCommand(client, "You don't have editing rights!");
        return Plugin_Handled;
    }

    if (args < 1)
    {
        ReplyToCommand(client, "Usage: sm_smbot_node_goto <node index>");
        return Plugin_Handled;
    }

    int index = GetCmdArgInt(1);
    CNode node = CNode(index);

    if (node.IsValid() && !node.IsFree())
    {
        float origin[3], angles[3];
        node.GetOrigin(origin);
        node.GetHintVector(angles);
        TeleportEntity(client, origin, angles);
        ReplyToCommand(client, "[SMBot] Teleported to node %i", index);
    }
    else
    {
        ReplyToCommand(client, "[SMBot] Node %i is invalid!", index);
    }

    return Plugin_Handled;
}

Action Cmd_nodeupdate(int client, int args)
{
    CClient botclient = CClient(client);

    if (!botclient.IsValid())
    {
        ReplyToCommand(client, "This command can only be used in-game!");
        return Plugin_Handled;
    }

    if (TheNodes.GetEditor() != client)
    {
        ReplyToCommand(client, "You don't have editing rights!");
        return Plugin_Handled;
    }

    if (args < 2)
    {
        ReplyToCommand(client, "Usage: sm_smbot_node_update <update> <value>");
        ReplyToCommand(client, "Valid updates: hint team vector");
        return Plugin_Handled;
    }

    char arg1[16];
    char arg2[16];

    GetCmdArg(1, arg1, sizeof(arg1));
    GetCmdArg(2, arg2, sizeof(arg2));

    float origin[3];
    GetClientAbsOrigin(client, origin);
    CNode node = TheNodes.GetNearestNode(origin);

    if (!node.IsValid())
    {
        ReplyToCommand(client, "No node nearby.");
        return Plugin_Handled;
    }

    if (strncmp(arg1, "hint", 4, false) == 0)
    {
        NodeHint hint = TheNodes.GetNodeHintByName(arg2);

        if (hint == NodeHint_Unknown)
        {
            char hintnames[256];
            TheNodes.GetAllAvailableHintsString(hintnames, sizeof(hintnames));
            ReplyToCommand(client, "Error: Unknown node hint of type \"%s\"", arg1);
            ReplyToCommand(client, "Valid hints: %s", hintnames);
            return Plugin_Handled;
        }

        node.hint = hint;
        ReplyToCommand(client, "[SMBot] Node #%i hint was changed to %s", node.index, arg2);
        return Plugin_Handled;
    }
    else if (strncmp(arg1, "team", 4, false) == 0)
    {
        TFTeam team;

        if (strncmp(arg2, "red", 3, false) == 0)
        {
            team = TFTeam_Red;
        }
        else if (strncmp(arg2, "blu", 3, false) == 0)
        {
            team = TFTeam_Blue;
        }
        else if (strncmp(arg2, "blue", 4, false) == 0)
        {
            team = TFTeam_Blue;
        }
        else if (strncmp(arg2, "none", 4, false) == 0)
        {
            team = TFTeam_Unassigned;
        }
        else if (strncmp(arg2, "auto", 4, false) == 0)
        {
            team = TF2_GetClientTeam(client);
        }
        else if (strncmp(arg2, "my", 2, false) == 0)
        {
            team = TF2_GetClientTeam(client);
        }
        else
        {
            ReplyToCommand(client, "Error: Unknown team \"%s\"", arg2);
            ReplyToCommand(client, "Valid teams are: red blu blue none auto my");
            return Plugin_Handled;
        }

        node.team = team;
        ReplyToCommand(client, "[SMBot] Node #%i team was changed to %s", node.index, arg2);
        return Plugin_Handled;
    }
    else if (strncmp(arg1, "vector", 6, false) == 0)
    {
        float vector[3];
        GetClientEyeAngles(client, vector);
        node.SetHintVector(vector);
        ReplyToCommand(client, "[SMBot] Node #%i hint vector was changed to (%.1f, %.1f, %.1f)", node.index, vector[0], vector[1], vector[2]);
        return Plugin_Handled;
    }
    
    ReplyToCommand(client, "Unknown update type \"%s\"", arg1);
    ReplyToCommand(client, "Valid updates: hint team vector");
    return Plugin_Handled;
}

Action Cmd_nodedrawall(int client, int args)
{
    CClient botclient = CClient(client);

    if (!botclient.IsValid())
    {
        ReplyToCommand(client, "This command can only be used in-game!");
        return Plugin_Handled;
    }

    if (TheNodes.GetEditor() != client)
    {
        ReplyToCommand(client, "You don't have editing rights!");
        return Plugin_Handled;
    }

    float origin[3];
    GetClientAbsOrigin(client, origin);
    TheNodes.DrawAllInRange(origin);
    ReplyToCommand(client, "[SMBot] Drawing all nearby nodes.");
    return Plugin_Handled;
}

Action Cmd_nodedumpinfo(int client, int args)
{
    CClient botclient = CClient(client);

    if (!botclient.IsValid())
    {
        ReplyToCommand(client, "This command can only be used in-game!");
        return Plugin_Handled;
    }

    if (args < 1)
    {
        ReplyToCommand(client, "Usage: sm_smbot_node_dumpinfo <node index>");
        return Plugin_Handled;
    }

    int arg1 = GetCmdArgInt(1);

    if (arg1 < 0 || arg1 >= MAX_NODES)
    {
        ReplyToCommand(client, "Node index out of range, got %i (0-%i)", arg1, MAX_NODES);
        return Plugin_Handled;
    }

    ReplyToCommand(client, "=== NODE #%i ===", arg1);
    ReplyToCommand(client, "%s", g_bNodeUsed[arg1] ? "Used" : "Free");
    ReplyToCommand(client, "Hint %i, Team %i", g_iNodeHint[arg1], g_iNodeTeam[arg1]);
    ReplyToCommand(client, "Origin: %.2f %.2f %.2f", g_NodeOrigin[arg1][0], g_NodeOrigin[arg1][1], g_NodeOrigin[arg1][2]);
    ReplyToCommand(client, "Vector: %.2f %.2f %.2f", g_flNodeHintVector[arg1][0], g_flNodeHintVector[arg1][1], g_flNodeHintVector[arg1][2]);

    return Plugin_Handled;
}

void InitBehavior()
{
    SMBotMainAction.Initialize();
    SMBotDeadAction.Initialize();
    TacticalMonitorAction.Initialize();
    SenarioMonitorAction.Initialize();
    RoamAction.Initialize();
    CTFMainAction.Initialize();
    FetchEnemyFlag.Initialize();
    DeliverEnemyFlag.Initialize();
    FindHealthAction.Initialize();
    FindAmmoAction.Initialize();
    MedicMainAction.Initialize();
}