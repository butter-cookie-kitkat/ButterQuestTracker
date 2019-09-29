local NAME, ns = ...

local QWH = LibStub("QuestWatchHelper-1.0");
local QLH = LibStub("QuestLogHelper-1.0");
local ZH = LibStub("ZoneHelper-1.0");
local TH = LibStub("TrackerHelper-1.0");

ButterQuestTracker = LibStub("AceAddon-3.0"):NewAddon("ButterQuestTracker");
local BQT = ButterQuestTracker;

StaticPopupDialogs[NAME .. "_WowheadURL"] = {
    text = ns.CONSTANTS.PATHS.LOGO .. ns.CONSTANTS.BRAND_COLOR .. " Butter Quest Tracker" .. "|r - Wowhead URL " .. ns.CONSTANTS.PATHS.LOGO,
    button2 = CLOSE,
    hasEditBox = true,
    editBoxWidth = 300,

    EditBoxOnEnterPressed = function(self)
        self:GetParent():Hide()
    end,

    EditBoxOnEscapePressed = function(self)
        self:GetParent():Hide()
    end,

    OnShow = function(self)
        local type = self.text.text_arg1;
        local id = self.text.text_arg2;
        local name = "...";

        if type == "quest" then
            local quest = QLH:GetQuest(id);

            name = quest.title;
        end

        self.text:SetText(self.text:GetText() .. "\n\n|cffff7f00" .. name .. "|r");
        self.editBox:SetText("https://classic.wowhead.com/" .. type .. "=" .. id);
        self.editBox:SetFocus();
        self.editBox:HighlightText();
    end,

    whileDead = true,
    hideOnEscape = true
}

function BQT:OnInitialize()
    self.db = LibStub("AceDB-3.0"):New("ButterQuestTrackerConfig", ns.CONSTANTS.DB_DEFAULTS, true);

    -- TODO: This is for backwards compatible support of the SavedVariables
    -- Remove this in v2.0.0
    if ButterQuestTrackerCharacterConfig then
        for key, value in pairs(ButterQuestTrackerCharacterConfig) do
            self.db.char[key] = value;
            ButterQuestTrackerCharacterConfig[key] = nil;
        end
    end
    -- END TODO

    QWH:BypassWatchLimit(self.db.char.MANUALLY_TRACKED_QUESTS);
    QWH:KeepHidden();

    QWH:OnQuestWatchUpdated(function(questWatchUpdates)
        for index, updateInfo in pairs(questWatchUpdates) do
            local questID = QLH:GetQuestIDFromIndex(index);

            if updateInfo.byUser then
                if updateInfo.watched then
                    self.db.char.MANUALLY_TRACKED_QUESTS[questID] = true;
                else
                    self.db.char.MANUALLY_TRACKED_QUESTS[questID] = false;
                end
            end
        end

        self:RefreshView();
    end);

    QLH:OnQuestUpdated(function(updatedQuests)
        self:LogTrace("Event(OnQuestUpdated)");
        for questID, updatedQuest in pairs(updatedQuests) do
            if updatedQuest.abandoned then
                self.db.char.QUESTS_LAST_UPDATED[questID] = nil;
            else
                self.db.char.QUESTS_LAST_UPDATED[questID] = updatedQuest.lastUpdated;

                -- If the quest is updated then remove it from the manually tracked quests list.
                if not updatedQuests.initialUpdate then
                    if self.db.global.AutoTrackUpdatedQuests then
                        self.db.char.MANUALLY_TRACKED_QUESTS[questID] = true;
                    elseif self.db.char.MANUALLY_TRACKED_QUESTS[questID] == false then
                        self.db.char.MANUALLY_TRACKED_QUESTS[questID] = nil;
                    end
                end
            end
        end

        self:RefreshView();
    end);

    ZH:OnZoneChanged(function(info)
        self:LogInfo("Changed Zones: (" .. info.zone .. ", " .. info.subZone .. ")");
        self:RefreshQuestWatch();
    end)

    self.db.char.QUESTS_LAST_UPDATED = QLH:SetQuestsLastUpdated(self.db.char.QUESTS_LAST_UPDATED);

    TH:UpdateFrame({
        clamp = true,

        x = self.db.global.PositionX,
        y = self.db.global.PositionY,

        width = self.db.global.Width,
        maxHeight = self.db.global.MaxHeight,

        backgroundColor = {
            r = self.db.global['BackgroundColor-R'],
            g = self.db.global['BackgroundColor-G'],
            b = self.db.global['BackgroundColor-B'],
            a = self.db.global['BackgroundColor-A']
        },

        backgroundAlwaysVisible = self.db.global.BackgroundAlwaysVisible
    });

    TH:SetDebugMode(self.db.global.DeveloperMode);

    self:RefreshQuestWatch();
    if self.db.global.Sorting == "ByQuestProximity" then
        self:UpdateQuestProximityTimer();
    else
        self:RefreshView();
    end

    self:LogInfo("Initialized");
end

function BQT:ShowWowheadPopup(type, id)
    StaticPopup_Show(NAME .. "_WowheadURL", type, id)
end

local function getDistance(x1, y1, x2, y2)
	return math.sqrt( (x2-x1)^2 + (y2-y1)^2 );
end

local function count(t)
    local _count = 0;
    if t then
        for _, _ in pairs(t) do _count = _count + 1 end
    end
    return _count;
end

local function spairs(t, order)
    -- collect the keys
    local keys = {};
    for k in pairs(t) do keys[#keys+1] = k end

    -- if order function given, sort by it by passing the table and keys a, b,
    -- otherwise just sort the keys
    if order then
        table.sort(keys, function(a, b) return order(t[a], t[b]) end);
    else
        table.sort(keys);
    end

    -- return the iterator function
    local i = 0
    return function()
        i = i + 1
        if keys[i] then
            -- i = fake index
            -- t[keys[i]] = value
            -- keys[i] = real index
            return i, t[keys[i]], keys[i];
        end
    end
end

local function getWorldPlayerPosition()
    local uiMapID = C_Map.GetBestMapForUnit("player");
    local mapPosition = C_Map.GetPlayerMapPosition(uiMapID, "player");
    local _, worldPosition = C_Map.GetWorldPosFromMapPos(uiMapID, mapPosition);

    return worldPosition;
end

local function getDistanceToClosestObjective(quest)
    if not BQT.playerPosition then
        BQT.playerPosition = getWorldPlayerPosition();
    end

    local closestDistance;
    if Questie then
        local QQ = QuestieDB:GetQuest(quest.questID);

        if not QQ then return end;

        if quest.isComplete or count(quest.objectives) == 0 then
            local finisher;
            if QQ.Finisher.Type == "monster" then
                finisher = QuestieDB:GetNPC(QQ.Finisher.Id)
            elseif QQ.Finisher.Type == "object" then
                finisher = QuestieDB:GetObject(QQ.Finisher.Id)
            end

            if not finisher then return end;

            for zoneID, spawns in pairs(finisher.spawns) do
                for _, coords in pairs(spawns) do
                    local uiMapID = ZH:GetUIMapID(zoneID);

                    if uiMapID then
                        local _, worldPosition = C_Map.GetWorldPosFromMapPos(uiMapID, {
                            x = coords[1] / 100,
                            y = coords[2] / 100
                        });

                        local distance = getDistance(BQT.playerPosition.x, BQT.playerPosition.y, worldPosition.x, worldPosition.y);
                        if closestDistance == nil or distance < closestDistance then
                            closestDistance = distance;
                        end
                    end
                end
            end
        elseif QQ.Objectives then
            for _, objective in pairs(QQ.Objectives) do
                for _, v in pairs(objective.AlreadySpawned) do
                    for _, mapRef in pairs(v.mapRefs) do
                        local _, worldPosition = C_Map.GetWorldPosFromMapPos(mapRef.data.UiMapID, {
                            x = mapRef.x / 100,
                            y = mapRef.y / 100
                        });

                        local distance = getDistance(BQT.playerPosition.x, BQT.playerPosition.y, worldPosition.x, worldPosition.y);
                        if closestDistance == nil or distance < closestDistance then
                            closestDistance = distance;
                        end
                    end
                end
            end
        end
    end

    return closestDistance;
end

local function sortQuestFallback(quest, otherQuest, field, comparator)
    local value = quest[field];
    local otherValue = otherQuest[field];

    if value == otherValue then
        return quest.index < otherQuest.index;
    end

    if not value and otherValue then
        return false;
    elseif value and not otherValue then
        return true;
    end

    if comparator == ">" then
        return value > otherValue;
    elseif comparator == "<" then
        return value < otherValue;
    else
        BQT:LogError("Unknown Comparator. (" .. comparator .. ")");
    end
end

local function sortQuests(quest, otherQuest)
    local sorting = BQT.db.global.Sorting or "nil";
    if sorting == "Disabled" then
        return false;
    end

    if sorting == "ByLevel" then
        return sortQuestFallback(quest, otherQuest, "level", "<");
    elseif sorting == "ByLevelReversed" then
        return sortQuestFallback(quest, otherQuest, "level", ">");
    elseif sorting == "ByPercentCompleted" then
        return sortQuestFallback(quest, otherQuest, "completionPercent", ">");
    elseif sorting == "ByRecentlyUpdated" then
        return sortQuestFallback(quest, otherQuest, "lastUpdated", ">");
    elseif sorting == "ByQuestProximity" then
        if Questie then
            quest.distanceToClosestObjective = getDistanceToClosestObjective(quest);
            otherQuest.distanceToClosestObjective = getDistanceToClosestObjective(otherQuest);
        else
            quest.distanceToClosestObjective = 0;
            otherQuest.distanceToClosestObjective = 0;
        end

        return sortQuestFallback(quest, otherQuest, "distanceToClosestObjective", "<")
    else
        BQT:LogError("Unknown Sorting value. (" .. sorting .. ")")
    end

    return false;
end

function BQT:UpdateQuestProximityTimer()
    if self.db.global.Sorting == "ByQuestProximity" then
        local initialized = false;
        self:RefreshView();

        self.questProximityTimer = C_Timer.NewTicker(5.0, function()
            self:LogTrace("-- Starting ByQuestProximity Checks --");
            self:LogTrace("Checking if player has moved...");
            local position = getWorldPlayerPosition();
            local distance = getDistance(position.x, position.y, self.playerPosition.x, self.playerPosition.y);

            if not initialized or distance > 0.01 then
                initialized = true;
                self.playerPosition = position;
                self:RefreshView();
            else
                self:LogTrace("Player movement wasn't greater then 5, ignoring... (" .. distance .. ")");
            end
            self:LogTrace("-- Ending ByQuestProximity Checks --");
        end);
    elseif self.questProximityTimer then
        self.playerPosition = nil;
        self.questProximityTimer:Cancel();
    end
end

function BQT:RefreshQuestWatch()
    self:LogTrace("Refreshing Quest Watch");

    local quests = QLH:GetQuests();

    local currentZone = GetRealZoneText();
    local minimapZone = GetMinimapZoneText();

    for _, quest in pairs(quests) do
        self:UpdateQuestWatch(currentZone, minimapZone, quest);
    end
end

function BQT:UpdateQuestWatch(currentZone, minimapZone, quest)
    local isCurrentZone = quest.zone == currentZone or quest.zone == minimapZone;

    if self.db.char.MANUALLY_TRACKED_QUESTS[quest.questID] == true then
        return AddQuestWatch(quest.index);
    elseif self.db.char.MANUALLY_TRACKED_QUESTS[quest.questID] == false then
        return RemoveQuestWatch(quest.index);
    elseif self.db.global.DisableFilters then
        return RemoveQuestWatch(quest.index);
    end

    if self.db.global.HideCompletedQuests and quest.isComplete then
        return RemoveQuestWatch(quest.index);
    end

    if self.db.global.CurrentZoneOnly then
        if isCurrentZone or quest.isClassQuest or quest.isProfessionQuest then
            AddQuestWatch(quest.index);
        else
            return RemoveQuestWatch(quest.index);
        end
    end

    AddQuestWatch(quest.index);
end

function BQT:RefreshView()
    self:LogInfo("Refresh Quests");
    TH:Clear();

    local quests = QLH:GetWatchedQuests();
    local questLimit = self.db.global.DisableFilters and MAX_WATCHABLE_QUESTS or self.db.global.QuestLimit;
    local questCount = QLH:GetQuestCount();
    local visibleQuestCount = math.min(questLimit, count(quests));

    self:LogTrace("Quest Count:", questCount);
    self:LogTrace("Visible Quest Count:", visibleQuestCount);

    local headerLabel;
    if self.db.global.TrackerHeaderFormat == "Quests" then
        headerLabel = "Quests";
    elseif self.db.global.TrackerHeaderFormat == "QuestsNumberVisible" then

        if visibleQuestCount < questCount then
            headerLabel = "Quests (" .. visibleQuestCount .. "/" .. questCount .. ")";
        else
            headerLabel = "Quests";
        end
    end

    if headerLabel ~= nil then
        TH:DrawFont({
            label = headerLabel,
            size = self.db.global.TrackerHeaderFontSize,
            color = NORMAL_FONT_COLOR,
            hoverColor = HIGHLIGHT_FONT_COLOR,

            container = TH:CreateContainer({
                padding = {
                    bottom = visibleQuestCount > 0 and self.db.global.QuestPadding or 0
                },

                events = {
                    OnMouseDown = function(_, button)
                        local frame = TH:GetFrame();

                        if button == "LeftButton" then
                            frame:StartMoving();
                            TH:SetBackgroundVisibility(true);
                        else
                            if InterfaceOptionsFrame:IsShown() then
                                InterfaceOptionsFrame:Hide();
                            else
                                InterfaceOptionsFrame:Show();
                                InterfaceOptionsFrame_OpenToCategory("ButterQuestTracker");
                            end
                        end
                    end,

                    OnMouseUp = function()
                        local frame = TH:GetFrame();

                        frame:StopMovingOrSizing();
                        frame:SetUserPlaced(false);

                        TH:SetDebugMode();
                        local x, y = TH:GetPosition();

                        self.db.global.PositionX = x;
                        self.db.global.PositionY = y;

                        TH:UpdatePosition(x, y);

                        LibStub("AceConfigRegistry-3.0"):NotifyChange("ButterQuestTracker");
                    end
                }
            })
        });
    end

    for i, quest in spairs(quests, sortQuests) do
        -- /dump QuestieDB:GetQuest(5147).Objectives[1].AlreadySpawned[10896].mapRefs
        if i <= questLimit then
            local questContainer = TH:CreateContainer({
                padding = {
                    top = i == 1 and 0 or self.db.global.QuestPadding
                },
                events = {
                    OnMouseUp = function(target, button)
                        if button == "LeftButton" then
                            if IsShiftKeyDown() then
                                self.db.char.MANUALLY_TRACKED_QUESTS[quest.questID] = false;
                                RemoveQuestWatch(quest.index);
                                PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON);
                            elseif IsAltKeyDown() then
                                self:ShowWowheadPopup("quest", quest.questID);
                            elseif IsControlKeyDown() then
                                ChatEdit_InsertLink("[" .. quest.title .. "]");
                            else
                                QLH:ToggleQuest(quest.index);
                            end
                        else
                            self:ToggleContextMenu(quest);
                        end
                    end
                }
            });

            local headerText = "[" .. quest.level .. "] ";

            if quest.isClassQuest then
                headerText = headerText .. "[C] ";
            elseif quest.isProfessionQuest then
                headerText = headerText .. "[P] ";
            end

            headerText = headerText .. quest.title;

            if self.db.global.DeveloperMode and quest.distanceToClosestObjective then
                local precision = "%.".. 1 .."f";
                headerText = headerText .. string.format(" ( " .. precision .. " )", quest.distanceToClosestObjective);
            end

            TH:DrawFont({
                label = headerText,
                size = self.db.global.QuestHeaderFontSize,
                color = self.db.global.ColorHeadersByDifficultyLevel and QLH:GetDifficultyColor(quest.difficulty) or NORMAL_FONT_COLOR,
                hoverColor = HIGHLIGHT_FONT_COLOR,
                container = questContainer
            });

            local objectiveCount = table.getn(quest.objectives);

            if objectiveCount == 0 then
                TH:DrawFont({
                    label = ' - ' .. quest.summary,
                    size = self.db.global.ObjectiveFontSize,
                    color = {
                        r = 0.8,
                        g = 0.8,
                        b = 0.8
                    },
                    hoverColor = HIGHLIGHT_FONT_COLOR,
                    container = questContainer,
                    padding = {
                        y = 1.25
                    }
                });
            elseif quest.isComplete then
                TH:DrawFont({
                    label = ' - Ready to turn in',
                    size = self.db.global.ObjectiveFontSize,
                    color = {
                        r = 0.0,
                        g = 0.7,
                        b = 0.0
                    },
                    hoverColor = HIGHLIGHT_FONT_COLOR,
                    container = questContainer,
                    padding = {
                        y = 1.25
                    }
                });
            else
                for _, objective in ipairs(quest.objectives) do
                    TH:DrawFont({
                        label = ' - ' .. objective.text,
                        size = self.db.global.ObjectiveFontSize,
                        color = objective.completed and HIGHLIGHT_FONT_COLOR or ns.CONSTANTS.COLORS.OBJECTIVE,
                        hoverColor = HIGHLIGHT_FONT_COLOR,
                        container = questContainer,
                        padding = {
                            y = 1.25
                        }
                    });
                end
            end
        end
    end
end

function BQT:ToggleContextMenu(quest)
    if not self.contextMenu then
        self.contextMenu = CreateFrame("Frame", "WPDemoContextMenu", UIParent, "UIDropDownMenuTemplate");
    end

    local isActive = UIDROPDOWNMENU_OPEN_MENU == self.contextMenu;
    local hasQuestChanged = not self.contextMenu.quest or self.contextMenu.quest.questID ~= quest.questID;

    self.contextMenu.quest = quest;

    UIDropDownMenu_Initialize(self.contextMenu, function()
        UIDropDownMenu_AddButton({
            text = self.contextMenu.quest.title,
            notCheckable = true,
            isTitle = true
        });

        UIDropDownMenu_AddButton({
            text = "Untrack Quest",
            notCheckable = true,
            func = function()
                self.db.char.MANUALLY_TRACKED_QUESTS[self.contextMenu.quest.questID] = false;
                RemoveQuestWatch(self.contextMenu.quest.index);
            end
        });

        UIDropDownMenu_AddButton({
            text = "View Quest",
            notCheckable = true,
            func = function()
                QLH:ToggleQuest(self.contextMenu.quest.index);
            end
        });

        UIDropDownMenu_AddButton({
            text = "|cff33ff99Wowhead|r URL",
            notCheckable = true,
            func = function()
                BQT:ShowWowheadPopup("quest", self.contextMenu.quest.questID);
            end
        });

        UIDropDownMenu_AddButton({
            text = "Share Quest",
            notCheckable = true,
            disabled = not UnitInParty("player") or not self.contextMenu.quest.sharable,
            func = function()
                QLH:ShareQuest(self.contextMenu.quest.index);
            end
        });

        UIDropDownMenu_AddButton({
            text = "Cancel",
            notCheckable = true,
            func = function()
                PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON);
            end
        });

        UIDropDownMenu_AddButton({
            isTitle = true
        });

        UIDropDownMenu_AddButton({
            text = "Abandon Quest",
            notCheckable = true,
            colorCode = "|cffff0000",
            func = function()
                QLH:AbandonQuest(self.contextMenu.quest.index);
                PlaySound(SOUNDKIT.IG_QUEST_LOG_ABANDON_QUEST);
            end
        });
    end, "MENU");

    -- If this Dropdown menu isn't already open then play the sound effect.
    if isActive and not hasQuestChanged then
        CloseDropDownMenus();
    else
        ToggleDropDownMenu(1, nil, self.contextMenu, "cursor", 0, -3);
        PlaySound(SOUNDKIT.IG_MAINMENU_OPEN);
    end
end

function BQT:ResetOverrides()
    self:LogInfo("Clearing Tracking Overrides...");
    for questID in pairs(self.db.char.MANUALLY_TRACKED_QUESTS) do
        local index = QLH:GetIndexFromQuestID(questID);
        if index then
            RemoveQuestWatch()
        end
    end

    self.db.char.MANUALLY_TRACKED_QUESTS = {};
    self:RefreshQuestWatch();
end

function BQT:Debug(type, bypass, ...)
    if bypass or (self.db.global.DeveloperMode and self.db.global.DebugLevel >= type.LEVEL) then
        print(ns.CONSTANTS.LOGGER.PREFIX .. type.COLOR, ...);
    end
end

function BQT:LogError(...)
    self:Debug(ns.CONSTANTS.LOGGER.TYPES.ERROR, true, ...);
end

function BQT:LogWarn(...)
    self:Debug(ns.CONSTANTS.LOGGER.TYPES.WARN, false, ...);
end

function BQT:LogInfo(...)
    self:Debug(ns.CONSTANTS.LOGGER.TYPES.INFO, false, ...);
end

function BQT:LogTrace(...)
    self:Debug(ns.CONSTANTS.LOGGER.TYPES.TRACE, false, ...);
end
