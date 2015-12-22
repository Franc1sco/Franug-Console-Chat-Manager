#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <multicolors>
#include <cstrike>
#include <geoip>

#define VERSION "1.0"

new Handle:kv;
new bool:nofile;

public Plugin:myinfo = 
{
	name = "SM Console Chat Manager",
	author = "Franc1sco Steam: franug",
	description = "",
	version = VERSION,
	url = "http://steamcommunity.com/id/franug"
};

public OnPluginStart()
{
	CreateConVar("sm_consolechatmanager_version", VERSION, "", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	
	RegConsoleCmd("say", SayConsole);
}

public OnMapStart()
{
	ReadT();
	PrecacheSound("common/talk.wav", false);
}

public ReadT()
{
	new String:Path[512];
	new String:map[64];
	GetCurrentMap(map, sizeof(map));
	BuildPath(Path_SM, Path, sizeof(Path), "configs/franug_consolechatmanager/%s.txt", map);
	if(!FileExists(Path))
	{	
		nofile = true;
		LogMessage("Config file not found: %s", Path);
		return;
	}
	nofile = false;
	
	
	kv = CreateKeyValues("Console_C");
	FileToKeyValues(kv, Path);
	if (!KvGotoFirstSubKey(kv))
	{
		LogMessage("Config file is corrupted: %s", Path);
		nofile = true;
		return;
	}
	nofile = false;
}

public Action:SayConsole(client, args)
{
	if (client==0 && !nofile)
	{
		decl String:buffer[255];
		GetCmdArgString(buffer,sizeof(buffer));
		StripQuotes(buffer);
		KvRewind(kv);
		if(!KvJumpToKey(kv, buffer)) return Plugin_Continue;
		for(new i = 1 ; i < MaxClients; i++)
		{
			if(IsClientInGame(i))
			{
				new String: sText[256];
				new String: sCountryTag[3];
				new String: sIP[26];
				GetClientIP(i, sIP, sizeof(sIP));
				GeoipCode2(sIP, sCountryTag);
				KvGetString(kv, sCountryTag, sText, sizeof(sText), "LANGMISSING");

				if (StrEqual(sText, "LANGMISSING"))
				{
					KvGetString(kv, "default", sText, sizeof(sText));
				}
				
				CPrintToChat(i, sText);
			}
		}
		EmitSoundToAll("common/talk.wav");
		return Plugin_Stop;
	}  
	return Plugin_Continue;
}