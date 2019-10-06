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

local function count(t)
    local _count = 0;
    for _, _ in pairs(t) do _count = _count + 1 end
    return _count;
end

function helper:_findIndex(t, value)
    for i, element in ipairs(t) do
        if element == value then
            return i;
        end
    end

    return nil;
end

local listeners = {};
function helper:_invoke(event, value)
    if not listeners[event] then return end

    for _, listener in pairs(listeners[event]) do
        listener(value);
    end
end

local invokeCache = {};
function helper:_invokeDebounce(event, value)
    if not listeners[event] then return end

    invokeCache[event] = invokeCache[event] or {};
    tinsert(invokeCache[event], value);

    debounce(event, function()
        self:_invoke(event, invokeCache[event]);
        invokeCache[event] = nil;
    end);
end

function helper:Off(event, listener)
    if not listeners[event] then return end

    local index = self:_findIndex(listeners[event], listener);

    if not index then return end

    table.remove(listeners[event], index);
end

function helper:On(event, listener)
    listeners[event] = listeners[event] or {};

    tinsert(listeners[event], listener);
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

            helper:_invokeDebounce("QUEST_WATCH_UPDATED", {
                byUser = IsShiftKeyDown() and QLH:IsShown(),
                index = index,
                questID = questID,
                watched = true
            });
        end
    end

    hooksecurefunc("AutoQuestWatch_Insert", _addWatch);
    hooksecurefunc("AddQuestWatch", _addWatch);
    hooksecurefunc("RemoveQuestWatch", function(index, isQuestie)
        -- This is a hack to ignore watch requests from Questie's Tracker...
        if isQuestie then return end

        local questID = QLH:GetQuestIDFromIndex(index);

        -- Ignore duplicates
        if questID and trackedQuests[questID] then
            trackedQuests[questID] = nil;

            helper:_invokeDebounce("QUEST_WATCH_UPDATED", {
                byUser = IsShiftKeyDown() and QLH:IsShown(),
                index = index,
                questID = questID,
                watched = false
            });
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

    QLH:On("QUESTS_UPDATED", function(quests)
        for questID, quest in pairs(quests) do
            if quest.abandoned then
                if trackedQuests[questID] then
                    trackedQuests[questID] = nil;

                    helper:_invokeDebounce("QUEST_WATCH_UPDATED", {
                        byUser = IsShiftKeyDown() and QLH:IsShown(),
                        index = quest.index,
                        questID = quest.questID,
                        watched = false
                    });
                end
            end
        end
    end);
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
            if added then
                C_Timer.After(0.1, function()
                    local index = QLH:GetIndexFromQuestID(questID);

                    helper:_invokeDebounce("QUEST_WATCH_UPDATED", {
                        byUser = IsShiftKeyDown() and QLH:IsShown(),
                        index = index,
                        questID = questID,
                        watched = added
                    });
                end);
            else
                local index = QLH:GetIndexFromQuestID(questID);

                helper:_invokeDebounce("QUEST_WATCH_UPDATED", {
                    byUser = IsShiftKeyDown() and QLH:IsShown(),
                    index = index,
                    questID = questID,
                    watched = added
                });
            end
        end
    end);
end
