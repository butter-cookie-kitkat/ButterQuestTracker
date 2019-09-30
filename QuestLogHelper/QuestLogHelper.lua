local AceEvent = LibStub:GetLibrary("AceEvent-3.0");
local helper = LibStub:NewLibrary("QuestLogHelper-1.0", 1);
-- /dump LibStub("QuestLogHelper-1.0"):GetQuests();
-- /dump LibStub("QuestLogHelper-1.0"):GetWatchedQuests();

local class = UnitClass("player");
local professions = {'Herbalism', 'Mining', 'Skinning', 'Alchemy', 'Blacksmithing', 'Enchanting', 'Engineering', 'Leatherworking', 'Tailoring', 'Cooking', 'Fishing', 'First Aid'};

local cache = {
    lastUpdated = {}
};

local function count(t)
    local _count = 0;
    if t then
        for _, _ in pairs(t) do _count = _count + 1 end
    end
    return _count;
end

local function has_value (tab, val)
    for _, value in ipairs(tab) do
        if value == val then
            return true
        end
    end

    return false
end

local function getQuestGrayLevel(level)
    if (level <= 5) then
        return 0;
    elseif (level <= 39) then
        return (level - math.floor(level / 10) - 5);
    else
        return (level - math.floor(level / 5) - 1);
    end
end

local function getCompletionPercent(objectives)
    local completionPercent = 0;

    for _, objective in ipairs(objectives) do
        if objective.completed then
            completionPercent = completionPercent + 1;
        elseif objective.numFulfilled ~= 0 then
            completionPercent = completionPercent + (objective.fulfilled / objective.required);
        end
    end

    return completionPercent / table.getn(objectives);
end

local listeners = {};
local updateListenersTimer;
local updatedQuests = {};
local function updateListeners(questID, info)
    if updateListenersTimer then
        updateListenersTimer:Cancel();
    end

    updatedQuests[questID] = info;

    updateListenersTimer = C_Timer.NewTimer(0.1, function()
        for _, listener in ipairs(listeners) do
            listener(updatedQuests);
        end
        updatedQuests = {};
    end)
end

function helper:OnQuestUpdated(listener)
    tinsert(listeners, listener);
end

function helper:SetQuestsLastUpdated(questsLastUpdated)
    if not questsLastUpdated then return end

    for questID, lastUpdated in pairs(questsLastUpdated) do
        if C_QuestLog.IsOnQuest(questID) then
            cache.lastUpdated[questID] = lastUpdated;
        else
            questsLastUpdated[questID] = nil;
        end
    end

    self:Refresh();
    return questsLastUpdated;
end

function helper:GetQuestIDFromIndex(index)
    if not index then return nil end

    local _, _, _, _, _, _, _, questID = GetQuestLogTitle(index);

    if not questID or questID == 0 then return nil end

    return questID;
end

function helper:GetIndexFromQuestID(questID)
    local quest = self:GetQuest(questID);

    return quest and quest.index;
end

function helper:GetQuestFrame()
    if not self._questFrame then
        if QuestGuru then -- https://www.curseforge.com/wow/addons/questguru_classic
            self._questFrame = QuestGuru;
            self._questFrame.addon = 'QuestGuru';
        elseif ClassicQuestLog then -- https://www.curseforge.com/wow/addons/classic-quest-log
            self._questFrame = ClassicQuestLog;
            self._questFrame.addon = 'ClassicQuestLog';
        elseif QuestLogEx then -- https://www.wowinterface.com/downloads/info24980-QuestLogEx.html
            self._questFrame = QuestLogExFrame;
            self._questFrame.addon = 'QuestLogEx';
        else
            self._questFrame = QuestLogFrame;
            self._questFrame.addon = 'Default';
        end
    end

    return self._questFrame;
end

function helper:IsShown()
    return self:GetQuestFrame():IsShown();
end

function helper:IsQuestSelected(index)
    return GetQuestLogSelection() == index;
end

function helper:ToggleQuest(index)
    local isQuestAlreadyOpen = self:IsShown() and self:IsQuestSelected(index);
    local questFrame = self:GetQuestFrame();

    if isQuestAlreadyOpen then
        HideUIPanel(questFrame);
    else
        ShowUIPanel(questFrame);
        QuestLog_SetSelection(index);

        if questFrame.addon == 'QuestLogEx' then
            QuestLogEx:Maximize();
        elseif questFrame.addon == 'Default' then
            local valueStep = QuestLogListScrollFrame.ScrollBar:GetValueStep();
            QuestLogListScrollFrame.ScrollBar:SetValue(index * valueStep - valueStep * 3);
        end
    end
end

function helper:GetDifficulty(level)
    local playerLevel = UnitLevel("player");

    if (level > (playerLevel + 4)) then
        return 4; -- Extremely Hard (Red)
    elseif (level > (playerLevel + 2)) then
        return 3; -- Hard (Orange)
    elseif (level <= (playerLevel + 2)) and (level >= (playerLevel - 2)) then
        return 2; -- Normal (Yellow)
    elseif (level > getQuestGrayLevel(playerLevel)) then
        return 1; -- Easy
    end

    return 0; -- Too Easy
end

function helper:GetDifficultyColor(difficulty)
    if (difficulty == 4) then
         -- Red
        return { r = 1, g = 0.1, b = 0.1 };
    elseif (difficulty == 3) then
        return { r = 1, g = 0.5, b = 0.25 }; -- Orange
    elseif (difficulty == 2) then
        return { r = 1, g = 1, b = 0 }; -- Yellow
    elseif (difficulty == 1) then
        return { r = 0.25, g = 0.75, b = 0.25 }; -- Green
    end

    return { r = 0.75, g = 0.75, b = 0.75 }; -- Grey
end

function helper:Refresh()
    local initialized = cache.quests and true;
    cache.quests = cache.quests or {};

    local numberOfEntries = GetNumQuestLogEntries();

    for questID, quest in pairs(cache.quests) do
        if not C_QuestLog.IsOnQuest(questID) then
            cache.quests[questID] = nil;
            cache.lastUpdated[questID] = nil;

            updateListeners(questID, {
                index = quest.index,
                lastUpdated = quest.lastUpdated,
                previousCompletionPercent = quest.completionPercent,
                completionPercent = quest.completionPercent,
                abandoned = true
            });
        end
    end

	local zone;
    for index = 1, numberOfEntries, 1 do
        local title, level, _, isHeader, _, isComplete, _, questID = GetQuestLogTitle(index);
        local isClassQuest = zone == class;
        local isProfessionQuest = has_value(professions, zone);

        if isHeader then
            zone = title;
        else
            local accepted = initialized and not cache.quests[questID] and true;

            if not cache.quests[questID] then
                cache.quests[questID] = {
                    title = title,
                    level = level,
                    questID = questID,
                    zone = zone,

                    -- Extras

                    sharable = self:IsQuestSharable(index),
                    summary = self:GetQuestSummary(index),
                    isClassQuest = isClassQuest,
                    isProfessionQuest = isProfessionQuest
                };
            end

            local quest = cache.quests[questID];
            quest.index = index;
            quest.isComplete = isComplete;
            quest.difficulty = self:GetDifficulty(level);
            quest.objectives = self:GetObjectives(questID);

            local completionPercent = getCompletionPercent(quest.objectives);

            local updated = quest.completionPercent and quest.completionPercent ~= completionPercent;
            if updated then
                quest.lastUpdated = GetTime();

                updateListeners(questID, {
                    index = quest.index,
                    lastUpdated = quest.lastUpdated,
                    previousCompletionPercent = quest.completionPercent,
                    completionPercent = completionPercent,
                    accepted = accepted,
                    updated = updated
                });
            elseif accepted then
                quest.lastUpdated = GetTime();

                updateListeners(questID, {
                    index = quest.index,
                    lastUpdated = quest.lastUpdated,
                    previousCompletionPercent = quest.completionPercent,
                    completionPercent = completionPercent,
                    accepted = accepted,
                    updated = updated
                });
            else
                quest.lastUpdated = quest.lastUpdated or cache.lastUpdated[questID];
            end

            quest.completionPercent = getCompletionPercent(quest.objectives);
        end
    end

    return cache.quests;
end

function helper:GetQuests()
    if not cache.quests then
        self:Refresh();
    end

    return cache.quests;
end

function helper:GetQuest(questID)
    if not cache.quests then
        self:Refresh();
    end

    return cache.quests[questID];
end

function helper:GetQuestCount()
    return count(helper:GetQuests());
end

function helper:GetWatchedQuests()
    local quests = self:GetQuests();
    local watchedQuests = {};

    for questID, quest in pairs(quests) do
        if IsQuestWatched(quest.index) then
            watchedQuests[questID] = quest;
        end
    end

    return watchedQuests;
end

function helper:GetObjectives(questID)
    local objectives = C_QuestLog.GetQuestObjectives(questID);
    local formattedObjectives = {};

    for i, objective in ipairs(objectives) do
        formattedObjectives[i] = {
            text = objective.text,
            type = objective.type,
            completed = objective.finished,
            fulfilled = objective.numFulfilled,
            required = objective.numRequired
        };
    end

    return formattedObjectives;
end

function helper:IsQuestSharable(index)
    self:Select(index);
    local sharable = GetQuestLogPushable();
    self:RevertSelection();

    return sharable;
end

function helper:AbandonQuest(index)
    self:Select(index);
    SetAbandonQuest();
    AbandonQuest();
    self:RevertSelection();
end

function helper:ShareQuest(index)

    self:Select(index);
    QuestLogPushQuest();
    self:RevertSelection();
end

function helper:GetQuestSummary(index)
    self:Select(index);
    local _, desc = GetQuestLogQuestText();
    self:RevertSelection();

    return desc;
end

local previousIndex;
function helper:Select(index)
    previousIndex = GetQuestLogSelection();
    SelectQuestLogEntry(index);
end

function helper:RevertSelection()
    if previousIndex then
        SelectQuestLogEntry(previousIndex);
        previousIndex = nil;
    end
end

AceEvent.RegisterEvent(helper, "QUEST_LOG_UPDATE", "Refresh");
