static NextBotActionFactory ActionFactory;

methodmap FetchEnemyFlag < NextBotAction
{
    public static void Initialize()
    {
        ActionFactory = new NextBotActionFactory("FetchEnemyFlag");
        ActionFactory.BeginDataMapDesc();
        ActionFactory.DefineEntityField("m_hTargetFlag");
        ActionFactory.DefineIntField("m_PathFollower");
        ActionFactory.EndDataMapDesc();
        ActionFactory.SetCallback(NextBotActionCallbackType_OnStart, FetchEnemyFlagOnStart);
        ActionFactory.SetCallback(NextBotActionCallbackType_OnResume, FetchEnemyFlagOnResume);
        ActionFactory.SetCallback(NextBotActionCallbackType_Update, FetchEnemyFlagUpdate);
        ActionFactory.SetQueryCallback(ContextualQueryType_ShouldRetreat, FetchEnemyFlagShouldRetreat);
    }

    public static NextBotActionFactory GetFactory()
    {
        return ActionFactory;
    }

    public FetchEnemyFlag()
    {
        return view_as<FetchEnemyFlag>(ActionFactory.Create());
    }
}

static int FetchEnemyFlagOnResume(FetchEnemyFlag action, SMBot actor, NextBotAction prevAction)
{
    CBaseEntity item = actor.GetItem();
    CCaptureFlag flag = CCaptureFlag(action.GetDataEnt("m_hTargetFlag"));
    CCaptureFlag carriedflag = CCaptureFlag(item.index);

    if (carriedflag.IsValidCaptureFlag()) // bot has a flag
    {
        return action.Done("I have a flag!");
    }

    if (!flag.IsValidCaptureFlag())
    {
        return action.Done("Target flag is invalid!");
    }

    return action.Continue();
}


static int FetchEnemyFlagOnStart(FetchEnemyFlag action, SMBot actor, NextBotAction prevAction)
{
    CCaptureFlag flag = CTFGameRules.GetFlagToCapture(actor.GetTeam());
    INextBot bot = actor.MyNextBotPointer();
    float goal[3];

    if (!flag.IsValidCaptureFlag())
    {
        return action.ChangeTo(RoamAction(), "No valid flag to capture!");
    }

    action.SetDataEnt("m_hTargetFlag", flag.index);

    PathFollower path = PathFollower(SMBotPathCost, Path_FilterIgnoreActors, Path_FilterOnlyActors);
    action.SetData("m_PathFollower", view_as<int>(path));
    flag.GetPosition(goal);
    path.ComputeToPos(bot, goal, .includeGoalIfPathFails = false);
    bot.SetCurrentPath(path); // sets the bot path (NextBot internal)
    actor.SetCurrentPath(path); // sets the bot path (SMBot variable)
    
    if (!path.IsValid())
    {
        bot.NotifyPathDestruction(path);
        actor.DestroyPath();
        path.Destroy();
        action.SetData("m_PathFollower", 0);
        return action.ChangeTo(RoamAction(), "My path is invalid!");
    }

    return action.Continue();
}

static int FetchEnemyFlagUpdate(FetchEnemyFlag action, SMBot actor, float interval)
{
    INextBot bot = actor.MyNextBotPointer();
    ILocomotion locomotion = bot.GetLocomotionInterface();
    PathFollower path = view_as<PathFollower>(action.GetData("m_PathFollower"));
    float goal[3];
    CBaseEntity item = actor.GetItem();
    CCaptureFlag flag = CCaptureFlag(action.GetDataEnt("m_hTargetFlag"));
    CCaptureFlag carriedflag = CCaptureFlag(item.index);

    if (carriedflag.IsValidCaptureFlag()) // bot has a flag
    {
        return action.Done("I have a flag!");
    }

    if (!flag.IsValidCaptureFlag())
    {
        return action.Done("Target flag is invalid!");
    }

    if (flag.IsStolen())
    {
        return action.Done("Someone took the flag.");
    }

    if (path.GetAge() > 5.0)
    {
        flag.GetPosition(goal);
        path.ComputeToPos(bot, goal, .includeGoalIfPathFails = false);
    }

    path.Update(bot);
    locomotion.Run();

    if (!path.IsValid())
    {
        bot.NotifyPathDestruction(path);
        actor.DestroyPath();
        path.Destroy();
        action.SetData("m_PathFollower", 0);
        return action.ChangeTo(RoamAction(), "My path is invalid!");
    }

    return action.Continue();
}

static QueryResultType FetchEnemyFlagShouldRetreat(TacticalMonitorAction action, INextBot bot)
{
    SMBot smbot = SMBot(bot.GetEntity());

    if (smbot.IsHealthLow())
    {
        return ANSWER_YES;
    }

    return ANSWER_NO;
}