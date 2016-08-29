#include <sourcemod>
#include <motdchanger>
#pragma semicolon 1
#pragma newdecls required

static Handle g_hOnGetClientVGUIUrl = null;
static char g_sTitle[1024];
static char g_sType[16];
static char g_sMessage[2048];

public Plugin myinfo =
{
	name = "MOTD Changer",
	author = "Neuro Toxin",
	description = "Provides a forward for plugins to change MOTD URL's",
	version = "0.0.4",
	url = "https://github.com/ntoxin66/CSGO-MotdChanger"
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	RegPluginLibrary("motdchanger");
	CreateNative("MotdChanger_SendClientMotd", Native_MotdChanger_SendClientMotd);
	CreateNative("MotdChanger_SetType", Native_MotdChanger_SetType);
	CreateNative("MotdChanger_SetTitle", Native_MotdChanger_SetTitle);
	CreateNative("MotdChanger_SetMessage", Native_MotdChanger_SetMessage);
	return APLRes_Success;
}

public void OnPluginStart()
{
	UserMsg umVGUIMenu = GetUserMessageId("VGUIMenu");
	if (umVGUIMenu == INVALID_MESSAGE_ID)
		SetFailState("UserMsg `umVGUIMenu` not found!");
	
	HookUserMessage(umVGUIMenu, OnVGUIMenu, true);
	g_hOnGetClientVGUIUrl = CreateGlobalForward("OnGetClientVGUIUrl", ET_Single, Param_Cell, Param_String, Param_String, Param_String);
}

public Action OnVGUIMenu(UserMsg msg_id, Protobuf msg, const int[] players, int playersNum, bool reliable, bool init)
{
	char name[7];
	msg.ReadString("name", name, sizeof(name));
	
	int client = players[0];
	PrintToConsole(client, "> OnVGUIMenu(name='%s', show=%d)", name, msg.ReadBool("show"));
	
	if (!StrEqual(name, "info"))
		return Plugin_Continue;
	
	Protobuf subkey[3]; int subkeylookup[3];
	for (int i = 0; i < 3; i++)
	{
		subkey[i] = msg.ReadRepeatedMessage("subkeys", i);
		subkey[i].ReadString("name", name, sizeof(name));
		//PrintToConsole(client, "> OnVGUIMenu.subkeys[%d].name='%s'", i, name);
		
		if (StrEqual(name, "title"))
		{
			subkeylookup[0] = i;
			subkey[i].ReadString("str", g_sTitle, sizeof(g_sTitle));
			//PrintToConsole(client, "> OnVGUIMenu.subkeys[%d].str='%s'", i, g_sTitle);
		}
		else if (StrEqual(name, "type"))
		{
			subkeylookup[1] = i;
			subkey[i].ReadString("str", g_sType, sizeof(g_sType));
			//PrintToConsole(client, "> OnVGUIMenu.subkeys[%d].str='%s'", i, g_sType);
		}
		else if (StrEqual(name, "msg"))
		{
			subkeylookup[2] = i;
			subkey[i].ReadString("str", g_sMessage, sizeof(g_sMessage));
			//PrintToConsole(client, "> OnVGUIMenu.subkeys[%d].str='%s'", i, g_sMessage);
		}
	}
	
	if (StrEqual(g_sType, "1") && StrEqual(g_sMessage, "motd"))
	{
		Action result;
		Call_StartForward(g_hOnGetClientVGUIUrl);
		Call_PushCell(client);
		Call_PushString(g_sTitle);
		Call_PushString(g_sType);
		Call_PushString(g_sMessage);
		Call_Finish(result);
		
		if (result == Plugin_Stop)
		{
			PrintToConsole(client, "> MOTD BLOCKED");
			msg.SetBool("show", false);
			delete subkey[0];
			delete subkey[1];
			delete subkey[2];
			return Plugin_Continue;
		}
		
		if (result == Plugin_Changed)
		{
			subkey[subkeylookup[0]].SetString("str", g_sTitle);
			subkey[subkeylookup[1]].SetString("str", g_sType);
			subkey[subkeylookup[2]].SetString("str", g_sMessage);
			
			//PrintToConsole(client, "> OnVGUIMenu.title='%s'", g_sTitle);
			PrintToConsole(client, "> OnVGUIMenu.type='%s'", g_sType);
			PrintToConsole(client, "> OnVGUIMenu.msg='%s'", g_sMessage);
		}
	}
	
	delete subkey[0];
	delete subkey[1];
	delete subkey[2];
	return Plugin_Continue;
}

public int Native_MotdChanger_SetTitle(Handle plugin, int params)
{
	GetNativeString(1, g_sTitle, sizeof(g_sTitle));
	return 1;
}

public int Native_MotdChanger_SetType(Handle plugin, int params)
{
	GetNativeString(1, g_sType, sizeof(g_sType));
	return 1;
}

public int Native_MotdChanger_SetMessage(Handle plugin, int params)
{
	GetNativeString(1, g_sMessage, sizeof(g_sMessage));
	return 1;
}

public int Native_MotdChanger_SendClientMotd(Handle plugin, int params)
{
	int client = GetNativeCell(1);
	GetNativeString(2, g_sTitle, sizeof(g_sTitle));
	GetNativeString(3, g_sType, sizeof(g_sType));
	GetNativeString(4, g_sMessage, sizeof(g_sMessage));
	
	Protobuf vguimenu = view_as<Protobuf>(StartMessageOne("VGUIMenu", client));
	
	vguimenu.SetString("name", "info");
	vguimenu.SetBool("show", true);
	
	Protobuf subkey;
	
	subkey = vguimenu.AddMessage("subkeys");
	subkey.SetString("name", "title");
	subkey.SetString("str", g_sTitle);
	
	subkey = vguimenu.AddMessage("subkeys");
	subkey.SetString("name", "type");
	subkey.SetString("str", g_sType);
	
	subkey = vguimenu.AddMessage("subkeys");
	subkey.SetString("name", "msg");
	subkey.SetString("str", g_sMessage);
	
	EndMessage();
	delete vguimenu;
}