--[[

	oUF_Dys - Based on oUF_Lyn

	Author:     Dys
	Mail:       dys.wowace@gmail.com

	Credits for original work:
	Author:		Lyn
	Mail:		post@endlessly.de
	URL:		http://www.wowinterface.com/list.php?skinnerid=62149

	Credits:	oUF_TsoHG (used as base) / http://www.wowinterface.com/downloads/info8739-oUF_TsoHG.html
				Rothar for buff border (and Neal for the edited version)
				p3lim for party toggle function

--]]


-- Pick up the global oUF
local parent, ns = ...
local oUF = ns.oUF
if not oUF then return end

-- ------------------------------------------------------------------------
-- font, fontsize and textures
-- ------------------------------------------------------------------------
local font = "Interface\\AddOns\\oUF_Dys\\fonts\\font.ttf"
local upperfont = "Interface\\AddOns\\oUF_Dys\\fonts\\upperfont.ttf"
local bartex = "Interface\\AddOns\\oUF_Dys\\textures\\statusbar"
local bufftex = "Interface\\AddOns\\oUF_Dys\\textures\\border"
local highlighttex = "Inerface\\AddOns\\oUF_Dys\\textures\\statusbar"
local playerClass = select(2, UnitClass("player"))

-- castbar position
local playerCastBar_x = 0
local playerCastBar_y = -260
local targetCastBar_x = 11
local targetCastBar_y = -160

-- ------------------------------------------------------------------------
-- change some colors :)
-- ------------------------------------------------------------------------
oUF.colors.happiness = {
	[1] = {182/225, 34/255, 32/255},	-- unhappy
	[2] = {220/225, 180/225, 52/225},	-- content
	[3] = {143/255, 194/255, 32/255},	-- happy
}

-- ------------------------------------------------------------------------
-- right click
-- ------------------------------------------------------------------------
local menu = function(self)
	local unit = self.unit:sub(1, -2)
	local cunit = self.unit:gsub("^%l", string.upper)

	if(cunit == 'Vehicle') then
		cunit = 'Pet'
	end

	if(unit == "party" or unit == "partypet") then
		ToggleDropDownMenu(1, nil, _G["PartyMemberFrame"..self.id.."DropDown"], "cursor", 0, 0)
	elseif(_G[cunit.."FrameDropDown"]) then
		ToggleDropDownMenu(1, nil, _G[cunit.."FrameDropDown"], "cursor", 0, 0)
	end
end

-- ------------------------------------------------------------------------
-- reformat everything above 9999, i.e. 10000 -> 10k
-- ------------------------------------------------------------------------
local numberize = function(v)
	if v <= 9999 then return v end
	if v >= 1000000 then
		local value = string.format("%.1fm", v/1000000)
		return value
	elseif v >= 10000 then
		local value = string.format("%.1fk", v/1000)
		return value
	end
end

-- ------------------------------------------------------------------------
-- health update
-- ------------------------------------------------------------------------
local PostUpdateHealth = function(self, unit, min, max)
	if(UnitIsDead(unit) or UnitIsGhost(unit)) then
		bar:SetValue(0)
	end
end

-- ------------------------------------------------------------------------
-- power update
-- ------------------------------------------------------------------------
local function PreUpdatePower(self, unit)
	if self.unit ~= 'player' then return end

	local cur = UnitPower('player', SPELL_POWER_MANA)
	local max = UnitPowerMax('player', SPELL_POWER_MANA)

	self.DruidMana:SetMinMaxValues(0, max)
	self.DruidMana:SetValue(cur)

	self.DruidMana.Text:SetFormattedText('%d%%', math.floor(cur / max * 100))

	local powertype = UnitPowerType('player')
	self.DruidMana:SetAlpha((powertype ~= 0) and 1 or 0)
end

local PostUpdatePower = function(self, unit, min, max)
	if UnitIsPlayer(unit) and min ~=0 and (UnitIsDead(unit) or UnitIsGhost(unit)) then
		bar:SetValue(0)
	end
end

-- ------------------------------------------------------------------------
-- aura reskin
-- ------------------------------------------------------------------------
local auraIcon = function(self, button)
	self.showDebuffType = true -- show debuff border type color

	button.icon:SetTexCoord(.07, .93, .07, .93)
	button.icon:SetPoint("TOPLEFT", button, "TOPLEFT", 1, -1)
	button.icon:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -1, 1)

	button.overlay:SetTexture(bufftex)
	button.overlay:SetTexCoord(0,1,0,1)
	button.overlay.Hide = function(self) self:SetVertexColor(0.3, 0.3, 0.3) end

	button.cd:SetReverse()
	button.cd:SetPoint("TOPLEFT", button, "TOPLEFT", 2, -2)
	button.cd:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -2, 2)
end

-- ------------------------------------------------------------------------
-- Some tags I want
-- ------------------------------------------------------------------------
oUF.TagEvents["dys:curhp"] = oUF.TagEvents.curhp
oUF.Tags["dys:curhp"] = function(u)
	local text=""
	if UnitIsDead(u) or UnitIsGhost(u) then
		text = "|cff2000dead|r"
	elseif not UnitIsConnected(u) then
		text = "|cff808080offline|r"
	else
		text = "|cff33EE44"..numberize(UnitHealth(u)) .."|r"
	end
	return text
end

local colorHealthRed = function(self, event, unit, bar, min, max)
						   bar:SetStatusBarColor(1, 0, 0)
end

local checkThreatSituation = function(self, event, unit, status)
	if status == 3 then
		self.OverrideUpdateHealth = colorHealthRed
	else
		self.OverrideUpdateHealth = nil
	end
	self:UpdateElement("Health")
end

-- ------------------------------------------------------------------------
-- Custom filter for Auras
-- ------------------------------------------------------------------------
local auraBlackList = {
	-- Bested <City of Choice>
	[64805] = true,
	[64808] = true,
	[64809] = true,
	[64810] = true,
	[64811] = true,
	[64812] = true,
	[64813] = true,
	[64814] = true,
	[64815] = true,
	[64818] = true,
	-- Hellscream's Warsong
	[73816] = true,
	[73818] = true,
	[73819] = true,
	[73820] = true,
	[73821] = true,
	[73822] = true,
	-- Tricked or Treated
	[24755] = true,
}

local auraFilter = function(auras, unit, aura, name, rank, texture, count, dtype, duration, timeLeft, caster, isStealable, shouldConsolidate, spellId)
	-- Leave the consolidated buffs alone
	if shouldConsolidate then
		return false
	end

	-- Don't allow blacklisted debuffs
	if auraBlackList[spellId] then
		return false
	end

	return true
end

-- ------------------------------------------------------------------------
-- the layout starts here
-- ------------------------------------------------------------------------
local StyleSettings

local func = function(settings, self, unit, isSingle)
	local settings = StyleSettings[self.style] or {}

	self:SetSize(settings.width, settings.height)

	self.menu = menu -- Enable the menus

	self:SetScript("OnEnter", UnitFrame_OnEnter)
	self:SetScript("OnLeave", UnitFrame_OnLeave)

	-- XXX: Change to AnyUp when RegisterAttributeDriver doesn't cause clicks
	-- to get incorrectly eaten.
	self:RegisterForClicks("AnyDown")

	--
	-- background
	--
	self:SetBackdrop{
	bgFile = "Interface\\ChatFrame\\ChatFrameBackground", tile = true, tileSize = 16,
	insets = {left = -2, right = -2, top = -2, bottom = -2},
	}
	self:SetBackdropColor(0,0,0,1) -- and color the backgrounds

	--
	-- healthbar
	--
	self.Health = CreateFrame"StatusBar"
	self.Health:SetHeight(settings["healthbar-height"])
	self.Health:SetStatusBarTexture(bartex)
	self.Health:SetParent(self)
	self.Health:SetPoint"TOP"
	self.Health:SetPoint"LEFT"
	self.Health:SetPoint"RIGHT"
	--
	-- healthbar background
	--
	self.Health.bg = self.Health:CreateTexture(nil, "BORDER")
	self.Health.bg:SetAllPoints(self.Health)
	self.Health.bg:SetTexture(bartex)
	self.Health.bg:SetAlpha(0.30)

	--
	-- healthbar functions
	--
	self.Health.colorClass = true
	self.Health.colorReaction = true
	self.Health.colorDisconnected = true
	self.Health.colorTapping = true
	self.Health.PostUpdate = PostUpdateHealth -- let the colors be

	--
	-- powerbar
	--
	if settings["have-powerbar"] then
		self.Power = CreateFrame"StatusBar"
		self.Power:SetHeight(settings["powerbar-height"])
		self.Power:SetStatusBarTexture(bartex)
		self.Power:SetParent(self)
		self.Power:SetPoint"LEFT"
		self.Power:SetPoint"RIGHT"
		self.Power:SetPoint("TOP", self.Health, "BOTTOM", 0, -1.45) -- Little offset to make it pretty

		--
		-- powerbar background
		--
		self.Power.bg = self.Power:CreateTexture(nil, "BORDER")
		self.Power.bg:SetAllPoints(self.Power)
		self.Power.bg:SetTexture(bartex)
		self.Power.bg:SetAlpha(0.30)

		--
		-- powerbar functions
		--
		self.Power.colorTapping = true
		self.Power.colorDisconnected = true
		self.Power.colorClass = true
		self.Power.colorPower = true
		self.Power.colorHappiness = false
		self.Power.PostUpdate = PostUpdatePower
	end

	--
	-- Info Line
	--
	local fontsize = settings["fontsize"]
	self.InfoLeft = self.Health:CreateFontString(nil, "OVERLAY")
	self.InfoLeft:SetPoint("LEFT", self, 0, fontsize)
	self.InfoLeft:SetJustifyH("LEFT")
	self.InfoLeft:SetShadowOffset(1, -1)
	self.InfoLeft:SetFont(font, fontsize, "OUTLINE")
	self.InfoLeft:SetHeight(fontsize + 2)
	self.InfoRight = self.Health:CreateFontString(nil, "OVERLAY")
	self.InfoRight:SetPoint("RIGHT", self, 0, fontsize)
	self.InfoRight:SetJustifyH("RIGHT")
	self.InfoRight:SetShadowOffset(1, -1)
	self.InfoRight:SetFont(font, fontsize, "OUTLINE")
	self.InfoLeft:SetHeight(fontsize + 2)
	if unit=="player" then
		self:Tag(self.InfoLeft, "[curpp]")
		self:Tag(self.InfoRight, "[dys:curhp].[perhp]%")
	elseif unit=="target" then
		self:Tag(self.InfoLeft, "[difficulty][level][shortclassification] [raidcolor][name]|r")
		self:Tag(self.InfoRight, "[dys:curhp].[perhp]%")
	elseif unit:match("boss") then
		self:Tag(self.InfoLeft, "[name]")
		self:Tag(self.InfoRight, "[dys:curhp].[perhp]%")
	else
		self:Tag(self.InfoLeft, "[raidcolor][name]")
		self:Tag(self.InfoRight, "[perhp]%")
	end

	-- ------------------------------------
	-- player
	-- ------------------------------------
	if unit=="player" then
		-- Check aggro, and update health color
		-- TODO: Won't do squat. Need to hook in deeper
		self.OverrideUpdateThreat = checkThreatSituation

		-- A texture or a frame is needed to activate threat module.
		-- We won't be using it to display anything, though.
		-- checkThreatSituation updates health bar color
		local threat = self.Health:CreateTexture(nil, "OVERLAY")
		self.Threat = threat

		if(playerClass=="DRUID") then
			self.Power.PreUpdate = PreUpdatePower -- For Druid mana
			-- bar
			self.DruidMana = CreateFrame('StatusBar', nil, self)
			self.DruidMana:SetPoint('BOTTOM', self, 'TOP', 0, 14)
			self.DruidMana:SetStatusBarTexture(bartex)
			self.DruidMana:SetStatusBarColor(45/255, 113/255, 191/255)
			self.DruidMana:SetHeight(10)
			self.DruidMana:SetWidth(250)
			-- bar bg
			self.DruidMana.bg = self.DruidMana:CreateTexture(nil, "BORDER")
			self.DruidMana.bg:SetAllPoints(self.DruidMana)
			self.DruidMana.bg:SetTexture(bartex)
			self.DruidMana.bg:SetAlpha(0.30)
			-- black bg
			self.DruidMana:SetBackdrop{
				bgFile = "Interface\\ChatFrame\\ChatFrameBackground", tile = true, tileSize = 16,
				insets = {left = -2, right = -2.5, top = -2.5, bottom = -2},
				}
			self.DruidMana:SetBackdropColor(0,0,0,1)
			-- text
			self.DruidMana.Text = self.DruidMana:CreateFontString(nil, 'OVERLAY')
			self.DruidMana.Text:SetPoint("CENTER", self.DruidMana, "CENTER", 0, 1)
			self.DruidMana.Text:SetFont(font, 12, "OUTLINE")
			self.DruidMana.Text:SetTextColor(1,1,1)
			self.DruidMana.Text:SetShadowOffset(1, -1)
		end

		--
		-- leader icon
		--
		self.Leader = self.Health:CreateTexture(nil, "OVERLAY")
		self.Leader:SetHeight(16)
		self.Leader:SetWidth(16)
		self.Leader:SetPoint("CENTER", self, "TOP", 0, 4)
		self.Leader:SetTexture"Interface\\GroupFrame\\UI-Group-LeaderIcon"

		--
		-- raid target icons
		--
		self.RaidIcon = self.Health:CreateTexture(nil, "OVERLAY")
		self.RaidIcon:SetHeight(16)
		self.RaidIcon:SetWidth(16)
		self.RaidIcon:SetPoint("TOP", self, 0, 9)
		self.RaidIcon:SetTexture"Interface\\TargetingFrame\\UI-RaidTargetingIcons"

		--
		-- oUF_PowerSpark support
		--
		self.Spark = self.Power:CreateTexture(nil, "OVERLAY")
		self.Spark:SetTexture("Interface\\CastingBar\\UI-CastingBar-Spark")
		self.Spark:SetVertexColor(1, 1, 1, 1)
		self.Spark:SetBlendMode("ADD")
		self.Spark:SetHeight(self.Power:GetHeight()*2.5)
		self.Spark:SetWidth(self.Power:GetHeight()*2)

		--
		-- debuffs
		--
		self.TxtDebuffs = CreateFrame("Frame", nil, self)
		self.TxtDebuffs.height = 33
		self.TxtDebuffs.width = 380
		self.TxtDebuffs.spacing = 4
		self.TxtDebuffs.num = 10
		self.TxtDebuffs.fontSize = 20
		self.TxtDebuffs.labelFont = font
		self.TxtDebuffs.initialAnchor = "TOP"
		self.TxtDebuffs:SetHeight((self.TxtDebuffs.height + self.TxtDebuffs.spacing)* self.TxtDebuffs.num - self.TxtDebuffs.spacing)
		self.TxtDebuffs:SetWidth(self.TxtDebuffs.width)
		self.TxtDebuffs:SetPoint("TOP", UIParent, "TOP", 0, -30)
		self.TxtDebuffs["growth-y"] = "DOWN"
		self.TxtDebuffs.filter = false
		self.TxtDebuffs.bgTexture = bartex
		self.TxtDebuffs.CustomFilter = auraFilter

		--
		-- Buffs
		--
		self.TxtBuffs = CreateFrame("Frame", nil, self)
		self.TxtBuffs.height = 20
		self.TxtBuffs.width = 200
		self.TxtBuffs.spacing = 2
		self.TxtBuffs.num = 10
		self.TxtBuffs.fontSize = 11
		self.TxtBuffs.labelFont = font
		self.TxtBuffs.initialAnchor = "TOP"
		self.TxtBuffs:SetHeight((self.TxtBuffs.height + self.TxtBuffs.spacing)* self.TxtBuffs.num - self.TxtBuffs.spacing)
		self.TxtBuffs:SetWidth(self.TxtBuffs.width)
		self.TxtBuffs:SetPoint("TOPRIGHT", UIParent, "BOTTOMRIGHT", -5, 850)
		self.TxtBuffs["growth-y"] = "DOWN"
		self.TxtBuffs.filter = false
		self.TxtBuffs.bgTexture = bartex
		self.TxtBuffs.CustomFilter = auraFilter

		--
		-- Resting
		--
		self.Resting = self.Health:CreateTexture(nil, "OVERLAY")
		self.Resting:SetHeight(32)
		self.Resting:SetWidth(32)
		self.Resting:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 36, -30)

		--
		-- PvP
		--
		self.PvP = self.Health:CreateTexture(nil, "OVERLAY")
		self.PvP:SetHeight(48)
		self.PvP:SetWidth(48)
		self.PvP:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 4, -32)

	end

	-- ------------------------------------
	-- pet
	-- ------------------------------------
	if unit=="pet" then
		if playerClass=="HUNTER" then
			self.Health.colorReaction = false
			self.Health.colorClass = false
			self.Health.colorHappiness = true
		end
	end

	-- ------------------------------------
	-- target
	-- ------------------------------------
	if unit=="target" then
		self.Health.colorClass = false

		--
		-- combo points
		--
		if(playerClass=="ROGUE" or playerClass=="DRUID") then
			self.CPoints = self:CreateFontString(nil, "OVERLAY")
			self.CPoints:SetPoint("RIGHT", self, "LEFT", -10, 0)
			self.CPoints:SetFont(font, 38, "OUTLINE")
			self.CPoints:SetTextColor(0, 0.81, 1)
			self.CPoints:SetShadowOffset(1, -1)
			self.CPoints:SetJustifyH"RIGHT"
		end

		--
		-- raid target icons
		--
		self.RaidIcon = self.Health:CreateTexture(nil, "OVERLAY")
		self.RaidIcon:SetHeight(24)
		self.RaidIcon:SetWidth(24)
		self.RaidIcon:SetPoint("RIGHT", self, 30, 0)
		self.RaidIcon:SetTexture"Interface\\TargetingFrame\\UI-RaidTargetingIcons"

		--
		-- buffs
		--
		self.Buffs = CreateFrame("Frame", nil, self) -- buffs
		self.Buffs.size = 22
		self.Buffs:SetHeight(self.Buffs.size)
		self.Buffs:SetWidth(self.Buffs.size * 5)
		self.Buffs:SetPoint("BOTTOMLEFT", self, "TOPLEFT", -2, 15)
		self.Buffs.initialAnchor = "BOTTOMLEFT"
		self.Buffs["growth-y"] = "TOP"
		self.Buffs.num = 20
		self.Buffs.spacing = 2
		self.Buffs.PostCreateIcon = auraIcon

		--
		-- debuffs
		--
		self.Debuffs = CreateFrame("Frame", nil, self)
		self.Debuffs.size = 30
		self.Debuffs:SetHeight(self.Debuffs.size)
		self.Debuffs:SetWidth(self.Debuffs.size * 9)
		self.Debuffs:SetPoint("TOPLEFT", self, "BOTTOMLEFT", -2, -6)
		self.Debuffs.initialAnchor = "TOPLEFT"
		self.Debuffs["growth-y"] = "DOWN"
		self.Debuffs.filter = "HARMFUL|PLAYER"
		self.Debuffs.showDebuffType = true
		self.Debuffs.num = 40
		self.Debuffs.spacing = 2
		self.Debuffs.PostCreateIcon = auraIcon
	end

	-- ------------------------------------
	-- target of target and focus
	-- ------------------------------------
	if unit=="targettarget" or unit=="focus" or unit=="mouseover" or unit=="mouseovertarget" then
		--
		-- raid target icons
		--
		self.RaidIcon = self.Health:CreateTexture(nil, "OVERLAY")
		self.RaidIcon:SetHeight(16)
		self.RaidIcon:SetWidth(16)
		self.RaidIcon:SetPoint("RIGHT", self, 0, 9)
		self.RaidIcon:SetTexture"Interface\\TargetingFrame\\UI-RaidTargetingIcons"
	end

	-- Clip name if needed
	self.InfoLeft:SetWidth(settings["width"]*0.75)

	-- ------------------------------------
	-- boss frames
	-- ------------------------------------
	if unit:match("boss") then
		self.Health.colorClass = false

		--
		-- raid target icons
		--
		self.RaidIcon = self.Health:CreateTexture(nil, "OVERLAY")
		self.RaidIcon:SetHeight(24)
		self.RaidIcon:SetWidth(24)
		self.RaidIcon:SetPoint("RIGHT", self, 30, 0)
		self.RaidIcon:SetTexture"Interface\\TargetingFrame\\UI-RaidTargetingIcons"
	end

	return self
end

-- ------------------------------------------------------------------------
-- spawning the frames
-- ------------------------------------------------------------------------

--
-- normal frames
--
StyleSettings = {
	["Dys"] = {
		["width"] = 250,
		["height"] = 27,
		["healthbar-height"] = 15.5,
		["have-powerbar"] = true,
		["powerbar-height"] = 10,
		["fontsize"] = 15,
	},
	["Dys - medium"] = {
		["width"] = 180,
		["height"] = 20,
		["healthbar-height"] = 15,
		["have-powerbar"] = true,
		["powerbar-height"] = 3,
		["fontsize"] = 13,
	},
	["Dys - small"] = {
		["width"] = 120,
		["height"] = 18,
		["healthbar-height"] = 18,
		["fontsize"] = 12,
	}
}

local RegisterStyle = function (name)
	oUF:RegisterStyle(name, setmetatable(StyleSettings[name], {__call = func}))
end

RegisterStyle("Dys")
RegisterStyle("Dys - medium")
RegisterStyle("Dys - small")

oUF:Factory(
	function (self)
		self:SetActiveStyle("Dys")

		local player = self:Spawn("player", "oUF_Player")
		player:SetPoint("CENTER", -300, -260)

		local target = self:Spawn("target", "oUF_Target")
		target:SetPoint("CENTER", 300, -260)

		local focustarget = self:Spawn("focustarget", "oUF_FocusTarget")
		focustarget:SetPoint("TOPRIGHT", focus, "BOTTOMRIGHT", 0, -60)

		self:SetActiveStyle("Dys - small")

		local pet = self:Spawn("pet", "oUF_Pet")
		pet:SetPoint("BOTTOMLEFT", player, 0, -30)
		local tot = self:Spawn("targettarget", "oUF_TargetTarget")
		tot:SetPoint("TOPRIGHT", target, 0, 35)
		local focus = self:Spawn("focus", "oUF_Focus")
		focus:SetPoint("BOTTOMRIGHT", player, 0, -30)

		self:SetActiveStyle("Dys - medium")

		local bosses = {}
		for i = 1, MAX_BOSS_FRAMES do
			bosses[i] = self:Spawn("boss"..i, "oUF_Boss" .. i)
			if i == 1 then
				bosses[i]:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", 5, 700)
			else
				bosses[i]:SetPoint("TOP", bosses[i-1], "BOTTOM", 0, -15)
			end
		end
	end )
