Convars:RegisterConvar("STEAM_ID_HANDLER_NETWORK_ID", "", "", FCVAR_PROTECTED)
Convars:RegisterConvar("STEAM_ID_HANDLER_XUID", "", "", FCVAR_PROTECTED)
Convars:RegisterConvar("STEAM_ID_HANDLER_USER_ID", "", "", FCVAR_PROTECTED)
Convars:RegisterConvar("STEAM_ID_HANDLER_NAME", "", "", FCVAR_PROTECTED)

Convars:RegisterConvar("STEAM_ID_HANDLER_USER_ID_WHITELIST", "", "", FCVAR_PROTECTED)

SteamIdHandler = {
	n = 1,
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
function SteamIdHandler.tableToString(t)
	local str = ""
	for idx, val in ipairs(t) do
		if idx == 1 then
			str = val
		else
			str = str .. SteamIdHandler.separator .. val
		end
	end
	return str
end

--[[
string				name		player name
playercontroller	userid		user ID on server (unique on server)
string				networkid	player network (i.e steam) id
uint64				xuid		steam id
string				address		ip:port
bool				bot	
]]--

--tInfo{userid}
function SteamIdHandler.RemoveUserInfo(tInfo)

	-- user doesn't exist
	if not SteamIdHandler.HasUser(tInfo.userid) then
		-- print("wtf???")
		return
	end
	
	local networkids = SteamIdHandler.split(Convars:GetStr("STEAM_ID_HANDLER_NETWORK_ID"), SteamIdHandler.separator)
	local xuids = SteamIdHandler.split(Convars:GetStr("STEAM_ID_HANDLER_XUID"), SteamIdHandler.separator)
	local uids = SteamIdHandler.split(Convars:GetStr("STEAM_ID_HANDLER_USER_ID"), SteamIdHandler.separator)
	local names = SteamIdHandler.split(Convars:GetStr("STEAM_ID_HANDLER_NAME"), SteamIdHandler.separator)
	
	local idx = SteamIdHandler.UserId[tInfo.userid]
	
	networkids[idx] = networkids[SteamIdHandler.n]
	table.remove(networkids)
	
	xuids[idx] = xuids[SteamIdHandler.n]
	table.remove(xuids)
	
	uids[idx] = uids[SteamIdHandler.n]
	table.remove(uids)
	
	names[idx] = names[SteamIdHandler.n]
	table.remove(names)
	
	for k, v in pairs(SteamIdHandler.UserId) do
		-- find the key with the last index
		if v == SteamIdHandler.n then
			SteamIdHandler.UserId[k] = idx
			break
		end
	end
	
	-- erase user's existance
	SteamIdHandler.UserId[tInfo.userid] = nil
	
	-- update convars
	Convars:SetStr("STEAM_ID_HANDLER_NETWORK_ID", SteamIdHandler.tableToString(networkids))
	Convars:SetStr("STEAM_ID_HANDLER_XUID", SteamIdHandler.tableToString(xuids))
	Convars:SetStr("STEAM_ID_HANDLER_USER_ID", SteamIdHandler.tableToString(uids))
	Convars:SetStr("STEAM_ID_HANDLER_NAME", SteamIdHandler.tableToString(names))
	
	-- decrease size
	SteamIdHandler.n = SteamIdHandler.n - 1
end

--tInfo{userid, networkid, xuid, name}
function SteamIdHandler.AddUserInfo(tInfo)
	if SteamIdHandler.HasUser(tInfo.userid) then
		print("Already has info for: "..tInfo.name)
		return
	end

	-- (SteamIdHandler.n ~= 0) : "\0" ? ""
	local sep = (SteamIdHandler.n ~= 1) and SteamIdHandler.separator or ""
	local str = Convars:GetStr("STEAM_ID_HANDLER_NETWORK_ID")
	Convars:SetStr("STEAM_ID_HANDLER_NETWORK_ID", str .. sep .. tInfo.networkid)
	
	str = Convars:GetStr("STEAM_ID_HANDLER_XUID")
	Convars:SetStr("STEAM_ID_HANDLER_XUID", str .. sep .. tostring(tInfo.xuid))
	
	str = Convars:GetStr("STEAM_ID_HANDLER_USER_ID")
	Convars:SetStr("STEAM_ID_HANDLER_USER_ID", str .. sep .. tInfo.userid)
	
	str = Convars:GetStr("STEAM_ID_HANDLER_NAME")
	Convars:SetStr("STEAM_ID_HANDLER_NAME", str .. sep .. tInfo.name)
	
	SteamIdHandler.UserId[tInfo.userid] = SteamIdHandler.n
	SteamIdHandler.n = SteamIdHandler.n + 1

	print("Player Info Added")
	__DumpScope(0, tInfo)
end

--tInfo{userid, name}
function SteamIdHandler.UpdateUserName(tInfo)
	-- user doesn't exist
	if not SteamIdHandler.HasUser(tInfo.userid) then
		-- print("wtf???")
		return
	end
	
	local names = SteamIdHandler.split(Convars:GetStr("STEAM_ID_HANDLER_NAME"), SteamIdHandler.separator)
	
	local idx = SteamIdHandler.UserId[tInfo.userid]
	
	-- update name
	names[idx] = tInfo.name
	
	-- update convar
	Convars:SetStr("STEAM_ID_HANDLER_NAME", SteamIdHandler.tableToString(names))
end

--tInfo{userid}
function SteamIdHandler.AddUserToWhitelist(tInfo)
	local str = Convars:GetStr("STEAM_ID_HANDLER_USER_ID_WHITELIST")
	local sep = (#str ~= 0) and SteamIdHandler.separator or ""
	Convars:SetStr("STEAM_ID_HANDLER_USER_ID_WHITELIST", str .. sep .. tInfo.userid)
end

function SteamIdHandler.HasUser(uid)
	return SteamIdHandler.UserId[uid] ~= nil
end

function SteamIdHandler.FireEvents()
	-- prepare event data tables
	local event_datas = {}
	local networkids = SteamIdHandler.split(Convars:GetStr("STEAM_ID_HANDLER_NETWORK_ID"), SteamIdHandler.separator)
	local xuids = SteamIdHandler.split(Convars:GetStr("STEAM_ID_HANDLER_XUID"), SteamIdHandler.separator)
	local uids = SteamIdHandler.split(Convars:GetStr("STEAM_ID_HANDLER_USER_ID"), SteamIdHandler.separator)
	local names = SteamIdHandler.split(Convars:GetStr("STEAM_ID_HANDLER_NAME"), SteamIdHandler.separator)
	for idx, v in ipairs(networkids) do
		table.insert(event_datas, {
			networkid = networkids[idx],
			xuid = xuids[idx],
			userid = uids[idx],
			name = names[idx]
		})
	end

	-- fire fake events
	for _, v in ipairs(event_datas) do
		FireGameEvent("player_connect", v)
	end

end

function SteamIdHandler.DumpInfo()
	-- prepare event data tables
	local event_datas = {}
	local networkids = SteamIdHandler.split(Convars:GetStr("STEAM_ID_HANDLER_NETWORK_ID"), SteamIdHandler.separator)
	local xuids = SteamIdHandler.split(Convars:GetStr("STEAM_ID_HANDLER_XUID"), SteamIdHandler.separator)
	local uids = SteamIdHandler.split(Convars:GetStr("STEAM_ID_HANDLER_USER_ID"), SteamIdHandler.separator)
	local names = SteamIdHandler.split(Convars:GetStr("STEAM_ID_HANDLER_NAME"), SteamIdHandler.separator)
	for idx, v in ipairs(networkids) do
		table.insert(event_datas, {
			networkid = networkids[idx],
			xuid = tonumber(xuids[idx]),
			userid = tonumber(uids[idx]),
			name = names[idx]
		})
	end

	-- print
	__DumpScope(0, event_datas)
end

function SteamIdHandler.Reset()
	Convars:SetStr("STEAM_ID_HANDLER_NETWORK_ID", "")
	Convars:SetStr("STEAM_ID_HANDLER_XUID", "")
	Convars:SetStr("STEAM_ID_HANDLER_USER_ID", "")
	Convars:SetStr("STEAM_ID_HANDLER_NAME", "")
	Convars:SetStr("STEAM_ID_HANDLER_USER_ID_WHITELIST", "")
	SteamIdHandler.n = 0
	SteamIdHandler.UserId = {}
end

-- for SteamIdHandler.HasUser and RemoveUserInfo
if #Convars:GetStr("STEAM_ID_HANDLER_USER_ID") ~= 0 then
	for field,s in string.gmatch(Convars:GetStr("STEAM_ID_HANDLER_USER_ID"), "([^"..SteamIdHandler.separator.."]*)("..SteamIdHandler.separator.."?)") do
		print(field)
		SteamIdHandler.UserId[tonumber(field)] = SteamIdHandler.n
		SteamIdHandler.n = SteamIdHandler.n + 1
		if s == "" then
			break
		end
	end
end


if #Convars:GetStr("STEAM_ID_HANDLER_USER_ID_WHITELIST") ~= 0 then
	-- get whitelist
	local whitelist = {}
	for field,s in string.gmatch(Convars:GetStr("STEAM_ID_HANDLER_USER_ID_WHITELIST"), "([^"..SteamIdHandler.separator.."]*)("..SteamIdHandler.separator.."?)") do
		whitelist[tonumber(field)] = true
		if s == "" then
			break
		end
	end

	-- remove player who didn't load in on last map -> somehow got disconnected without triggering player_disconnect
	for k, v in pairs(SteamIdHandler.UserId) do
		if whitelist[k] == nil then
			SteamIdHandler.RemoveUserInfo({userid = k})
		end
	end
end

-- reset whitelist
Convars:SetStr("STEAM_ID_HANDLER_USER_ID_WHITELIST", "");

ListenToGameEvent("player_connect", SteamIdHandler.AddUserInfo, nil)
ListenToGameEvent("player_disconnect", SteamIdHandler.RemoveUserInfo, nil)
ListenToGameEvent("player_info", SteamIdHandler.UpdateUserName, nil)
ListenToGameEvent("player_activate", SteamIdHandler.AddUserToWhitelist, nil)