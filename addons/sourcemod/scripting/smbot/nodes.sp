/**
 * SMBot Nodes
 */

#define NODE_VERSION 1          // Node file version.
#define MAX_NODES 1024          // Maximum nodes allowed.
#define INVALID_NODE_ID -1      // Invalid Node.
#define NODE_HEIGHT 72          // Node height for drawing.
#define SAVE_MAX_EDITORS 3      // Maximum number of editor names to be saved.

enum NodeHint
{
    NodeHint_DontCare = -2,             // Don't Care. Used when searching nodes.
    NodeHint_Unknown = -1,              // Unknown hint type.
    NodeHint_None = 0,                  // No hint.
    NodeHint_Sniper,                    // Snipers should camp here.
    NodeHint_SentryGun,                 // Engineers should build a sentry gun here.
    NodeHint_Dispenser,                 // Engineers should build a dispenser here.
    NodeHint_TeleporterExit,            // Engineers should build a teleporter exit here.
    NodeHint_TeleporterEntrance,        // Engineers should build a teleporter entrance here.
    NodeHint_Deathmatch,                // Deathmatch roaming hint.

    NodeHint_MaxHintType                // Maximum number of hints available.
}

int g_iNodeHintColor[view_as<int>(NodeHint_MaxHintType)][4] = {
    { 255, 255, 255, 255 }, // None
    { 0, 255, 0, 255 }, // Sniper
    { 255, 0, 0, 255 }, // SentryGun 
    { 0, 0, 255, 255 }, // Dispenser 
    { 255, 165, 0, 255 }, // Tele Exit 
    { 165, 42, 42, 255 }, // Tele Entrance 
    { 255, 105, 180, 255 } // Deathmatch
}

char g_szNodeHintName[view_as<int>(NodeHint_MaxHintType)][16] = {
    "None",
    "Sniper",
    "Sentry Gun",
    "Dispenser",
    "Tele Exit",
    "Tele Entrance",
    "Deathmatch"
}

bool g_bNodeUsed[MAX_NODES]; // True if the node is used
bool g_bNodeTaken[MAX_NODES]; // True if the node is taken by a bot
int g_iNodeTeam[MAX_NODES]; // Node team
int g_iNodeHint[MAX_NODES]; // Node hint type
float g_NodeOrigin[MAX_NODES][3]; // Node origin vector
float g_flNodeHintVector[MAX_NODES][3]; // Node hint vector
bool g_NodeVisibilityTable[MAX_NODES][MAX_NODES]; // table of node visibility [source][other]

bool g_bHasNodes; // does the current map has nodes
bool g_bHasVisibilityData; // does the current map has node visibility table set;
bool g_bNodeEdit; // node edit mode enabled/disabled
bool g_bBuildingVisTable;
bool g_bFirstEdit; // First edit being made to this map
int g_iNodeEditor; // current node editor player
float g_flNextNodeDrawTime; // timer for drawing nodes
char g_szNodeEditors[SAVE_MAX_EDITORS][MAX_NAME_LENGTH];
int g_iNumberOfEditors;

methodmap CNode
{
    public CNode(int index)
    {
        return view_as<CNode>(index);
    }

    property int index
    {
        public get()
        {
            return view_as<int>(this);
        }
    }

    // Checks if the Node instance is valid.
    // @note This checks the node index, use IsFree() to check if the node is usable.
    public bool IsValid()
    {
        return this.index >= 0 && this.index < MAX_NODES;
    }

    // Marks this node as used
    public void Register()
    {
        g_bNodeUsed[this.index] = true;
        g_bNodeTaken[this.index] = false;
    }

    // Destroys the node, removing it
    public void Destroy()
    {
        g_bNodeUsed[this.index] = false;
        VectorCopy(NULL_VECTOR, g_NodeOrigin[this.index]);
        VectorCopy(NULL_VECTOR, g_flNodeHintVector[this.index]);
        g_iNodeTeam[this.index] = 0;
        g_iNodeHint[this.index] = 0;
    }

    // Gets the node ID. Same as index
    public int ID()
    {
        return this.index;
    }

    // Sets the node origin
    public void SetOrigin(float vector[3])
    {
        VectorCopy(vector, g_NodeOrigin[this.index]);
    }

    // Gets the node origin
    public void GetOrigin(float buffer[3])
    {
        VectorCopy(g_NodeOrigin[this.index], buffer);
    }

    public void GetMiddlePoint(float buffer[3])
    {
        VectorCopy(g_NodeOrigin[this.index], buffer);
        buffer[2] += float(NODE_HEIGHT/2);
    }

    public void GetTopPoint(float buffer[3])
    {
        VectorCopy(g_NodeOrigin[this.index], buffer);
        buffer[2] += float(NODE_HEIGHT);
    }

    // Sets the node hint vector
    public void SetHintVector(float vector[3])
    {
        VectorCopy(vector, g_flNodeHintVector[this.index]);
    }

    // Gets the node hint vector
    public void GetHintVector(float buffer[3])
    {
        VectorCopy(g_flNodeHintVector[this.index], buffer);
    }

    public void GetColor(int buffer[4])
    {
        VectorCopyEx(g_iNodeHintColor[view_as<int>(this.hint)], buffer, 4);
    }

    public void GetHintName(char[] name, int size)
    {
        strcopy(name, size, g_szNodeHintName[view_as<int>(this.hint)]);
    }

    public void Draw(const float duration = 1.0)
    {
        float start[3];
        float angles[3];
        float fwd[3];
        float end[3];
        float mid[3];
        int colors[4];
        this.GetOrigin(start);
        this.GetMiddlePoint(mid);
        this.GetHintVector(angles);
        VectorCopy(start, end);
        end[2] += NODE_HEIGHT;
        this.GetColor(colors);
        GetAngleVectors(angles, fwd, NULL_VECTOR, NULL_VECTOR);
        ScaleVector(fwd, 24.0);
        AddVectors(mid, fwd, fwd);

        UTIL_DrawLaser(-1, start, end, colors, duration);
        UTIL_DrawLaser(-1, mid, fwd, { 255,255,255,255 }, duration);
    }

    // Checks if the node is free
    //
    // @note A free node is a node that hasn't been registered and is invalid for usage.
    // @return      true if the node is free
    public bool IsFree()
    {
        return g_bNodeUsed[this.index] == false;
    }

    public bool IsAvailable()
    {
        return g_bNodeTaken[this.index] == false;
    }

    // Marks the node as available/unavailable.
    // @note This is to prevent multiple bots from using the same node at the same time
    // @param reserved      Is the node reserved? If true, bots won't be able to use it until it becomes unreserved
    public void ChangeAvailableStatus(bool reserved = false)
    {
        g_bNodeTaken[this.index] = reserved;
    }

    public bool ForTeam(TFTeam team)
    {
        if (this.team == TFTeam_Unassigned)
        {
            return true;
        }

        return this.team == team;
    }

    // Get/Set this node team
    property TFTeam team
    {
        public get()
        {
            return view_as<TFTeam>(g_iNodeTeam[this.index]);
        }
        public set(TFTeam value)
        {
            g_iNodeTeam[this.index] = view_as<int>(value);
        }
    }

    // Get/Set this node hint
    property NodeHint hint
    {
        public get()
        {
            return view_as<NodeHint>(g_iNodeHint[this.index]);
        }
        public set(NodeHint value)
        {
            g_iNodeHint[this.index] = view_as<int>(value);
        }
    }

    public bool IsOfType(NodeHint type)
    {
        return this.hint == type;
    }
}

methodmap TheNodes
{
    // Reset per map data
    public static void ClearMapData()
    {
        g_bHasNodes = false;
        g_bHasVisibilityData = false;
        g_bBuildingVisTable = false;
        g_bFirstEdit = false;
        g_iNumberOfEditors = 0;
        TheNodes.ClearEditor();

        // memset would be really useful right now
        for(int i = 0; i < MAX_NODES; i++)
        {
            g_bNodeUsed[i] = false;
            g_bNodeTaken[i] = false;
            g_iNodeHint[i] = 0;
            g_iNodeTeam[i] = 0;
            VectorCopy(NULL_VECTOR, g_NodeOrigin[i]);
            VectorCopy(NULL_VECTOR, g_flNodeHintVector[i]);
        }

        for(int i = 0; i < SAVE_MAX_EDITORS; i++)
        {
            strcopy(g_szNodeEditors[i], sizeof(g_szNodeEditors[]), "");
        }

        TheNodes.ClearVisibilityTable();
    }

    // Clear the node visibility table
    public static void ClearVisibilityTable()
    {
        for(int i = 0; i < MAX_NODES; i++)
        {
            for(int y = 0; y < MAX_NODES; y++)
            {
                g_NodeVisibilityTable[i][y] = false;
            }
        }
    }

    public static bool IsValidNodeID(int id)
    {
        return id >= 0 && id < MAX_NODES;
    }

    // Builds the SMBot data storage directory
    public static void BuildNodeDirectory()
    {
        char szNodeFolder[PLATFORM_MAX_PATH];

        BuildPath(Path_SM, szNodeFolder, sizeof(szNodeFolder), "data/smbot/");
        
        if (!DirExists(szNodeFolder))
        {
            LogMessage("Creating NODE storage folder.");
            CreateDirectory(szNodeFolder, 766);
        }
    }

    // Returns the first free node index
    public static int GetFirstFreeNode()
    {
        for(int i = 0; i < MAX_NODES; i++)
        {
            CNode node = CNode(i);

            if (node.IsFree())
                return node.index;
        }

        return INVALID_NODE_ID;
    }

    // Gets the nearest node to the given origin
    // @param origin        Search origin vector
    // @param maxdistance   Maximum search distance (squared)
    // @return              Nearest node found or invalid node if none. Use IsValid() to check.
    public static CNode GetNearestNode(const float origin[3], const float maxdistance = 25000.0)
    {
        int best = INVALID_NODE_ID;
        float dest[3];
        float smallest = maxdistance * 2.0, distance;

        for(int i = 0; i < MAX_NODES; i++)
        {
            CNode node = CNode(i);

            if (node.IsFree())
                continue;

            node.GetOrigin(dest);
            distance = GetVectorDistance(origin, dest, true);

            if (distance > maxdistance)
                continue;

            if (distance < smallest)
            {
                smallest = distance;
                best = i;
            }
        }

        return CNode(best);
    }

    // Gets the nearest node to the given origin.
    // @param origin            Search origin vector.
    // @param hint              Node type to search.
    // @param available_only    If set to **true**, nodes currently being used by bots are ignored.
    // @param maxdistance       Maximum search distance (squared).
    // @return                  Nearest node found or invalid node if none. Use IsValid() to check.
    public static CNode GetNearestNodeOfType(const float origin[3], const NodeHint hint = NodeHint_Unknown, const bool available_only = true, const float maxdistance = 25000.0)
    {
        int best = INVALID_NODE_ID;
        float dest[3];
        float smallest = maxdistance * 2.0, distance;

        for(int i = 0; i < MAX_NODES; i++)
        {
            CNode node = CNode(i);

            if (node.IsFree())
                continue;

            if (!node.IsOfType(hint))
                continue;

            if (available_only && !node.IsAvailable())
                continue;

            node.GetOrigin(dest);
            distance = GetVectorDistance(origin, dest, true);

            if (distance > maxdistance)
                continue;

            if (distance < smallest)
            {
                smallest = distance;
                best = i;
            }
        }

        return CNode(best);
    }

    // Gets a random node within a maximum and minimum distance.
    // @param origin            Search origin vector.
    // @param hint              Node type to search.
    // @param available_only    If set to **true**, nodes currently being used by bots are ignored.
    // @param mindistance       Minimum search distance (squared).
    // @param maxdistance       Maximum search distance (squared).
    // @return                  Random node within a given max distance.
    public static CNode GetRandomNode(const float origin[3], const NodeHint hint = NodeHint_DontCare, const bool available_only = true, const float mindistance = 0.0, const float maxdistance = 25000000.0)
    {
        int best = INVALID_NODE_ID;
        float dest[3];
        float distance;
        int num_nodes = 0;
        int found[MAX_NODES];

        for(int i = 0; i < MAX_NODES; i++)
        {
            CNode node = CNode(i);

            if (node.IsFree())
                continue;

            if (hint != NodeHint_DontCare && !node.IsOfType(hint))
                continue;

            if (available_only && !node.IsAvailable())
                continue;

            node.GetOrigin(dest);
            distance = GetVectorDistance(origin, dest, true);

            if (distance < mindistance)
                continue;

            if (distance > maxdistance)
                continue;

            found[num_nodes] = i;
            num_nodes++;
        }

        if (num_nodes <= 0)
        {
            return CNode(INVALID_NODE_ID);
        }

        best = found[Math_GetRandomInt(0, num_nodes - 1)];

        return CNode(best);
    }

    // Collects all nodes visible to the given position
    // @param origin            Position to test visibility
    // @param hint              Hint to search for or `NodeHint_DontCare` to ignore hints
    // @param visible_nodes     Array to store visible nodes at
    // @param num_visible       Number of visible nodes collected
    // @return                  **TRUE** if at least one visible node, false otherwise.
    public static bool CollectVisibleNodes(const float origin[3], const NodeHint hint = NodeHint_DontCare, int visible_nodes[MAX_NODES], int &num_visible)
    {
        float dest[3];
        num_visible = 0;

        for(int i = 0; i < MAX_NODES; i++)
        {
            CNode node = CNode(i);

            if (node.IsFree())
                continue;

            if (hint != NodeHint_DontCare && !node.IsOfType(hint))
                continue;

            node.GetMiddlePoint(dest);

            if (!UTIL_QuickSimpleTraceLine(origin, dest, MASK_VISIBLE|CONTENTS_WINDOW|CONTENTS_GRATE))
            {
                visible_nodes[num_visible] = i;
                num_visible++;
            }
        }

        if (num_visible > 0)
            return true;

        return false;
    }

    // Collects all nodes visible to the origin node.
    // @note This uses the node visibility table.
    // @param origin            Origin node.
    // @param hint              Hint to search for or `NodeHint_DontCare` to ignore hints.
    // @param visible_nodes     Array to store visible nodes at.
    // @param num_visible       Number of visible nodes collected.
    // @return                  **TRUE** if at least one visible node, false otherwise.
    public static bool CollectVisibleNodesEx(const CNode origin, const NodeHint hint = NodeHint_DontCare, int visible_nodes[MAX_NODES], int &num_visible)
    {
        num_visible = 0;

        for(int i = 0; i < MAX_NODES; i++)
        {
            CNode node = CNode(i);

            if (node.IsFree())
                continue;

            if (hint != NodeHint_DontCare && !node.IsOfType(hint))
                continue;

            if (origin.index == i)
                continue;

            if (TheNodes.IsVisible(origin, node))
            {
                visible_nodes[num_visible] = i;
                num_visible++;
            }
        }

        if (num_visible > 0)
            return true;

        return false;
    }

    // Gets the current editor
    public static int GetEditor()
    {
        return g_iNodeEditor;
    }

    // Sets the current editor
    // @param editor        Client index of the editor
    public static int SetEditor(int editor)
    {
        g_iNodeEditor = editor;
        g_bNodeEdit = true;
        g_flNextNodeDrawTime = 0.0;
    }

    // Clears the editor
    public static void ClearEditor()
    {
        g_iNodeEditor = -1;
        g_bNodeEdit = false;
        g_flNextNodeDrawTime = 0.0;
    }

    // Check if edit mode is enabled
    public static bool IsEditing()
    {
        return g_bNodeEdit;
    }

    public static float GetNextDrawTime()
    {
        return g_flNextNodeDrawTime;
    }

    public static float SetNextDrawTime(float time)
    {
        g_flNextNodeDrawTime = GetGameTime() + time;
    }

    public static bool ShouldDraw()
    {
        return g_flNextNodeDrawTime <= GetGameTime();
    }

    public static void DrawAllInRange(const float center[3], const float radius = 1500000.0, const float duration = 20.0)
    {
        float dest[3];
        float distance;

        for(int i = 0; i < MAX_NODES; i++)
        {
            CNode node = CNode(i);

            if (node.IsFree())
                continue;

            node.GetOrigin(dest);
            distance = GetVectorDistance(center, dest, true);

            if (distance <= radius)
            {
                node.Draw(duration);
            }
        }
    }

    // Add node editing credits
    public static void AddEditorCredits(int client)
    {
        char buffer[MAX_NAME_LENGTH];
        GetClientName(client, buffer, sizeof(buffer));

        for(int i = 0; i < SAVE_MAX_EDITORS; i++)
        {
            if (!g_szNodeEditors[i]) // No editor saved yet! Save it!
            {
                LogMessage("Saved new editor %s", buffer);
                strcopy(g_szNodeEditors[i], sizeof(g_szNodeEditors[]), buffer);
                g_iNumberOfEditors++;
                return;
            }
        }

        // Check if name is already saved.
        // NOTE: index 0 is considered to be the original creator and should never be replaced!
        for(int i = 1; i < SAVE_MAX_EDITORS; i++)
        {
            if (strcmp(g_szNodeEditors[i], buffer) == 0)
            {
                return; // Editor name already saved!
            }
        }

        // Move editor index 2 to index 1, save name to index 2
        strcopy(g_szNodeEditors[1], sizeof(g_szNodeEditors[]), g_szNodeEditors[2]);
        strcopy(g_szNodeEditors[2], sizeof(g_szNodeEditors[]), buffer);
        LogMessage("Saved editor %s", buffer);
    }

    // Checks if there is at least 1 node being used
    public static bool HasAnyNodes()
    {
        for(int i = 0;i < MAX_NODES;i++)
        {
            if (g_bNodeUsed[i])
            {
                return true;
            }

            return false;
        }
    }

    // Saves the current node to disk
    public static void SaveNodes()
    {
        char map[128];
        char destination[PLATFORM_MAX_PATH];
        UTIL_GetMapName(map, sizeof(map));

        LogMessage("Saving nodes for %s", map);

        BuildPath(Path_SM, destination, sizeof(destination), "data/smbot/%s.nodes", map);

        File file = OpenFile(destination, "wb");

        if (file == null)
        {
            SetFailState("Failed to save node file %s", destination);
        }

        file.WriteString("SMBotNodes", true); // Header
        file.WriteInt8(NODE_VERSION); // Nodes version
        file.WriteInt8(g_iNumberOfEditors);

        for(int i = 0; i < g_iNumberOfEditors; i++)
        {
            file.WriteString(g_szNodeEditors[i], true);
        }

        file.WriteInt8(g_bHasVisibilityData ? 1 : 0);

        file.Write(g_bNodeUsed, MAX_NODES, 1);
        file.Write(g_iNodeTeam, MAX_NODES, 1);
        file.Write(g_iNodeHint, MAX_NODES, 2);

        for(int i = 0; i < MAX_NODES; i++)
        {
            file.Write(view_as<int>(g_NodeOrigin[i]), 3, 4);
            file.Write(view_as<int>(g_flNodeHintVector[i]), 3, 4);
        }

        LogMessage("Successfully saved node files for %s", map);
        LogMessage("Nodes saved to: \"%s\"", destination);

        int counter = 0;

        for(int i = 0; i < MAX_NODES; i++)
        {
            if (g_bNodeUsed[i])
                counter++;
        }

        LogMessage("Saved %i nodes for %s", counter, map);

        delete file;
    }

    public static void SaveVisTable()
    {
        char map[128];
        char destination[PLATFORM_MAX_PATH];
        UTIL_GetMapName(map, sizeof(map));

        LogMessage("Saving node visibility table for %s", map);

        BuildPath(Path_SM, destination, sizeof(destination), "data/smbot/%s.vis", map);

        File file = OpenFile(destination, "wb");

        if (file == null)
        {
            SetFailState("Failed to save node visibility table file %s", destination);
        }

        file.WriteString("SMBotVisTable", true); // Header
        file.WriteInt8(NODE_VERSION); // Nodes version

        for(int i = 0; i < MAX_NODES; i++)
        {
            for(int y = 0; y < MAX_NODES; y++)
            {
                file.WriteInt8(g_NodeVisibilityTable[i][y] ? 1 : 0);
            }
        }

        LogMessage("Successfully saved node visibility table file for %s", map);
        LogMessage("Nodes visibility table saved to: \"%s\"", destination);

        delete file;
    }

    public static void LoadNodes()
    {
        char map[128];
        char destination[PLATFORM_MAX_PATH];
        UTIL_GetMapName(map, sizeof(map));

        LogMessage("Loading nodes for %s", map);

        BuildPath(Path_SM, destination, sizeof(destination), "data/smbot/%s.nodes", map);

        File file = OpenFile(destination, "rb");

        if (file == null)
        {
            PrintToServer("Map %s does not have nodes.", map);
            g_bHasNodes = false;
            return;
        }

        char header[16];
        file.ReadString(header, sizeof(header), -1); // Read header

        if (strncmp("SMBotNodes", header, 10) != 0)
        {
            LogError("Node file \"%s\" contains invalid header!", destination);
            delete file;
            return;
        }

        int version;
        file.ReadInt8(version); // read file

        if (version > NODE_VERSION)
        {
            LogError("Node version %i > %i!", version, NODE_VERSION);
            delete file;
            return;
        }

        if (version != NODE_VERSION)
        {
            LogMessage("Warning: Node file version is %i while plugin node version is %i", version, NODE_VERSION);
        }

        file.ReadInt8(g_iNumberOfEditors);

        for(int i = 0; i < g_iNumberOfEditors; i++)
        {
            file.ReadString(g_szNodeEditors[i], sizeof(g_szNodeEditors[]), -1);
        }

        int visdata;
        file.ReadInt8(visdata);
        g_bHasVisibilityData = visdata != 0;

        file.Read(g_bNodeUsed, MAX_NODES, 1);
        file.Read(g_iNodeTeam, MAX_NODES, 1);
        file.Read(g_iNodeHint, MAX_NODES, 2);

        for(int i = 0; i < MAX_NODES; i++)
        {
            file.Read(g_NodeOrigin[i], 3, 4);
            file.Read(g_flNodeHintVector[i], 3, 4);
        }

        g_bHasNodes = true;
        PrintToServer("Finished loading nodes for %s", map);

        delete file;

        int counter = 0;

        for(int i = 0; i < MAX_NODES; i++)
        {
            if (g_bNodeUsed[i])
                counter++;
        }

        LogMessage("Loaded %i nodes for %s", counter, map);

        if (g_bHasVisibilityData)
        {
            TheNodes.LoadVisibilityTable();
        }
        else
        {
            TheNodes.BuildVisibilityTable(true);
        }
    }

    public static void LoadVisibilityTable()
    {
        char map[128];
        char destination[PLATFORM_MAX_PATH];
        UTIL_GetMapName(map, sizeof(map));

        LogMessage("Loading node visibility table for %s", map);

        BuildPath(Path_SM, destination, sizeof(destination), "data/smbot/%s.vis", map);

        File file = OpenFile(destination, "rb");

        if (file == null)
        {
            PrintToServer("Map %s does not have node visibility table.", map);
            g_bHasVisibilityData = false;
            TheNodes.BuildVisibilityTable(true);
            return;
        }

        char header[16];
        file.ReadString(header, sizeof(header), -1); // Read header

        if (strncmp("SMBotVisTable", header, 13) != 0)
        {
            LogError("Node Visibility file \"%s\" contains invalid header!", destination);
            delete file;
            return;
        }

        int version;
        file.ReadInt8(version); // read file

        if (version > NODE_VERSION)
        {
            LogError("Node visibility version %i > %i!", version, NODE_VERSION);
            delete file;
            return;
        }

        if (version != NODE_VERSION)
        {
            LogMessage("Warning: Node visibility file version is %i while plugin node version is %i", version, NODE_VERSION);
        }

        for(int i = 0; i < MAX_NODES; i++)
        {
            for(int y = 0; y < MAX_NODES; y++)
            {
                int isvisible;
                file.ReadInt8(isvisible);
                g_NodeVisibilityTable[i][y] = isvisible != 0;
            }
        }

        LogMessage("Successfully loaded node visibility table file for %s", map);
        LogMessage("Nodes visibility table loaded from: \"%s\"", destination);
        g_bHasVisibilityData = true;
        delete file;
    }

    // Builds the node visibility table
    // @param reset     Set to true when starting a new build
    // @param step      Step increment per call
    public static void BuildVisibilityTable(bool reset = false, const int step = 16)
    {
        static int last;

        if (!g_bHasNodes)
            return;

        if (reset == true)
        {
            last = 0;
            g_bBuildingVisTable = true;
            CreateTimer(0.2, Timer_BuildVisibilityTime, .flags = TIMER_REPEAT);
        }

        int tlast = last;
        float start1[3], start2[3], start3[3], end1[3], end2[3], end3[3];
        
        for(int iter1 = last; iter1 < last + step; iter1++)
        {
            if (iter1 >= MAX_NODES) // reached end
            {
                g_bBuildingVisTable = false;
                g_bHasVisibilityData = true;
                PrintToServer("Finished building Node Visibility Table");
                TheNodes.SaveVisTable();
                TheNodes.SaveNodes();
                return;
            }

            CNode node1 = CNode(iter1);
            tlast++;

            if (node1.IsFree())
                continue;

            node1.GetOrigin(start1);
            node1.GetMiddlePoint(start2);
            node1.GetTopPoint(start3);

            for(int iter2 = 0; iter2 < MAX_NODES; iter2++)
            {
                CNode node2 = CNode(iter2);

                if (node2.IsFree())
                    continue;

                if (node1.index == node2.index) // Node can't see itself
                {
                    g_NodeVisibilityTable[node1.index][node2.index] = false;
                }

                node2.GetOrigin(end1);
                node2.GetMiddlePoint(end2);
                node2.GetTopPoint(end3)

                // check vis
                bool visible = !UTIL_QuickSimpleTraceLine(start1, end1, MASK_VISIBLE_AND_NPCS|CONTENTS_WINDOW); // origin to origin
                if (!visible) { visible = !UTIL_QuickSimpleTraceLine(start1, end2, MASK_VISIBLE_AND_NPCS|CONTENTS_WINDOW); } // origin to mid
                if (!visible) { visible = !UTIL_QuickSimpleTraceLine(start1, end3, MASK_VISIBLE_AND_NPCS|CONTENTS_WINDOW); } // origin to top
                if (!visible) { visible = !UTIL_QuickSimpleTraceLine(start2, end1, MASK_VISIBLE_AND_NPCS|CONTENTS_WINDOW); } // mid to origin
                if (!visible) { visible = !UTIL_QuickSimpleTraceLine(start2, end2, MASK_VISIBLE_AND_NPCS|CONTENTS_WINDOW); } // mid to mid
                if (!visible) { visible = !UTIL_QuickSimpleTraceLine(start2, end3, MASK_VISIBLE_AND_NPCS|CONTENTS_WINDOW); } // mid to top
                if (!visible) { visible = !UTIL_QuickSimpleTraceLine(start3, end1, MASK_VISIBLE_AND_NPCS|CONTENTS_WINDOW); } // top to origin
                if (!visible) { visible = !UTIL_QuickSimpleTraceLine(start3, end2, MASK_VISIBLE_AND_NPCS|CONTENTS_WINDOW); } // top to mid
                if (!visible) { visible = !UTIL_QuickSimpleTraceLine(start3, end3, MASK_VISIBLE_AND_NPCS|CONTENTS_WINDOW); } // top to top

                g_NodeVisibilityTable[node1.index][node2.index] = visible;
            }
        }

        last = tlast;
        float progress = last/float(MAX_NODES);
        progress *= 100.0;
        PrintToServer("Building Node Visibility table (%i%%)", RoundToNearest(progress));
    }

    // Translates a hint name to a hint type
    // @param name      Hint name
    public static NodeHint GetNodeHintByName(const char[] name)
    {
        for(int i = 0; i < view_as<int>(NodeHint_MaxHintType); i++)
        {
            if (strcmp(name, g_szNodeHintName[i], false) == 0)
            {
                return view_as<NodeHint>(i);
            }
        }

        return NodeHint_Unknown;
    }

    // Gets all available hint names as a string
    // @param buffer    Buffer to store the name
    // @param size      Buffer size
    public static void GetAllAvailableHintsString(char[] buffer, int size)
    {
        for(int i = 0; i < view_as<int>(NodeHint_MaxHintType); i++)
        {
            if (i == 0)
            {
                Format(buffer, size, "%s", g_szNodeHintName[i]);
                continue;
            }

            Format(buffer, size, "%s, %s", buffer, g_szNodeHintName[i]);
        }
    }

    // Adds a new node
    // @param client        Index of the client requesting a node to be added
    // @param team          Node team
    // @param hint          Node hint type
    // @return              True if a node was added, false if not
    public static bool AddNode(int client, TFTeam team = TFTeam_Unassigned, NodeHint hint = NodeHint_None)
    {
        float origin[3];
        float angles[3];
        int index = TheNodes.GetFirstFreeNode();

        if (index == INVALID_NODE_ID)
        {
            PrintToChat(client, "[SMBot] Failed to add new node. No free node available.");
            return false;
        }

        GetClientAbsOrigin(client, origin);
        GetClientEyeAngles(client, angles);

        CNode node = CNode(index);

        node.Register();
        node.SetOrigin(origin);
        node.SetHintVector(angles);
        node.team = team;
        node.hint = hint;

        char teamname[32];
        GetTeamName(view_as<int>(team), teamname, sizeof(teamname));

        PrintToChat(client, "[SMBot] Node #%i added for team \"%s\" with hint \"%s\"", index, teamname, g_szNodeHintName[view_as<int>(hint)]);
        g_bHasVisibilityData = false; // This will force visibility data to be rebuilt

        if (!g_bFirstEdit)
        {
            g_bFirstEdit = true;
            TheNodes.AddEditorCredits(client);
        }

        if (!g_bHasNodes)
        {
            g_bHasNodes = true;
        }

        return true;
    }

    // Removes the nearest node of the given client
    // @param client        Client index
    public static bool RemoveNode(int client)
    {
        float origin[3];
        GetClientAbsOrigin(client, origin);
        CNode node = TheNodes.GetNearestNode(origin);

        if (node.IsValid())
        {
            node.Destroy();
            PrintToChat(client, "[SMBot] Node #%i was removed!", node.index);
            g_bHasVisibilityData = false; // This will force visibility data to be rebuilt
        }
    }

    // Checks if a node can see another node using the visibility table
    // @param node1     First Node
    // @param node2     Second Node
    // @return          **TRUE** if second node is visible to first node
    public static bool IsVisible(CNode node1, CNode node2)
    {
        return g_NodeVisibilityTable[node1.index][node2.index];
    }
}

Action Timer_BuildVisibilityTime(Handle timer)
{
    TheNodes.BuildVisibilityTable();

    return g_bBuildingVisTable ? Plugin_Continue : Plugin_Stop;
}