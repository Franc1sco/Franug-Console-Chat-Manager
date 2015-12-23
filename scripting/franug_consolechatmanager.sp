#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <multicolors>
#include <geoip>

#pragma newdecls required // let's go new syntax! 

#define VERSION "1.1"

Handle kv;
char Path[PLATFORM_MAX_PATH];

public Plugin myinfo = 
{
	name = "SM Console Chat Manager",
	author = "Franc1sco Steam: franug",
	description = "",
	version = VERSION,
	url = "http://steamcommunity.com/id/franug"
};

public void OnPluginStart()
{
	CreateConVar("sm_consolechatmanager_version", VERSION, "", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	
	RegConsoleCmd("say", SayConsole);
	
}

public void OnMapStart()
{
	ReadT();
	PrecacheSound("common/talk.wav", false);
}

public void ReadT()
{
	char map[64];
	GetCurrentMap(map, sizeof(map));
	BuildPath(Path_SM, Path, sizeof(Path), "configs/franug_consolechatmanager/%s.txt", map);
	
	kv = CreateKeyValues("Console_C");
	
	if(!FileExists(Path)) KeyValuesToFile(kv, Path);
	else FileToKeyValues(kv, Path);
}

public Action SayConsole(int client, int args)
{
	if (client==0)
	{
		char buffer[255];
		GetCmdArgString(buffer,sizeof(buffer));
		StripQuotes(buffer);
		
		if(!KvJumpToKey(kv, buffer))
		{
			KvJumpToKey(kv, buffer, true);
			Format(buffer, sizeof(buffer), "{darkred}Console: %s", buffer);
			KvSetString(kv, "default", buffer);
			KvRewind(kv);
			KeyValuesToFile(kv, Path);
			return Plugin_Continue;
		}
		
		char sText[256];
		char sCountryTag[3];
		char sIP[26];
		
		for(int i = 1 ; i < MaxClients; i++)
			if(IsClientInGame(i))
			{
				GetClientIP(i, sIP, sizeof(sIP));
				GeoipCode2(sIP, sCountryTag);
				KvGetString(kv, sCountryTag, sText, sizeof(sText), "LANGMISSING");

				if (StrEqual(sText, "LANGMISSING")) KvGetString(kv, "default", sText, sizeof(sText));
				
				CPrintToChat(i, sText);
			}

		KvRewind(kv);
		EmitSoundToAll("common/talk.wav");
		return Plugin_Stop;
	}  
	return Plugin_Continue;
}