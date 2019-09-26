local AceEvent = LibStub:GetLibrary("AceEvent-3.0");
local helper = LibStub:NewLibrary("ZoneHelper-1.0", 1);
local isWoWClassic = select(4, GetBuildInfo()) < 20000;

local listeners = {};
local previousSubZone = GetMinimapZoneText();
local previousZone = GetRealZoneText();
local function updateListeners()
    local subZone = GetMinimapZoneText();
    local zone = GetRealZoneText();

    if previousSubZone == subZone and previousZone == zone then return end

    for i, listener in ipairs(listeners) do
        listener({
            previousSubZone = previousSubZone,
            previousZone = previousZone,
            subZone = subZone,
            zone = zone
        });
    end

    previousSubZone = subZone;
    previousZone = zone;
end

function helper:OnZoneChanged(listener)
    tinsert(listeners, listener);
end

AceEvent.RegisterEvent(helper, "ZONE_CHANGED", updateListeners);
AceEvent.RegisterEvent(helper, "ZONE_CHANGED_INDOORS", updateListeners);
AceEvent.RegisterEvent(helper, "ZONE_CHANGED_NEW_AREA", updateListeners);
