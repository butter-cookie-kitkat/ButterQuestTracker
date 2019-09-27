local AceEvent = LibStub:GetLibrary("AceEvent-3.0");
local helper = LibStub:NewLibrary("QuestLogHelper-1.0", 1);
local isWoWClassic = select(4, GetBuildInfo()) < 20000;
-- /dump LibStub("QuestLogHelper-1.0"):GetQuests();
-- /dump LibStub("QuestLogHelper-1.0"):GetWatchedQuests();

local class = UnitClass("player");
local professions = {'Herbalism', 'Mining', 'Skinning', 'Alchemy', 'Blacksmithing', 'Enchanting', 'Engineering', 'Leatherworking', 'Tailoring', 'Cooking', 'Fishing', 'First Aid'};

local cache = {
    quests = {},
    lastUpdated = {}
};

local function count(t)
    local count = 0;
    if t then
        for _, _ in pairs(t) do count = count + 1 end
    end
    return count;
end

local function has_value (tab, val)
    for index, value in ipairs(tab) do
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

    for i, objective in ipairs(objectives) do
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
        for i, listener in ipairs(listeners) do
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
    for _, quest in pairs(cache.quests) do
        if questID == quest.questID then
            return quest.index;
        end
    end

    return nil;
end

function helper:IsShown()
    if QuestLogEx then -- https://www.wowinterface.com/downloads/info24980-QuestLogEx.html
        return QuestLogExFrame:IsShown();
    elseif ClassicQuestLog then -- https://www.curseforge.com/wow/addons/classic-quest-log
        return ClassicQuestLog:IsShown();
    elseif QuestGuru then -- https://www.curseforge.com/wow/addons/questguru_classic
        return QuestGuru:IsShown();
    else
        return QuestLogFrame:IsShown();
    end
end

function helper:IsQuestSelected(index)
    return GetQuestLogSelection() == index;
end

function helper:ToggleQuest(index)
    local isQuestAlreadyOpen = self:IsShown() and self:IsQuestSelected(index);

    if QuestLogEx then -- https://www.wowinterface.com/downloads/info24980-QuestLogEx.html
        if isQuestAlreadyOpen then
            HideUIPanel(QuestLogExFrame);
        else
            ShowUIPanel(QuestLogExFrame);
            QuestLogEx:QuestLog_SetSelection(index);
            QuestLogEx:Maximize();
        end
    elseif ClassicQuestLog then -- https://www.curseforge.com/wow/addons/classic-quest-log
        if isQuestAlreadyOpen then
            HideUIPanel(ClassicQuestLog);
        else
            ShowUIPanel(ClassicQuestLog);
            QuestLog_SetSelection(index);
        end
    elseif QuestGuru then -- https://www.curseforge.com/wow/addons/questguru_classic
        if isQuestAlreadyOpen then
            HideUIPanel(QuestGuru);
        else
            ShowUIPanel(QuestGuru);
            QuestGuru:SelectQuestIndex(index);
        end
    else
        if isQuestAlreadyOpen then
            HideUIPanel(QuestLogFrame);
        else
            ShowUIPanel(QuestLogFrame);
            QuestLog_SetSelection(index);
            local valueStep = QuestLogListScrollFrame.ScrollBar:GetValueStep();
            QuestLogListScrollFrame.ScrollBar:SetValue(index * valueStep / 2);
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
        return 1, 0.1, 0.1; -- Red
    elseif (difficulty == 3) then
        return 1, 0.5, 0.25; -- Orange
    elseif (difficulty == 2) then
        return 1, 1, 0; -- Yellow
    elseif (difficulty == 1) then
        return 0.25, 0.75, 0.25; -- Green
    end

    return 0.75, 0.75, 0.75; -- Grey
end

function helper:Refresh()
    local numberOfEntries = GetNumQuestLogEntries();

    for questID, quest in pairs(cache.quests) do
        if not C_QuestLog.IsOnQuest(questID) then
            cache.quests[questID] = nil;
            cache.lastUpdated[questID] = nil;

            updateListeners(questID, {
                lastUpdated = quest.lastUpdated,
                previousCompletionPercent = quest.completionPercent,
                completionPercent = quest.completionPercent,
                abandoned = true
            });
        end
    end

	local zone;
    for index = 1, numberOfEntries, 1 do
        local title, level, suggestedGroup, isHeader, _, isComplete, frequency, questID, startEvent, displayQuestID, isOnMap, hasLocalPOI, isTask, isBounty, isStory, isHidden, isScaling = GetQuestLogTitle(index);
        local isClassQuest = zone == class;
        local isProfessionQuest = has_value(professions, zone);

        if isHeader then
            zone = title;
        else
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

            if quest.completionPercent and quest.completionPercent ~= completionPercent then
                quest.lastUpdated = GetTime();

                updateListeners(questID, {
                    lastUpdated = quest.lastUpdated,
                    previousCompletionPercent = quest.completionPercent,
                    completionPercent = completionPercent
                });
            elseif not cache.lastUpdated[questID] and not quest.lastUpdated then
                quest.lastUpdated = GetTime();

                updateListeners(questID, {
                    lastUpdated = quest.lastUpdated,
                    previousCompletionPercent = quest.completionPercent,
                    completionPercent = completionPercent,
                    initialUpdate = true
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
    local currentSelection = GetQuestLogSelection();

    SelectQuestLogEntry(index);
    local sharable = GetQuestLogPushable();
    SelectQuestLogEntry(currentSelection);

    return sharable;
end

function helper:AbandonQuest(index)
    local currentSelection = GetQuestLogSelection();

    SelectQuestLogEntry(index);
    SetAbandonQuest();
    AbandonQuest();
    SelectQuestLogEntry(currentSelection);
end

function helper:ShareQuest(index)
    local currentSelection = GetQuestLogSelection();

    SelectQuestLogEntry(index);
    QuestLogPushQuest();
    SelectQuestLogEntry(currentSelection);
end

function helper:GetQuestSummary(index)
    local currentSelection = GetQuestLogSelection();

    SelectQuestLogEntry(index);
    local _, desc = GetQuestLogQuestText();
    SelectQuestLogEntry(currentSelection);

    return desc;
end

AceEvent.RegisterEvent(helper, "QUEST_LOG_UPDATE", "Refresh");
