// Extra copies per monster: 1 = x2 total, 2 = x3 total
const int Patch_MoreMonsters_Copies = 2;

// One "done" flag per world, saved with the savegame
var int Patch_MoreMonsters_Done[8];

func void Patch_MoreMonsters_Run() {
    var int arr;
    var int listPtr;
    var zCListSort node;
    var C_NPC mmNpc;
    var int i;
    var int n;
    var int copies;
    var int inst;
    var string wp;

    if (!Hlp_IsValidNpc(hero)) { return; };
    if (CurrentLevel <= 0) || (CurrentLevel >= 8) { return; };
    if (MEM_ReadStatArr(Patch_MoreMonsters_Done, CurrentLevel)) { return; };
    MEM_WriteStatArr(Patch_MoreMonsters_Done, CurrentLevel, TRUE);

    // Pass 1: collect living monsters (not dragons)
    arr = MEM_ArrayCreate();
    listPtr = MEM_World.voblist_npcs;
    while (listPtr);
        node = _^(listPtr);
        if (node.data) {
            mmNpc = _^(node.data);
            if (mmNpc.guild > GIL_SEPERATOR_HUM)
            && (mmNpc.guild < GIL_SEPERATOR_ORC)
            && (mmNpc.guild != GIL_DRAGON)
            && (!Npc_IsDead(mmNpc)) {
                MEM_ArrayInsert(arr, node.data);
            };
        };
        listPtr = node.next;
    end;

    // Pass 2: spawn copies at the nearest waypoint of each monster
    n = MEM_ArraySize(arr);
    i = 0;
    while (i < n);
        mmNpc = _^(MEM_ArrayRead(arr, i));
        wp = Npc_GetNearestWP(mmNpc);
        inst = Hlp_GetInstanceID(mmNpc);
        if (!Hlp_StrCmp(wp, "")) {
            copies = 0;
            while (copies < Patch_MoreMonsters_Copies);
                Wld_InsertNpc(inst, wp);
                copies += 1;
            end;
        };
        i += 1;
    end;
    MEM_ArrayFree(arr);
};

func void Ninja_MoreMonsters_Init() {
    MEM_InitAll();
    LeGo_MergeFlags(LeGo_FrameFunctions);
    FF_ApplyOnceExt(Patch_MoreMonsters_Run, 3000, -1);
};
