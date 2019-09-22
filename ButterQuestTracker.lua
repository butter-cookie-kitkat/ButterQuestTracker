local NAME, ns = ...

ButterQuestTracker = CreateFrame("Frame", nil, UIParent);
local BQT = ButterQuestTracker;

local waitTable = {};
local waitFrame = nil;
local function BQT__wait(delay, func, ...)
	if type(delay) ~= "number" or type(func) ~= "function" then
	  return false;
	end

	if waitFrame == nil then
		waitFrame = CreateFrame("Frame","WaitFrame", UIParent)
		waitFrame:SetScript("onUpdate", function (self, elapse)
			local count = #waitTable
			local i = 1
			while i <= count do
				local waitRecord = tremove(waitTable,i)
				local d = tremove(waitRecord,1)
				local f = tremove(waitRecord,1)
				local p = tremove(waitRecord,1)
				if d > elapse then
					tinsert(waitTable,i,{d-elapse,f,p})
					i = i + 1
				else
					count = count - 1
					f(unpack(p))
				end
			end
		end)
	end
	tinsert(waitTable, {
		delay,
		func,
		{...}
	});
	return true
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
		local x = (frame:GetRight() - GetScreenWidth()) * UIParent:GetEffectiveScale();
		local y = (frame:GetTop() - GetScreenHeight()) * UIParent:GetEffectiveScale();
		ButterQuestTrackerConfig.PositionX = x;
		ButterQuestTrackerConfig.PositionY = y;

		LibStub("AceConfigRegistry-3.0"):NotifyChange("ButterQuestTracker");
		ns.Log.Info("Moved to (" .. x .. ", " .. y .. ").")
	end);
		
	self.fontStrings = {};
	self.clickFrames = {};

	self:RefreshFrame();
	self:RefreshPosition();
end

function BQT:RefreshPosition() 
	self:SetPoint("TOPRIGHT", UIParent, "TOPRIGHT", ButterQuestTrackerConfig.PositionX, ButterQuestTrackerConfig.PositionY);
end

function BQT:RefreshSize(height) 
	height = height or self:GetHeight();
	self:SetSize(ButterQuestTrackerConfig.Width, math.min(height, ButterQuestTrackerConfig.MaxHeight));
end

function BQT:RefreshFrame()
	if IsAltKeyDown() then
		self:EnableMouse(true)
		self:SetBackdropColor(0, 1, 0, .5)
	else
		self:EnableMouse(false) 
		self:StopMovingOrSizing()
		if ButterQuestTrackerConfig.DeveloperMode then
			self:SetBackdropColor(1, 1, 1, 0.5)
		else
			self:SetBackdropColor(0, 0, 0, 0)
		end
	end

	for i, clickFrame in ipairs(self.clickFrames) do
		if ButterQuestTrackerConfig.DeveloperMode then
			clickFrame:SetBackdropColor(0, 1, 0, 0.5);
		else
			clickFrame:SetBackdropColor(0, 0, 0, 0);
		end
	end
end

function BQT:GetQuests(criteria)
	criteria = criteria or {}
	local numberOfEntries, questCount = GetNumQuestLogEntries()

	local currentZone = GetRealZoneText()
	local minimapZone = GetMinimapZoneText()

	local class = UnitClass("player")
	local zone
	local quests = {}
	for index = 1, numberOfEntries, 1 do
		local title, level, suggestedGroup, isHeader, _, isComplete, frequency, questID, startEvent, displayQuestID, isOnMap, hasLocalPOI, isTask, isBounty, isStory, isHidden, isScaling = GetQuestLogTitle(index);
		local isCurrentMinimapZone = zone == minimapZone
		local isCurrentZone = zone == currentZone or isCurrentMinimapZone
		local isClassQuest = zone == class

		if isHeader then
			zone = title
		elseif criteria.currentZoneOnly == false or isCurrentZone or isClassQuest then
			local objectives = C_QuestLog.GetQuestObjectives(questID)

			-- Utilize the Quest Description if it doesn't have any objectives
			if table.getn(objectives) == 0 then
				-- TODO: Not a big fan of this since we're mucking with the users selected quest in the quest log.
				-- Is there an alternative way to get the quest text.. ?
				self:SelectQuestLogEntry(index, function()
					local _, desc = GetQuestLogQuestText()
		
					tinsert(objectives, {
						text = desc,
						finished = false
					});
				end);
			end
			
			tinsert(quests, {
				index = index,
				title = title,
				level = level,
				isComplete = isComplete,
				questID = questID,
				zone = zone,
				objectives = objectives,
				isCurrentZone = isCurrentZone,
				isCurrentMinimapZone = isCurrentMinimapZone,
				isClassQuest = isClassQuest,
				gui = {}
			})
		end
	end

	return quests, questCount
end

function BQT:Clear()
	if QuestWatchFrame:IsVisible() then
		QuestWatchFrame:Hide()
	end

	for i, fontString in ipairs(self.fontStrings) do
		fontString:Hide();
	end

	-- Frames can't be destroyed, therefore they have to be reused!
	for i, clickFrame in ipairs(self.clickFrames) do
		clickFrame:Hide();
	end

	self.truncated = false;
end

function BQT:LoadQuests()
	ns.Log.Info("Load Quests");
	self:Clear();
	
	local currentLineNumber = 1;

	local quests, questCount = self:GetQuests({
		currentZoneOnly = ButterQuestTrackerConfig.CurrentZoneOnly;
	});

	local visibleQuestCount = 0;
	local visibleObjectiveCount = 0;
	
	local header = self:CreateHeader(self, "Quests");
	self.fontStrings[currentLineNumber] = header;

	for i, quest in ipairs(quests) do
		if not self.truncated and visibleQuestCount < ButterQuestTrackerConfig.QuestLimit then
			currentLineNumber = currentLineNumber + 1;

			local questStartLineNumber = currentLineNumber;
			local objectiveCount = 0;

			self.fontStrings[currentLineNumber] = self:CreateQuestHeader(self.fontStrings[currentLineNumber - 1], quest);
			quest.gui.header = self.fontStrings[currentLineNumber];
	
			if quest.isComplete == 1 then
				currentLineNumber = currentLineNumber + 1;
				objectiveCount = objectiveCount + 1;
	
				self.fontStrings[currentLineNumber] = self:CreateReadyToTurnIn(self.fontStrings[currentLineNumber - 1]);
				quest.gui.readyToTurnIn = self.fontStrings[currentLineNumber];
			else
				for _, objective in ipairs(quest.objectives) do
					currentLineNumber = currentLineNumber + 1;
					objectiveCount = objectiveCount + 1;
		
					self.fontStrings[currentLineNumber] = self:CreateQuestObjective(self.fontStrings[currentLineNumber - 1], objective);
				end
			end

			if self:GetTop() - self.fontStrings[currentLineNumber]:GetBottom() > ButterQuestTrackerConfig.MaxHeight then
				self.truncated = true;
				for lineNumber = questStartLineNumber, currentLineNumber do
					self.fontStrings[lineNumber]:Hide();
				end

				currentLineNumber = currentLineNumber - objectiveCount;

				self.fontStrings[currentLineNumber] = self:CreateTruncatedHeader(self.fontStrings[currentLineNumber - 1], "...");
			else
				visibleQuestCount = visibleQuestCount + 1;
				visibleObjectiveCount = visibleObjectiveCount + objectiveCount;
				self:SetClickFrame(i, quest);
			end
		end
	end

	if visibleQuestCount < questCount then
		header:SetText("Quests (" .. visibleQuestCount .. "/" .. questCount .. ")");
	end
	
	local frameHeight = 10 + visibleQuestCount * 10 + visibleObjectiveCount * 2;

	if self.truncated then
		frameHeight = frameHeight - 10;
	end
	
	for _, text in pairs(self.fontStrings) do
		if text:IsVisible() then
			frameHeight = frameHeight + text:GetHeight();
		end
	end
	
	self:RefreshSize(frameHeight);
	self:RefreshFrame();
end

function BQT:CreateFont(anchor, label)
	local font = self:CreateFontString(nil, nil, "GameFontNormal")

	font:SetShadowOffset(1, -2)
	font:SetText(label)
	font:SetJustifyH("LEFT")
	font:SetTextColor(0.8, 0.8, 0.8)
	font:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, 0)
	font:SetPoint("RIGHT", self, "RIGHT", -5, 0) -- This is for word-wrapping

	return font
end

function BQT:CreateHeader(anchor, label)
	local header = self:CreateFont(anchor, label)

	header:SetTextColor(NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b)	
	header:SetPoint("TOPLEFT", anchor, "TOPLEFT", 5, -5)

	return header
end

function BQT:CreateTruncatedHeader(anchor)
	local header = self:CreateHeader(anchor, "...");

	header:SetTextColor(NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b, 0.75);
	header:SetPoint("TOPLEFT", anchor, "TOPLEFT", 5, -5);
	header:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, -10);

	return header
end

function BQT:CreateQuestHeader(anchor, questInfo, fontString, previousFontString)
	local headerText = "[" .. questInfo.level .. "] ";
	
	if questInfo.isClassQuest then
		headerText = headerText .. "[C] ";
	end

	headerText = headerText .. questInfo.title;

	local header = self:CreateHeader(anchor, headerText);
	
	header:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, -10);

	return header;
end

function BQT:CreateReadyToTurnIn(anchor)
	local turnInFont = self:CreateFont(anchor, " - Ready to turn in")
	turnInFont:SetTextColor(0.0, 0.7, 0.0)
	turnInFont:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, -2)

	return turnInFont
end

function BQT:CreateQuestObjective(anchor, objective)
	local objectiveFont = self:CreateFont(anchor, " - " .. objective.text)
	
	if objective.finished then
		objectiveFont:SetTextColor(HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b)
	end
	
	objectiveFont:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, -2)

	objective.gui = objectiveFont

	return objectiveFont
end

function BQT:IsQuestLogPanelVisible()
	if QuestLogEx then
		return QuestLogExFrame:IsVisible();
	elseif ClassicQuestLog then
		return ClassicQuestLog:IsVisible();
	else
		return QuestLogFrame:IsVisible();
	end
end

function BQT:ViewQuest(quest)
	local isQuestAlreadyOpen = GetQuestLogSelection() == quest.index and self:IsQuestLogPanelVisible();

	if QuestLogEx then
		ns.Log.Trace('Clicked Quest with QuestLogEx enabled.');
		if isQuestAlreadyOpen then
			HideUIPanel(QuestLogExFrame);
		else
			ShowUIPanel(QuestLogExFrame);
			QuestLogEx:QuestLog_SetSelection(quest.index);
			QuestLogEx:Maximize();
		end
	elseif ClassicQuestLog then
		ns.Log.Trace('Clicked Quest with ClassicQuestLog enabled.');
		if isQuestAlreadyOpen then
			HideUIPanel(ClassicQuestLog);
		else
			ShowUIPanel(ClassicQuestLog);
			QuestLog_SetSelection(quest.index);
		end
	else
		ns.Log.Trace('Clicked Quest with Default enabled.');
		if isQuestAlreadyOpen then
			HideUIPanel(QuestLogFrame);
		else
			ShowUIPanel(QuestLogFrame);
			QuestLog_SetSelection(quest.index);
			local valueStep = QuestLogListScrollFrame.ScrollBar:GetValueStep();
			QuestLogListScrollFrame.ScrollBar:SetValue(quest.index * valueStep / 2);
		end
	end
end

function BQT:SelectQuestLogEntry(index, func)
	local currentSelection = GetQuestLogSelection();
	
	SelectQuestLogEntry(index);
	func();

	SelectQuestLogEntry(currentSelection);
end

function BQT:ToggleContextMenu(quest)
	if not self.contextMenu then
		self.contextMenu = CreateFrame("Frame", "WPDemoContextMenu", UIParent, "UIDropDownMenuTemplate");
	end

	local isActive = UIDROPDOWNMENU_OPEN_MENU == self.contextMenu;
	local hasQuestChanged = not self.contextMenu.quest or self.contextMenu.quest.questID ~= quest.questID;

	self.contextMenu.quest = quest;

	UIDropDownMenu_Initialize(self.contextMenu, function(frame, level, menuList)
		self:SelectQuestLogEntry(quest.index, function()
			UIDropDownMenu_AddButton({
				text = quest.title,
				notCheckable = true,
				isTitle = true
			});
	
			UIDropDownMenu_AddButton({
				text = "View Quest",
				notCheckable = true,
				func = function()
					self:ViewQuest(quest);
				end
			});
	
			UIDropDownMenu_AddButton({
				text = "Share Quest",
				notCheckable = true,
				disabled = not UnitInParty("player") or not GetQuestLogPushable(),
				func = function()
					self:SelectQuestLogEntry(quest.index, function()
						QuestLogPushQuest();
					end);
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
					SetAbandonQuest(quest.index);
					AbandonQuest();
				end
			});
		end);
	end, "MENU");

	-- If this Dropdown menu isn't already open then play the sound effect.
	if isActive and not hasQuestChanged then
		CloseDropDownMenus();
	else
		ToggleDropDownMenu(1, nil, self.contextMenu, "cursor", 0, -3);
		PlaySound(SOUNDKIT.IG_MAINMENU_OPEN);
	end
end

function BQT:SetClickFrame(i, quest)
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
				BQT:ViewQuest(self.quest);
			end
		end);

		clickFrame:SetScript("OnEnter", function(self)
			self.quest.gui.header:SetTextColor(HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b);
			
			for _, objective in ipairs(self.quest.objectives) do
				if objective.gui ~= nil then
					objective.gui:SetTextColor(HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b);
				end
			end
		end);

		clickFrame:SetScript("OnLeave", function(self)
			self.quest.gui.header:SetTextColor(NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b);
			
			for _, objective in ipairs(self.quest.objectives) do
				if objective.gui ~= nil then
					if objective.done then
						objective.gui:SetTextColor(HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b);
					else
						objective.gui:SetTextColor(.8, .8, .8);
					end
				end
			end
		end);
	end

	clickFrame:Show();

	local height = quest.gui.header:GetHeight();

	if quest.gui.readyToTurnIn then
		height = height + quest.gui.readyToTurnIn:GetHeight();
	end
	
	for i, objective in ipairs(quest.objectives) do
		if objective.gui then
			height = height + objective.gui:GetHeight();
		end
	end

	clickFrame:SetPoint("TOPLEFT", quest.gui.header, "TOPLEFT", 0, 0);
	clickFrame:SetPoint("TOPRIGHT", quest.gui.header, "TOPRIGHT", 0, 0);
	clickFrame:SetHeight(height);
	clickFrame.quest = quest
end

function BQT:ADDON_LOADED(addon)
	if addon == NAME then
		if not ButterQuestTrackerConfig or not ButterQuestTrackerConfig.VERSION or ButterQuestTrackerConfig.VERSION < ns.CONSTANTS.DEFAULT_CONFIG.VERSION then
			ButterQuestTrackerConfig = CopyTable(ns.CONSTANTS.DEFAULT_CONFIG)
		end

		ns.Log.Info("ADDON_LOADED");
		self:Initialize();
		self:UnregisterEvent("ADDON_LOADED");
	end
end

function BQT:QUEST_LOG_UPDATE()
	ns.Log.Trace("QUEST_LOG_UPDATE")
	self:LoadQuests()
end

function BQT:ZONE_CHANGED_NEW_AREA()
	ns.Log.Info("ZONE_CHANGED_NEW_AREA")
	self:LoadQuests()
end

function BQT:MODIFIER_STATE_CHANGED()
	ns.Log.Trace("MODIFIER_STATE_CHANGED")
	if self:IsMouseOver() or self:IsMouseEnabled() then
		self:RefreshFrame()
	end
end

function BQT:QUEST_WATCH_LIST_CHANGED()
	ns.Log.Trace("QUEST_WATCH_LIST_CHANGED")
	-- The watch quest hasn't been made visible yet so we need to wait...
	BQT__wait(0.0001, function ()
		if QuestWatchFrame:IsVisible() then
			QuestWatchFrame:Hide()
		end
	end)
end

function BQT:OnEvent(event, ...)
	self[event](self, ...)
end

BQT:RegisterEvent("ADDON_LOADED")
BQT:RegisterEvent("QUEST_LOG_UPDATE")
BQT:RegisterEvent("MODIFIER_STATE_CHANGED")
BQT:RegisterEvent("ZONE_CHANGED_NEW_AREA")
BQT:RegisterEvent("QUEST_WATCH_LIST_CHANGED")
BQT:SetScript("OnEvent", BQT.OnEvent)