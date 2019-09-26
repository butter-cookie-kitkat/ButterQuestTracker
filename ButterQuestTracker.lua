local NAME, ns = ...

local QWH = LibStub("QuestWatchHelper-1.0");
local QLH = LibStub("QuestLogHelper-1.0");

ButterQuestTracker = CreateFrame("Frame", nil, UIParent);
local BQT = ButterQuestTracker;

StaticPopupDialogs[NAME .. "_WowheadURL"] = {
    text = ns.CONSTANTS.PATHS.LOGO .. ns.CONSTANTS.BRAND_COLOR .. " Butter Quest Tracker" .. "|r - Wowhead URL " .. ns.CONSTANTS.PATHS.LOGO,
    button2 = CLOSE,
    hasEditBox = 1,
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

    timeout = 0,
    whileDead = 1,
    hideOnEscape = 1
}

function BQT:ShowWowheadPopup(type, id)
    StaticPopup_Show(NAME .. "_WowheadURL", type, id)
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

local function sortQuests(quest, otherQuest)
    local sorting = BQT.DB.Global.Sorting or "nil";
    if sorting == "Disabled" then
        return false;
    end

    if sorting == "ByLevel" then
        return quest.level < otherQuest.level;
    elseif sorting == "ByLevelReversed" then
        return quest.level > otherQuest.level;
    elseif sorting == "ByPercentCompleted" then
        return quest.completionPercent > otherQuest.completionPercent;
    elseif sorting == "ByRecentlyUpdated" then
        return quest.lastUpdated > otherQuest.lastUpdated;
    else
        ns.Log.Error("Unknown Sorting value. (" .. sorting .. ")")
    end

    return false;
end

function BQT:Initialize()
    self:SetSize(1, 1)
    self:SetFrameStrata("BACKGROUND")
    self:SetMovable(true)
    self:SetClampedToScreen(true)
    self:SetBackdrop({ bgFile = "Interface/Tooltips/UI-Tooltip-Background" })

    self:RegisterForDrag("LeftButton")
    self:SetScript("OnDragStart", self.StartMoving)
    self:SetScript("OnDragStop", function(frame)
        frame:StopMovingOrSizing();
        frame:SetUserPlaced(false);
        local x = frame:GetRight();
        local y = frame:GetTop();
        local inversedX = x - GetScreenWidth();
        local inversedY = y - GetScreenHeight();
        self.DB.Global.PositionX = inversedX;
        self.DB.Global.PositionY = inversedY;

        LibStub("AceConfigRegistry-3.0"):NotifyChange("ButterQuestTracker");
        ns.Log.Info("Moved to ( x: " .. x .. ", y: " .. y .. ").");
        ns.Log.Info("Moved to ( inversedX: " .. inversedX .. ", inversedY: " .. inversedY .. ").");
    end);

    self.clickFrames = {};

     -- These are all the gui elements
    self.gui = {
        quests = {},
        lines = {}
    };

    self:RefreshFrame();
    self:RefreshPosition();
    self:RefreshSize();
    self.initialized = true;
end

function BQT:RefreshPosition()
    self:SetPoint("TOPRIGHT", UIParent, "TOPRIGHT", self.DB.Global.PositionX, self.DB.Global.PositionY);
end

function BQT:RefreshSize(height)
    height = height or self:GetHeight();
    self:SetSize(self.DB.Global.Width, math.min(height, self.DB.Global.MaxHeight));
end

function BQT:RefreshFrame()
    if IsAltKeyDown() then
        self:EnableMouse(true);
        self:SetBackdropColor(0, 1, 0, .5);
    else
        self:EnableMouse(false);
        self:StopMovingOrSizing();
        if self.DB.Global.DeveloperMode then
            self:SetBackdropColor(1, 1, 1, 0.5);
        else
            self:SetBackdropColor(0, 0, 0, 0);
        end
    end

    for i, clickFrame in ipairs(self.clickFrames) do
        if self.DB.Global.DeveloperMode then
            clickFrame:SetBackdropColor(0, 1, 0, 0.5);
        else
            clickFrame:SetBackdropColor(0, 0, 0, 0);
        end
    end
end

function BQT:RefreshQuestWatch(criteria)
    criteria = criteria or {};

    local quests = QLH:GetQuests();

    local currentZone = GetRealZoneText();
    local minimapZone = GetMinimapZoneText();

    for questID, quest in pairs(quests) do
        self:UpdateQuestWatch(criteria, currentZone, minimapZone, quest);
    end
end

function BQT:UpdateQuestWatch(criteria, currentZone, minimapZone, quest)
    local isCurrentZone = quest.zone == currentZone or quest.zone == minimapZone;

    if self.DB.Char.MANUALLY_TRACKED_QUESTS[quest.questID] == true then
        return AddQuestWatch(quest.index);
    elseif self.DB.Char.MANUALLY_TRACKED_QUESTS[quest.questID] == false then
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

function BQT:Clear()
    for i, line in ipairs(self.gui.lines) do
        line:Hide();
    end

    -- Frames can't be destroyed, therefore they have to be reused!
    for i, clickFrame in ipairs(self.clickFrames) do
        clickFrame:Hide();
    end

    self.truncated = false;
end

function BQT:Refresh()
    ns.Log.Info("Refresh Quests");
    self:Clear();

    self:RefreshQuestWatch({
        currentZoneOnly = self.DB.Global.CurrentZoneOnly,
        hideCompletedQuests = self.DB.Global.HideCompletedQuests
    });

    local quests = QLH:GetWatchedQuests();

    local currentLineNumber = 1;

    local visibleQuestCount = 0;
    local visibleObjectiveCount = 0;

    self.gui.header = self:CreateHeader(self, "");
    self.gui.lines[currentLineNumber] = self.gui.header;

    for i, quest in spairs(quests, sortQuests) do
        if not self.truncated and visibleQuestCount < self.DB.Global.QuestLimit then
            currentLineNumber = currentLineNumber + 1;

            local questStartLineNumber = currentLineNumber;

            self.gui.quests[i] = {
                header = nil,
                readyToTurnIn = nil,
                objectives = {}
            };
            local questGUI = self.gui.quests[i];

            questGUI.header = self:CreateQuestHeader(self.gui.lines[currentLineNumber - 1], quest);
            self.gui.lines[currentLineNumber] = questGUI.header;

            local objectiveCount = table.getn(quest.objectives);

            if objectiveCount == 0 then
                currentLineNumber = currentLineNumber + 1;

                questGUI.summary = self:CreateQuestSummary(self.gui.lines[currentLineNumber - 1], quest);
                self.gui.lines[currentLineNumber] = questGUI.summary;
            elseif quest.isComplete then
                currentLineNumber = currentLineNumber + 1;
                objectiveCount = 1;

                questGUI.readyToTurnIn = self:CreateReadyToTurnIn(self.gui.lines[currentLineNumber - 1]);
                self.gui.lines[currentLineNumber] = questGUI.readyToTurnIn;
            else
                for i, objective in ipairs(quest.objectives) do
                    currentLineNumber = currentLineNumber + 1;

                    questGUI.objectives[i] = self:CreateQuestObjective(self.gui.lines[currentLineNumber - 1], objective);
                    self.gui.lines[currentLineNumber] = questGUI.objectives[i];
                end
            end

            if self:GetTop() - self.gui.lines[currentLineNumber]:GetBottom() > self.DB.Global.MaxHeight then
                self.truncated = true;
                for lineNumber = questStartLineNumber, currentLineNumber do
                    self.gui.lines[lineNumber]:Hide();
                end

                currentLineNumber = currentLineNumber - objectiveCount;

                self.gui.truncated = self:CreateTruncatedHeader(self.gui.lines[currentLineNumber - 1], "...");
                self.gui.lines[currentLineNumber] = self.gui.truncated;
            else
                visibleQuestCount = visibleQuestCount + 1;
                visibleObjectiveCount = visibleObjectiveCount + objectiveCount;
                self:SetClickFrame(i, quest, questGUI);
            end
        end
    end

    local frameHeight = 10 + visibleQuestCount * 10 + visibleObjectiveCount * 2;

    local questCount = QLH:GetQuestCount();
    if self.DB.Global.TrackerHeaderFormat == "Quests" then
        self.gui.header:SetText("Quests");
    elseif self.DB.Global.TrackerHeaderFormat == "QuestsNumberVisible" then
        if visibleQuestCount < questCount then
            self.gui.header:SetText("Quests (" .. visibleQuestCount .. "/" .. questCount .. ")");
        else
            self.gui.header:SetText("Quests");
        end
    end

    if self.truncated then
        frameHeight = frameHeight - 10;
    end

    for _, text in pairs(self.gui.lines) do
        if text:IsVisible() then
            frameHeight = frameHeight + text:GetHeight();
        end
    end

    self:RefreshSize(frameHeight);
    self:RefreshFrame();
end

function BQT:CreateFont(anchor, label)
    local font = self:CreateFontString(nil, nil, "GameFontNormal")

    font:SetText(label);
    font:SetJustifyH("LEFT");
    font:SetTextColor(0.8, 0.8, 0.8);
    font:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, 0);
    font:SetPoint("RIGHT", self, "RIGHT", -5, 0); -- This is for word-wrapping

    return font
end

function BQT:CreateHeader(anchor, label)
    local header = self:CreateFont(anchor, label)

    header:SetFont(header:GetFont(), self.DB.Global.TrackerHeaderFontSize);
    header:SetTextColor(NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b);
    header:SetPoint("TOPLEFT", anchor, "TOPLEFT", 5, -5);

    return header
end

function BQT:CreateTruncatedHeader(anchor)
    local header = self:CreateHeader(anchor, "...");

    header:SetFont(header:GetFont(), self.DB.Global.QuestHeaderFontSize);
    header:SetTextColor(NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b, 0.75);
    header:SetPoint("TOPLEFT", anchor, "TOPLEFT", 5, -5);
    header:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, -10);

    return header
end

function BQT:CreateQuestHeader(anchor, questInfo, fontString, previousFontString)
    local headerText = "[" .. questInfo.level .. "] ";

    if questInfo.isClassQuest then
        headerText = headerText .. "[C] ";
    elseif questInfo.isProfessionQuest then
        headerText = headerText .. "[P] ";
    end

    headerText = headerText .. questInfo.title;

    local header = self:CreateHeader(anchor, headerText);
    header:SetFont(header:GetFont(), self.DB.Global.QuestHeaderFontSize);
    if self.DB.Global.ColorHeadersByDifficultyLevel then
        header:SetTextColor(QLH:GetDifficultyColor(questInfo.difficulty));
    else
        header:SetTextColor(NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b)
    end

    header:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, -self.DB.Global.QuestPadding);

    return header;
end

function BQT:CreateReadyToTurnIn(anchor)
    local turnInFont = self:CreateFont(anchor, " - Ready to turn in");
    turnInFont:SetFont(turnInFont:GetFont(), self.DB.Global.ObjectiveFontSize);
    turnInFont:SetTextColor(0.0, 0.7, 0.0);
    turnInFont:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, -2);

    return turnInFont;
end

function BQT:CreateQuestSummary(anchor, quest)
    local summary = self:CreateFont(anchor, " - " .. quest.summary);

    summary:SetFont(summary:GetFont(), self.DB.Global.ObjectiveFontSize);
    summary:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, -2);

    return summary;
end

function BQT:CreateQuestObjective(anchor, objective)
    local objectiveFont = self:CreateFont(anchor, " - " .. objective.text);

    objectiveFont:SetFont(objectiveFont:GetFont(), self.DB.Global.ObjectiveFontSize);
    if objective.completed then
        objectiveFont:SetTextColor(HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b);
    end

    objectiveFont:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, -2);

    return objectiveFont;
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

function BQT:SetClickFrame(i, quest, gui)
    local clickFrame = self.clickFrames[i];

    if not clickFrame then
        self.clickFrames[i] = CreateFrame("Frame");
        clickFrame = self.clickFrames[i];
        clickFrame:SetBackdrop({ bgFile = "Interface/Tooltips/UI-Tooltip-Background" });
        clickFrame:SetScript("OnMouseUp", function(self)
            if GetMouseButtonClicked() == "RightButton" then
                BQT:ToggleContextMenu(self.quest);
            elseif IsShiftKeyDown() then
                BQT.DB.Char.MANUALLY_TRACKED_QUESTS[self.quest.questID] = false;
                RemoveQuestWatch(self.quest.index);
                PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON);
            elseif IsControlKeyDown() then
                ChatEdit_InsertLink("[" .. self.quest.title .. "]");
            elseif IsAltKeyDown() then
                BQT:ShowWowheadPopup("quest", self.quest.questID);
            else
                CloseDropDownMenus();
                QLH:ToggleQuest(self.quest.index);
            end
        end);

        clickFrame:SetScript("OnEnter", function(self)
            self.gui.header:SetTextColor(HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b);

            if self.gui.readyToTurnIn then
                self.gui.readyToTurnIn:SetTextColor(HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b);
            end

            if self.gui.summary then
                self.gui.summary:SetTextColor(HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b);
            end

            for j, objective in ipairs(self.quest.objectives) do
                local objectiveGUI = self.gui.objectives and self.gui.objectives[j];

                if objectiveGUI then
                    objectiveGUI:SetTextColor(HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b);
                end
            end
        end);

        clickFrame:SetScript("OnLeave", function(self)
            if BQT.DB.Global.ColorHeadersByDifficultyLevel then
                self.gui.header:SetTextColor(QLH:GetDifficultyColor(self.quest.difficulty));
            else
                self.gui.header:SetTextColor(NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b)
            end

            if self.gui.readyToTurnIn then
                self.gui.readyToTurnIn:SetTextColor(0.0, 0.7, 0.0);
            end

            if self.gui.summary then
                self.gui.summary:SetTextColor(.8, .8, .8);
            end

            for j, objective in ipairs(self.quest.objectives) do
                local objectiveGUI = self.gui.objectives and self.gui.objectives[j];

                if objectiveGUI then
                    if objective.completed then
                        objectiveGUI:SetTextColor(HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b);
                    else
                        objectiveGUI:SetTextColor(.8, .8, .8);
                    end
                end
            end
        end);
    end

    clickFrame:Show();

    local lastObjective;
    if gui.readyToTurnIn then
        lastObjective = gui.readyToTurnIn;
    elseif gui.summary then
        lastObjective = gui.summary;
    elseif gui.objectives and table.getn(gui.objectives) > 0 then
        lastObjective = gui.objectives[table.getn(gui.objectives)];
    else
        lastObjective = gui.header;
    end

    clickFrame:SetPoint("TOPLEFT", gui.header, "TOPLEFT", 0, 0);
    clickFrame:SetPoint("TOPRIGHT", gui.header, "TOPRIGHT", 0, 0);
    clickFrame:SetPoint("BOTTOMLEFT", lastObjective, "BOTTOMLEFT", 0, 0);
    clickFrame:SetPoint("BOTTOMRIGHT", lastObjective, "BOTTOMRIGHT", 0, 0);
    clickFrame.quest = quest;
    clickFrame.gui = gui;
end

function BQT:ADDON_LOADED(addon)
    if addon == NAME then
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

        self.DB = {
            Global = ButterQuestTrackerConfig,
            Char = ButterQuestTrackerCharacterConfig,
        };

        ns.Log.Info("ADDON_LOADED");

        QWH:BypassWatchLimit(self.DB.Char.MANUALLY_TRACKED_QUESTS);
        QWH:KeepHidden();

        QWH:OnQuestWatchUpdated(function(questWatchUpdates)
            for index, updateInfo in pairs(questWatchUpdates) do
                local questID = QLH:GetQuestIDFromIndex(index);

                if updateInfo.byUser then
                    if updateInfo.watched then
                        self.DB.Char.MANUALLY_TRACKED_QUESTS[questID] = true;
                    else
                        self.DB.Char.MANUALLY_TRACKED_QUESTS[questID] = false;
                    end
                end
            end

            self:Refresh();
        end);

        QLH:OnQuestUpdated(function(updatedQuests)
            ns.Log.Trace("Event(OnQuestUpdated)");
            for questID, updatedQuest in pairs(updatedQuests) do
                if updatedQuest.abandoned then
                    self.DB.Char.QUESTS_LAST_UPDATED[questID] = nil;
                else
                    self.DB.Char.QUESTS_LAST_UPDATED[questID] = updatedQuest.lastUpdated;

                    -- TODO: This is how we're going to automatically track updated quests.
                    -- if not updatedQuests.initialUpdate and QWH:IsAutomaticQuestWatchEnabled() then
                    --     print('auto quest watch');
                    -- end
                end
            end

            self:Refresh();
        end);

        self.DB.Char.QUESTS_LAST_UPDATED = QLH:SetQuestsLastUpdated(self.DB.Char.QUESTS_LAST_UPDATED);

        self:Initialize();
        self:Refresh();
        self:UnregisterEvent("ADDON_LOADED");
    end
end

function BQT:ZONE_CHANGED()
    ns.Log.Info("Changed Zones: (" .. GetRealZoneText() .. ", " .. GetMinimapZoneText() .. ")");
    self:Refresh();
end

function BQT:MODIFIER_STATE_CHANGED()
    ns.Log.Trace("MODIFIER_STATE_CHANGED");
    if self:IsMouseOver() or self:IsMouseEnabled() then
        self:RefreshFrame();
    end
end

function BQT:OnEvent(event, ...)
    self[event](self, ...)
end

BQT:RegisterEvent("ADDON_LOADED");
BQT:RegisterEvent("MODIFIER_STATE_CHANGED");
BQT:RegisterEvent("ZONE_CHANGED");
BQT:SetScript("OnEvent", BQT.OnEvent)
