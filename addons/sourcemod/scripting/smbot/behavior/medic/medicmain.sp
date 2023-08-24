static NextBotActionFactory ActionFactory;

methodmap MedicMainAction < NextBotAction
{
    public static void Initialize()
    {
        ActionFactory = new NextBotActionFactory("MedicMain");
        ActionFactory.BeginDataMapDesc();
        ActionFactory.DefineEntityField("m_hHealTarget");
        ActionFactory.DefineFloatField("m_flNextSearchTime");
        ActionFactory.DefineFloatField("m_flRePathTime");
        ActionFactory.DefineIntField("m_hPathFollower");
        ActionFactory.DefineBoolField("m_bMoveGoal");
        ActionFactory.DefineVectorField("m_vecGoal");
        ActionFactory.EndDataMapDesc();
        ActionFactory.SetCallback(NextBotActionCallbackType_OnStart, OnStart);
        ActionFactory.SetCallback(NextBotActionCallbackType_OnResume, OnResume);
        ActionFactory.SetCallback(NextBotActionCallbackType_OnEnd, OnEnd);
        ActionFactory.SetCallback(NextBotActionCallbackType_OnSuspend, OnSuspend);
        ActionFactory.SetCallback(NextBotActionCallbackType_Update, Update);
        ActionFactory.SetQueryCallback(ContextualQueryType_ShouldRetreat, ShouldRetreat);
        ActionFactory.SetQueryCallback(ContextualQueryType_ShouldHurry, ShouldHurry);
    }

    public static NextBotActionFactory GetFactory()
    {
        return ActionFactory;
    }

    public MedicMainAction()
    {
        return view_as<MedicMainAction>(ActionFactory.Create());
    }

    property CTFPlayer CurrentHealTarget
    {
        public get()
        {
            return view_as<CTFPlayer>(this.GetDataEnt("m_hHealTarget"));
        }
        public set(CTFPlayer value)
        {
            this.SetDataEnt("m_hHealTarget", value.index);
        }
    }

    property float ChangePatientDelay
    {
        public get()
        {
            return this.GetDataFloat("m_flNextSearchTime");
        }
        public set(float value)
        {
            this.SetDataFloat("m_flNextSearchTime", value);
        }
    }

    public CTFPlayer ChooseBestHealTarget(int[] patients, int size, INextBot medic)
    {
        int best = -1, current;
        float factor, bestfactor = 9999999999.0;

        for(int i = 0; i < size; i++)
        {
            current = patients[i];
            CTFPlayer TFPlayer = CTFPlayer(current);

            if (!IsClientInGame(current))
                continue; // safety

            // lower factor = better heal target
            // set base factor
            switch(TFPlayer.GetClass())
            {
                case TFClass_Scout:
                {
                    factor = 5000.0;
                    break;
                }
                case TFClass_Soldier, TFClass_Heavy:
                {
                    factor = 500.0;
                    break;
                }
                case TFClass_Pyro, TFClass_DemoMan:
                {
                    factor = 1000.0;
                    break;
                }
                case TFClass_Engineer, TFClass_Medic:
                {
                    factor = 2000.0;
                    break;
                }
                case TFClass_Sniper:
                {
                    factor = 3000.0;
                    break;
                }
                case TFClass_Spy:
                {
                    factor = 4000.0;

                    if (TFPlayer.IsDisguised())
                    {
                        factor *= 9.0;
                    }

                    break;
                }
            }

            float range = medic.GetRangeSquaredTo(current);
            range = Math_Clamp(range, 0.0, 50000000.0); // cap range
            factor += range;

            factor = factor * TFPlayer.GetHealthPercent();

            if (TFPlayer.IsInCondition(TFCond_OnFire) || TFPlayer.IsInCondition(TFCond_Bleeding))
            {
                factor *= 0.05;
            }

            if (factor < bestfactor)
            {
                bestfactor = factor
                best = current;
            }
        }

        return CTFPlayer(best);
    }
}

static int OnResume(MedicMainAction action, SMBot actor, NextBotAction prevAction)
{
    action.SetDataFloat("m_flNextSearchTime", 0.0);
    action.SetDataFloat("m_flRePathTime", 0.0);
    action.SetDataEnt("m_hHealTarget", -1);
    action.SetData("m_bMoveGoal", 0);
    action.SetDataVector("m_vecGoal", NULL_VECTOR);

    PathFollower path = view_as<PathFollower>(action.GetData("m_hPathFollower"));
    INextBot bot = actor.MyNextBotPointer();

    if (!path)
    {
        PathFollower newPath = PathFollower(SMBotPathCost, Path_FilterIgnoreActors, Path_FilterOnlyActors);
        actor.SetCurrentPath(view_as<Path>(newPath));
        bot.SetCurrentPath(newPath);
        action.SetData("m_hPathFollower", view_as<int>(newPath));
    }

    return action.Continue();
}

static int OnStart(MedicMainAction action, SMBot actor, NextBotAction prevAction)
{
    action.SetDataFloat("m_flNextSearchTime", 0.0);
    action.SetDataFloat("m_flRePathTime", 0.0);
    action.SetDataEnt("m_hHealTarget", -1);
    action.SetData("m_bMoveGoal", 0);
    action.SetDataVector("m_vecGoal", NULL_VECTOR);

    PathFollower path = view_as<PathFollower>(action.GetData("m_hPathFollower"));
    INextBot bot = actor.MyNextBotPointer();

    if (!path)
    {
        PathFollower newPath = PathFollower(SMBotPathCost, Path_FilterIgnoreActors, Path_FilterOnlyActors);
        actor.SetCurrentPath(view_as<Path>(newPath));
        bot.SetCurrentPath(newPath);
        action.SetData("m_hPathFollower", view_as<int>(newPath));
    }

    return action.Continue();
}

static int Update(MedicMainAction action, SMBot actor, float interval)
{
    if (!actor.IsClass(TFClass_Medic))
    {
        return action.Done("I am not a medic!");
    }

    CTFWeaponBase activeweapon = actor.GetActiveWeapon();
    CTFWeaponBase secondaryweapon = actor.GetWeaponOfSlot(TFWeaponSlot_Secondary);

    if (secondaryweapon.IsValidTFWeapon() && CWeaponMedigun.IsMedigun(secondaryweapon.index))
    {
        if (secondaryweapon.index != activeweapon.index)
        {
            actor.WeaponSwitch(secondaryweapon.index); // Switch to the medigun
        }
    }

    int patients[TF_MAXPLAYERS];
    PathFollower path = view_as<PathFollower>(action.GetData("m_hPathFollower"));
    INextBot bot = actor.MyNextBotPointer();
    PlayerBody body = actor.GetPlayerBody();
    actor.IgnoreEnemies();
    CTFPlayer myPatient = action.CurrentHealTarget;

    float now = GetGameTime();

    if (action.ChangePatientDelay >= now)
    {
        action.ChangePatientDelay = now + GetRandomFloat(1.0, 2.0);
        actor.CollectHealTargets(patients, sizeof(patients));
        myPatient = action.ChooseBestHealTarget(patients, sizeof(patients), bot);
        action.CurrentHealTarget = myPatient;
        path.Invalidate();
    }

    if (bot.GetRangeSquaredTo(myPatient.index) <= 400.0 * 400.0)
    {
        float aimAt[3];
        myPatient.WorldSpaceCenter(aimAt);
        body.AimTowards(aimAt, CRITICAL, 1.0, "Aiming at my patient!");
        actor.PressButton(BOTBUTTON_ATTACK, 0.2);
    }
    else
    {
        if (!path.IsValid() || path.GetAge() > 0.5)
        {
            path.ComputeToTarget(bot, myPatient.index)
        }

        path.Update(bot);
    }

    return action.Continue();
}

static void OnSuspend(MedicMainAction action, SMBot actor, NextBotAction priorAction)
{
}

static void OnEnd(MedicMainAction action, SMBot actor, NextBotAction nextAction)
{
    PathFollower path = view_as<PathFollower>(action.GetData("m_hPathFollower"));
    INextBot bot = actor.MyNextBotPointer();

    if (path)
    {
        action.SetData("m_hPathFollower", 0);
        path.Destroy();
        actor.DestroyPath();
        bot.NotifyPathDestruction(path);
    }
}

static QueryResultType ShouldRetreat(MedicMainAction action, INextBot bot)
{
    SMBot actor = SMBot(bot.GetEntity());

    CWeaponMedigun secondaryweapon = view_as<CWeaponMedigun>(actor.GetWeaponOfSlot(TFWeaponSlot_Secondary));

    if (secondaryweapon.IsValidTFWeapon() && CWeaponMedigun.IsMedigun(secondaryweapon.index))
    {
        if (secondaryweapon.GetUberChargePercent() >= 1.0)
            return ANSWER_NO;
    }

    return ANSWER_YES;
}

static QueryResultType ShouldHurry(MedicMainAction action, INextBot bot)
{
    return ANSWER_NO;
}