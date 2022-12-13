static NextBotActionFactory ActionFactory;

methodmap TacticalMonitorAction < NextBotAction
{
    public static void Initialize()
    {
        ActionFactory = new NextBotActionFactory("TacticalMonitor");
        ActionFactory.BeginDataMapDesc();
        ActionFactory.EndDataMapDesc();
        ActionFactory.SetCallback(NextBotActionCallbackType_Update, Update);
        ActionFactory.SetCallback(NextBotActionCallbackType_InitialContainedAction, InitialContainedAction);
    }

    public static NextBotActionFactory GetFactory()
    {
        return ActionFactory;
    }

    public TacticalMonitorAction()
    {
        return view_as<TacticalMonitorAction>(ActionFactory.Create());
    }
}

static NextBotAction InitialContainedAction(TacticalMonitorAction action, SMBot actor)
{
    return SenarioMonitorAction();
}

static int Update(TacticalMonitorAction action, SMBot actor, float interval)
{
    return action.Continue();
}