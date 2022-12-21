static NextBotActionFactory ActionFactory;

methodmap SMBotDeadAction < NextBotAction
{
    public static void Initialize()
    {
        ActionFactory = new NextBotActionFactory("SMBotDeadAction");
        ActionFactory.BeginDataMapDesc();
        ActionFactory.EndDataMapDesc();
        ActionFactory.SetCallback(NextBotActionCallbackType_Update, DeadActionUpdate);
    }

    public static NextBotActionFactory GetFactory()
    {
        return ActionFactory;
    }

    public SMBotDeadAction()
    {
        return view_as<SMBotDeadAction>(ActionFactory.Create());
    }
}

static int DeadActionUpdate(SMBotDeadAction action, SMBot actor, float interval)
{
    actor.SetDesiredClass(actor.SelectClassToPlay()); // try to change class
    actor.ResetDecoratedDebugString();
    actor.BuildDecoratedDebugString(action); // for debugging
    actor.DestroyPath();

    if (actor.IsAlive())
    {
        return action.ChangeTo(SMBotMainAction(), "I'm alive now!");
    }

    return action.Continue();
}