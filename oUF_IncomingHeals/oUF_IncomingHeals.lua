if not oUF then return end

local type = type
local pairs = pairs
local select = select
local UnitName = UnitName

local HealComm = LibStub:GetLibrary("LibHealComm-3.0")

local objects = oUF.objects
local units = oUF.units
local needUpdate -- Flag for updating on next "tick"
-- Table for objects that need updating next OnUpdate
-- object as key, unit name as value
local objectsNeedingUpdate = {} 
local healModifiers = {} -- cache healing modifiers, indexed by name

-- Player information
local playerName = UnitName("player")
local playerIsCasting = false -- true when player is casting a _healing_ spell
local playerHealTargetNames = {} -- who are the player healing? indexed by name
local playerHealSize = 0 -- as recieved from HealComm
local playerEndTime = nil -- GetTime() + cast time when the cast started

-- OnUpdate to bucket the updates slightly
local timer = 0
local function OnUpdate(self, elapsed)
	timer = timer + elapsed
	-- minimum seconds between updates, subject to tweak
	-- 0.125 = 8 times/second
	if timer >= 0.125 and needUpdate then
		-- iterate through all objects that needs updating
		for obj, name in pairs(objectsNeedingUpdate) do
			if type(name) ~= "string" then
				local unit = obj.unit
				if unit then
					local server
					name, server = UnitName(unit)
					if server then name = name.."-"..server end
				else
					name = nil
				end
			end
			if name then
				local healMod = healModifiers[name]
				if not healMod then -- No healMod cached, ask HealComm
					healMod = HealComm:UnitHealModifierGet(name)
					healModifiers[name] = healMod
				end
				if playerIsCasting and playerHealTargetNames[name] then
					-- player is healing this guy
					local incomingHeal, incomingHealAfter = HealComm:UnitIncomingHealGet(name, playerEndTime)
					obj:UpdateHeals(healMod, incomingHeal or 0, playerHealSize or 0, incomingHealAfter or 0)
				else
					local _, incomingHeal = HealComm:UnitIncomingHealGet(name, 0)
					obj:UpdateHeals(healMod, incomingHeal or 0, 0, 0)
				end
			else
				-- But how can you heal that which has no name?
				obj:UpdateHeals(1, 0, 0, 0)
			end
			objectsNeedingUpdate[obj] = nil
		end
		needUpdate = nil
		timer = 0
	end
end

local function OnEvent(self, event, ...)
	if event == "PLAYER_TARGET_CHANGED" then
		-- Check if there's frames for target, tot and totot and place them in queue for update.
		local t = units["target"]
		if t then objectsNeedingUpdate[t] = true end
		t = units["targettarget"]
		if t then objectsNeedingUpdate[t] = true end
		t = units["targettargettarget"]
		if t then objectsNeedingUpdate[t] = true end
		needUpdate = true
	else -- Only 2 events registered. If it's not one it's definatly the other
	--elseif event == "PLAYER_FOCUS_CHANGED" then
		-- Check if there's frames for focus, tof and totof and place them in queue for update.
		local f = units["focus"]
		if f then objectsNeedingUpdate[f] = true end
		f = units["focustarget"]
		if f then objectsNeedingUpdate[f] = true end
		f = units["focustargettarget"]
		if f then objectsNeedingUpdate[f] = true end
		needUpdate = true
	end
end

local frame = CreateFrame("Frame")
frame:SetScript("OnUpdate", OnUpdate)
frame:SetScript("OnEvent", OnEvent)
frame:RegisterEvent("PLAYER_TARGET_CHANGED")
frame:RegisterEvent("PLAYER_FOCUS_CHANGED")

local nameList = {} -- recycled table for multiple names
local function UpdateForNames(forPlayer, ...)
	local numberOfNames = select("#", ...)
	if numberOfNames > 1 then
		-- Many targets
		-- Start with generating a list with names to avoid nested loops later.
		if forPlayer == true then
			-- Player is healing
			for i = 1, numberOfNames do
				local name = select(i, ...)
				nameList[name] = true
				playerHealTargetNames[name] = true
			end
		else
			-- Player stopped healing or
			-- Someone else is healing or stopped healing
			for i = 1, numberOfNames do
				nameList[select(i, ...)] = true
			end
		end
		-- loop through all objects, looking for units with the right names
		for _, obj in ipairs(objects) do
			local unit = obj.unit
			if unit and not obj.ignoreIncomingHeal then
				local name, server = UnitName(unit)
				if server then name = name.."-"..server end
				if nameList[name] then
					objectsNeedingUpdate[obj] = name -- flag for update
					-- Don't break early since the guy can be on more than one frame
				end
			end
		end
		-- Clear the nameList
		for name in pairs(nameList) do
			nameList[name] = nil
		end
	elseif numberOfNames == 1 then
		-- One target
		local target = ...
		if forPlayer then playerHealTargetNames[target] = true end
		for _, obj in ipairs(objects) do
			local unit = obj.unit
			if unit and not obj.ignoreIncomingHeal then
				local name, server = UnitName(unit)
				if server then name = name.."-"..server end
				if name == target then
					objectsNeedingUpdate[obj] = name
				end
			end
		end
	else
		-- Will this happen?
	end
	needUpdate = true -- Flag to update next OnUpdate
end

-------------------------------------------------
--[[--[=[--]]-- Callbacks -----------------------
-------------------------------------------------

-- Used for both HealComm_DirectHealStart and HealComm_DirectHealDelayed
local function DirectHealStart(event, healerName, healSize, endTime, ...)
	if healerName == playerName then
		playerIsCasting = true
		playerHealSize = healSize
		playerEndTime = endTime
		UpdateForNames(true, ...)
	else
		UpdateForNames(nil, ...)
	end
end

local function DirectHealStop(event, healerName, healSize, succeeded, ...)
	if healerName == playerName then
		playerIsCasting = false
		for name in pairs(playerHealTargetNames) do
			playerHealTargetNames[name] = nil
		end
		playerEndTime = nil
	end
	UpdateForNames(nil, ...)
end

local function HealModifierUpdate(event, unit, targetName, healModifier)
	healModifiers[targetName] = healModifier
	local object = units[unit]
	if object and not object.ignoreIncomingHeal and object.incomingHealActive then
		objectsNeedingUpdate[object] = targetName
		needUpdate = true
	end
end

--Register callbacks
HealComm.RegisterCallback("oUF_IncomingHeals", "HealComm_DirectHealStart", DirectHealStart)
HealComm.RegisterCallback("oUF_IncomingHeals", "HealComm_DirectHealDelayed", DirectHealStart)
HealComm.RegisterCallback("oUF_IncomingHeals", "HealComm_DirectHealStop", DirectHealStop)
HealComm.RegisterCallback("oUF_IncomingHeals", "HealComm_HealModifierUpdate", HealModifierUpdate)

--[[--]=]--]]-- For Notepad++ folding -----------
-------------------------------------------------

local function UpdateHeals(self, healMod, incomingHeal, incomingPlayerHeal, incomingHealAfter)
	if not healMod then
		objectsNeedingUpdate[self] = true
		needUpdate = true
	else
		local healSize = incomingHeal + incomingPlayerHeal + incomingHealAfter
		local bar = self.Health
		local curHP, maxHP = bar:GetMinMaxValues()
		if healSize == 0 or maxHP <= 100 then
			-- hide if there's no heal or if health is less than or equal to 100
			-- (nice on for Prince in Karazhan so you don't get green bars across 
			-- your screen when someone heal people with 1 health)
			self.IncomingHeal:Hide()
			local incPlayerHeal = self.IncomingPlayerHeal
			if incPlayerHeal then incPlayerHeal:Hide() end
			self.incomingHealActive = false
			return
		end
		curHP = bar:GetValue()
		local incHeal = self.IncomingHeal
		local incPlayerHeal = self.IncomingPlayerHeal
		local widthValue = bar:GetWidth() / maxHP -- do this once, used in several places later
		
		-- healMod *   percentHealed    * bar:GetWidth() = 
		-- healMod * (healSize / maxHP) * bar:GetWidth() = 
		-- healMod * healSize * (bar:GetWidth() / maxHP) = 
		-- healMod * healSize * widthValue
		incHeal:SetWidth(healMod * healSize * widthValue)
		--  percentHealth  * bar:GetWidth() = 
		-- (curHP / maxHP) * bar:GetWidth() = 
		-- curHP * (bar:GetWidth() / maxHP) = 
		-- curHP * widthValue
		incHeal:SetPoint("LEFT", bar, "LEFT", curHP * widthValue, 0)
		incHeal:Show()
		if incPlayerHeal then
			if incomingPlayerHeal > 0 then
				incPlayerHeal:SetWidth(healMod * incomingPlayerHeal * widthValue)
				incPlayerHeal:SetPoint("LEFT", incHeal, "LEFT", incomingHeal*widthValue, 0)
				incPlayerHeal:Show()
			else
				incPlayerHeal:Hide()
			end
		end
		self.incomingHealActive = true
	end
end

-- Special UpdateHeals to use as PostUpdateHealth
local function UpdateHealsPostHealth(self, event, unit, bar, min, max)
	if not self.incomingHealActive then return end
	if event == "UNIT_MAXHEALTH" then
		-- Max health changed, might need to resize
		objectsNeedingUpdate[self] = true
		needUpdate = true
		return
	end
	self.IncomingHeal:SetPoint("LEFT", bar, "LEFT", min * bar:GetWidth() / max, 0)
end
-- Global function. See readme.txt
oUF_IncomingHeals_UpdateHealsPostHealth = UpdateHealsPostHealth

local function createDefault(object, texture, color, playerColor, alpha, playerAlpha)
	local bar = object.Health
	local h = bar:GetHeight()
	local texture = texture or bar:GetStatusBarTexture():GetTexture()
	local r, g, b, a
	-- Incoming heal
	if color and type(color) == "table" then
		if color.r then
			r, g, b, a = color.r, color.g, color.b, color.a
		elseif r[1] then
			r, g, b, a = color[1], color[2], color[3], color[4]
		end
	else
		r, g, b = 0, 1, 0
	end
	a = alpha or a or 0.25
	local inc = bar:CreateTexture()
	inc:SetHeight(h)
	inc:SetWidth(16)
	inc:SetPoint("LEFT", bar, "LEFT", 0, 0)
	inc:SetTexture(texture)
	inc:SetVertexColor(r, g, b, a)
	inc:Hide()
	object.IncomingHeal = inc
	
	-- Incoming player heal
	if playerColor ~= false then
		a = nil -- Reset for player color
		if playerColor and type(playerColor) == "table" then
			if playerColor.r then
				r, g, b, a = playerColor.r, playerColor.g, playerColor.b, playerColor.a
			elseif r[1] then
				r, g, b, a = playerColor[1], playerColor[2], playerColor[3], playerColor[4]
			end
		else
			r, g, b = 0, 0.8, 0.8 -- Robin egg blue
		end
		a = playerAlpha or a or 0.4
		local incPlayer = bar:CreateTexture()
		incPlayer:SetHeight(h)
		incPlayer:SetWidth(8)
		incPlayer:SetPoint("LEFT", inc, "LEFT", 0, 0)
		incPlayer:SetTexture(texture)
		incPlayer:SetVertexColor(r, g, b, a)
		incPlayer:Hide()
		
		object.IncomingPlayerHeal = incPlayer
	end
end
-- Global function. See readme.txt
oUF_IncomingHeals_CreateDefault = createDefault

-- Init objects
local function addIncomingHeal(object)
	if object.ignoreIncomingHeal then return end
	if not object.IncomingHeal then
		createDefault(object)
	end
	if not object.UpdateHeals then
		object.UpdateHeals = UpdateHeals
	end
	-- Hog the PostUpdateHealth
	if not object.PostUpdateHealth then
		object.PostUpdateHealth = UpdateHealsPostHealth
	end
end

for _, object in ipairs(objects) do addIncomingHeal(object) end
oUF:RegisterInitCallback(addIncomingHeal)
