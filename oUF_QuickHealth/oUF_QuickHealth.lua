local eventFrame = CreateFrame("Frame");
local QuickHealth = LibStub("LibQuickHealth-1.0");
local _G = getfenv(0);
local oUF = oUF;
local units = oUF.units;
local objects = oUF.objects

-- Map that will contain the units of every guid
local GUIDMap = {};

-- This function will regenerate the map
local function RemapGUIDMap()
	for key in pairs(GUIDMap) do
		GUIDMap[key] = nil;
	end
	for unit in pairs(units) do
		local guid = UnitGUID(unit);
		if(guid) then
			if(not GUIDMap[guid]) then
				GUIDMap[guid] = {};
			end
			table.insert(GUIDMap[guid], unit)
		end
	end
end


-- env changement code taken from interruptus
local proxyEnv = {
	UnitHealth = function(...) return QuickHealth:UnitHealth(...); end,
}

setmetatable(proxyEnv, {
	__index    = _G,
	__newindex = function (t, k, v) _G[k] = v end,
})

local handlerTable = {};
eventFrame:SetScript("OnEvent", function(self, event, ...)
	handlerTable[event](handlerTable, ...);
end);

function handlerTable.PLAYER_LOGIN(self)
	oldEnv = getfenv(oUF.UNIT_HEALTH);
	QuickHealth.RegisterCallback(self, "HealthUpdated", function(event, GUID, newHealth)
		setfenv(oUF.UNIT_HEALTH, proxyEnv);
		local unitids = GUIDMap[GUID];
		if(unitids) then
			for i = 1, #unitids do
				local unit = unitids[i];
				for _, obj in ipairs(objects) do
					if(obj:IsShown()) then
						obj:UNIT_HEALTH("UNIT_HEALTH", unit)
					end
				end
			end
		end
		setfenv(oUF.UNIT_HEALTH, oldEnv);
	end);
end

-- Remap guids when party changed ONLY if we're not in a raid.
function handlerTable:PARTY_MEMBERS_CHANGED()
	if(GetNumRaidMembers() > 0) then return end
	RemapGUIDMap();
end

-- Remap guids when the raid roster gets updated.
handlerTable.RAID_ROSTER_UPDATE = RemapGUIDMap;
eventFrame:RegisterEvent("PARTY_MEMBERS_CHANGED");
eventFrame:RegisterEvent("RAID_ROSTER_UPDATE");
eventFrame:RegisterEvent("PLAYER_LOGIN");
