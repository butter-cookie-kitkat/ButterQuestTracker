local AceEvent = LibStub:GetLibrary("AceEvent-3.0");
local QLH = LibStub("QuestLogHelper-1.0");
local helper = LibStub:NewLibrary("QuestWatchHelper-1.0", 1);
local isWoWClassic = select(4, GetBuildInfo()) < 20000;

local BlizzardTrackerFrame = isWoWClassic and QuestWatchFrame or ObjectiveTrackerFrame;

local listeners = {};
local updateListenersTimer;
local updatedQuestIndexes = {};
local function updateListeners(index, watched)
    if updateListenersTimer then
        updateListenersTimer:Cancel();
    end

    updatedQuestIndexes[index] = {
        watched = watched,
        -- This is a massive hack, is there a better way to see if a quest log was manually watched by the user.. ?
        byUser = IsShiftKeyDown() and QLH:IsShown()
    };

    updateListenersTimer = C_Timer.NewTimer(0.1, function()
        for i, listener in ipairs(listeners) do
            listener(updatedQuestIndexes);
        end
        updatedQuestIndexes = {};
    end)
end

function helper:GetFrame()
    return BlizzardTrackerFrame;
end

function helper:BypassWatchLimit(trackedQuests)
    if not isWoWClassic then return end

    trackedQuests = trackedQuests or {};

    local function _addWatch(index)
        local questID = QLH:GetQuestIDFromIndex(index);

        -- Ignore duplicates
        if questID and not trackedQuests[questID] then
            trackedQuests[questID] = true;

            updateListeners(index, true);
        end
    end

    hooksecurefunc("AutoQuestWatch_Insert", _addWatch);
    hooksecurefunc("AddQuestWatch", _addWatch);
    hooksecurefunc("RemoveQuestWatch", function(index)
        local questID = QLH:GetQuestIDFromIndex(index);

        if questID and trackedQuests[questID] then
            trackedQuests[questID] = nil;

            updateListeners(index, false);
        end
    end);

    IsQuestWatched = function(index)
        return trackedQuests[QLH:GetQuestIDFromIndex(index)];
    end

    GetNumQuestWatches = function()
        return table.getn(trackedQuests);
    end

    -- This bypasses a limitation that would prevent users from tracking quests without objectives
    GetNumQuestLeaderBoards = function()
        local index = GetQuestLogSelection();
        local questID = QLH:GetQuestIDFromIndex(index);

        if not questID then return 0 end

        local quest = QLH:GetQuest(questID);

        if not quest then return 0 end

        return table.getn(quest.objectives);
    end
end

function helper:OnQuestWatchUpdated(listener)
    tinsert(listeners, listener);
end

function helper:KeepHidden()
    BlizzardTrackerFrame:HookScript("OnShow", function(self)
        return self:Hide()
    end);
    BlizzardTrackerFrame:Hide();
end

if not isWoWClassic then
    AceEvent.RegisterEvent(helper, "QUEST_WATCH_LIST_CHANGED", function(event, questID, added)
        if questID then
            local index = QLH:GetIndexFromQuestID(questID);
            updateListeners(index, added);
        end
    end);
end
