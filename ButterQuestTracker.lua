local _, ns = ...

local QWH = LibStub("QuestWatchHelper-1.0");
local Tracker = LibStub("ButterQuestTracker/Tracker");

ButterQuestTracker = LibStub("AceAddon-3.0"):NewAddon("ButterQuestTracker", "AceEvent-3.0");
local BQT = ButterQuestTracker;

function BQT:OnInitialize()
    self.db = LibStub("AceDB-3.0"):New("ButterQuestTrackerConfig", ns.CONSTANTS.DB_DEFAULTS, true);
    self.hiddenContainers = {}
    
    -- TODO: This is for backwards compatible support of the SavedVariables
    -- Remove this in v2.0.0
    if ButterQuestTrackerCharacterConfig then
        for key, value in pairs(ButterQuestTrackerCharacterConfig) do
            self.db.char[key] = value;
            ButterQuestTrackerCharacterConfig[key] = nil;
        end
    end
    -- END TODO
end

function BQT:OnEnable()
    QWH:BypassWatchLimit(self.db.char.MANUALLY_TRACKED_QUESTS);
    QWH:KeepHidden();

    Tracker:SetConfig({
        BackgroundColor = self.db.global.BackgroundColor,
        DeveloperMode = self.db.global.DeveloperMode,
        MaxHeight = self.db.global.MaxHeight,
        Position = self.db.global.Position,
        Width = self.db.global.Width
    });

    Tracker:SetMarkForRender(true);
end

function BQT:OnPlayerEnteringWorld()
    self:UnregisterEvent("PLAYER_ENTERING_WORLD");

    -- self.tracker = LibStub("TrackerHelper-1.0"):New({
    --     position = {
    --         x = self.db.global.PositionX,
    --         y = self.db.global.PositionY
    --     },

    --     width = self.db.global.Width,
    --     maxHeight = self.db.global.MaxHeight,

    --     backgroundColor = self.db.global.BackgroundColor,

    --     backgroundVisible = self.db.global.BackgroundAlwaysVisible or self.db.global.DeveloperMode,

    --     locked = self.db.global.LockFrame
    -- });

    -- self.db.char.QUESTS_LAST_UPDATED = QLH:SetQuestsLastUpdated(self.db.char.QUESTS_LAST_UPDATED);

    -- self:RefreshQuestWatch();
    -- self:RefreshView();
    -- if self.db.global.Sorting == "ByQuestProximity" then
    --     self:UpdateQuestProximityTimer();
    -- end

    -- -- This is a massive hack to prevent questie from ignoring us.
    -- C_Timer.After(3.0, function()
    --     QH:SetAutoHideQuestHelperIcons(self.db.global.AutoHideQuestHelperIcons);
    -- end);

    -- self:LogInfo("Enabled");
end

BQT:RegisterEvent("PLAYER_ENTERING_WORLD", "OnPlayerEnteringWorld");

function BQT:Render()
    Tracker:Render();
end

-- Informs the tracker to refresh it's computed values.
function BQT:Refresh()
    Tracker:Refresh();
end