static NextBotActionFactory ActionFactory;

methodmap SenarioMonitorAction < NextBotAction
{
    public static void Initialize()
    {
        ActionFactory = new NextBotActionFactory("SenarioMonitor");
        ActionFactory.BeginDataMapDesc();
        ActionFactory.EndDataMapDesc();
        ActionFactory.SetCallback(NextBotActionCallbackType_OnStart, OnStart);
        ActionFactory.SetCallback(NextBotActionCallbackType_OnResume, OnResume);
        ActionFactory.SetCallback(NextBotActionCallbackType_Update, Update);
        ActionFactory.SetCallback(NextBotActionCallbackType_InitialContainedAction, InitialContainedAction);
    }

    public static NextBotActionFactory GetFactory()
    {
        return ActionFactory;
    }

    public SenarioMonitorAction()
    {
        return view_as<SenarioMonitorAction>(ActionFactory.Create());
    }
}

static NextBotAction InitialContainedAction(SenarioMonitorAction action, SMBot actor)
{
    if (actor.IsClass(TFClass_Engineer))
    {
        return NULL_ACTION; // To-do: Engineer
    }
    else if (actor.IsClass(TFClass_Medic))
    {
        return NULL_ACTION; // To-do: Medic
    }
    else if (actor.IsClass(TFClass_Sniper))
    {
        return NULL_ACTION; // To-do: Sniper
    }
    else if (actor.IsClass(TFClass_Spy))
    {
        return NULL_ACTION; // To-do: Spy
    }
    else if (CTFGameRules.GetGameType() == TFGameType_CTF)
    {
        return CTFMainAction();
    }

    return NULL_ACTION;
}

static int OnResume(SenarioMonitorAction action, SMBot actor, NextBotAction prevAction)
{
    return action.Continue();
}

static int OnStart(SenarioMonitorAction action, SMBot actor, NextBotAction prevAction)
{
    return action.Continue();
}

static int Update(SenarioMonitorAction action, SMBot actor, float interval)
{
    return action.Continue();
}