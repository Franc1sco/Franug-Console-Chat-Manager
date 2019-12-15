/*  SM Console Chat Manager
 *
 *  Copyright (C) 2017 Francisco 'Franc1sco' García
 * 
 * This program is free software: you can redistribute it and/or modify it
 * under the terms of the GNU General Public License as published by the Free
 * Software Foundation, either version 3 of the License, or (at your option) 
 * any later version.
 *
 * This program is distributed in the hope that it will be useful, but WITHOUT 
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS 
 * FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License along with 
 * this program. If not, see http://www.gnu.org/licenses/.
 */

#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <multicolors>
#include <geoip>
#include <emitsoundany>

#pragma newdecls required // let's go new syntax! 

#define VERSION "1.2.1"

Handle kv;
char Path[PLATFORM_MAX_PATH];

bool csgo;

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
	CreateConVar("sm_consolechatmanager_version", VERSION, "", FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	
	RegConsoleCmd("say", SayConsole);
	
}

public APLRes AskPluginLoad2(Handle myself, bool late, char [] error, int err_max)
{
	if(GetEngineVersion() == Engine_CSGO)
	{
		csgo = true;
	} else csgo = false;
	
	return APLRes_Success;
}

public void OnMapStart()
{
	ReadT();
}

public void ReadT()
{
	delete kv;
	
	char map[64];
	GetCurrentMap(map, sizeof(map));
	BuildPath(Path_SM, Path, sizeof(Path), "configs/franug_consolechatmanager/%s.txt", map);
	
	kv = CreateKeyValues("Console_C");
	
	if(!FileExists(Path)) KeyValuesToFile(kv, Path);
	else FileToKeyValues(kv, Path);
	
	CheckSounds();
}

void CheckSounds()
{
	PrecacheSound("common/talk.wav", false);
	
	char buffer[255];
	if(KvGotoFirstSubKey(kv))
	{
		do
		{
			KvGetString(kv, "sound", buffer, 64, "default");
			if(!StrEqual(buffer, "default"))
			{
				if(!csgo) PrecacheSound(buffer);
				else PrecacheSoundAny(buffer);
				
				Format(buffer, 255, "sound/%s", buffer);
				AddFileToDownloadsTable(buffer);
			}
			
		} while (KvGotoNextKey(kv));
	}
	
	KvRewind(kv);
}

public Action SayConsole(int client, int args)
{
	if (client==0)
	{
		char buffer[255], buffer2[255],soundp[255], soundt[255];
		GetCmdArgString(buffer,sizeof(buffer));
		StripQuotes(buffer);
		if(kv == INVALID_HANDLE)
		{
			ReadT();
		}
		
		if(!KvJumpToKey(kv, buffer))
		{
			KvJumpToKey(kv, buffer, true);
			Format(buffer2, sizeof(buffer2), "{darkred}Console: %s", buffer);
			KvSetString(kv, "default", buffer2);
			KvRewind(kv);
			KeyValuesToFile(kv, Path);
			KvJumpToKey(kv, buffer);
		}
		
		char sText[256];
		char sCountryTag[3];
		char sIP[26];
		
		bool blocked = (KvGetNum(kv, "blocked", 0)?true:false);
		
		if(blocked)
		{
			KvRewind(kv);
			return Plugin_Stop;
		}
		
		KvGetString(kv, "sound", soundp, sizeof(soundp), "default");
		if(StrEqual(soundp, "default"))
			Format(soundt, 255, "common/talk.wav");
		else
			Format(soundt, 255, soundp);
		
		for(int i = 1 ; i < MaxClients; i++)
			if(IsClientInGame(i))
			{
				GetClientIP(i, sIP, sizeof(sIP));
				GeoipCode2(sIP, sCountryTag);
				KvGetString(kv, sCountryTag, sText, sizeof(sText), "LANGMISSING");

				if (StrEqual(sText, "LANGMISSING")) KvGetString(kv, "default", sText, sizeof(sText));
				
				CPrintToChat(i, sText);
			}
			
		if(!StrEqual(soundp, "none"))
		{
			if(!csgo || StrEqual(soundp, "default")) EmitSoundToAll(soundt);
			else EmitSoundToAllAny(soundt);
		}
		
		if(KvJumpToKey(kv, "hinttext"))
		{
			for(int i = 1 ; i < MaxClients; i++)
				if(IsClientInGame(i))
				{
					GetClientIP(i, sIP, sizeof(sIP));
					GeoipCode2(sIP, sCountryTag);
					KvGetString(kv, sCountryTag, sText, sizeof(sText), "LANGMISSING");

					if (StrEqual(sText, "LANGMISSING")) KvGetString(kv, "default", sText, sizeof(sText));
				
					PrintHintText(i, sText);
				}
		}

		KvRewind(kv);
		return Plugin_Stop;
	}  
	return Plugin_Continue;
}