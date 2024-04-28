// globals
bool g_bIsLooking[TF_MAXPLAYERS];
LookAtPriorityType g_iLookPriority[TF_MAXPLAYERS];
float g_flLookAtVector[TF_MAXPLAYERS][3];
float g_flLookAtTime[TF_MAXPLAYERS];

static char s_prioritydebugname[5][16] = {
    "BORING",
    "INTERESTING",
    "IMPORTANT",
    "CRITICAL",
    "MANDATORY"
}

methodmap PlayerBody < IBody
{
    public void MyReset()
    {
        INextBot nextbot = this.GetBot();
        int index = nextbot.GetEntity();

        g_bIsLooking[index] = false;
        g_iLookPriority[index] = BORING;
        g_flLookAtVector[index][0] = 0.0;
        g_flLookAtVector[index][1] = 0.0;
        g_flLookAtVector[index][2] = 0.0;
        g_flLookAtTime[index] = 0.0;
    }

    public bool IsLooking()
    {
        INextBot nextbot = this.GetBot();
        int index = nextbot.GetEntity();
        return g_bIsLooking[index];
    }

    public LookAtPriorityType GetCurrentPriority()
    {
        INextBot nextbot = this.GetBot();
        int index = nextbot.GetEntity();
        return g_iLookPriority[index];
    }

    public void RunLook(float eyeangles[3])
    {
        INextBot nextbot = this.GetBot();
        int index = nextbot.GetEntity();
        const float speed = 50.0; // TO-DO: add config

        if (!this.IsLooking())
            return;

        if (g_flLookAtTime[index] <= GetGameTime())
        {
            this.MyReset();
            return;
        }

        float eyes[3];
        GetClientEyePosition(index, eyes);
        float goal[3];
        goal = g_flLookAtVector[index];

        float result[3];
        MakeVectorFromPoints(eyes, goal, result);
        GetVectorAngles(result, result);

        eyeangles[PITCH] = UTIL_ApproachAngle(result[PITCH], eyeangles[PITCH], speed);
        eyeangles[YAW] = UTIL_ApproachAngle(result[YAW], eyeangles[YAW], speed);
        eyeangles[PITCH] = NormalizeViewPitch(eyeangles[PITCH]);

        //PrintVectorToServer("Eye Angles", eyeangles);

        // SnapEyeAngles(index, eyeangles);
        VScript_SnapPlayerAngles(index, eyeangles);
    }

    // Makes the bot aim towards a target vector
    //
    // @param target        Target vector to aim at
    // @param priority      Look priority
    // @param duration      How long to keep looking at the given vector
    // @param reason        Reason for debugging
    // @return              true if the bot will aim at the given location
    public bool AimTowards(float target[3], LookAtPriorityType priority, float duration, const char[] reason = "")
    {
        INextBot nextbot = this.GetBot();
        int index = nextbot.GetEntity();

        if (priority >= this.GetCurrentPriority())
        {
            g_bIsLooking[index] = true;
            g_iLookPriority[index] = priority;
            g_flLookAtVector[index] = target;
            g_flLookAtTime[index] = GetGameTime() + duration;

            if (g_iDebugBotTarget == index)
            {
                PrintToConsoleAll("%N(#%i) Aiming towards (%.2f %.2f %.2f). Priority: \"%s\" Reason: \"%s\".", index, index, target[0], target[1], target[2], s_prioritydebugname[view_as<int>(priority)], reason);
            }

            return true;
        }
        else
        {
            if (g_iDebugBotTarget == index)
            {
                if (priority < this.GetCurrentPriority())
                {
                    PrintToConsoleAll("%N(#%i) Aim Towards (%.2f %.2f %.2f) rejected by priority!", index, index, target[0], target[1], target[2]);
                }
            }
        }

        return false;
    }
}
