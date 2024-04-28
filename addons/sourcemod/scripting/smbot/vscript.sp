// SMBot VScript utilitys

/**
 * Sets the player eye angles via VScript
 *
 * @param client    Client index
 * @param angles    Angle vector
 */
void VScript_SnapPlayerAngles(int client, float angles[3])
{
    char szAngles[128];
    FormatEx(szAngles, sizeof(szAngles), "!self.SnapEyeAngles(QAngle(%.2f, %.2f, %.2f))", angles[0], angles[1], angles[2]);
    SetVariantString(szAngles);
    AcceptEntityInput(client, "RunScriptCode");
}