static NextBotActionFactory ActionFactory;

methodmap RoamAction < NextBotAction
{
    public static void Initialize()
    {
        ActionFactory = new NextBotActionFactory("Roam");
        ActionFactory.BeginDataMapDesc();
        ActionFactory.DefineIntField("m_PathFollower");
        ActionFactory.DefineVectorField("m_Goal");
        ActionFactory.DefineIntField("m_iStuckCounter");
        ActionFactory.EndDataMapDesc();
        ActionFactory.SetCallback(NextBotActionCallbackType_OnStart, OnStart);
        ActionFactory.SetCallback(NextBotActionCallbackType_Update, Update);
        ActionFactory.SetCallback(NextBotActionCallbackType_OnEnd, OnEnd);
        ActionFactory.SetEventCallback(EventResponderType_OnStuck, OnStuck);
    }

    public static NextBotActionFactory GetFactory()
    {
        return ActionFactory;
    }

    public RoamAction()
    {
        return view_as<RoamAction>(ActionFactory.Create());
    }

    property PathFollower path
    {
        public get()
        {
            return this.GetData("m_PathFollower");
        }
        public set(PathFollower value)
        {
            this.SetData("m_PathFollower", value);
        }
    }

    public void SetGoalVector(float value[3])
    {
        this.SetDataVector("m_Goal", value);
    }

    public void GetGoalVector(float goal[3])
    {
        this.GetDataVector("m_Goal", goal);
    }

    property int stuckcounter
    {
        public get()
        {
            return this.GetData("m_iStuckCounter");
        }
        public set(int value)
        {
            this.SetData("m_iStuckCounter", value);
        }
    }
}

static int OnStart(RoamAction action, SMBot actor, NextBotAction prevAction)
{
    actor.UpdateLastKnownArea();
    CNavArea start = actor.GetLastKnownArea();
    INextBot bot = actor.MyNextBotPointer();

    if (start == NULL_AREA)
    {
        return action.Done("No starting area");
    }

    HidingSpot spot = NULL_HIDING_SPOT;

    do
    {
        spot = TheHidingSpots.Get(Math_GetRandomInt(0, TheHidingSpots.Length - 1));
    }
    while(spot == NULL_HIDING_SPOT)

    CNavArea finalarea = spot.GetArea();
    float center[3];
    finalarea.GetCenter(center);
    action.SetGoalVector(center);

    PathFollower path = PathFollower(SMBotPathCost, Path_FilterIgnoreActors, Path_FilterOnlyActors);
    if (!path.ComputeToPos(bot, center, .includeGoalIfPathFails = false))
    {
        path.Destroy();
        return action.Done("Failed to get path to my destination!");
    }

    action.path = path;
    action.stuckcounter = 0;
    bot.SetCurrentPath(path);

    if (!path.IsValid())
    {
        bot.NotifyPathDestruction(path);
        path.Destroy();
        action.path = view_as<PathFollower>(0);
        return action.Done("My path is invalid!");
    }

    return action.Continue();
}

static int Update(RoamAction action, SMBot actor, float interval)
{
    INextBot bot = actor.MyNextBotPointer();
    ILocomotion locomotion = bot.GetLocomotionInterface();
    PathFollower path = action.path;
    float goal[3];
    float endpos[3];
    path.GetEndPosition(endpos);
    action.GetGoalVector(goal);

    if (bot.GetRangeToEx(goal) <= 128.0 || bot.GetRangeSquaredToEx(endpos) <= 128.0)
    {
        return action.Done("Goal reached!");
    }

    path.Update(bot);
    locomotion.Run();

    if (path.GetAge() >= 10.0)
    {
        path.ComputeToPos(bot, goal, .includeGoalIfPathFails = false);
    }

    return action.Continue();
}

static void OnEnd(RoamAction action, SMBot actor, NextBotAction nextAction)
{
    PathFollower path = action.path;
    INextBot bot = actor.MyNextBotPointer();
    bot.GetLocomotionInterface().Stop();

    if (path)
    {
        bot.NotifyPathDestruction(path);
        path.Destroy();
    }
}

static int OnStuck(RoamAction action, SMBot actor)
{
    float goal[3];
    action.GetGoalVector(goal);
    PathFollower path = action.path;
    INextBot bot = actor.MyNextBotPointer();
    ILocomotion loco = bot.GetLocomotionInterface();
    loco.Jump();
    action.stuckcounter = action.stuckcounter + 1;

    if (path)
    {
        path.ComputeToPos(actor.MyNextBotPointer(), goal);
    }

    if (action.stuckcounter >= 5)
    {
        return action.TryDone(RESULT_IMPORTANT, "I am stuck!");
    }

    return action.TryContinue(RESULT_TRY);
}