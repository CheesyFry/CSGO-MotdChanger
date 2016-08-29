#if defined _motdchanger_included
  #endinput
#endif
#define _motdchanger_included

forward Action OnGetClientVGUIUrl(int client, const char[] title, const char[] type, const char[] msg);

native void MotdChanger_SendClientMotd(int client, const char[] title, const char[] type, const char[] msg);
native void MotdChanger_SetTitle(const char[] value);
native void MotdChanger_SetType(const char[] value);
native void MotdChanger_SetMessage(const char[] value);

methodmap MotdChanger
{
	public MotdChanger()
	{
		return view_as<int>(0);
	}
	
	public static void SetTitle(const char[] value)
	{
		MotdChanger_SetTitle(value);
	}
	
	public static void SetType(const char[] value)
	{
		MotdChanger_SetType(value);
	}
	
	public static void SetMessage(const char[] value)
	{
		MotdChanger_SetMessage(value);
	}
}

#if !defined REQUIRE_PLUGIN
public __pl_motdchanger_SetNTVOptional()
{
	MarkNativeAsOptional("SendClientMotdViaVGUI");
}
#endif

public SharedPlugin __pl_motdchanger = 
{
	name = "motdchanger",
	file = "motdchanger.smx",
	#if defined REQUIRE_PLUGIN
		required = 1,
	#else
		required = 0,
	#endif
};