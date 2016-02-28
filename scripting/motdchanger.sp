#include <sourcemod>
#include <motdchanger>
#pragma semicolon 1
#pragma newdecls required

static Handle g_hOnGetClientVGUIUrl = null;
static bool s_bClientRequiresVGUIMenu[MAXPLAYERS+1];

public Plugin myinfo =
{
	name = "MOTD Changer",
	author = "Neuro Toxin",
	description = "Allows plugins to change the MOTD URL",
	version = "0.0.1",
	url = ""
}

public void OnPluginStart()
{
	UserMsg umVGUIMenu = GetUserMessageId("VGUIMenu");
	if (umVGUIMenu == INVALID_MESSAGE_ID)
		SetFailState("Your game server doesn't support VGUI menus.");
	HookUserMessage(umVGUIMenu, OnVGUIMenu, true);
	
	g_hOnGetClientVGUIUrl = CreateGlobalForward("OnGetClientVGUIUrl", ET_Single, Param_Cell, Param_String);
}

public bool OnClientConnect(int client, char[] rejectmsg, int maxlen)
{
	s_bClientRequiresVGUIMenu[client] = true;
	return true;
}

public Action OnVGUIMenu(UserMsg msg_id, Handle bf, const int[] players, int playersNum, bool reliable, bool init)
{
	int client = players[0];
	
	if (!IsClientInGame(client))
		return Plugin_Continue;
	
	if (IsFakeClient(client))
		return Plugin_Continue;
		
	if (!s_bClientRequiresVGUIMenu[client])
		return Plugin_Continue;
	
	s_bClientRequiresVGUIMenu[client] = false;
	CreateTimer(0.1, OnClientVGUIMenuRequired, GetClientUserId(client));
	return Plugin_Handled;
}

public Action OnClientVGUIMenuRequired(Handle timer, any userid)
{
	int client = GetClientOfUserId(userid);
	
	if(client == 0)
		return Plugin_Continue;
		
	char url[512];

	Call_StartForward(g_hOnGetClientVGUIUrl);
	Call_PushCell(client);
	Call_PushStringEx(url, sizeof(url), SM_PARAM_STRING_COPY, SM_PARAM_COPYBACK);
	Call_Finish();
		
	SendClientVGUIMenu(client, url);
	return Plugin_Continue;
}

stock void SendClientVGUIMenu(int client, const char[] url)
{
	Handle kv = CreateKeyValues("data");
	KvSetNum(kv, "cmd", 5);
	KvSetString(kv, "msg", url);
	KvSetString(kv, "title", "MOTDgd AD");
	KvSetNum(kv, "type", MOTDPANEL_TYPE_URL);
	
	ShowVGUIPanel(client, "info", kv);
	CloseHandle(kv);
}