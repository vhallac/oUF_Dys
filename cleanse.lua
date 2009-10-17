
-- Pick up the global, which is controlled by X-oUF of the TOC file.
local oUF = oUF_Dys
local SM = LibStub("LibSharedMedia-3.0")
local spacing_x = 3
local spacing_y = -3
local size_x = 27
local size_y = 27
local playerClass = select(2, UnitClass("player"))
local cleanseInfo = {
	MAGE = {
		canCure = { "Curse" },
		spellId = {
			475 -- Remove Curse (Mage)
		},
	},
	DRUID = {
		canCure = { "Curse", "Poison" },
		spellId = {
			2782, -- Remove Curse (Druid)
			2893, -- Abolish Poison
		},
	},
	PRIEST = {
		canCure = { "Disease", "Magic" },
		spellId = {
			552, -- Abolish Disease
			988, -- Dispel Magic
		}
	}
}
local playerCleanseInfo = cleanseInfo[playerClass]

SM:Register("sound", "beam11", "Interface\\AddOns\\oUF_Dys\\sounds\\beam11.wav")

local function HasDebuffType(unit, t)
	for i=1,40 do
		local name, _, _, _, debuffType = UnitDebuff(unit, i)
		if not name then return end
		for i, val in ipairs(t) do
			if debuffType == val then
				local inRange = IsSpellInRange(playerCleanseInfo.spellId[i], "spell", unit)
				return true, inRange
			end
		end
	end
end

local lastPlayed = GetTime()
local warnSoundDelta = 15 -- Play the sound 15 secs after the previous one

local Update = function(self, event, unit)
	local playSound = false
	if unit == self.unit then
		local hasCurable, inRange = HasDebuffType(unit, self.AuraTransparency)
		if hasCurable then
			if inRange then
				self:SetBackdropColor(1, 0, 0, 1)
				self:SetBackdropBorderColor(1, 0, 0, 1)
				playSound = true
			else
				self:SetBackdropColor(0.4, 0, 0, 0.6)
				self:SetBackdropBorderColor(0.4, 0, 0, 0.6)
			end
		else
			self:SetBackdropColor(0, 0, 0, .1)
			self:SetBackdropBorderColor(0, 0, 0, .1)
		end
		local curTime = GetTime()
		if playSound and  curTime - lastPlayed > warnSoundDelta then
			lastPlayed = curTime
			PlaySoundFile(SM:Fetch("sound", "beam11"))
		end
	end
end

local Enable = function(self)
	if(self.AuraTransparency) then
		self:RegisterEvent("UNIT_AURA", Update)
		return true
	end
end

local Disable = function(self)
	if(self.AuraTransparency) then
		self:UnregisterEvent("UNIT_AURA", Update)
	end
end

oUF:AddElement('AuraTransparency', Update, Enable, Disable)

local backdrop = {
	bgFile = "Interface\\Tooltips\\UI-Tooltip-Background", tile = true, tileSize = 8,
	edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", edgeSize = 8,
	insets = {left = 0, right = 0, top = 0, bottom = 0},
	}

local func = function(self, unit)
	self:SetScript("OnEnter", UnitFrame_OnEnter)
	self:SetScript("OnLeave", UnitFrame_OnLeave)

	self:RegisterForClicks"anyup"
	self:SetBackdrop(backdrop)
	self:SetBackdropColor(0,0,0,1)

	self:SetWidth(size_x)
	self:SetHeight(size_y)

	self:SetAttribute('initial-height', size_x)
	self:SetAttribute('initial-width', size_y)

	-- And adjust the initial value of the transparency
	self.AuraTransparency = playerCleanseInfo and playerCleanseInfo.canCure

	return self
end

oUF:RegisterStyle("Dys - Cleanse", func)
oUF:SetActiveStyle("Dys - Cleanse")

--
-- raid
--
if playerCleanseInfo then
	oUF_Dys.Cleanse = {}
	for i = 1, NUM_RAID_GROUPS do
		local raidGroup = oUF:Spawn("header", "oUF_Cleanse" .. i)
		if i == 1 then
			raidGroup:SetManyAttributes('showParty', true,
										'showPlayer', true,
										'showSolo', true)
		end
		raidGroup:SetManyAttributes('groupFilter', tostring(i),
									'showRaid', true,
									'point', "LEFT",
									'xoffset', spacing_x,
									'yOffset', 0)
		table.insert(oUF_Dys.Cleanse, raidGroup)
		if i == 1 then
			raidGroup:SetPoint("TOPRIGHT", UIParent, "CENTER", -spacing_x/2, -290)
		elseif i%2 == 0 then
			raidGroup:SetPoint("TOPLEFT", oUF_Dys.Cleanse[i-1], "TOPRIGHT", spacing_x, 0)
		else
			raidGroup:SetPoint("TOPLEFT", oUF_Dys.Cleanse[i-2], "BOTTOMLEFT", 0, spacing_y)
		end
		raidGroup:Show()
	end
end

