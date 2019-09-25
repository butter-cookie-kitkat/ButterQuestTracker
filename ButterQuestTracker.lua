local NAME, ns = ...

local QWH = LibStub("QuestWatchHelper-1.0");
local QLH = LibStub("QuestLogHelper-1.0");

ButterQuestTracker = CreateFrame("Frame", nil, UIParent);
local BQT = ButterQuestTracker;

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

    self.forciblyTrackedQuests = {}; -- These are quests that can't be untracked unless a filter is disabled

     -- These are all the gui elements
    self.gui = {
        quests = {},
        lines = {}
    };

	self:RefreshFrame();
	self:RefreshPosition();
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
    self.forciblyTrackedQuests = {};

    local quests = QLH:GetQuests();

	local currentZone = GetRealZoneText();
    local minimapZone = GetMinimapZoneText();

    for questID, quest in pairs(quests) do
        -- RemoveQuestWatch(quest.index);
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
            self.forciblyTrackedQuests[quest.questID] = true;
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
	ns.Log.Info("Load Quests");
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

			if quest.isComplete then
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

	header:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, -10);

	return header;
end

function BQT:CreateReadyToTurnIn(anchor)
	local turnInFont = self:CreateFont(anchor, " - Ready to turn in");
    turnInFont:SetFont(turnInFont:GetFont(), self.DB.Global.ObjectiveFontSize);
	turnInFont:SetTextColor(0.0, 0.7, 0.0);
	turnInFont:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, -2);

	return turnInFont;
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

	UIDropDownMenu_Initialize(self.contextMenu, function(frame, level, menuList)
        UIDropDownMenu_AddButton({
            text = quest.title,
            notCheckable = true,
            isTitle = true
        });

        UIDropDownMenu_AddButton({
            text = "Untrack Quest",
            notCheckable = true,
            disabled = self.forciblyTrackedQuests[self.contextMenu.quest.questID],
            func = function()
                self.DB.Char.MANUALLY_TRACKED_QUESTS[self.contextMenu.quest.questID] = false;
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
                SetAbandonQuest(self.contextMenu.quest.index);
                AbandonQuest();
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
				ChatEdit_InsertLink("[" .. self.quest.title .. "] ");
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
    else
		lastObjective = gui.objectives[table.getn(gui.objectives)];
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

        QWH:BypassWatchLimit(self.DB.Global.TRACKED_QUESTS);
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

        self:Initialize();

		ns.Log.Info("ADDON_LOADED");
		self:UnregisterEvent("ADDON_LOADED");
	end
end

function BQT:QUEST_LOG_UPDATE()
	ns.Log.Trace("QUEST_LOG_UPDATE");
	self:Refresh();
end

function BQT:ZONE_CHANGED_NEW_AREA()
	ns.Log.Info("ZONE_CHANGED_NEW_AREA");
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
BQT:RegisterEvent("QUEST_LOG_UPDATE");
BQT:RegisterEvent("MODIFIER_STATE_CHANGED");
BQT:RegisterEvent("ZONE_CHANGED_NEW_AREA");
BQT:SetScript("OnEvent", BQT.OnEvent)
