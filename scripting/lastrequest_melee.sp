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

int g_iClip1 = -1;

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
    
    g_iClip1 = FindSendPropInfo("CBaseCombatWeapon", "m_iClip1");
    if (g_iClip1 == -1)
    {
        SetFailState("Unable to find offset for clip.");
    }
    
    LoopClients(client)
    {
    	OnClientPutInServer(client);
    }
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
            CreateTimer(1.7, Timer_GiveItem, pack);
            bRemove = true;
        }
        
        if (g_bRunning && g_iCurrentLR == g_iLRHammer && defIndex == view_as<int>(CSWeapon_HAMMER))
        {
            DataPack pack = new DataPack();
            pack.WriteCell(event.GetInt("userid"));
            pack.WriteString("hammer");
            CreateTimer(1.7, Timer_GiveItem, pack);
            bRemove = true;
        }
        
        if (g_bRunning && g_iCurrentLR == g_iLRSpanner && defIndex == view_as<int>(CSWeapon_SPANNER))
        {
            DataPack pack = new DataPack();
            pack.WriteCell(event.GetInt("userid"));
            pack.WriteString("spanner");
            CreateTimer(1.7, Timer_GiveItem, pack);
            bRemove = true;
        }
        
        if (bRemove)
        {
        	int weapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
        	int iDef = GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex");
        	
        	if (IsValidEntity(weapon) && defIndex == iDef)
        	   CreateTimer(4.0, Timer_RemoveWeapon, EntIndexToEntRef(weapon));
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
               CreateTimer(1.0, Timer_RemoveWeapon, EntIndexToEntRef(weapon));
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
    
    return Plugin_Handled;
}

public int LR_Start(Handle LR_Array, int iIndexInArray)
{
    g_iCurrentLR = GetArrayCell(LR_Array, iIndexInArray, view_as<int>(Block_LRType));
    
    if(g_iCurrentLR == g_iLRZeus)
        StartLR(LR_Array, iIndexInArray);
    else if(g_iCurrentLR == g_iLRFists)
        StartLR(LR_Array, iIndexInArray);
    else if(g_iCurrentLR == g_iLRAxe)
        StartLR(LR_Array, iIndexInArray);
    else if(g_iCurrentLR == g_iLRHammer)
        StartLR(LR_Array, iIndexInArray);
    else if(g_iCurrentLR == g_iLRSpanner)
        StartLR(LR_Array, iIndexInArray);
}

public int LR_Stop(int Type, int Prisoner, int Guard)
{
    ResetSettings();
}

void StartLR(Handle hArray, int inArray)
{
    g_iLRPrisoner = GetArrayCell(hArray, inArray, view_as<int>(Block_Prisoner));
    g_iLRGuard = GetArrayCell(hArray, inArray, view_as<int>(Block_Guard));
    
    RemoveAllWeapons(g_iLRPrisoner);
    RemoveAllWeapons(g_iLRGuard);
    
    int iWeaponP = -1;
    int iWeaponG = -1;
    
    char sGame[24];
    if(g_iCurrentLR == g_iLRZeus)
    {
        Format(sGame, sizeof(sGame), "Zeus");
        
        iWeaponP = GivePlayerItem(g_iLRPrisoner, "weapon_taser");
        iWeaponG = GivePlayerItem(g_iLRGuard, "weapon_taser");
        
        EquipPlayerWeapon(g_iLRPrisoner, iWeaponP);
        EquipPlayerWeapon(g_iLRGuard, iWeaponG);
    }
    else if(g_iCurrentLR == g_iLRFists)
    {
        Format(sGame, sizeof(sGame), "Fist");
        
        iWeaponP = GivePlayerItem(g_iLRPrisoner, "weapon_fists");
        iWeaponG = GivePlayerItem(g_iLRGuard, "weapon_fists");
        
        EquipPlayerWeapon(g_iLRPrisoner, iWeaponP);
        EquipPlayerWeapon(g_iLRGuard, iWeaponG);
    }
    else if(g_iCurrentLR == g_iLRAxe)
    {
        Format(sGame, sizeof(sGame), "Axe");
        
        iWeaponP = GivePlayerItem(g_iLRPrisoner, "weapon_axe");
        iWeaponG = GivePlayerItem(g_iLRGuard, "weapon_axe");
        
        EquipPlayerWeapon(g_iLRPrisoner, iWeaponP);
        EquipPlayerWeapon(g_iLRGuard, iWeaponG);
    }
    else if(g_iCurrentLR == g_iLRHammer)
    {
        Format(sGame, sizeof(sGame), "Hammer");
        
        iWeaponP = GivePlayerItem(g_iLRPrisoner, "weapon_hammer");
        iWeaponG = GivePlayerItem(g_iLRGuard, "weapon_hammer");
        
        EquipPlayerWeapon(g_iLRPrisoner, iWeaponP);
        EquipPlayerWeapon(g_iLRGuard, iWeaponG);
    }
    else if(g_iCurrentLR == g_iLRSpanner)
    {
        Format(sGame, sizeof(sGame), "Spanner");
        
        iWeaponP = GivePlayerItem(g_iLRPrisoner, "weapon_spanner");
        iWeaponG = GivePlayerItem(g_iLRGuard, "weapon_spanner");
        
        EquipPlayerWeapon(g_iLRPrisoner, iWeaponP);
        EquipPlayerWeapon(g_iLRGuard, iWeaponG);
    }
    
    if (IsClientValid(g_iLRPrisoner))
    {
    	if (!g_bMessage)
    	{
            CPrintToChatAll("[Last Request] %N requested %s Fight against %N.", g_iLRPrisoner, sGame, g_iLRGuard);
        }
        
        g_bMessage = true;
    	g_bRunning = true;
        InitializeLR(g_iLRPrisoner);
    }
}

void ResetSettings()
{
    g_bRunning = false;
    
    g_iLRPrisoner = -1;
    g_iLRGuard = -1;
    
    g_iCurrentLR = -1;
    
    g_bMessage = false;
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
