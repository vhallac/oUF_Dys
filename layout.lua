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

-- ------------------------------------------------------------------------
-- local horror
-- This speeds up the name lookups, but messes with function/variable patching.
-- ------------------------------------------------------------------------
local select = select
local UnitClass = UnitClass
local UnitIsDead = UnitIsDead
local UnitIsPVP = UnitIsPVP
local UnitIsGhost = UnitIsGhost
local UnitIsPlayer = UnitIsPlayer
local UnitReaction = UnitReaction
local UnitIsConnected = UnitIsConnected
local UnitCreatureType = UnitCreatureType
local UnitClassification = UnitClassification
local UnitReactionColor = UnitReactionColor
local RAID_CLASS_COLORS = RAID_CLASS_COLORS
-- Pick up the global, which is controlled by X-oUF of the TOC file.
local oUF = oUF_Dys

-- ------------------------------------------------------------------------
-- font, fontsize and textures
-- ------------------------------------------------------------------------
local font = "Interface\\AddOns\\oUF_Dys\\fonts\\font.ttf"
local upperfont = "Interface\\AddOns\\oUF_Dys\\fonts\\upperfont.ttf"
local fontsize = 15
local smallfontsize = 12
local bartex = "Interface\\AddOns\\oUF_Dys\\textures\\statusbar"
local bufftex = "Interface\\AddOns\\oUF_Dys\\textures\\border"
local highlighttex = "Interface\\AddOns\\oUF_Dys\\textures\\statusbar"
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
	local cunit = self.unit:gsub("(.)", string.upper, 1)

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
local updateHealth = function(self, event, unit, bar, min, max)
	if(UnitIsDead(unit) or UnitIsGhost(unit)) then
		bar:SetValue(0)
	end
end

-- ------------------------------------------------------------------------
-- power update
-- ------------------------------------------------------------------------
local function PreUpdatePower(self, event, unit)
	if self.unit ~= 'player' then return end

	local cur = UnitPower('player', SPELL_POWER_MANA)
	local max = UnitPowerMax('player', SPELL_POWER_MANA)

	self.DruidMana:SetMinMaxValues(0, max)
	self.DruidMana:SetValue(cur)

	self.DruidMana.Text:SetFormattedText('%d%%', math.floor(cur / max * 100))

	local powertype = UnitPowerType('player')
	self.DruidMana:SetAlpha((powertype ~= 0) and 1 or 0)
end

local PostUpdatePower = function(self, event, unit, bar, min, max)
	if UnitIsPlayer(unit) and min ~=0 and (UnitIsDead(unit) or UnitIsGhost(unit)) then
		bar:SetValue(0)
	end
end

-- ------------------------------------------------------------------------
-- aura reskin
-- ------------------------------------------------------------------------
local auraIcon = function(self, button, icons)
	icons.showDebuffType = true -- show debuff border type color

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
oUF.TagEvents["[dyscurhp]"] = "UNIT_HEALTH"
oUF.Tags["[dyscurhp]"] = function(u)
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
-- the layout starts here
-- ------------------------------------------------------------------------
local func = function(self, unit)
	self.menu = menu -- Enable the menus

	self:SetScript("OnEnter", UnitFrame_OnEnter)
	self:SetScript("OnLeave", UnitFrame_OnLeave)

	self:RegisterForClicks"anyup"
	self:SetAttribute("*type2", "menu")

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
	self.Health:SetHeight(19) -- Custom height
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
	self.PostUpdateHealth = updateHealth -- let the colors be

	--
	-- powerbar
	--
	self.Power = CreateFrame"StatusBar"
	self.Power:SetHeight(3)
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
	self.PostUpdatePower = PostUpdatePower

	--
	-- Info Line
	--
	self.InfoLeft = self.Health:CreateFontString(nil, "OVERLAY")
	self.InfoLeft:SetPoint("LEFT", self, 0, 15)
	self.InfoLeft:SetJustifyH("LEFT")
	self.InfoLeft:SetShadowOffset(1, -1)
	self.InfoRight = self.Health:CreateFontString(nil, "OVERLAY")
	self.InfoRight:SetPoint("RIGHT", self, 0, 15)
	self.InfoRight:SetJustifyH("RIGHT")
	self.InfoRight:SetShadowOffset(1, -1)
	if unit=="player" then
		self.InfoLeft:SetFont(font, fontsize, "OUTLINE")
		self.InfoRight:SetFont(font, fontsize, "OUTLINE")
		self:Tag(self.InfoLeft, "[curpp]")
		self:Tag(self.InfoRight, "[dyscurhp(.)][perhp(%)]")
	elseif unit=="target" then
		self.InfoLeft:SetFont(font, fontsize, "OUTLINE")
		self.InfoRight:SetFont(font, fontsize, "OUTLINE")
		self:Tag(self.InfoLeft, "[difficulty][level][shortclassification][( )raidcolor][name(|r)]")
		self:Tag(self.InfoRight, "[dyscurhp(.)][perhp(%)]")
	else
		self.InfoLeft:SetFont(font, smallfontsize, "OUTLINE")
		self.InfoRight:SetFont(font, smallfontsize, "OUTLINE")
		self:Tag(self.InfoLeft, "[raidcolor][name]")
		self:Tag(self.InfoRight, "[perhp(%)]")
	end

	-- ------------------------------------
	-- player
	-- ------------------------------------
	if unit=="player" then
		self:SetWidth(250)
		self:SetHeight(27)
		self.Health:SetHeight(15.5)
		self.Power:SetHeight(10)
		-- Check aggro, and update health color
		self.OverrideUpdateThreat = checkThreatSituation
		-- A texture or a frame is needed to activate threat module.
		-- We won't be using it to display anything, though.
		-- checkThreatSituation updates health bar color
		local threat = self.Health:CreateTexture(nil, "OVERLAY")
		self.Threat = threat

		if(playerClass=="DRUID") then
			self.PreUpdatePower = PreUpdatePower -- For Druid mana
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
		-- self.Spark.rtl = true -- Make the spark go from Right To Left instead
		-- self.Spark.manatick = true -- Show mana regen ticks outside FSR (like the energy ticker)
		-- self.Spark.highAlpha = 1 	-- What alpha setting to use for the FSR and energy spark
		-- self.Spark.lowAlpha = 0.25 -- What alpha setting to use for the mana regen ticker

		--
		-- oUF_BarFader
		--
		self.BarFade = true
		self.BarFadeAlpha = 0.2

		--
		-- debuffs
		--
		self.Debuffs = CreateFrame("Frame", nil, self)
		self.Debuffs.size = 30
		self.Debuffs:SetHeight(self.Debuffs.size)
		self.Debuffs:SetWidth(self.Debuffs.size * 9)
		self.Debuffs:SetPoint("TOPRIGHT", self.Health, "TOPLEFT", -3, 2)
		self.Debuffs.initialAnchor = "TOPRIGHT"
		self.Debuffs["growth-x"] = "LEFT"
		self.Debuffs["growth-y"] = "DOWN"
		self.Debuffs.filter = false
		self.Debuffs.num = 40
		self.Debuffs.spacing = 2

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
		self:SetWidth(120)
		self:SetHeight(18)
		self.Health:SetHeight(18)

		if playerClass=="HUNTER" then
			self.Health.colorReaction = false
			self.Health.colorClass = false
			self.Health.colorHappiness = true
		end

		--
		-- oUF_BarFader
		--
		self.BarFade = true
		self.BarFadeAlpha = 0.2
	end

	-- ------------------------------------
	-- target
	-- ------------------------------------
	if unit=="target" then
		self:SetWidth(250)
		self:SetHeight(27)
		self.Health:SetHeight(15.5)
		self.Power:SetHeight(10)

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
	end

	-- ------------------------------------
	-- target of target and focus
	-- ------------------------------------
	if unit=="targettarget" or unit=="focus" or unit=="mouseover" or unit=="mouseovertarget" then
		self:SetWidth(120)
		self:SetHeight(18)
		self.Health:SetHeight(18)
		self.Power:Hide()

		--
		-- raid target icons
		--
		self.RaidIcon = self.Health:CreateTexture(nil, "OVERLAY")
		self.RaidIcon:SetHeight(16)
		self.RaidIcon:SetWidth(16)
		self.RaidIcon:SetPoint("RIGHT", self, 0, 9)
		self.RaidIcon:SetTexture"Interface\\TargetingFrame\\UI-RaidTargetingIcons"

		--
		-- oUF_BarFader
		--
		if unit=="focus" then
			self.BarFade = true
			self.BarFadeAlpha = 0.2
		end
	end

	-- ------------------------------------
	-- player and target castbar
	-- ------------------------------------
	if(unit == 'player' or unit == 'target') then
		self.Castbar = CreateFrame('StatusBar', nil, self)
		self.Castbar:SetStatusBarTexture(bartex)

		if(unit == "player") then
			self.Castbar:SetStatusBarColor(1, 0.50, 0)
			self.Castbar:SetHeight(24)
			self.Castbar:SetWidth(260)

			self.Castbar:SetBackdrop({
				bgFile = "Interface\ChatFrame\ChatFrameBackground",
				insets = {top = -3, left = -3, bottom = -3, right = -3}})

			self.Castbar.SafeZone = self.Castbar:CreateTexture(nil,"ARTWORK")
			self.Castbar.SafeZone:SetTexture(bartex)
			self.Castbar.SafeZone:SetVertexColor(.75,.10,.10,.6)
			self.Castbar.SafeZone:SetPoint("TOPRIGHT")
			self.Castbar.SafeZone:SetPoint("BOTTOMRIGHT")

			self.Castbar:SetPoint('CENTER', UIParent, 'CENTER', playerCastBar_x, playerCastBar_y)

			--
			-- GCD spark
			--
			self.GCD = CreateFrame("Frame", nil, self)
			self.GCD:SetPoint('TOPLEFT', self.Castbar, 'BOTTOMLEFT')
			self.GCD:SetPoint('TOPRIGHT', self.Castbar, 'BOTTOMRIGHT')
			self.GCD:SetHeight(4)

			self.GCD.Spark = self.GCD:CreateTexture(nil, "OVERLAY")
			self.GCD.Spark:SetTexture("Interface\\CastingBar\\UI-CastingBar-Spark")
			self.GCD.Spark:SetBlendMode("ADD")
			self.GCD.Spark:SetHeight(10)
			self.GCD.Spark:SetWidth(10)
			self.GCD.Spark:SetPoint('BOTTOMLEFT', self.Title, 'BOTTOMLEFT', -5, -5)

			self.GCD.ReferenceSpellName = "Ice Lance"
		else
			self.Castbar:SetStatusBarColor(0.80, 0.01, 0)
			self.Castbar:SetHeight(24)
			self.Castbar:SetWidth(286)

			self.Castbar:SetBackdrop({
				bgFile = "Interface\ChatFrame\ChatFrameBackground",
				insets = {top = -3, left = -30, bottom = -3, right = -3}})

			self.Castbar.Icon = self.Castbar:CreateTexture(nil, 'OVERLAY')
			self.Castbar.Icon:SetPoint("RIGHT", self.Castbar, "LEFT", -3, 0)
			self.Castbar.Icon:SetHeight(24)
			self.Castbar.Icon:SetWidth(24)
			self.Castbar.Icon:SetTexCoord(0.1,0.9,0.1,0.9)

			self.Castbar:SetPoint('CENTER', UIParent, 'CENTER', targetCastBar_x, targetCastBar_y)
		end

		self.Castbar:SetBackdropColor(0, 0, 0, 0.5)

		self.Castbar.bg = self.Castbar:CreateTexture(nil, 'BORDER')
		self.Castbar.bg:SetAllPoints(self.Castbar)
		self.Castbar.bg:SetTexture(0, 0, 0, 0.6)

		self.Castbar.Text = self.Castbar:CreateFontString(nil, 'OVERLAY')
		self.Castbar.Text:SetPoint('LEFT', self.Castbar, 2, 0)
		self.Castbar.Text:SetFont(upperfont, 11, "OUTLINE")
		self.Castbar.Text:SetShadowOffset(1, -1)
		self.Castbar.Text:SetTextColor(1, 1, 1)
		self.Castbar.Text:SetJustifyH('LEFT')

		self.Castbar.Time = self.Castbar:CreateFontString(nil, 'OVERLAY')
		self.Castbar.Time:SetPoint('RIGHT', self.Castbar, -2, 0)
		self.Castbar.Time:SetFont(upperfont, 12, "OUTLINE")
		self.Castbar.Time:SetTextColor(1, 1, 1)
		self.Castbar.Time:SetJustifyH('RIGHT')
	end


	-- ------------------------------------
	-- party
	-- ------------------------------------
	if(self:GetParent():GetName():match"oUF_Party") then
		self:SetWidth(160)
		self:SetHeight(20)
		self.Health:SetHeight(15)
		self.Power:SetHeight(3)

		--
		-- debuffs
		--
		self.Debuffs = CreateFrame("Frame", nil, self)
		self.Debuffs.size = 20 * 1.3
		self.Debuffs:SetHeight(self.Debuffs.size)
		self.Debuffs:SetWidth(self.Debuffs.size * 5)
		self.Debuffs:SetPoint("LEFT", self, "RIGHT", 5, 0)
		self.Debuffs.initialAnchor = "TOPLEFT"
		self.Debuffs.filter = false
		self.Debuffs.showDebuffType = true
		self.Debuffs.spacing = 2
		self.Debuffs.num = 2 -- max debuffs

		--
		-- raid target icons
		--
		self.RaidIcon = self.Health:CreateTexture(nil, "OVERLAY")
		self.RaidIcon:SetHeight(24)
		self.RaidIcon:SetWidth(24)
		self.RaidIcon:SetPoint("LEFT", self, -30, 0)
		self.RaidIcon:SetTexture"Interface\\TargetingFrame\\UI-RaidTargetingIcons"
	end

	-- ------------------------------------
	-- raid
	-- ------------------------------------
	if(self:GetParent():GetName():match"oUF_Raid") then
		self:SetWidth(85)
		self:SetHeight(15)
		self.Health:SetHeight(15)
		self.Power:Hide()
		self.Health:SetFrameLevel(2)
		self.Power:SetFrameLevel(2)

		--
		-- oUF_DebuffHighlight support
		--
		self.DebuffHighlight = self.Health:CreateTexture(nil, "OVERLAY")
		self.DebuffHighlight:SetAllPoints(self.Health)
		self.DebuffHighlight:SetTexture("Interface\\AddOns\\oUF_Dys\\textures\\highlight.tga")
		self.DebuffHighlight:SetBlendMode("ADD")
		self.DebuffHighlight:SetVertexColor(0, 0, 0, 0)
		self.DebuffHighlightAlpha = 0.8
		self.DebuffHighlightFilter = true
	end

	--
	-- fading for party and raid
	--
	if(not unit) then -- fadeout if units are out of range
		self.Range = false -- put true to make party/raid frames fade out if not in your range
		self.inRangeAlpha = 1.0 -- what alpha if IN range
		self.outsideRangeAlpha = 0.5 -- the alpha it will fade out to if not in range
	end

	--
	-- custom aura textures
	--
	self.PostCreateAuraIcon = auraIcon
	self.SetAuraPosition = auraOffset

	if(self:GetParent():GetName():match"oUF_Party") then
		self:SetAttribute('initial-height', 20)
		self:SetAttribute('initial-width', 160)
	else
		self:SetAttribute('initial-height', height)
		self:SetAttribute('initial-width', width)
	end

	return self
end

-- ------------------------------------------------------------------------
-- spawning the frames
-- ------------------------------------------------------------------------

--
-- normal frames
--
oUF:RegisterStyle("Dys", func)

oUF:SetActiveStyle("Dys")
local player = oUF:Spawn("player", "oUF_Player")
player:SetPoint("CENTER", -300, -260)
local target = oUF:Spawn("target", "oUF_Target")
target:SetPoint("CENTER", 300, -260)
local pet = oUF:Spawn("pet", "oUF_Pet")
pet:SetPoint("BOTTOMLEFT", player, 0, -30)
local tot = oUF:Spawn("targettarget", "oUF_TargetTarget")
tot:SetPoint("TOPRIGHT", target, 0, 35)
local focus	= oUF:Spawn("focus", "oUF_Focus")
focus:SetPoint("BOTTOMRIGHT", player, 0, -30)
--[[ Dys: No need for this yet
local mouseover = oUF:Spawn("mouseover", "oUF_MO")
mouseover:SetPoint("BOTTOMLEFT", pet, 0, -30)
local mouseovertarget = oUF:Spawn("mouseovertarget", "oUF_MOT")
mouseovertarget:SetPoint("BOTTOMLEFT", focus, 0, -30)
]]--

--
-- party
--
local party	= oUF:Spawn("header", "oUF_Party")
party:SetManyAttributes("showParty", true, "yOffset", -15)
party:SetPoint("TOPLEFT", 35, -320)
party:Show()
party:SetAttribute("showRaid", false)

--[[
--
-- raid
--
local Raid = {}
for i = 1, NUM_RAID_GROUPS do
	local RaidGroup = oUF:Spawn("header", "oUF_Raid" .. i)
	RaidGroup:SetAttribute("groupFilter", tostring(i))
	RaidGroup:SetAttribute("showRaid", true)
	RaidGroup:SetAttribute("yOffset", -10)
	RaidGroup:SetAttribute("point", "TOP")
	RaidGroup:SetAttribute("showRaid", true)
	table.insert(Raid, RaidGroup)
	if i == 1 then
		RaidGroup:SetPoint("TOPLEFT", UIParent, 35, -35)
	else
		RaidGroup:SetPoint("TOPLEFT", Raid[i-1], "TOPRIGHT", 10, 0)
	end
	RaidGroup:Show()
end
]]--
--
-- party toggle in raid
--
local partyToggle = CreateFrame('Frame')
partyToggle:RegisterEvent('PLAYER_LOGIN')
partyToggle:RegisterEvent('RAID_ROSTER_UPDATE')
partyToggle:RegisterEvent('PARTY_LEADER_CHANGED')
partyToggle:RegisterEvent('PARTY_MEMBER_CHANGED')
partyToggle:SetScript('OnEvent', function(self)
	if(InCombatLockdown()) then
		self:RegisterEvent('PLAYER_REGEN_ENABLED')
	else
		self:UnregisterEvent('PLAYER_REGEN_DISABLED')
		if(HIDE_PARTY_INTERFACE == "1" and GetNumRaidMembers() > 0) then
			party:Hide()
		else
			party:Show()
		end
	end
end)
