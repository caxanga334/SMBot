static NextBotActionFactory ActionFactory;

methodmap FindHealthAction < NextBotAction
{
    public static void Initialize()
    {
        ActionFactory = new NextBotActionFactory("FindHealth");
        ActionFactory.BeginDataMapDesc();
        ActionFactory.DefineIntField("m_PathFollower");
        ActionFactory.DefineVectorField("m_Goal");
        ActionFactory.DefineIntField("m_iStuckCounter");
        ActionFactory.DefineEntityField("m_hHealthSource");
        ActionFactory.DefineIntField("m_iSourceType");
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

    public FindHealthAction()
    {
        return view_as<FindHealthAction>(ActionFactory.Create());
    }

    public static bool IsPossible(SMBot actor)
    {
        if (actor.GetNumHealers() > 0)
        {
            return false;
        }

        return true;
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

    public bool FindHealthSource(SMBot actor, const float maxsearchrange = 5000000.0)
    {
        float origin[3], source[3];
        float nearest = maxsearchrange, current;
        char classname[32];
        bool found = false;
        CBaseEntity entity;
        actor.GetAbsOrigin(origin);

        for(int i = MaxClients + 1; i < 2048; i++)
        {
            if (!IsValidEntity(i))
                continue;

            GetEntityClassname(i, classname, sizeof(classname));
            entity = CBaseEntity(i);
            entity.WorldSpaceCenter(source);
            current = GetVectorDistance(origin, source, true);

            if (current > nearest)
                continue;

            if (strncmp(classname, "item_healthkit_", 15, false) == 0)
            {
                CItem item = CItem(i);

                if (!item.CanBePicked() || !item.CanBePickedByTeam(actor.GetTeam()))
                    continue;

                this.SetDataEnt("m_hHealthSource", i);
                this.SetData("m_iSourceType", 0); // item healthkit
                found = true;
            }
            else if (strncmp(classname, "obj_dispenser", 13, false) == 0)
            {
                CObjectDispenser dispenser = CObjectDispenser(i);

                if (dispenser.GetTeam() != actor.GetTeam())
                    continue;

                this.SetDataEnt("m_hHealthSource", i);
                this.SetData("m_iSourceType", 1); // dispenser
                found = true;
            }
            else if (strncmp(classname, "func_regenerate", 15, false) == 0)
            {
                CFuncRegenerate resupply = CFuncRegenerate(i);

                if(!resupply.CanBeUsedByTeam(actor.GetTeam()))
                    continue;

                this.SetDataEnt("m_hHealthSource", i);
                this.SetData("m_iSourceType", 2); // resupply locker
                found = true;
            }
            else
            {
                continue;
            }

            nearest = current;
        }

        return found;
    }
}

static int OnStart(FindHealthAction action, SMBot actor, NextBotAction prevAction)
{
    actor.pathtype = SAFEST_PATH;
    INextBot bot = actor.MyNextBotPointer();

    if (!action.FindHealthSource(actor))
    {
        return action.Done("No nearby health source!");
    }

    float center[3];
    int sourceentity = action.GetDataEnt("m_hHealthSource");
    CBaseEntity source = CBaseEntity(sourceentity);
    source.WorldSpaceCenter(center);
    action.SetGoalVector(center);


    PathFollower path = PathFollower(SMBotPathCost, Path_FilterIgnoreActors, Path_FilterOnlyActors);
    if (!path.ComputeToPos(bot, center, .includeGoalIfPathFails = false))
    {
        path.Destroy();
        actor.DestroyPath();
        return action.Done("Failed to get path to my destination!");
    }

    action.path = path;
    action.stuckcounter = 0;
    bot.SetCurrentPath(path);
    actor.SetCurrentPath(path);

    if (!path.IsValid())
    {
        bot.NotifyPathDestruction(path);
        path.Destroy();
        actor.DestroyPath();
        action.path = view_as<PathFollower>(0);
        return action.Done("My path is invalid!");
    }

    return action.Continue();
}

static int Update(FindHealthAction action, SMBot actor, float interval)
{
    INextBot bot = actor.MyNextBotPointer();
    ILocomotion locomotion = bot.GetLocomotionInterface();
    PathFollower path = action.path;
    float goal[3];
    action.GetGoalVector(goal);
    int type = action.GetData("m_iSourceType");
    int source = action.GetDataEnt("m_hHealthSource");
    CBaseEntity entity = CBaseEntity(source);

    if (!entity.IsValid())
    {
        return action.Done("Health source is no longer valid!");
    }

    if (type == 0)
    {
        CItem item = CItem(source);

        if (!item.CanBePicked())
        {
            return action.Done("Health source is no longer valid!");
        }
    }

    if (actor.GetHealthPercent() >= 0.99)
    {
        return action.Done("Fully healed!");
    }

    path.Update(bot);
    locomotion.Run();

    // Bot reached end of path
    if (path.FirstSegment() == NULL_PATH_SEGMENT && bot.GetRangeToEx(goal) >= 96.0)
    {
        locomotion.DriveTo(goal);
    }

    if (path.GetAge() >= 10.0)
    {
        path.ComputeToPos(bot, goal, .includeGoalIfPathFails = false);
    }

    return action.Continue();
}

static void OnEnd(FindHealthAction action, SMBot actor, NextBotAction nextAction)
{
    PathFollower path = action.path;
    INextBot bot = actor.MyNextBotPointer();
    bot.GetLocomotionInterface().Stop();
    actor.pathtype = FASTEST_PATH;

    if (path)
    {
        bot.NotifyPathDestruction(path);
        actor.DestroyPath();
        path.Destroy();
    }
}

static int OnStuck(FindHealthAction action, SMBot actor)
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