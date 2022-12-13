#include "tacticalmonitor.sp"
#include "senariomonitor.sp"
#include "roam.sp"
#include "senario/capturetheflag.sp"

static NextBotActionFactory ActionFactory;

methodmap SMBotMainAction < NextBotAction
{
    public static void Initialize()
    {
        ActionFactory = new NextBotActionFactory("MainAction");
        ActionFactory.BeginDataMapDesc();
        ActionFactory.EndDataMapDesc();
        ActionFactory.SetCallback(NextBotActionCallbackType_Update, Update);
        ActionFactory.SetCallback(NextBotActionCallbackType_OnStart, OnStart);
        ActionFactory.SetCallback(NextBotActionCallbackType_InitialContainedAction, InitialContainedAction);
        ActionFactory.SetEventCallback(EventResponderType_OnActorEmoted, OnActorEmoted);
        ActionFactory.SetEventCallback(EventResponderType_OnWeaponFired, OnWeaponFired);
        ActionFactory.SetEventCallback(EventResponderType_OnTerritoryContested, OnTerritoryContested);
        ActionFactory.SetEventCallback(EventResponderType_OnTerritoryCaptured, OnTerritoryCaptured);
        ActionFactory.SetEventCallback(EventResponderType_OnTerritoryLost, OnTerritoryLost);
        ActionFactory.SetEventCallback(EventResponderType_OnCommandString, OnCommandString);
        ActionFactory.SetQueryCallback(ContextualQueryType_SelectTargetPoint, SelectTargetPoint);
        ActionFactory.SetQueryCallback(ContextualQueryType_SelectMoreDangerousThreat, SelectMoreDangerousThreat);
    }

    public static NextBotActionFactory GetFactory()
    {
        return ActionFactory;
    }

    public SMBotMainAction()
    {
        return view_as<SMBotMainAction>(ActionFactory.Create());
    }


}

static NextBotAction InitialContainedAction(NextBotAction action, CBaseCombatCharacter actor)
{
    return TacticalMonitorAction();
}

static int OnStart(SMBotMainAction action, SMBot actor, NextBotAction prevAction)
{
    return action.Continue();
}

static int Update(SMBotMainAction action, SMBot actor, float interval)
{
    actor.ResetDecoratedDebugString();
    actor.BuildDecoratedDebugString(action); // for debugging
    actor.UpdateLookingAround();
    actor.FireWeaponAtEnemy();

    return action.Continue();
}

static int OnActorEmoted(NextBotAction action, SMBot actor, CBaseCombatCharacter emoter, int emote)
{
    return action.TryContinue();
}

static int OnWeaponFired(NextBotAction action, SMBot actor, CBaseCombatCharacter whoFired, CBaseEntity weapon)
{
    return action.TryContinue();   
}

static int OnTerritoryContested(NextBotAction action, int actor, int victim)
{
    return action.TryContinue();   
}

static int OnTerritoryCaptured(NextBotAction action, int actor, int victim)
{
    return action.TryContinue();   
}

static int OnTerritoryLost(NextBotAction action, int actor, int victim)
{
    return action.TryContinue();   
}

static int OnCommandString(NextBotAction action, SMBot actor, const char[] command)
{
    return action.TryContinue();
}

/**
 * Given a subject, return the world space position we should aim at
 */
static void SelectTargetPoint(NextBotAction action, INextBot bot, CBaseCombatCharacter subject, float pos[3])
{
    SMBot me = SMBot(bot.GetEntity());
    IVision vision = bot.GetVisionInterface();
    int target = subject.index;
    float myPos[3];
    float theirPos[3];
    float theirCenter[3];

    if (!subject.IsValid())
        return;

    me.GetAbsOrigin(myPos);
    subject.GetAbsOrigin(theirPos);
    subject.WorldSpaceCenter(theirCenter);

    if (CBaseObject.IsBaseObject(target))
    {
        CBaseObject baseobject = CBaseObject(target);
        baseobject.WorldSpaceCenter(pos); // aim at the object center
        return;
    }

    CTFWeaponBase myWeapon = me.GetActiveWeapon();

    if (myWeapon.IsValid())
    {
        if (me.GetDifficulty() != Easy)
        {
            // lead our target and aim for the feet with the rocket launcher
            if (myWeapon.GetWeaponID() == TF_WEAPON_ROCKETLAUNCHER)
            {
                // if they are above us, don't aim for the feet
                const float aboveTolerance = 30.0;
                if (theirPos[2] - aboveTolerance > myPos[2])
                {
                    if (vision.IsAbleToSee(theirPos, DISREGARD_FOV))
                    {
                        subject.GetAbsOrigin(pos);
                        return;
                    }

                    subject.WorldSpaceCenter(pos);
                    return;
                }

                // aim at the ground under the subject
                if (subject.GetPropEnt(Prop_Data, "m_hGroundEntity") == -1)
                {
                    float endPos[3];
                    subject.GetAbsOrigin(endPos);
                    endPos[2] -= 200.0;

                    Handle trace = TR_TraceRayEx(theirPos, endPos, MASK_SOLID, RayType_EndPoint);
                    if (TR_DidHit(trace))
                    {
                        TR_GetEndPosition(pos, trace);
                        delete trace;
                        return;
                    }
                    
                    delete trace;
                }

                // aim at their feet and lead our target
                const float baseMissileSpeed = 1100.0; // to-do, read weapon attributes
                const float veryCloseRange = 150.0;
                float rangetBetween = bot.GetRangeToEx(theirPos);
                
                if (rangetBetween > veryCloseRange)
                {
                    float travelTime = rangetBetween / baseMissileSpeed;
                    float targetSpot[3];
                    float targetVelocity[3];

                    subject.GetAbsVelocity(targetVelocity);
                    targetSpot[0] = theirPos[0] + travelTime * targetVelocity[0];
                    targetSpot[1] = theirPos[1] + travelTime * targetVelocity[1];
                    targetSpot[2] = theirPos[2] + travelTime * targetVelocity[2];

                    if (vision.IsAbleToSee(targetSpot, DISREGARD_FOV))
                    {
                        VectorCopy(targetSpot, pos);
                        return;
                    }

                    // targetSpot can't be seen by the bot, to prevent the bot from shooting into a wall close to them, just aim directly at the enemy
                    VectorCopy(theirPos, pos);
                    return;
                }
            }
            else if (CTFWeaponBase.WeaponID_IsSniperRifle(myWeapon.GetWeaponID()))
            {
                if (CTFPlayer.IsPlayerEntity(target))
                {
                    CTFPlayer TFPlayer = CTFPlayer(target);
                    int headBone = TFPlayer.LookUpBone("bip_head");
                    float desiredAimSpot[3];
                    float boneAngle[3];

                    switch(me.GetDifficulty())
                    {
                        case Expert, Hard:
                        {
                            if (headBone >= 0)
                            {
                                TFPlayer.GetBonePosition(headBone, desiredAimSpot, boneAngle);

                                if (vision.IsAbleToSee(desiredAimSpot, DISREGARD_FOV))
                                {
                                    VectorCopy(desiredAimSpot, pos);
                                    return;
                                }
                            }
                        }
                    }
                }

                subject.WorldSpaceCenter(pos);
                return;
            }
        }
    }

    subject.WorldSpaceCenter(pos);
    return;
}

// To-do:
static CKnownEntity SelectMoreDangerousThreat(NextBotAction action, INextBot bot, CBaseCombatCharacter subject, CKnownEntity threat1, CKnownEntity threat2)
{
    if (threat1 == NULL_KNOWN_ENTITY && threat2 == NULL_KNOWN_ENTITY)
    { // ???
        return NULL_KNOWN_ENTITY;
    }

    if (threat1 == NULL_KNOWN_ENTITY && threat2 != NULL_KNOWN_ENTITY)
    {
        return threat1;
    }
    else if (threat1 != NULL_KNOWN_ENTITY && threat2 == NULL_KNOWN_ENTITY)
    {
        return threat2;
    }

    // At this point both threat1 and threat2 should be valid
    //CBaseEntity ent1 = CBaseEntity(threat1.GetEntity());
    //CBaseEntity ent2 = CBaseEntity(threat2.GetEntity());

    if (bot.GetRangeSquaredTo(threat1.GetEntity()) < bot.GetRangeSquaredTo(threat2.GetEntity()))
    {
        return threat1;
    }

    return threat2;
}