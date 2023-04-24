Convars:RegisterConvar("STEAM_ID_HANDLER_NETWORK_ID", "", "", FCVAR_RELEASE)
Convars:RegisterConvar("STEAM_ID_HANDLER_XUID", "", "", FCVAR_RELEASE)
Convars:RegisterConvar("STEAM_ID_HANDLER_USER_ID", "", "", FCVAR_RELEASE)
Convars:RegisterConvar("STEAM_ID_HANDLER_NAME", "", "", FCVAR_RELEASE)

Convars:RegisterConvar("STEAM_ID_HANDLER_USER_ID_WHITELIST", "", "", FCVAR_RELEASE)

SteamIdHandler = {
	n = 1,
	n1 = 1,
	separator = "\24",
	UserId = {},
}

-- stolen from https://stackoverflow.com/a/7615129
function SteamIdHandler.split(inputstr, sep)
    sep=sep or '%s' 
    local t={}  
    for field,s in string.gmatch(inputstr, "([^"..sep.."]*)("..sep.."?)") do 
        table.insert(t,field)  
        if s=="" then 
            return t 
        end 
    end 
end
function SteamIdHandler.toString(table)
	local str = ""
	for idx, val in ipairs(table) do
		if idx == 1 then
			str = val
		end
		str = str .. SteamIdHandler.separator .. val
	end
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
	-- (#SteamIdHandler.UserId ~= 0) : "\0" ? ""
	local sep = (#SteamIdHandler.UserId ~= 0) and "\24" or ""
	local str = Convars:GetStr("STEAM_ID_HANDLER_NETWORK_ID")
	Convars:SetStr("STEAM_ID_HANDLER_NETWORK_ID", str .. sep .. tInfo.networkid)
	
	str = Convars:GetStr("STEAM_ID_HANDLER_XUID")
	Convars:SetStr("STEAM_ID_HANDLER_XUID", str .. sep .. tInfo.xuid)
	
	str = Convars:GetStr("STEAM_ID_HANDLER_USER_ID")
	Convars:SetStr("STEAM_ID_HANDLER_USER_ID", str .. sep .. tInfo.userid)
	
	str = Convars:GetStr("STEAM_ID_HANDLER_NAME")
	Convars:SetStr("STEAM_ID_HANDLER_NAME", str .. sep .. tInfo.name)
	
	SteamIdHandler.UserId[tInfo.userid] = true
end

function SteamIdHandler.UpdateUserName(tInfo)
end

function SteamIdHandler.AddUserToWhitelist(tInfo)
	local str = Convars:GetStr("STEAM_ID_HANDLER_USER_ID_WHITELIST")
	local sep = (#str ~= 0) and "\24" or ""
	Convars:SetStr("STEAM_ID_HANDLER_USER_ID_WHITELIST", str .. sep .. tInfo.userid)
end

function SteamIdHandler.HasUser(uid)
	return SteamIdHandler[uid] ~= nil
end

function SteamIdHandler.FireEvents()

	-- prepare event data tables
	local event_datas = {}
	local networkids = split(Convars:GetStr("STEAM_ID_HANDLER_NETWORK_ID"), SteamIdHandler.separator)
	local xuids = split(Convars:GetStr("STEAM_ID_HANDLER_XUID"), SteamIdHandler.separator)
	local uids = split(Convars:GetStr("STEAM_ID_HANDLER_USER_ID"), SteamIdHandler.separator)
	local names = split(Convars:GetStr("STEAM_ID_HANDLER_NAME"), SteamIdHandler.separator)
	for idx, v in ipairs(networkids) do
		event_datas[idx].networkid = networkids[idx]
		event_datas[idx].xuid = xuids[idx]
		event_datas[idx].userid = uids[idx]
		event_datas[idx].name = names[idx]
	end

	-- fire fake events
	for _, v in ipairs(event_datas) do
		FireGameEvent("player_connect", v)
	end

end

-- for SteamIdHandler.HasUser
for field,s in string.gmatch(Convars:GetStr("STEAM_ID_HANDLER_USER_ID"), "([^"..SteamIdHandler.separator.."]*)("..SteamIdHandler.separator.."?)") do
	SteamIdHandler.UserId[field] = true
	if s == "" then
		break
	end
end

-- get whitelist
local whitelist = {}
for field,s in string.gmatch(Convars:GetStr("STEAM_ID_HANDLER_USER_ID_WHITELIST"), "([^"..SteamIdHandler.separator.."]*)("..SteamIdHandler.separator.."?)") do
	whitelist[field] = true
	if s == "" then
		break
	end
end

-- remove player who didn't spawn on last map -> somehow got disconnected without triggering player_disconnect
local uids = split(Convars:GetStr("STEAM_ID_HANDLER_USER_ID"), SteamIdHandler.separator)



SteamIdHandler.RemoveUserInfo(tInfo)

-- reset whitelist
Convars:SetStr("STEAM_ID_HANDLER_USER_ID_WHITELIST", "");

ListenToGameEvent("player_connect", SteamIdHandler.AddUserInfo)
ListenToGameEvent("player_disconnect", SteamIdHandler.RemoveUserInfo)
ListenToGameEvent("player_info", SteamIdHandler.UpdateUserName)
ListenToGameEvent("player_activate", SteamIdHandler.AddUserToWhitelist)