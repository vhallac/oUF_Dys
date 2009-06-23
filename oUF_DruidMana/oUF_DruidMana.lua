if select(2, UnitClass('player')) ~= 'DRUID' then return end

local LDM = LibStub('LibDruidMana-1.0')

local function UpdateElement(bar, min, max)
	bar:SetMinMaxValues(0, max)
	bar:SetValue(min)

	if(bar.text) then
		if(min ~= max) then
			bar.text:SetFormattedText('%d%%', math.floor(min / max * 100))
		else
			bar.text:SetText()
		end
	end
end

function oUF:UNIT_DISPLAYPOWER(event, unit)
	if(self.unit == unit) then
		if(self.DruidMana) then
			if(UnitPowerType(unit) ~= 0) then
				self.DruidMana:Show()
			else
				self.DruidMana:Hide()
			end
		end
	end
	-- hook so oUF still gets the update
	oUF.UNIT_MAXMANA(self, event, unit)
end

LDM:AddListener(function(curMana, maxMana)
	for _, obj in ipairs(oUF.objects) do
		if(obj.DruidMana) then
			UpdateElement(obj.DruidMana, curMana, maxMana)
		end
	end
end)

oUF:RegisterInitCallback(function(self)
	if(self.DruidMana) then
		-- hide bar on load, LDM wont have values anyways
		self.DruidMana:Hide()
	end
end)