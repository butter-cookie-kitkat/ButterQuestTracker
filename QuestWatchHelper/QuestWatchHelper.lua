local AceEvent = LibStub:GetLibrary("AceEvent-3.0");
local QLH = LibStub("QuestLogHelper-1.0");
local helper = LibStub:NewLibrary("QuestWatchHelper-1.0", 1);
local isWoWClassic = select(4, GetBuildInfo()) < 20000;

local BlizzardTrackerFrame = isWoWClassic and QuestWatchFrame or ObjectiveTrackerFrame;

local timers = {};
local function debounce(name, func)
    if timers[name] then
        timers[name]:Cancel();
    end

    timers[name] = C_Timer.NewTimer(0.1, func);
end

local listeners = {};
local updatedQuestIndexes = {};
local function updateListeners(index, watched)
    updatedQuestIndexes[index] = {
        watched = watched,
        -- This is a massive hack, is there a better way to see if a quest log was manually watched by the user.. ?
        byUser = IsShiftKeyDown() and QLH:IsShown()
    };

    debounce("listeners", function()
        for _, listener in ipairs(listeners) do
            listener(updatedQuestIndexes);
        end
        updatedQuestIndexes = {};
    end);
end

local updatedQuestIDs = {};
local function updateMapTrackerAddons(updatedQuestID, updatedWathed)
    updatedQuestIDs[updatedQuestID] = updatedWathed;

    debounce("mapAddons", function()
        for questID, watched in pairs(updatedQuestIDs) do
            if Questie then
                local quest = QuestieDB:GetQuest(questID);

                quest.HideIcons = not watched;
            end
        end

        if Questie then
            QuestieQuest:UpdateHiddenNotes();
        end
        updatedQuestIDs = {};
    end);
end

local function count(t)
    local _count = 0;
    for _, _ in pairs(t) do _count = _count + 1 end
    return _count;
end

function helper:GetFrame()
    return BlizzardTrackerFrame;
end

function helper:IsAutomaticQuestWatchEnabled()
    return GetCVar('autoQuestWatch') == '1';
end

function helper:SetAutomaticQuestWatch(autoQuestWatch)
    SetCVar('autoQuestWatch', autoQuestWatch and '1' or '0');
end

function helper:BypassWatchLimit(initialTrackedQuests)
    if not isWoWClassic then return end

    local trackedQuests = {};
    for questID, tracked in pairs(initialTrackedQuests) do
        if tracked then
            trackedQuests[questID] = true;
        end
    end

    local function _addWatch(index, isQuestie)
        -- This is a hack to ignore watch requests from Questie's Tracker...
        if isQuestie then return end

        local questID = QLH:GetQuestIDFromIndex(index);

        -- Ignore duplicates
        if questID and not trackedQuests[questID] then
            trackedQuests[questID] = true;

            updateListeners(index, true);
            updateMapTrackerAddons(questID, true);
        end
    end

    hooksecurefunc("AutoQuestWatch_Insert", _addWatch);
    hooksecurefunc("AddQuestWatch", _addWatch);
    hooksecurefunc("RemoveQuestWatch", function(index, isQuestie)
        -- This is a hack to ignore watch requests from Questie's Tracker...
        if isQuestie then return end

        local questID = QLH:GetQuestIDFromIndex(index);

        if questID and trackedQuests[questID] then
            trackedQuests[questID] = nil;

            updateListeners(index, false);
            updateMapTrackerAddons(questID, false);
        end
    end);

    IsQuestWatched = function(index)
        return trackedQuests[QLH:GetQuestIDFromIndex(index)];
    end

    GetNumQuestWatches = function()
        return 0;
    end

    -- This bypasses a limitation that would prevent users from tracking quests without objectives
    GetNumQuestLeaderBoards = function(index)
        index = index or GetQuestLogSelection();
        local questID = QLH:GetQuestIDFromIndex(index);

        if not questID then return 0 end

        local quest = QLH:GetQuest(questID);

        if not quest then return 0 end

        local objectiveCount = count(quest.objectives);

        if objectiveCount == 0 then return 1 end

        return objectiveCount;
    end

    MAX_WATCHABLE_QUESTS = C_QuestLog.GetMaxNumQuests();

    QLH:OnQuestUpdated(function(quests)
        for questID, quest in pairs(quests) do
            if quest.abandoned then
                updateListeners(quest.index, false);

                if trackedQuests[questID] then
                    trackedQuests[questID] = nil;

                    updateListeners(quest.index, false);
                end
            end
        end
    end);

    -- This is a massive hack to prevent questie from ignoring us.
    C_Timer.After(0.1, function()
        for questID in pairs(QLH:GetQuests()) do
            updateMapTrackerAddons(questID, trackedQuests[questID] == true);
        end
    end);
end

function helper:OnQuestWatchUpdated(listener)
    tinsert(listeners, listener);
end

function helper:KeepHidden()
    BlizzardTrackerFrame:HookScript("OnShow", function(frame)
        return frame:Hide()
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
