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

function BQT:OnEnable()
    if not ButterQuestTrackerConfig then
        ButterQuestTrackerConfig = {};
    end

    if not ButterQuestTrackerCharacterConfig then
        ButterQuestTrackerCharacterConfig = {};
    end

    for key, value in pairs(ns.CONSTANTS.DEFAULT_CONFIG) do
        if ButterQuestTrackerConfig[key] == nil then
            ButterQuestTrackerConfig[key] = value;
        end
    end

    for key, value in pairs(ns.CONSTANTS.DEFAULT_CHARACTER_CONFIG) do
        if ButterQuestTrackerCharacterConfig[key] == nil then
            ButterQuestTrackerCharacterConfig[key] = value;
        end
    end

    QWH:BypassWatchLimit(ButterQuestTrackerCharacterConfig.MANUALLY_TRACKED_QUESTS);
    QWH:KeepHidden();

    QWH:OnQuestWatchUpdated(function(questWatchUpdates)
        for index, updateInfo in pairs(questWatchUpdates) do
            local questID = QLH:GetQuestIDFromIndex(index);

            if updateInfo.byUser then
                if updateInfo.watched then
                    ButterQuestTrackerCharacterConfig.MANUALLY_TRACKED_QUESTS[questID] = true;
                else
                    ButterQuestTrackerCharacterConfig.MANUALLY_TRACKED_QUESTS[questID] = false;
                end
            end
        end

        self:RefreshView();
    end);

    QLH:OnQuestUpdated(function(updatedQuests)
        ns.Log.Trace("Event(OnQuestUpdated)");
        for questID, updatedQuest in pairs(updatedQuests) do
            if updatedQuest.abandoned then
                ButterQuestTrackerCharacterConfig.QUESTS_LAST_UPDATED[questID] = nil;
            else
                ButterQuestTrackerCharacterConfig.QUESTS_LAST_UPDATED[questID] = updatedQuest.lastUpdated;

                -- If the quest is updated then remove it from the manually tracked quests list.
                if not updatedQuests.initialUpdate then
                    if ButterQuestTrackerConfig.AutoTrackUpdatedQuests then
                        ButterQuestTrackerCharacterConfig.MANUALLY_TRACKED_QUESTS[questID] = true;
                    elseif ButterQuestTrackerCharacterConfig.MANUALLY_TRACKED_QUESTS[questID] == false then
                        ButterQuestTrackerCharacterConfig.MANUALLY_TRACKED_QUESTS[questID] = nil;
                    end
                end
            end
        end

        self:RefreshView();
    end);

    ZH:OnZoneChanged(function(info)
        ns.Log.Info("Changed Zones: (" .. info.zone .. ", " .. info.subZone .. ")");
        self:RefreshQuestWatch();
    end)

    ButterQuestTrackerCharacterConfig.QUESTS_LAST_UPDATED = QLH:SetQuestsLastUpdated(ButterQuestTrackerCharacterConfig.QUESTS_LAST_UPDATED);

    TH:UpdateFrame({
        clamp = true,

        x = ButterQuestTrackerConfig.PositionX,
        y = ButterQuestTrackerConfig.PositionY,

        width = ButterQuestTrackerConfig.Width,
        maxHeight = ButterQuestTrackerConfig.MaxHeight,

        backgroundColor = {
            r = ButterQuestTrackerConfig['BackgroundColor-R'],
            g = ButterQuestTrackerConfig['BackgroundColor-G'],
            b = ButterQuestTrackerConfig['BackgroundColor-B'],
            a = ButterQuestTrackerConfig['BackgroundColor-A']
        },

        backgroundAlwaysVisible = ButterQuestTrackerConfig.BackgroundAlwaysVisible
    });

    TH:SetDebugMode(ButterQuestTrackerConfig.DeveloperMode);

    self:RefreshQuestWatch();
    self:RefreshView();
    ns.Log.Info("Addon Initialized");
end

function BQT:ShowWowheadPopup(type, id)
    StaticPopup_Show(NAME .. "_WowheadURL", type, id)
end

local function count(t)
    local count = 0;
    if t then
        for _, _ in pairs(t) do count = count + 1 end
    end
    return count;
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

local function sortQuestFallback(quest, otherQuest, field, comparator)
    local value = quest[field];
    local otherValue = otherQuest[field];

    if value == otherValue then
        return quest.index < otherQuest.index;
    end

    if comparator == ">" then
        return value > otherValue;
    elseif comparator == "<" then
        return value < otherValue;
    else
        ns.Log.Error("Unknown Comparator. (" .. comparator .. ")");
    end
end

local function sortQuests(quest, otherQuest)
    local sorting = ButterQuestTrackerConfig.Sorting or "nil";
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
    else
        ns.Log.Error("Unknown Sorting value. (" .. sorting .. ")")
    end

    return false;
end

function BQT:RefreshQuestWatch()
    ns.Log.Trace("Refreshing Quest Watch");
    local criteria = {
        currentZoneOnly = ButterQuestTrackerConfig.CurrentZoneOnly,
        hideCompletedQuests = ButterQuestTrackerConfig.HideCompletedQuests
    };

    local quests = QLH:GetQuests();

    local currentZone = GetRealZoneText();
    local minimapZone = GetMinimapZoneText();

    for questID, quest in pairs(quests) do
        self:UpdateQuestWatch(criteria, currentZone, minimapZone, quest);
    end
end

function BQT:UpdateQuestWatch(criteria, currentZone, minimapZone, quest)
    local isCurrentZone = quest.zone == currentZone or quest.zone == minimapZone;

    if ButterQuestTrackerCharacterConfig.MANUALLY_TRACKED_QUESTS[quest.questID] == true then
        return AddQuestWatch(quest.index);
    elseif ButterQuestTrackerCharacterConfig.MANUALLY_TRACKED_QUESTS[quest.questID] == false then
        return RemoveQuestWatch(quest.index);
    elseif ButterQuestTrackerConfig.DisableFilters then
        return RemoveQuestWatch(quest.index);
    end

    if criteria.hideCompletedQuests and quest.isComplete then
        return RemoveQuestWatch(quest.index);
    end

    if criteria.currentZoneOnly then
        if isCurrentZone or quest.isClassQuest or quest.isProfessionQuest then
            AddQuestWatch(quest.index);
        else
            return RemoveQuestWatch(quest.index);
        end
    end

    AddQuestWatch(quest.index);
end

function BQT:RefreshView()
    ns.Log.Info("Refresh Quests");
    TH:Clear();

    local quests = QLH:GetWatchedQuests();
    local questLimit = ButterQuestTrackerConfig.DisableFilters and MAX_WATCHABLE_QUESTS or ButterQuestTrackerConfig.QuestLimit;

    local headerLabel;
    if ButterQuestTrackerConfig.TrackerHeaderFormat == "Quests" then
        headerLabel = "Quests";
    elseif ButterQuestTrackerConfig.TrackerHeaderFormat == "QuestsNumberVisible" then
        local visibleQuestCount = math.min(questLimit, count(quests));
        local questCount = QLH:GetQuestCount();

        if visibleQuestCount < questCount then
            headerLabel = "Quests (" .. visibleQuestCount .. "/" .. questCount .. ")";
        else
            headerLabel = "Quests";
        end
    end

    if headerLabel ~= nil then
        TH:DrawFont({
            label = headerLabel,
            size = ButterQuestTrackerConfig.TrackerHeaderFontSize,
            color = NORMAL_FONT_COLOR,
            hoverColor = HIGHLIGHT_FONT_COLOR,

            container = TH:CreateContainer({
                padding = {
                    bottom = ButterQuestTrackerConfig.QuestPadding
                },

                events = {
                    OnMouseDown = function()
                        local frame = TH:GetFrame();

                        frame:StartMoving();

                        TH:SetBackgroundVisibility(true);
                    end,

                    OnMouseUp = function()
                        local frame = TH:GetFrame();

                        frame:StopMovingOrSizing();
                        frame:SetUserPlaced(false);

                        TH:SetDebugMode();
                        local x, y = TH:GetPosition();

                        ButterQuestTrackerConfig.PositionX = x;
                        ButterQuestTrackerConfig.PositionY = y;

                        TH:UpdatePosition(x, y);

                        LibStub("AceConfigRegistry-3.0"):NotifyChange("ButterQuestTracker");
                    end
                }
            })
        });
    end

    for i, quest in spairs(quests, sortQuests) do
        if i <= questLimit then
            local questContainer = TH:CreateContainer({
                padding = {
                    top = i == 1 and 0 or ButterQuestTrackerConfig.QuestPadding
                },
                events = {
                    OnMouseUp = function(target, button)
                        if button == "LeftButton" then
                            QLH:ToggleQuest(quest.index);
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

            TH:DrawFont({
                label = headerText,
                size = ButterQuestTrackerConfig.QuestHeaderFontSize,
                color = ButterQuestTrackerConfig.ColorHeadersByDifficultyLevel and QLH:GetDifficultyColor(quest.difficulty) or NORMAL_FONT_COLOR,
                hoverColor = HIGHLIGHT_FONT_COLOR,
                container = questContainer
            });

            local objectiveCount = table.getn(quest.objectives);

            if objectiveCount == 0 then
                TH:DrawFont({
                    label = ' - ' .. quest.summary,
                    size = ButterQuestTrackerConfig.ObjectiveFontSize,
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
                    size = ButterQuestTrackerConfig.ObjectiveFontSize,
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
                for i, objective in ipairs(quest.objectives) do
                    TH:DrawFont({
                        label = ' - ' .. objective.text,
                        size = ButterQuestTrackerConfig.ObjectiveFontSize,
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

    UIDropDownMenu_Initialize(self.contextMenu, function(self, level, menuList)
        UIDropDownMenu_AddButton({
            text = self.quest.title,
            notCheckable = true,
            isTitle = true
        });

        UIDropDownMenu_AddButton({
            text = "Untrack Quest",
            notCheckable = true,
            func = function()
                BQT.DB.Char.MANUALLY_TRACKED_QUESTS[self.quest.questID] = false;
                RemoveQuestWatch(self.quest.index);
            end
        });

        UIDropDownMenu_AddButton({
            text = "View Quest",
            notCheckable = true,
            func = function()
                QLH:ToggleQuest(self.quest.index);
            end
        });

        UIDropDownMenu_AddButton({
            text = "|cff33ff99Wowhead|r URL",
            notCheckable = true,
            func = function()
                BQT:ShowWowheadPopup("quest", self.quest.questID);
            end
        });

        UIDropDownMenu_AddButton({
            text = "Share Quest",
            notCheckable = true,
            disabled = not UnitInParty("player") or not self.quest.sharable,
            func = function()
                QLH:ShareQuest(self.quest.index);
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
                QLH:AbandonQuest(self.quest.index);
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
    ns.Log.Info("Clearing Tracking Overrides...");
    for questID, tracked in pairs(ButterQuestTrackerCharacterConfig.MANUALLY_TRACKED_QUESTS) do
        local index = QLH:GetIndexFromQuestID(questID);
        if index then
            RemoveQuestWatch()
        end
    end

    ButterQuestTrackerCharacterConfig.MANUALLY_TRACKED_QUESTS = {};
    self:RefreshQuestWatch();
end
