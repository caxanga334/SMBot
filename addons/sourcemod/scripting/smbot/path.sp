/**
 * Path finding cost for SMBot
 */

// Default path cost for all bots
float SMBotPathCost(INextBot bot, CNavArea area, CNavArea fromArea, CNavLadder ladder, CBaseEntity elevator, float length)
{
    SMBot smbot = SMBot(bot.GetEntity());
    float dist;
    float stepheigh = bot.GetLocomotionInterface().GetStepHeight();
    float maxjumpheigh = bot.GetLocomotionInterface().GetMaxJumpHeight();
    float deathdropheigh = bot.GetLocomotionInterface().GetDeathDropHeight();
    float deltaZ;
    CTFNavArea tfarea = view_as<CTFNavArea>(area);

    if (fromArea == NULL_AREA)
    {
        return 0.0; // first area in the search
    }

    if (!bot.GetLocomotionInterface().IsAreaTraversable(area))
    {
        return -1.0; // can't pass
    }

    // This attribute seems to be ignored by TF2, implement it manually
    if (area.HasAttributes(NAV_MESH_TRANSIENT))
    {
        float start[3], end[3];
        area.GetCenter(start);
        VectorCopy(start, end);
        start[2] += 2.0;
        end[2] -= 24.0;

        // Check for ground, trace should hit something if there is ground
        bool hasground = UTIL_QuickSimpleTraceLine(start, end);

        if (!hasground)
        {
            return -1.0; // Nav mesh doesn't have ground (missing bridge?)
        }

        fromArea.GetCenter(end);
        end[2] += 2.0;

        // Check if there is something blocking between area and fromarea center
        bool hasblocker = UTIL_QuickSimpleTraceLine(start, end);

        if (hasblocker)
        {
            return -1.0;
        }
    }

    if (smbot.IsFromTeam(TFTeam_Blue) && (tfarea.HasAttributeTF(RED_SPAWN_ROOM) || tfarea.HasAttributeTF(RED_ONE_WAY_DOOR) ))
    {
        return -1.0; // not for my team
    }
    else if (smbot.IsFromTeam(TFTeam_Red) && (tfarea.HasAttributeTF(BLUE_SPAWN_ROOM) || tfarea.HasAttributeTF(BLUE_ONE_WAY_DOOR) ))
    {
        return -1.0; // not for my team
    }

    if (ladder != NULL_LADDER_AREA)
    {
        dist = ladder.Length;
    }
    else if (length > 0.0)
    {
        dist = length;
    }
    else
    {
        float vector[3];
        float center1[3];
        float center2[3];
        area.GetCenter(center1);
        fromArea.GetCenter(center2);
        SubtractVectors(center1, center2, vector)
        dist = GetVectorLength(vector);
    }

    deltaZ = fromArea.ComputeAdjacentConnectionHeightChange(area);

    if (deltaZ >= stepheigh)
    {
        if (deltaZ >= maxjumpheigh)
        {
            return -1.0; // too high to reach
        }

        dist *= 2.0; // apply jump penalty to-do: add config
    }
    else if ( deltaZ < -deathdropheigh )
    {
        return -1.0; // too far to drop
    }

    if (area.HasAttributes(NAV_MESH_CROUCH))
    {
        dist *= 3.0; // apply crouch penalty
    }

    if (area.HasAttributes(NAV_MESH_AVOID))
    {
        dist *= 9.0;
    }

    if (smbot.pathtype == SAFEST_PATH)
    {
        if (smbot.IsFromTeam(TFTeam_Red) && tfarea.HasAttributeTF(BLUE_SENTRY))
        {
            dist *= 5.0;
        }
        else if (smbot.IsFromTeam(TFTeam_Blue) && tfarea.HasAttributeTF(RED_SENTRY))
        {
            dist *= 5.0;
        }
    }

    float cost = dist;

    return cost + fromArea.GetCostSoFar();
}