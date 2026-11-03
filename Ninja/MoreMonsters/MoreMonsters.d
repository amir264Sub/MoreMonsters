// Extra copies per monster: 1 = x2 total
const int Patch_MoreMonsters_Copies = 1;

// Monsters processed per tick (one tick = 1 second)
const int Patch_MoreMonsters_Batch = 8;

var int Patch_MoreMonsters_Done[8];
var int Patch_MoreMonsters_Ticks;
var int Patch_MoreMonsters_ViaWp;
var int Patch_MoreMonsters_ViaRange;

func void Patch_MoreMonsters_Run() {
    var int listPtr;
    var zCListSort node;
    var C_NPC mmNpc;
    var int arr;
    var int i;
    var int n;
    var int copies;
    var int inst;
    var int marked;
    var int pending;
    var string wp;

    if (!Hlp_IsValidNpc(hero)) { return; };
    if (CurrentLevel <= 0) || (CurrentLevel >= 8) { return; };

    Patch_MoreMonsters_Ticks += 1;
    if (Patch_MoreMonsters_Ticks < 3) { return; };

    // Step 1 (once per world): mark all living monsters as pending
    if (!MEM_ReadStatArr(Patch_MoreMonsters_Done, CurrentLevel)) {
        MEM_WriteStatArr(Patch_MoreMonsters_Done, CurrentLevel, TRUE);
        marked = 0;
        listPtr = MEM_World.voblist_npcs;
        while (listPtr);
            node = _^(listPtr);
            if (node.data) {
                mmNpc = _^(node.data);
                if (mmNpc.guild > GIL_SEPERATOR_HUM)
                && (mmNpc.guild < GIL_SEPERATOR_ORC)
                && (mmNpc.guild != GIL_DRAGON)
                && (!Npc_IsDead(mmNpc)) {
                    mmNpc.aivar[99] = 7001;
                    marked += 1;
                };
            };
            listPtr = node.next;
        end;
        Print(ConcatStrings("MoreMonsters marked: ", IntToString(marked)));
        return;
    };

    // Step 2 (every tick): collect a few pending monsters
    arr = MEM_ArrayCreate();
    pending = 0;
    listPtr = MEM_World.voblist_npcs;
    while (listPtr);
        node = _^(listPtr);
        if (node.data) {
            mmNpc = _^(node.data);
            if (mmNpc.aivar[99] == 7001) {
                if (MEM_ArraySize(arr) < Patch_MoreMonsters_Batch) {
                    MEM_ArrayInsert(arr, node.data);
                } else {
                    pending += 1;
                };
            };
        };
        listPtr = node.next;
    end;

    // Step 3: spawn the copies for the collected monsters
    n = MEM_ArraySize(arr);
    i = 0;
    while (i < n);
        mmNpc = _^(MEM_ArrayRead(arr, i));
        mmNpc.aivar[99] = 7002;
        if (!Npc_IsDead(mmNpc)) {
            wp = Npc_GetNearestWP(mmNpc);
            inst = Hlp_GetInstanceID(mmNpc);
            copies = 0;
            while (copies < Patch_MoreMonsters_Copies);
                if (!Hlp_StrCmp(wp, "")) {
                    Wld_InsertNpc(inst, wp);
                    Patch_MoreMonsters_ViaWp += 1;
                } else {
                    Wld_SpawnNpcRange(mmNpc, inst, 1, 500);
                    Patch_MoreMonsters_ViaRange += 1;
                };
                copies += 1;
            end;
        };
        i += 1;
    end;
    MEM_ArrayFree(arr);

    if (n > 0) {
        Print(ConcatStrings(ConcatStrings(ConcatStrings("MoreMonsters left ", IntToString(pending)), " wp "), ConcatStrings(IntToString(Patch_MoreMonsters_ViaWp), ConcatStrings(" range ", IntToString(Patch_MoreMonsters_ViaRange)))));
    };
};

func void Ninja_MoreMonsters_Init() {
    MEM_InitAll();
    LeGo_MergeFlags(LeGo_FrameFunctions);
    FF_ApplyOnceExt(Patch_MoreMonsters_Run, 1000, -1);
};
