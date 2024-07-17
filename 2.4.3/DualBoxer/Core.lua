DualBoxerDB = {
	["pos_a"] = "CENTER",
	["pos_c"] = "CENTER",
	["pos_x"] = "-200",
	["pos_y"] = "200",
	["data"] = {},
}

local Settings = {
	["scale"] = 1,
	["barsize"] = 16,
	["texture"] = "",
	["background"] = "Interface\\DialogFrame\\UI-DialogBox-BackGround-Dark",
	["border"] = "Interface\\Tooltips\\UI-Tooltip-Border",
	["refresh_rate"] = 2,
}

local function ShortNumber(number)
	if number >= 1000000000 then
		return ("%.2fB"):format(number/1000000000)
	elseif number >= 1000000 then
		return ("%.2fM"):format(number/1000000)
	elseif number >= 1000 then
		return ("%.2fK"):format(number/1000)
	else
		return number
	end
end

local function DecimalToHexColor(r, g, b, a)
	return ("|c%02x%02x%02x%02x"):format(a*255, r*255, g*255, b*255)
end

local function TableSum(table)
	local retVal = 0

	for _, n in ipairs(table) do
		retVal = retVal + n
	end

	return retVal
end

local function unitIndex(name)
	for k,v in pairs(DualBoxerDB.data) do
		if v["name"] == name then
			return k
		end
	end
	return false
end

local function IsInParty(name)
	if ( name == UnitName("player") ) then
		return true
	end

	if ( GetNumRaidMembers() > 0 ) then
		for i=1,GetNumRaidMembers(),1 do
			if ( UnitName("raid"..i) == name ) then
				return true
			end
		end
	elseif ( GetNumPartyMembers() > 0 ) then
		for i=1,GetNumPartyMembers(),1 do
			if ( UnitName("party"..i) == name ) then
				return true
			end
		end
	end

	return false
end

local function WhoIsMaster()
	-- Replace this with a setting in the addon to specify the master. If it is set then forward whispers otherwise don't.
	--local master = UnitName("player")
	--local lvl = UnitLevel("player")
	local master = nil
	local lvl = UnitLevel("player")

	if ( GetNumPartyMembers() > 0 ) then
		for i=1,GetNumPartyMembers(),1 do
			if ( UnitLevel("party"..i) > lvl ) then
				lvl = UnitLevel("party"..i)
				master = UnitName("party"..i)
			end
		end
	end

	return master
end

local function DualBoxerXP_Refresh()
	local sortTbl = {}
	for k,v in ipairs(DualBoxerDB.data) do table.insert(sortTbl, k) end
	table.sort(sortTbl, function(a,b) return DualBoxerDB.data[a].percent > DualBoxerDB.data[b].percent end)

	local index = 1
	for k,v in ipairs(sortTbl) do
		local bar = _G["DualBoxerXPFrameBar"..index] or DualBoxerXP_AddBar(index)
		local name = DualBoxerDB.data[v].name
		local percent = DualBoxerDB.data[v].percent
		local lvl = DualBoxerDB.data[v].lvl
		local class = string.upper(DualBoxerDB.data[v].class)

		_G["DualBoxerXPFrameBar"..index.."Name"]:SetText(name)
		_G["DualBoxerXPFrameBar"..index.."Percent"]:SetText(("%s%% [%s]"):format(percent, lvl))	

		if ( class ~= nil and RAID_CLASS_COLORS[class] ~= nil ) then
			bar:SetStatusBarColor(RAID_CLASS_COLORS[class].r, RAID_CLASS_COLORS[class].g, RAID_CLASS_COLORS[class].b, 1)
		else
			bar:SetStatusBarColor(0, 1, 0, 1)
		end
		bar:SetValue(DualBoxerDB.data[v].percent)

		if IsInParty(DualBoxerDB.data[v].name) ~= false then
			bar:Show()
			index = index + 1
		end
	end
end

local function AddUnit(name, class, curXP, maxXP, lvl)
	local index = false
	local percent = ("%.0f"):format((curXP / maxXP)*100)

	for k,v in pairs(DualBoxerDB.data) do
		if v.name == name then
			index = k
			break
		end
	end

	if index == false then
		table.insert(DualBoxerDB.data, { ["name"] = name, ["class"] = class, ["curXP"] = curXP, ["maxXP"] = maxXP, ["lvl"] = lvl, ["percent"] = percent })
	else
		DualBoxerDB.data[index].percent = percent
		DualBoxerDB.data[index].curXP = curXP
		DualBoxerDB.data[index].maxXP = maxXP
		DualBoxerDB.data[index].lvl = lvl
	end

	DualBoxerXP_Refresh()
end

local f = CreateFrame("frame", "DualBoxerXPFrame", UIParent)

local maxScroll = 0
local numBars = 0

f:SetPoint("CENTER")
--f:SetSize(410, 150)
f:SetSize(300, 150)
f:SetClampedToScreen(true)
f:SetMovable(true)
f:EnableMouse(true)
f:SetUserPlaced(true)
f:SetBackdrop( { bgFile = "Interface\\DialogFrame\\UI-DialogBox-BackGround-Dark", edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", tile = true, tileSize = 32, edgeSize = 14, insets = { left = 3, right = 3, top = 3, bottom = 3 } } )

f:SetScript("OnMouseDown", function(self, button)
	f:StartMoving()
end)

f:SetScript("OnMouseUp", function(self, button)
	DualBoxerDB.pos_a, _, DualBoxerDB.pos_c, DualBoxerDB.pos_x, DualBoxerDB.pos_y = DualBoxerXPFrame:GetPoint(1)

	f:StopMovingOrSizing()
end)

local titlebar = CreateFrame("Frame", "DualBoxerXPFrameTitleBar", DualBoxerXPFrame)
titlebar:SetPoint("TOPLEFT", DualBoxerXPFrame, "TOPLEFT", 4, -4)
titlebar:SetSize(DualBoxerXPFrame:GetWidth() - 8, 18)
titlebar:SetBackdrop( { bgFile = "Interface\\BUTTONS\\GRADBLUE", edgeFile = nil, tile = false, tileSize = titlebar:GetWidth(), edgeSize = 0, insets = { left = 0, right = 0, top = 0, bottom = 0 } } )
titlebar:SetBackdropColor(1, 0.5, 0.5, 1)
titlebar:Show()
local title = titlebar:CreateFontString(titlebar:GetName().."Text", "OVERLAY")
title:SetFont("Fonts\\ARIALN.ttf", 12, "OUTLINE")
title:SetAllPoints(titlebar)
title:SetJustifyH("LEFT")
title:SetText("DualBoxerXP")
title:Show()

local scp = CreateFrame("ScrollFrame", "DualBoxerXPFrameSCParent", DualBoxerXPFrame)
scp:SetPoint("TOPLEFT", DualBoxerXPFrame, "TOPLEFT", 4, -24)
scp:SetPoint("BOTTOMRIGHT", DualBoxerXPFrame, "BOTTOMRIGHT", -4, 4)

local sc = CreateFrame("Frame", "DualBoxerXPFrameSC", DualBoxerXPFrameSCParent)
sc:EnableMouse(true)
sc:EnableMouseWheel(true)

sc:SetWidth(DualBoxerXPFrameSCParent:GetWidth())
sc:SetHeight(((Settings.barsize + 2)*25)-2)

DualBoxerXPFrameSCParent:SetScrollChild(sc)

function DualBoxerXP_AddBar(i)
	if _G["DualBoxerXPFrameBar"..i] then return end

	local sb = CreateFrame("StatusBar", "DualBoxerXPFrameBar"..i, DualBoxerXPFrameSC)
	sb:SetMinMaxValues(0, 100)
	sb:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
	sb:GetStatusBarTexture():SetHorizTile(false)
	sb:SetStatusBarColor(0, 1, 0)
	sb:SetValue(0)
	sb:SetHeight(Settings.barsize)

	sb:SetPoint("TOPLEFT", DualBoxerXPFrameSC, "TOPLEFT", 0, (-2-(i*(Settings.barsize + 2)))+(Settings.barsize + 2))

	local t = sb:CreateFontString("DualBoxerXPFrameBar"..i.."Name", "OVERLAY", "NumberFont_Outline_Med")
	t:SetJustifyH("LEFT")
	t:SetPoint("LEFT", sb, "LEFT", 2, 0)

	local t = sb:CreateFontString("DualBoxerXPFrameBar"..i.."Percent", "OVERLAY", "NumberFont_Outline_Med")
	t:SetJustifyH("RIGHT")
	t:SetPoint("RIGHT", sb, "RIGHT", -2, 0)

	_G["DualBoxerXPFrameBar"..i]:SetWidth(DualBoxerXPFrameSC:GetWidth())
	_G["DualBoxerXPFrameBar"..i.."Name"]:SetSize((_G["DualBoxerXPFrameBar"..i]:GetWidth()/2), Settings.barsize)
	_G["DualBoxerXPFrameBar"..i.."Percent"]:SetSize((_G["DualBoxerXPFrameBar"..i]:GetWidth()/2), Settings.barsize)

	DualBoxerXPFrameSC:SetHeight(i*(Settings.barsize + 2))
	maxScroll = DualBoxerXPFrameSC:GetHeight()-128
	numBars = i
	return _G["DualBoxerXPFrameBar"..i]
end

local function FollowUnitByName(name)
	name = string.lower(name)
	local playerName = string.lower(UnitName("player"))
	if ( name == "me" or name == "" or name == nil ) then
		name = playerName
	end

	if ( playerName ~= name ) then
		if ( GetNumRaidMembers() > 0 ) then
			for i=1,GetNumRaidMembers(),1 do
				if ( string.lower(UnitName("raid"..i)) == name ) then
					FollowUnit("raid"..i)
					break
				end
			end
		elseif ( GetNumPartyMembers() > 0 ) then
			for i=1,GetNumPartyMembers(),1 do
				local unitName = string.lower(UnitName("party"..i))
				if ( unitName == name ) then
					FollowUnit("party"..i)
					break
				end
			end
		end
	end
end

local function SendGroupMessage(msg)
	if ( GetNumRaidMembers() > 0 ) then
		SendChatMessage(msg, "RAID", nil, nil)
	elseif ( GetNumPartyMembers() > 0 ) then
		SendChatMessage(msg, "PARTY", nil, nil)
	else
		SendChatMessage(msg, "SAY", nil, nil)
	end
end

local function SendAddOnMessage(msg)
	SendChatMessage(msg, "CHANNEL", nil, GetChannelName("DualBoxer"))
end

f:SetScript("OnMouseWheel", function(self, delta)
	local scp = DualBoxerXPFrameSCParent

	if delta > 0 then
		if scp:GetVerticalScroll() > 20 then
			scp:SetVerticalScroll(scp:GetVerticalScroll()-20)
		else
			scp:SetVerticalScroll(0)
		end
	else
		if scp:GetVerticalScroll() < maxScroll then
			scp:SetVerticalScroll(scp:GetVerticalScroll()+20)
		else
			scp:SetVerticalScroll(maxScroll)
		end
	end
end)

f:SetScript("OnEvent", function(self, event, ...)
	--print(cmd, target)
	if ( event == "VARIABLES_LOADED" or event == "PLAYER_ENTERING_WORLD" ) then
		JoinChannelByName("DualBoxer")

		for i=1,NUM_CHAT_WINDOWS,1 do
			RemoveChatWindowChannel(i, "DualBoxer")
		end

		self:SetPoint(DualBoxerDB.pos_a, UIParent, DualBoxerDB.pos_c, DualBoxerDB.pos_x, DualBoxerDB.pos_y)
		self:UnregisterEvent("VARIABLES_LOADED")

		SendAddOnMessage("REFRESH")

		DualBoxerXP_Refresh()
	elseif ( event == "CHAT_MSG_PARTY" or event == "CHAT_MSG_PARTY_LEADER" or event == "CHAT_MSG_RAID" or event == "CHAT_MSG_RAID_LEADER" ) then
		local msg, name = ...
		local cmd, target = string.split(" ", string.lower(msg), 2)

		if ( cmd == "f" or cmd == "follow" ) then
			if ( target == "me" or target == "" or target == nil ) then
				target = name
			end
				--[[
				for i=1,4,1 do
					if ( target == UnitName("party"..i) ) then
						FollowUnit("party"..i)
					end
				end
				]]
			FollowUnitByName(target)
			--SendGroupMessage("Following "..target)
		elseif ( cmd == "!f" or cmd == "!follow" ) then
			FollowUnit("player")
		end
	elseif ( event == "CHAT_MSG_WHISPER" ) then
		local msg, name, _, _, _, _, _, _, _, _, _, guid = ...
		local cmd, target = string.split(" ", string.lower(msg), 2)

		if ( cmd == "inv" or cmd == "invite" ) then
			if ( target == "me" or target == "" or target == nil ) then
				target = name
			end

			InviteUnit(target)
		elseif ( cmd == "follow" or cmd == "f" ) then
			if ( target == "me" or target == "" or target == nil ) then
				target = name
			end

			FollowUnitByName(target)
			--SendGroupMessage("Following "..target)
		elseif ( cmd == "promote" ) then
			if ( target == "me" or target == "" or target == nil ) then
				target = name
			end
			PromoteToLeader(target)
			SendGroupMessage("Promoted "..target.." to leader.")
		else
			--print(GetPlayerInfoByGUID(guid))
			local master = WhoIsMaster()
			if ( master ~= nil ) then
				SendChatMessage(("[%s]: %s"):format(name, msg), "WHISPER", nil, master)
			end
		end
	elseif ( event == "PLAYER_LEVEL_UP" ) then
		local lvl = ...
		SendAddOnMessage(("XP:%s:%s:%s:%s:%s"):format(UnitName("player"), UnitClass("player"), UnitXP("player"), UnitXPMax("player"), lvl))
	elseif ( event == "PLAYER_XP_UPDATE" ) then
		--local xp = ("%.0f"):format((UnitXP("player") / UnitXPMax("player"))*100)
		SendAddOnMessage(("XP:%s:%s:%s:%s:%s"):format(UnitName("player"), UnitClass("player"), UnitXP("player"), UnitXPMax("player"), UnitLevel("player")))
	elseif ( event == "CHAT_MSG_CHANNEL" ) then
		local msg, name, _, _, _, _, _, _, chan = ...		

		if ( chan == "DualBoxer" ) then
			local type, args = string.split(":", msg, 2)

			if ( type == "XP" ) then
				local unitName, class, curXP, maxXP, lvl = string.split(":", args, 5)
				
				AddUnit(unitName, class, curXP, maxXP, lvl)

				--DualBoxerDB.data[name].curXP = curXP
				--DualBoxerDB.data[name].maxXP = maxXP
				--DualBoxerDB.data[name].lvl = lvl
			elseif ( type == "REFRESH" ) then
				SendAddOnMessage(("XP:%s:%s:%s:%s:%s"):format(UnitName("player"), UnitClass("player"), UnitXP("player"), UnitXPMax("player"), UnitLevel("player")))				
			end
		end
	elseif ( event == "RAID_ROSTER_UPDATE" or event == "PARTY_MEMBERS_CHANGED" ) then
		DualBoxerXP_Refresh()
		SendAddOnMessage("REFRESH")
	end
end)

f:RegisterEvent("CHAT_MSG_PARTY")
f:RegisterEvent("CHAT_MSG_PARTY_LEADER")
f:RegisterEvent("CHAT_MSG_WHISPER")
f:RegisterEvent("CHAT_MSG_RAID")
f:RegisterEvent("CHAT_MSG_RAID_LEADER")
f:RegisterEvent("CHAT_MSG_CHANNEL")
f:RegisterEvent("VARIABLES_LOADED")
f:RegisterEvent("PLAYER_ENTERING_WORLD")
f:RegisterEvent("PLAYER_XP_UPDATE")
f:RegisterEvent("PLAYER_LEVEL_UP")
f:RegisterEvent("RAID_ROSTER_UPDATE")
f:RegisterEvent("PARTY_MEMBERS_CHANGED")
