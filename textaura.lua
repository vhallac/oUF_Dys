--[[
	Elements handled: .Auras, .Buffs, .Debuffs

	Shared:
	 - spacing: Padding between aura icons. (Default: 0)
	 - width: Width of the bar (default: 100)
	 - height: Height of the bar (and size of the aura icons). (Default: 16)
	 - initialAnchor: Initial anchor in the aura frame. (Default: "BOTTOMLEFT")
	 - onlyShowPlayer: Only display icons casted by the player. (Default: nil)
	 - growth-y: Growth direction, affected by initialAnchor. (Default: "RIGHT")
	 - disableCooldown: Disable the Cooldown Spiral on the Aura Icons. (Default: nil)
	 - filter: Expects a string with filter. See the UnitAura[1] documentation for
		more information.
	 - bgTexture: Background texture name
	 - fontSize : Font size, in points (default: height - 2)
	 - labelFont : Font used for the label (default: "Fonts\\ARIALN.TTF")
	 - cdFond: Font used for duration countdown (default: "Fonts\\ARIALN.TTF")

	.Auras only:
	 - gap: Adds a empty icon to separate buffs and debuffs. (Default: nil)
	 - numBuffs: The maximum number of buffs that should be shown. (Default: 32)
	 - numDebuffs: The maximum number of debuffs that should be shown. (Default: 40)
	 - buffFilter: See filter on Shared. (Default: "HELPFUL")
	 - debuffFilter: See filter on Shared. (Default: "HARMFUL")
	 - Variables set by .Auras:
		 - visibleBuffs: Number of currently visible buff icons.
		 - visibleDebuffs: Number of currently visible debuff icons.
		 - visibleAuras: Total number of currently visible buffs + debuffs.

	.Buffs only:
	 - num: The maximum number of buffs that should be shown. (Default: 32)
	 - Variables set by .Buffs:
		 - visibleBuffs: Number of currently visible buff icons.

	.Debuffs only:
	 - num: The maximum number of debuffs that should be shown. (Default: 40)
	 - Variables set by .Debuffs:
		 - visibleDebuffs: Number of currently visible debuff icons.

	Functions that can be overridden from within a layout:
	 - :PostCreateTxtAuraIcon(icon, icons, index, isDebuff)
	 - :CreateTxtAuraIcon(icons, index, isDebuff)
	 - :PostUpdateTxtAuraIcon(icons, unit, icon, index, offset, filter, isDebuff)
	 - :PreUpdateTxtAura(event, unit)
	 - :PreTxtAuraSetPosition(auras, max)
	 - :PreTxtAuraSetPosition(auras, max)
	 - :PostUpdateTxtAura(event, unit)

	[1] http://www.wowwiki.com/API_UnitAura
--]]
local parent = debugstack():match[[\AddOns\(.-)\]]
local global = GetAddOnMetadata(parent, 'X-oUF')
assert(global, 'X-oUF needs to be defined in the parent add-on.')
local oUF = _G[global]

local OnEnter = function(self)
	if(not self:IsVisible()) then return end

	GameTooltip:SetOwner(self, "ANCHOR_BOTTOMRIGHT")
	GameTooltip:SetUnitAura(self.frame.unit, self:GetID(), self.filter)
end

local OnLeave = function()
	GameTooltip:Hide()
end

-- We don't really need to validate much here as the filter should prevent us
-- from doing something we shouldn't.
local OnClick = function(self)
	CancelUnitBuff(self.frame.unit, self:GetID(), self.filter)
end

local UpdateCd = function(cd, timeLeft)
	local timehr = floor(timeLeft/3600)
	timeLeft = timeLeft - timehr * 3600
	local timemin = floor(timeLeft/60)
	timeLeft = timeLeft - timemin * 60
	local nextmin = 60 - timeLeft
	local timesec = floor(timeLeft)
	local timeLeft = timeLeft - timesec
	local nextsec = 1 - timeLeft
	local timestr, nextUpdate
	if (timehr > 0) then
		timestr = tostring(timehr) .. "h" .. tostring(timemin) .. "m"
		nextUpdate = nextmin -- update every min
	elseif (timemin >= 10) then
		timestr = tostring(timemin) .. "m"
		nextUpdate = nextmin -- Update every minute
	elseif (timemin > 0) then
		timestr = tostring(timemin) .. "m" .. tostring(timesec) .. "s"
		nextUpdate = nextsec -- Update every second
	else
		timestr = tostring(timesec) .. "s"
		nextUpdate = 1 -- Update every second
		nextUpdate = nextsec -- Update every second
	end
	cd:SetText(timestr)
	return nextUpdate + 0.2 -- Check at least 50ms later than turn-over time
end

local AuraOnUpdate = function(self, elapsed)
	local curTime = GetTime()
	if curTime < self.nextUpdate then return end
	self.nextUpdate = UpdateCd(self.cd, self.endTime - curTime) + curTime
end

local createAuraIcon = function(self, auras, index, debuff)
	local button = CreateFrame("Button", nil, auras)
	button:EnableMouse(true)
	button:RegisterForClicks'RightButtonUp'

	local height = auras.height or 16
	local labelFont = auras.labelFont or "Fonts\\ARIALN.TTF"
	local cdFont = auras.cdFont or "Fonts\\ARIALN.TTF"
	local fontSize = auras.fontSize or (height - 2)
	button:SetWidth(auras.width or 100)
	button:SetHeight(height)

	local icon = button:CreateTexture(nil, "OVERLAY")
	icon:SetPoint("TOPLEFT", button, "TOPLEFT", 0, 0)
	icon:SetPoint("BOTTOMRIGHT", button, "BOTTOMLEFT", height, 0)

	local count = button:CreateFontString(nil, "OVERLAY")
	count:SetFontObject(NumberFontNormal)
	count:SetPoint("BOTTOMLEFT", icon, "BOTTOMLEFT", 1, 0)

	local cd = button:CreateFontString(nil, "OVERLAY")
	cd:SetFont(cdFont, fontSize, "OUTLINE")
	cd:SetPoint("RIGHT", button, "RIGHT", -1, 0)
	cd:SetWidth(80)
	cd:SetJustifyH("RIGHT")

	local label = button:CreateFontString(nil, "OVERLAY")
	label:SetFont(labelFont, fontSize, "OUTLINE")
	label:SetPoint("LEFT", icon, "RIGHT", 5, -1)
	label:SetPoint("RIGHT", cd, "LEFT", -5, 0)
	label:SetJustifyH("LEFT")

	local overlay = button:CreateTexture(nil, "BACKGROUND")
	overlay:SetTexture(auras.bgTexture or [[Interface\TargetingFrame\UI-StatusBar]])
	overlay:SetAllPoints(button)
--	overlay:SetTexCoord(.296875, .5703125, 0, .515625)

	button:SetScript("OnEnter", OnEnter)
	button:SetScript("OnLeave", OnLeave)

	if(self.unit == 'player') then
		button:SetScript('OnClick', OnClick)
	end

	table.insert(auras, button)

	button.parent = auras
	button.frame = self
	button.debuff = debuff

	button.icon = icon
	button.count = count
	button.label = label
	button.cd = cd
	button.overlay = overlay

	if(self.PostCreateTxtAuraIcon) then self:PostCreateTxtAuraIcon(button, auras, index, debuff) end

	return button
end

local customFilter = function(auras, unit, icon, name, rank, texture, count, dtype, duration, timeLeft, caster)
	local isPlayer

	if(caster == 'player' or caster == 'vehicle') then
		isPlayer = true
	end

	if((auras.onlyShowPlayer and isPlayer) or (not auras.onlyShowPlayer and name)) then
		icon.isPlayer = isPlayer
		icon.owner = caster
		return true
	end
end

local updateAura = function(self, unit, auras, index, offset, filter, isDebuff, max)
	if(index == 0) then index = max end

	local name, rank, texture, count, dtype, duration, endTime, caster = UnitAura(unit, index, filter)
	if(name) then
		local aura = auras[index + offset]
		if(not aura) then
			aura = (self.CreateTxtAuraIcon or createAuraIcon) (self, auras, index, isDebuff)
		end

		local show = (self.CustomAuraFilter or customFilter) (auras, unit, aura, name, rank, texture, count, dtype, duration, timeLeft, caster)
		if(show) then
			-- We might want to consider delaying the creation of an actual cooldown
			-- object to this point, but I think that will just make things needlessly
			-- complicated.
			local cd = aura.cd
			if(cd and not auras.disableCooldown) then
				if(duration and duration > 0) then
					aura.endTime = endTime
					local curTime = GetTime()
					aura.nextUpdate = UpdateCd(aura.cd, aura.endTime - curTime) + curTime
					aura:SetScript("OnUpdate", AuraOnUpdate)
					cd:Show()
				else
					cd:Hide()
				end
			end

			if((isDebuff and auras.showDebuffType) or (not isDebuff and auras.showBuffType) or auras.showType) then
				local color = DebuffTypeColor[dtype] or DebuffTypeColor.none

				aura.overlay:SetVertexColor(color.r, color.g, color.b)
				aura.overlay:Show()
			else
				aura.overlay:SetVertexColor(.5, .5, 0)
				aura.overlay:Show()
--				aura.overlay:Hide()
			end

			aura.icon:SetTexture(texture)
			aura.count:SetText((count > 1 and count))
			aura.label:SetText(name)

			aura.filter = filter
			aura.debuff = isDebuff

			aura:SetID(index)
			aura:Show()

			if(self.PostUpdateTxtAuraIcon) then
				self:PostUpdateTxtAuraIcon(auras, unit, icon, index, offset, filter, isDebuff)
			end
		else
			-- Hide the icon in-case we are in the middle of the stack.
			aura:Hide()
		end

		return true
	end
end

local SetTxtAuraPosition = function(self, auras, x)
	if(auras and x > 0) then
		local col = 0
		local row = 0
		local spacing = auras.spacing or 0
		local gap = auras.gap
		local height = (auras.height or 16) + spacing
		local anchor = auras.initialAnchor or "BOTTOMLEFT"
		local growthy = (auras["growth-y"] == "DOWN" and -1) or 1
		local rows = math.floor(auras:GetHeight() / height + .5)

		for i = 1, x do
			local button = auras[i]
			if(button and button:IsShown()) then
				if(gap and button.debuff) then
				end

				button:ClearAllPoints()
				button:SetPoint(anchor, auras, anchor, 0, row * height * growthy)
				row = row + 1
			end
		end
	end
end

local Update = function(self, event, unit)
	if(self.unit ~= unit) then return end
	if(self.PreUpdateTxtAura) then self:PreUpdateTxtAura(event, unit) end

	local auras, buffs, debuffs = self.TxtAuras, self.TxtBuffs, self.TxtDebuffs

	--[[
	if(auras) then
		local buffs = auras.numBuffs or 32
		local debuffs = auras.numDebuffs or 40
		local max = debuffs + buffs

		local visibleBuffs, visibleDebuffs = 0, 0
		for index = 1, max do
			if(index > buffs) then
				if(updateIcon(self, unit, auras, index % debuffs, visibleBuffs, auras.debuffFilter or auras.filter or 'HARMFUL', true, debuffs)) then
					visibleDebuffs = visibleDebuffs + 1
				end
			else
				if(updateIcon(self, unit, auras, index, 0, auras.buffFilter or  auras.filter or 'HELPFUL')) then
					visibleBuffs = visibleBuffs + 1
				end
			end
		end

		local index = visibleBuffs + visibleDebuffs + 1
		while(auras[index]) do
			auras[index]:Hide()
			index = index + 1
		end

		auras.visibleBuffs = visibleBuffs
		auras.visibleDebuffs = visibleDebuffs
		auras.visibleAuras = visibleBuffs + visibleDebuffs

		if(self.PreTxtAuraSetPosition) then self:PreTxtAuraSetPosition(auras, max) end
		self:SetTxtAuraPosition(auras, max)
	end

	if(buffs) then
		local filter = buffs.filter or 'HELPFUL'
		local max = buffs.num or 32
		local visibleBuffs = 0
		for index = 1, max do
			if(not updateIcon(self, unit, buffs, index, 0, filter)) then
				max = index - 1

				while(buffs[index]) do
					buffs[index]:Hide()
					index = index + 1
				end
				break
			end

			visibleBuffs = visibleBuffs + 1
		end

		buffs.visibleBuffs = visibleBuffs

		if(self.PreTxtAuraSetPosition) then self:PreTxtAuraSetPosition(buffs, max) end
		self:SetTxtAuraPosition(buffs, max)
	end
]]--
	if(debuffs) then
		local filter = debuffs.filter or 'HARMFUL'
		local max = debuffs.num or 40
		local visibleDebuffs = 0
		for index = 1, max do
			if(not updateAura(self, unit, debuffs, index, 0, filter, true)) then
				max = index - 1

				while(debuffs[index]) do
					debuffs[index]:Hide()
					index = index + 1
				end
				break
			end

			visibleDebuffs = visibleDebuffs + 1
		end
		debuffs.visibleDebuffs = visibleDebuffs

		if(self.PreTxtAuraSetPosition) then self:PreTxtAuraSetPosition(debuffs, max) end
		self:SetTxtAuraPosition(debuffs, max)
	end

	if(self.PostUpdateTxtAura) then self:PostUpdateTxtAura(event, unit) end
end

local Enable = function(self)
	if(self.TxtBuffs or self.TxtDebuffs or self.TxtAuras) then
		if(not self.SetTxtAuraPosition) then
			self.SetTxtAuraPosition = SetTxtAuraPosition
		end
		self:RegisterEvent("UNIT_AURA", Update)

		return true
	end
end

local Disable = function(self)
	if(self.TxtBuffs or self.TxtDebuffs or self.TxtAuras) then
		self:UnregisterEvent("UNIT_AURA", Update)
	end
end

oUF:AddElement('TxtAura', Update, Enable, Disable)
