Convars:RegisterConvar("STEAM_ID_HANDLER_NETWORK_ID", "", "",FCVAR_RELEASE)
Convars:RegisterConvar("STEAM_ID_HANDLER_XUID", "", "",FCVAR_RELEASE)
Convars:RegisterConvar("STEAM_ID_HANDLER_USER_ID, "", "",FCVAR_RELEASE)
Convars:RegisterConvar("STEAM_ID_HANDLER_NAME", "", "",FCVAR_RELEASE)

Convars:RegisterConvar("STEAM_ID_HANDLER_USER_ID_WHITELIST", "", "",FCVAR_RELEASE)

SteamIdHandler = {
	n = 1,
	UserId = {},
	WhiteList = {},
}
local s = Convars:GetStr("STEAM_ID_HANDLER_USER_ID")
-- stolen from https://stackoverflow.com/a/7615129
for s in string.gmatch(inputstr, "([^".."\0".."]+)") do
	SteamIdHandler.UserId[n]
	n = n + 1
end

--[[
string				name		player name
playercontroller	userid		user ID on server (unique on server)
string				networkid	player network (i.e steam) id
uint64				xuid		steam id
string				address		ip:port
bool				bot	
]]--


function SteamIdHandler.RemoveUserInfo(tInfo)
end

function SteamIdHandler.AddUserInfo(tInfo)
	if SteamIdHandler.HasUser(tInfo.userid) then
		return
	end
	-- SteamIdHandler.UserId[1] : "\0" ? ""
	local sep = SteamIdHandler.UserId[1] and "\0" or "" 
	local str = Convars:GetStr("STEAM_ID_HANDLER_NETWORK_ID")
	Convars:SetStr("STEAM_ID_HANDLER_NETWORK_ID", str .. sep .. tInfo.networkid)
	
	str = Convars:GetStr("STEAM_ID_HANDLER_XUID")
	Convars:SetStr("STEAM_ID_HANDLER_XUID", str .. sep .. tInfo.xuid)
	
	str = Convars:GetStr("STEAM_ID_HANDLER_USER_ID")
	Convars:SetStr("STEAM_ID_HANDLER_USER_ID", str .. sep .. tInfo.userid)
	
	str = Convars:GetStr("STEAM_ID_HANDLER_NAME")
	Convars:SetStr("STEAM_ID_HANDLER_NAME", str .. sep .. tInfo.name)
	
	SteamIdHandler.UserId[n] = tInfo.userid
	n = n + 1
end

function SteamIdHandler.UpdateUserName(tInfo)
end

function SteamIdHandler.AddUserToWhitelist(uid)
	
end

function SteamIdHandler.HasUser(uid)
	for _, v in ipairs(SteamIdHandler.UserId)
		if v == uid then
			return true
		end
	end
	return false
end

function SteamIdHandler.FireEvents()
	-- prepare event data tables
	local event_datas = {}
	FireGameEvent()
end

ListenToGameEvent("player_connect", SteamIdHandler.AddUserInfo)
ListenToGameEvent("player_disconnect", SteamIdHandler.RemoveUserInfo)
ListenToGameEvent("player_info", SteamIdHandler.UpdateUserName)
ListenToGameEvent("player_activate", )