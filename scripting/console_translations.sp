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
	name = "SM Console Chat Control",
	author = "Franc1sco Steam: franug",
	description = "",
	version = VERSION,
	url = "http://steamcommunity.com/id/franug"
};

public OnPluginStart()
{
	CreateConVar("sm_consolechatcontrol_version", VERSION, "", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	
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
	BuildPath(Path_SM, Path, sizeof(Path), "configs/console_control/%s.txt", map);
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
		//PrintToChatAll("test1");
		KvRewind(kv);
		if(!KvJumpToKey(kv, buffer)) return Plugin_Continue;
		//PrintToChatAll("test2");
		for(new i = 1 ; i < MaxClients; i++)
		{
			if(IsValidPlayer(i))
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

stock bool:IsValidPlayer(client, bool:alive = false){
    if(client >= 1 && client <= MaxClients && IsClientConnected(client) && IsClientInGame(client) && (alive == false || IsPlayerAlive(client))){
        return true;
    }

    return false;
}