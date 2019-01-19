#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <cstrike>

#include <hosties>
#include <lastrequest>

#include <multicolors>

#pragma newdecls required

#define LoopClients(%1) for(int %1 = 1; %1 <= MaxClients; %1++) if(IsClientValid(%1))
#define DMG_THROW (2 << 6)

int g_iCurrentLR = -1;

int g_iLRZeus = -1;
int g_iLRFists = -1;
int g_iLRAxe = -1;
int g_iLRHammer = -1;
int g_iLRSpanner = -1;

int g_iLRPrisoner = -1;
int g_iLRGuard = -1;

bool g_bRunning = false;
bool g_bMessage = false;
bool g_bThrowDamage = false;

int g_iPrimaryAttack = -1;
int g_iSecondaryAttack = -1;

public Plugin myinfo = 
{
    name = "Last Request - Fists, Zeus, Hammer, Axe, Spanner", 
    author = "Bara", 
    description = "", 
    version = "1.0.0", 
    url = ""
};

public void OnPluginStart()
{
    HookEvent("round_start", Event_RoundStart);
    HookEvent("item_remove", Event_ItemRemove);
    HookEvent("weapon_fire", Event_WeaponFire);
    
    LoopClients(client)
    {
        OnClientPutInServer(client);
    }
    
    g_iPrimaryAttack = FindSendPropInfo("CBaseCombatWeapon", "m_flNextPrimaryAttack");
    g_iSecondaryAttack = FindSendPropInfo("CBaseCombatWeapon", "m_flNextSecondaryAttack");
}

public void OnConfigsExecuted()
{
    static bool bAddedLR_Zeus = false;
    if (!bAddedLR_Zeus)
    {
        g_iLRZeus = AddLastRequestToList(LR_Start, LR_Stop, "Zeus Fight", false);
        bAddedLR_Zeus = true;
    }
    
    static bool bAddedLR_Fists = false;
    if (!bAddedLR_Fists)
    {
        g_iLRFists = AddLastRequestToList(LR_Start, LR_Stop, "Fist Fight", false);
        bAddedLR_Fists = true;
    }
    
    static bool bAddedLR_Axe = false;
    if (!bAddedLR_Axe)
    {
        g_iLRAxe = AddLastRequestToList(LR_Start, LR_Stop, "Axe Fight", false);
        bAddedLR_Axe = true;
    }
    
    static bool bAddedLR_Hammer = false;
    if (!bAddedLR_Hammer)
    {
        g_iLRHammer = AddLastRequestToList(LR_Start, LR_Stop, "Hammer Fight", false);
        bAddedLR_Hammer = true;
    }
    
    static bool bAddedLR_Spanner = false;
    if (!bAddedLR_Spanner)
    {
        g_iLRSpanner = AddLastRequestToList(LR_Start, LR_Stop, "Spanner Fight", false);
        bAddedLR_Spanner = true;
    }
}

public void OnPluginEnd()
{
    RemoveLastRequestFromList(LR_Start, LR_Stop, "Zeus Fight");
    RemoveLastRequestFromList(LR_Start, LR_Stop, "Fist Fight");
    RemoveLastRequestFromList(LR_Start, LR_Stop, "Axe Fight");
    RemoveLastRequestFromList(LR_Start, LR_Stop, "Hammer Fight");
    RemoveLastRequestFromList(LR_Start, LR_Stop, "Spanner Fight");
}

public void OnClientPutInServer(int client)
{
    SDKHook(client, SDKHook_OnTakeDamageAlive, OnTakeDamageAlive);
}

public Action Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
    ResetSettings();
}

public Action Event_ItemRemove(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(event.GetInt("userid"));
    
    if (IsClientValid(client))
    {
        int defIndex = event.GetInt("defindex");
        
        bool bRemove = false;
        
        if (g_bRunning && g_iCurrentLR == g_iLRAxe && defIndex == view_as<int>(CSWeapon_AXE))
        {
            DataPack pack = new DataPack();
            pack.WriteCell(event.GetInt("userid"));
            pack.WriteString("axe");
            CreateTimer(1.4, Timer_GiveItem, pack);
            bRemove = true;
        }
        
        if (g_bRunning && g_iCurrentLR == g_iLRHammer && defIndex == view_as<int>(CSWeapon_HAMMER))
        {
            DataPack pack = new DataPack();
            pack.WriteCell(event.GetInt("userid"));
            pack.WriteString("hammer");
            CreateTimer(1.4, Timer_GiveItem, pack);
            bRemove = true;
        }
        
        if (g_bRunning && g_iCurrentLR == g_iLRSpanner && defIndex == view_as<int>(CSWeapon_SPANNER))
        {
            DataPack pack = new DataPack();
            pack.WriteCell(event.GetInt("userid"));
            pack.WriteString("spanner");
            CreateTimer(1.4, Timer_GiveItem, pack);
            bRemove = true;
        }
        
        if (bRemove)
        {
            int weapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
            int iDef = GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex");
            
            if (IsValidEntity(weapon) && defIndex == iDef)
            {
               CreateTimer(4.0, Timer_RemoveWeapon, EntIndexToEntRef(weapon));
            }
        }
    }
}

public Action Event_WeaponFire(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(event.GetInt("userid"));
    
    if (IsClientValid(client))
    {
        char sWeapon[32];
        event.GetString("weapon", sWeapon, sizeof(sWeapon));
        
        if (g_bRunning && g_iCurrentLR == g_iLRZeus && StrContains(sWeapon, "taser", false) != -1)
        {
            DataPack pack = new DataPack();
            pack.WriteCell(event.GetInt("userid"));
            pack.WriteString("taser");
            CreateTimer(0.6, Timer_GiveItem, pack);
            
            int weapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
            if (IsValidEntity(weapon))
            {
               CreateTimer(1.0, Timer_RemoveWeapon, EntIndexToEntRef(weapon));
            }
        }
    }
}

public Action OnTakeDamageAlive(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3])
{
    if (!g_bRunning)
    {
        return Plugin_Continue;
    }
    
    if (g_iCurrentLR != g_iLRZeus && g_iCurrentLR != g_iLRFists && g_iCurrentLR != g_iLRAxe && g_iCurrentLR != g_iLRHammer && g_iCurrentLR != g_iLRSpanner)
    {
        return Plugin_Continue;
    }
    
    if (!IsClientValid(victim) || !IsClientValid(attacker))
    {
        return Plugin_Continue;
    }
    
    char sWeapon[32];
    GetClientWeapon(attacker, sWeapon, sizeof(sWeapon));
    
    if (g_iCurrentLR == g_iLRZeus && StrContains(sWeapon, "taser", false) != -1)
    {
        return Plugin_Continue;
    }
    
    if (g_iCurrentLR == g_iLRFists && StrContains(sWeapon, "fists", false) != -1)
    {
        return Plugin_Continue;
    }
    
    if (g_bThrowDamage)
    {
        if (damagetype & DMG_THROW)
        {
            return Plugin_Continue;
        }
        else
        {
            return Plugin_Handled;
        }
    }
    else
    {
        if (g_iCurrentLR == g_iLRAxe && StrContains(sWeapon, "axe", false) != -1)
        {
            return Plugin_Continue;
        }
        
        if (g_iCurrentLR == g_iLRHammer && StrContains(sWeapon, "hammer", false) != -1)
        {
            return Plugin_Continue;
        }
        
        if (g_iCurrentLR == g_iLRSpanner && StrContains(sWeapon, "spanner", false) != -1)
        {
            return Plugin_Continue;
        }
    }
    
    return Plugin_Handled;
}

public int LR_Start(Handle LR_Array, int iIndexInArray)
{
    g_iCurrentLR = GetArrayCell(LR_Array, iIndexInArray, view_as<int>(Block_LRType));
    
    if(g_iCurrentLR == g_iLRZeus)
    {
        PrepareLR(LR_Array, iIndexInArray);
    }
    else if(g_iCurrentLR == g_iLRFists)
    {
        PrepareLR(LR_Array, iIndexInArray);
    }
    else if(g_iCurrentLR == g_iLRAxe)
    {
        PrepareLR(LR_Array, iIndexInArray);
    }
    else if(g_iCurrentLR == g_iLRHammer)
    {
        PrepareLR(LR_Array, iIndexInArray);
    }
    else if(g_iCurrentLR == g_iLRSpanner)
    {
        PrepareLR(LR_Array, iIndexInArray);
    }
}

public int LR_Stop(int Type, int Prisoner, int Guard)
{
    ResetSettings();
}

void PrepareLR(Handle hArray, int inArray)
{
    g_iLRPrisoner = GetArrayCell(hArray, inArray, view_as<int>(Block_Prisoner));
    g_iLRGuard = GetArrayCell(hArray, inArray, view_as<int>(Block_Guard));
    
    bool bAsk = false;
    
    char sGame[16];
    if(g_iCurrentLR == g_iLRZeus)
    {
        Format(sGame, sizeof(sGame), "Zeus");
    }
    else if(g_iCurrentLR == g_iLRFists)
    {
        Format(sGame, sizeof(sGame), "Fist");
    }
    else if(g_iCurrentLR == g_iLRAxe)
    {
        Format(sGame, sizeof(sGame), "Axe");
        bAsk = true;
    }
    else if(g_iCurrentLR == g_iLRHammer)
    {
        Format(sGame, sizeof(sGame), "Hammer");
        bAsk = true;
    }
    else if(g_iCurrentLR == g_iLRSpanner)
    {
        Format(sGame, sizeof(sGame), "Spanner");
        bAsk = true;
    }
    
    if (IsClientValid(g_iLRPrisoner))
    {
        if (bAsk)
        {        
            AskGamemode(g_iLRPrisoner, sGame);
        }
        else
        {
            StartLR(sGame);
        }
    }
}

void AskGamemode(int client, const char[] game)
{
    if (IsClientValid(client) && client == g_iLRPrisoner)
    {
        Menu menu = new Menu(Menu_AskGamemode);
        
        menu.SetTitle("Which gamemode?");
        menu.AddItem("throw", "Throw Damage");
        menu.AddItem("melee", "Melee Damage");
        menu.AddItem("game", game, ITEMDRAW_IGNORE);
        
        menu.Display(client, 10);
    }
    else
    {
        ResetSettings();
    }
}

public int Menu_AskGamemode(Menu menu, MenuAction action, int client, int param)
{
    if (action == MenuAction_Select)
    {
        if (!IsClientValid(client))
        {
            ResetSettings();
            return;
        }
        
        char sOption[8];
        menu.GetItem(param, sOption, sizeof(sOption));
        
        char sMode[8];
        Format(sMode, sizeof(sMode), "Melee");
        
        char sGame[16];
        char sInfoBuffer[8], sGameBuffer[16];
        for (int i = 0; i < menu.ItemCount; i++)
        {
            menu.GetItem(i, sInfoBuffer, sizeof(sInfoBuffer), _, sGameBuffer, sizeof(sGameBuffer));
            
            if (StrEqual(sInfoBuffer, "game", false))
            {
                strcopy(sGame, sizeof(sGame), sGameBuffer);
                break;
            }
        }
        
        if (strlen(sGame) < 3)
        {
            CPrintToChatAll("{darkred}[Last Request] {default}Something went wrong with info/game buffer...");
            ResetSettings();
            return;
        }
        
        if (StrEqual(sOption, "throw", false))
        {
            Format(sMode, sizeof(sMode), "Throw");
            g_bThrowDamage = true;
        }
        
        StartLR(sGame, true, sMode);
    }
    else if (action == MenuAction_Cancel)
    {
        if (param == MenuCancel_Timeout)
        {
            ResetSettings();
            
            if (IsClientValid(g_iLRPrisoner))
            {
                CPrintToChatAll("{darkred}[Last Request] {green}%N {default}took too long.", g_iLRPrisoner);
            }
        }
    }
    else if (action == MenuAction_End)
    {
        delete menu;
    }
}

void StartLR(const char[] game, bool mode = false, const char[] sMode = "")
{
    if (!g_bMessage)
    {
        if (mode)
        {
            CPrintToChatAll("{darkred}[Last Request] {green}%N {default}requested {green}%s Fight {default}(Gamemode: {green}%s Damage{default}) against {green}%N{default}.", g_iLRPrisoner, game, sMode, g_iLRGuard);
            CreateTimer(0.1, Timer_SetBlock, _, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
        }
        else
        {
            CPrintToChatAll("{darkred}[Last Request] {green}%N {default}requested {green}%s Fight {default}against {green}%N{default}.", g_iLRPrisoner, game, g_iLRGuard);
        }
    }
    
    g_bMessage = true;
    g_bRunning = true;
    
    RemoveAllWeapons(g_iLRPrisoner);
    RemoveAllWeapons(g_iLRGuard);
    
    if(g_iCurrentLR == g_iLRZeus)
    {
        int weapon = GivePlayerItem(g_iLRPrisoner, "weapon_taser");
        EquipPlayerWeapon(g_iLRPrisoner, weapon);

        weapon = GivePlayerItem(g_iLRGuard, "weapon_taser");
        EquipPlayerWeapon(g_iLRGuard, weapon);
    }
    else if(g_iCurrentLR == g_iLRFists)
    {
        int weapon = GivePlayerItem(g_iLRPrisoner, "weapon_fists");
        EquipPlayerWeapon(g_iLRPrisoner, weapon);

        weapon = GivePlayerItem(g_iLRGuard, "weapon_fists");
        EquipPlayerWeapon(g_iLRGuard, weapon);
    }
    else if(g_iCurrentLR == g_iLRAxe)
    {
        int weapon = GivePlayerItem(g_iLRPrisoner, "weapon_axe");
        EquipPlayerWeapon(g_iLRPrisoner, weapon);

        weapon = GivePlayerItem(g_iLRGuard, "weapon_axe");
        EquipPlayerWeapon(g_iLRGuard, weapon);
    }
    else if(g_iCurrentLR == g_iLRHammer)
    {
        int weapon = GivePlayerItem(g_iLRPrisoner, "weapon_hammer");
        EquipPlayerWeapon(g_iLRPrisoner, weapon);

        weapon = GivePlayerItem(g_iLRGuard, "weapon_hammer");
        EquipPlayerWeapon(g_iLRGuard, weapon);
    }
    else if(g_iCurrentLR == g_iLRSpanner)
    {
        int weapon = GivePlayerItem(g_iLRPrisoner, "weapon_spanner");
        EquipPlayerWeapon(g_iLRPrisoner, weapon);

        weapon = GivePlayerItem(g_iLRGuard, "weapon_spanner");
        EquipPlayerWeapon(g_iLRGuard, weapon);
    }
    
    InitializeLR(g_iLRPrisoner);
}

public Action Timer_SetBlock(Handle timer)
{
    if (g_bRunning && (g_iCurrentLR == g_iLRAxe || g_iCurrentLR == g_iLRHammer || g_iCurrentLR == g_iLRSpanner))
    {
        LoopClients(client)
        {
            if (client != g_iLRGuard && client != g_iLRPrisoner)
            {
                continue;
            }
            
            int weapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
            
            if (!IsValidEntity(weapon))
            {
                return Plugin_Continue;
            }
            
            int iDef = GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex");
            
            if (iDef == view_as<int>(CSWeapon_AXE) || iDef == view_as<int>(CSWeapon_HAMMER) || iDef == view_as<int>(CSWeapon_SPANNER))
            {
                if (g_bThrowDamage)
                {
                   SetEntDataFloat(weapon, g_iPrimaryAttack, GetGameTime() + 1.0);
                }
                else
                {
                   SetEntDataFloat(weapon, g_iSecondaryAttack, GetGameTime() + 1.0);
                }
            }
        }
    }
    
    return Plugin_Stop;
}

void ResetSettings()
{
    g_bRunning = false;
    
    g_iLRPrisoner = -1;
    g_iLRGuard = -1;
    
    g_iCurrentLR = -1;
    
    g_bMessage = false;
    g_bThrowDamage = false;
}

bool IsClientValid(int client)
{
    if (client > 0 && client <= MaxClients)
    {
        if (!IsClientInGame(client))
        {
            return false;
        }

        if (IsClientSourceTV(client))
        {
            return false;
        }

        return true;
    }
    return false;
}

public Action Timer_GiveItem(Handle timer, DataPack pack)
{
    pack.Reset();
    
    int client = GetClientOfUserId(pack.ReadCell());
    
    char sWeapon[32];
    pack.ReadString(sWeapon, sizeof(sWeapon));
    
    delete pack;
    
    if (IsClientValid(client) && IsPlayerAlive(client))
    {
        Format(sWeapon, sizeof(sWeapon), "weapon_%s", sWeapon);
        int iWeapon = GivePlayerItem(client, sWeapon);
        
        EquipPlayerWeapon(client, iWeapon);
    }
    
    return Plugin_Stop;
}

public Action Timer_RemoveWeapon(Handle timer, int refIndex)
{
    int weapon = EntRefToEntIndex(refIndex);
    
    if (IsValidEntity(weapon))
    {
        RemoveEntity(weapon);
    }
    
    return Plugin_Stop;
}

void RemoveAllWeapons(int client)
{
    int iEnt = -1;
    for (int i = CS_SLOT_PRIMARY; i <= CS_SLOT_C4; i++)
    {
        while ((iEnt = GetPlayerWeaponSlot(client, i)) != -1)
        {
            SafeRemoveWeapon(client, iEnt, i);
        }
    }
}

bool SafeRemoveWeapon(int client, int weapon, int slot)
{
    if (HasEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex"))
    {
        int iDefIndex = GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex");
        
        if (iDefIndex < 0 || iDefIndex > 700)
        {
            return false;
        }
    }
    
    if (HasEntProp(weapon, Prop_Send, "m_bInitialized"))
    {
        if (GetEntProp(weapon, Prop_Send, "m_bInitialized") == 0)
        {
            return false;
        }
    }
    
    if (HasEntProp(weapon, Prop_Send, "m_bStartedArming"))
    {
        if (GetEntSendPropOffs(weapon, "m_bStartedArming") > -1)
        {
            return false;
        }
    }
    
    if (GetPlayerWeaponSlot(client, slot) != weapon)
    {
        return false;
    }
    
    if (!RemovePlayerItem(client, weapon))
    {
        return false;
    }
    
    int iWorldModel = GetEntPropEnt(weapon, Prop_Send, "m_hWeaponWorldModel");
    
    if (IsValidEdict(iWorldModel) && IsValidEntity(iWorldModel))
    {
        if (!AcceptEntityInput(iWorldModel, "Kill"))
        {
            return false;
        }
    }
    
    if (weapon == GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon"))
    {
        SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", -1);
    }
    
    AcceptEntityInput(weapon, "Kill");
    
    return true;
}
