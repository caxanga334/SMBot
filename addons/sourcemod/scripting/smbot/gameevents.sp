
void SetupGameEvents()
{
    HookEvent("teamplay_flag_event", Event_FlagEvent);
    HookEvent("teamplay_setup_finished", Event_SetupTimeFinished);
    /* Events to reset the nav data values */
    HookEvent("teamplay_round_start", NavDataEvent_OnRoundRestart);
    HookEvent("arena_round_start", NavDataEvent_OnRoundRestart);
    HookEvent("mvm_wave_complete", NavDataEvent_OnRoundRestart);
}

void Event_FlagEvent(Event event, const char[] name, bool dontBroadcast)
{
    int player = event.GetInt("player");
    int carrier = event.GetInt("carrier");
    int type = event.GetInt("eventtype");
    int home = event.GetInt("home");
    TFTeam team = view_as<TFTeam>(event.GetInt("team"));

    PrintToServer("teamplay_flag_event -- %i %i %i %i %i", player, carrier, type, home, view_as<int>(team));

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

        SMBot smbot = SMBot(i);

        if (smbot.IsFromTeam(team))
        {
            switch(type)
            {
                case TF_FLAGEVENT_PICKEDUP:
                {
                    PropagateCustomEventEx(i, "ctf_our_flag_stolen");
                }
                case TF_FLAGEVENT_DROPPED:
                {
                    PropagateCustomEventEx(i, "ctf_our_flag_dropped");
                }
            }
        }
        else
        {
            switch(type)
            {
                case TF_FLAGEVENT_PICKEDUP:
                {
                    PropagateCustomEventEx(i, "ctf_their_flag_stolen");
                }
                case TF_FLAGEVENT_DROPPED:
                {
                    PropagateCustomEventEx(i, "ctf_their_flag_dropped");
                }
            }
        }
    }
}

void Event_SetupTimeFinished(Event event, const char[] name, bool dontBroadcast)
{
    PropagateCustomEvent("teamplay_setup_finished");
}