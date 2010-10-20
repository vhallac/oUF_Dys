-- Pick up the global oUF
local parent, ns = ...
local oUF = ns.oUF
if not oUF then return end

local VISIBLE = 1
local HIDDEN = 0

local UpdateTooltip = function(self)
	GameTooltip:SetUnitAura(self.parent:GetParent().unit, self:GetID(), self.filter)
end

local OnEnter = function(self)
	if(not self:IsVisible()) then return end

	GameTooltip:SetOwner(self, "ANCHOR_BOTTOMRIGHT")
	self:UpdateTooltip()
end

local OnLeave = function()
	GameTooltip:Hide()
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
	return nextUpdate + 0.2 -- Check at least 200ms later than turn-over time
end

local AuraOnUpdate = function(self, elapsed)
	local curTime = GetTime()
	if curTime < self.nextUpdate then return end
	self.nextUpdate = UpdateCd(self.cd, self.endTime - curTime) + curTime
end

local createTxtAura = function(auras, index, filter)
	local button = CreateFrame("Button", nil, auras, "SecureActionButtonTemplate")
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

	button.UpdateTooltip = UpdateTooltip
	button:SetScript("OnEnter", OnEnter)
	button:SetScript("OnLeave", OnLeave)

	local unit = auras.__owner.unit
	if(unit == 'player') then
		button:SetAttribute("unit", unit)
		button:SetAttribute("index", index)
		button:SetAttribute("filter", filter)
		button:SetAttribute("type2", "cancelaura")
	end

	table.insert(auras, button)

	button.parent = auras

	button.icon = icon
	button.count = count
	button.label = label
	button.cd = cd
	button.overlay = overlay

	if(auras.PostCreateTxtAura) then auras:PostCreateTxtAura(button) end

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

local updateAura = function(unit, auras, index, offset, filter, isDebuff, max)
--	if(index == 0) then index = max end

	local name, rank, texture, count, dtype, duration, endTime, caster, isStealable, shouldConsolidate, spellId = UnitAura(unit, index, filter)
	if(name) then
		local aura = auras[index + offset]
		if(not aura) then
			aura = (auras.CreateTxtAura or createTxtAura) (auras, index, filter)
		end

		local show = (auras.CustomFilter or customFilter) (auras, unit, aura, name, rank, texture, count, dtype, duration, endTime, caster, isStealable, shouldConsolidate, spellId)
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

			if(auras.PostUpdateTxtAura) then
				auras:PostUpdateTxtAura(unit, icon, index, offset)
			end

			return VISIBLE
		else
			-- Hide the icon in-case we are in the middle of the stack.
			aura:Hide()

			return HIDDEN
		end
	end
end

local SetPosition = function(auras, x)
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

local filterAuras = function(unit, auras, filter, limit, isDebuff, offset, dontHide)
	if (not offset) then offset = 0 end
	local index = 1
	local visible = 0
	while(visible < limit) do
		local result = updateAura(unit, auras, index, offset, filter, isDebuff)
		if (not result) then
			break
		elseif (result == VISIBLE) then
			visible = visible + 1
		end
		index = index + 1
	end

	if (not dontHide) then
		for i = offset + index, #auras do
			auras[i]:Hide()
		end
	end

	return visible, index - 1
end

local Update = function(self, event, unit)
	if self.unit ~= unit  then return end

	local auras, buffs, debuffs = self.TxtAuras, self.TxtBuffs, self.TxtDebuffs

	if auras then
		if(auras.PreUpdate) then auras:PreUpdate(unit) end

		local numBuffs = auras.numBuffs or 32
		local numDebuffs = auras.numDebuffs or 40
		local max = debuffs + buffs

		local visibleBuffs, offset = filterAuras(unit, auras,
												 auras.buffFilter or auras.filter or 'HELPFUL',
												 numBuffs, nil, 0, true)
		auras.visibleBuffs = visibleBuffs

		auras.visibleDebuffs =  filterAuras(unit, auras,
											auras.debuffFilter or auras.filter or 'HARMFUL',
											numDebuffs, true, offset, false)
		auras.visibleAuras = auras.visibleBuffs + auras.visibleDebuffs

		if auras.PreSetPosition then auras:PreSetPosition(max) end
		(auras.SetPosition or SetPosition) (auras, max)

		if auras.PostUpdate then auras:PostUpdate(unit) end
	end

	if buffs then
		if(buffs.PreUpdate) then buffs:PreUpdate(unit) end

		local numBuffs = buffs.num or 32
		buffs.visibleBuffs = filterAuras(unit, buffs,
										 buffs.filter or "HELPFUL",
										 numBuffs, false, 0, false)

		if buffs.PreSetPosition then buffs:PreSetPosition(max) end
		(buffs.SetPosition or SetPosition) (buffs, numBuffs)

		if buffs.PostUpdate then buffs:PostUpdate(unit) end
	end

	if debuffs then
		if(debuffs.PreUpdate) then debuffs:PreUpdate(unit) end

		local numDebuffs = debuffs.num or 40
		buffs.visibleDebuffs = filterAuras(unit, debuffs,
										   debuffs.filter or "HARMFUL",
										   numDebuffs, true, 0, false)

		if debuffs.PreSetPosition then debuffs:PreSetPosition(max) end
		(debuffs.SetPosition or SetPosition) (debuffs, numDebuffs)

		if debuffs.PostUpdate then debuffs:PostUpdate(unit) end
	end
end

local ForceUpdate = function(element)
	return Update(element.__owner, 'ForceUpdate', element.__owner.unit)
end

local Enable = function(self)
	if(self.TxtBuffs or self.TxtDebuffs or self.TxtAuras) then
		self:RegisterEvent("UNIT_AURA", Update)

		local buffs = self.TxtBuffs
		if(buffs) then
			buffs.__owner = self
			buffs.ForceUpdate = ForceUpdate
		end

		local debuffs = self.TxtDebuffs
		if(debuffs) then
			debuffs.__owner = self
			debuffs.ForceUpdate = ForceUpdate
		end

		local auras = self.TxtAuras
		if(auras) then
			auras.__owner = self
			auras.ForceUpdate = ForceUpdate
		end

		return true
	end
end

local Disable = function(self)
	if(self.TxtBuffs or self.TxtDebuffs or self.TxtAuras) then
		self:UnregisterEvent("UNIT_AURA", Update)
	end
end

oUF:AddElement('TxtAura', Update, Enable, Disable)
