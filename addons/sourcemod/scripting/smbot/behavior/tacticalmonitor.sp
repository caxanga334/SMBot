static NextBotActionFactory ActionFactory;

methodmap TacticalMonitorAction < NextBotAction
{
    public static void Initialize()
    {
        ActionFactory = new NextBotActionFactory("TacticalMonitor");
        ActionFactory.BeginDataMapDesc();
        ActionFactory.DefineFloatField("m_flNextHealthTime");
        ActionFactory.DefineFloatField("m_flNextAmmoTime");
        ActionFactory.EndDataMapDesc();
        ActionFactory.SetCallback(NextBotActionCallbackType_Update, Update);
        ActionFactory.SetCallback(NextBotActionCallbackType_InitialContainedAction, InitialContainedAction);
        ActionFactory.SetQueryCallback(ContextualQueryType_ShouldRetreat, ShouldRetreat);
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
    float healtime = action.GetDataFloat("m_flNextHealthTime");
    float ammotime = action.GetDataFloat("m_flNextAmmoTime");
    INextBot bot = actor.MyNextBotPointer();
    IIntention intention = bot.GetIntentionInterface();

    if (healtime <= GetGameTime() && actor.IsHealthLow() && FindHealthAction.IsPossible(actor) && intention.ShouldRetreat() == ANSWER_YES)
    {
        healtime = GetGameTime() + Math_GetRandomFloat(5.0, 10.0);
        action.SetDataFloat("m_flNextHealthTime", healtime);
        return action.SuspendFor(FindHealthAction(), "Retreating for health!");
    }

    if (ammotime <= GetGameTime() && actor.IsAmmoLow() && intention.ShouldHurry() != ANSWER_YES)
    {
        ammotime = GetGameTime() + Math_GetRandomFloat(5.0, 10.0);
        action.SetDataFloat("m_flNextAmmoTime", ammotime);
        return action.SuspendFor(FindAmmoAction(), "Searching for ammo!");
    }

    return action.Continue();
}

static QueryResultType ShouldRetreat(TacticalMonitorAction action, INextBot bot)
{
    SMBot smbot = SMBot(bot.GetEntity());

    if (smbot.IsHealthLow())
    {
        return ANSWER_YES;
    }

    return ANSWER_NO;
}