#include "fetchenemyflag.sp"
#include "deliverenemyflag.sp"

static NextBotActionFactory ActionFactory;

methodmap CTFMainAction < NextBotAction
{
    public static void Initialize()
    {
        ActionFactory = new NextBotActionFactory("CaptureTheFlag");
        ActionFactory.BeginDataMapDesc();
        ActionFactory.EndDataMapDesc();
        ActionFactory.SetCallback(NextBotActionCallbackType_OnStart, OnStart);
        ActionFactory.SetCallback(NextBotActionCallbackType_OnResume, OnResume);
        ActionFactory.SetCallback(NextBotActionCallbackType_Update, Update);
    }

    public static NextBotActionFactory GetFactory()
    {
        return ActionFactory;
    }

    public CTFMainAction()
    {
        return view_as<CTFMainAction>(ActionFactory.Create());
    }
}

static int OnResume(CTFMainAction action, SMBot actor, NextBotAction prevAction)
{
    return action.Continue();
}


static int OnStart(CTFMainAction action, SMBot actor, NextBotAction prevAction)
{
    return action.Continue();
}

static int Update(CTFMainAction action, SMBot actor, float interval)
{
    CBaseEntity item = actor.GetItem();
    CCaptureFlag carriedflag = CCaptureFlag(item.index);
    CCaptureFlag theirflag = CTFGameRules.GetFlagToCapture(actor.GetTeam());

    if (GetURandomFloat() <= 0.20)
    {
        return action.SuspendFor(RoamAction());
    }

    if (carriedflag.IsValidCaptureFlag())
    {
        return action.SuspendFor(DeliverEnemyFlag(), "Delivering enemy flag to my base!");
    }
    else if(theirflag.IsValidCaptureFlag() && !theirflag.IsStolen())
    {
        return action.SuspendFor(FetchEnemyFlag(), "Fetching enemy flag!");
    }

    return action.SuspendFor(RoamAction());

    //return action.Continue();
}