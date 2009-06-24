From the site:

Use this instead:


local function PreUpdatePower(self, event, unit)
	ifi(self.unit ~= 'player') then return end

	local _, powertype = UnitPowerType('player')
	local min = UnitPower('player', SPELL_POWER_MANA)
	local max = UnitPowerMax('player', SPELL_POWER_MANA)

	self.DruidMana:SetMinMaxValues(0, max)
	self.DruidMana:SetValue(min)

	if(min ~= max) then
		self.DruidMana.Text:SetFormattedText('%d%%', math.floor(min / max * 100))
	else
		self.DruidMana.Text:SetText()
	end

	self.DruidMana:SetAlpha((powertype ~= 0) and 1 or 0)
	self.DruidMana.Text:SetAlpha((powertype ~= 0) and 1 or 0)
end


From ouf/elements/power:


	Functions that can be overridden from within a layout:
	 - :PreUpdatePower(event, unit)
	 - :OverrideUpdatePower(event, unit, bar, min, max) - Setting this function
	 will disable the above color settings.
	 - :PostUpdatePower(event, unit, bar, min, max)
