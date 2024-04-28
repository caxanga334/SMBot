// SM Bot navigation mesh data

#define MAX_STORED_NAV_AREA_ID 20000 // Support a maximum of 20000 nav areas
#define NAV_TEAM_RED 0
#define NAV_TEAM_BLU 1

/* The following values assumes the danger decay convar uses the default value */


float g_iNavDanger[2][MAX_STORED_NAV_AREA_ID];

methodmap CSMBotNavData
{
    public static void OnRoundRestart()
    {
        for(int team = 0; team < 2; team++)
        {
            for(int i = 0; i < MAX_STORED_NAV_AREA_ID; i++)
            {
                g_iNavDanger[team][i] = 0.0;
            }
        }
    }

    public static void Update()
    {
        for(int team = 0; team < 2; team++)
        {
            for(int i = 0; i < MAX_STORED_NAV_AREA_ID; i++)
            {
                if (g_iNavDanger[team][i] > 0)
                {
                    g_iNavDanger[team][i] -= sm_smbot_nav_danger_decay_rate.FloatValue;
                }
            }
        }
    }

    public static void IncreaseDanger(const int team, const int index, const float amount)
    {
        if (index >= MAX_STORED_NAV_AREA_ID) { LogStackTrace("Nav data out of bounds!"); return; }
        g_iNavDanger[team][index] += amount;
    }

    public static void DecreaseDanger(const int team, const int index, const float amount)
    {
        if (index >= MAX_STORED_NAV_AREA_ID) { LogStackTrace("Nav data out of bounds!"); return; }
        g_iNavDanger[team][index] -= amount;
    }

    public static float GetDanger(const int team, const int index)
    {
        if (index >= MAX_STORED_NAV_AREA_ID) { LogStackTrace("Nav data out of bounds!"); return 0.0; }
        return g_iNavDanger[team][index];
    }
}

void NavDataEvent_OnRoundRestart(Event event, const char[] name, bool dontBroadcast)
{
    CSMBotNavData.OnRoundRestart();
}

Action Timer_NavDataUpdate(Handle timer)
{
    CSMBotNavData.Update();
    return Plugin_Continue;
}