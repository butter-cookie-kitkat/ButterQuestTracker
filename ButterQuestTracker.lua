local NAME, ns = ...

local BQT = CreateFrame("Frame", nil, UIParent)

local AnchorFrame = CreateFrame("Frame")
local ClickFrames = {}
local frameWidth = 250

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
	tinsert(waitTable,{delay,func,{...}})
	return true
end

function BQT:Initialize()
	-- local background = self:CreateTexture(nil, "BACKGROUND")
	-- background:SetAllPoints()
	-- background:SetColorTexture(1, 1, 1, 0.5)
	-- background:SetGradientAlpha("VERTICAL", 0, 0, 0, 0, 0, 0, 0, 0.6)

	AnchorFrame:SetSize(1, 1)
	self:SetFrameStrata("BACKGROUND")
	self:SetMovable(true)
	self:SetClampedToScreen(true)
	self:SetBackdrop({ bgFile = "Interface/Tooltips/UI-Tooltip-Background" })
	
	self:RegisterForDrag("LeftButton")
	self:SetScript("OnDragStart", self.StartMoving)
	self:SetScript("OnDragStop", function(frame)
		frame:StopMovingOrSizing()
		frame:SetUserPlaced(false)
		local effectiveScale = UIParent:GetEffectiveScale()
		local right = frame:GetRight() * effectiveScale
		local top = frame:GetTop() * effectiveScale
		ButterQuestTrackerConfig.Position = {"TOPRIGHT", "UIParent", "BOTTOMLEFT", right, top}
	end)

	local oldSetPoint = self.SetPoint
	self.SetPoint = function(frame, point, relativeTo, relativePoint, x, y, override)
		if override then
			oldSetPoint(frame, point, relativeTo, relativePoint, x, y)
		end
	end
		
	self.fontStrings = {};

	self:RefreshFrame()
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
				SelectQuestLogEntry(index);
				local _, desc = GetQuestLogQuestText()
	
				tinsert(objectives, {
					text = desc,
					finished = false
				})
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
		self.fontStrings[i] = nil;
	end

	for i, clickFrame in ipairs(ClickFrames) do
		clickFrame:Hide();
		ClickFrames[i] = nil;
	end
end

function BQT:LoadQuests()
	self:Clear()
	
	local currentLineNumber = 1

	local quests, questCount = self:GetQuests({
		currentZoneOnly = ButterQuestTrackerConfig.CurrentZoneOnly
	})

	local visibleQuestCount = 0
	local visibleObjectiveCount = 0
	
	local header = self:CreateHeader(self, self, "Quests")
	self.fontStrings[currentLineNumber] = header

	for i, quest in ipairs(quests) do
		if visibleQuestCount < ButterQuestTrackerConfig.QuestLimit then
			currentLineNumber = currentLineNumber + 1
			visibleQuestCount = visibleQuestCount + 1

			self.fontStrings[currentLineNumber] = self:CreateQuestHeader(self, self.fontStrings[currentLineNumber - 1], quest)
			quest.gui.header = self.fontStrings[currentLineNumber]
	
			if quest.isComplete == 1 then
				currentLineNumber = currentLineNumber + 1
				visibleObjectiveCount = visibleObjectiveCount + 1
	
				self.fontStrings[currentLineNumber] = self:CreateReadyToTurnIn(self, self.fontStrings[currentLineNumber - 1])
				quest.gui.readyToTurnIn = self.fontStrings[currentLineNumber]
			else
				for _, objective in ipairs(quest.objectives) do
					currentLineNumber = currentLineNumber + 1
					visibleObjectiveCount = visibleObjectiveCount + 1
		
					self.fontStrings[currentLineNumber] = self:CreateQuestObjective(self, self.fontStrings[currentLineNumber - 1], objective)
				end
			end
	
			self:SetClickFrame(quest)
		end
	end

	if visibleQuestCount < questCount then
		header:SetText("Quests (" .. visibleQuestCount .. "/" .. questCount .. ")")
	end
	
	local frameHeight = 20 + (visibleQuestCount - 1) * 10 + visibleObjectiveCount * 2
	
	for _, text in pairs(self.fontStrings) do
		frameHeight = frameHeight + text:GetHeight()
	end
	
	self:SetSize(frameWidth, frameHeight)
end

function BQT:CreateFont(self, anchor, label)
	local font = self:CreateFontString(nil, nil, "GameFontNormal")

	font:SetShadowOffset(1, -2)
	font:SetText(label)
	font:SetJustifyH("LEFT")
	font:SetTextColor(0.8, 0.8, 0.8)
	font:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, 0)
	font:SetPoint("RIGHT", self, "RIGHT", -5, 0) -- This is for word-wrapping

	return font
end

function BQT:CreateHeader(self, anchor, label)
	local header = self:CreateFont(self, anchor, label)

	header:SetTextColor(NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b)	
	header:SetPoint("TOPLEFT", anchor, "TOPLEFT", 5, -5)

	return header
end

function BQT:CreateQuestHeader(self, anchor, questInfo, fontString, previousFontString)
	local headerText = "[" .. questInfo.level .. "] "
	
	if questInfo.isClassQuest then
		headerText = headerText .. "[C] "
	end

	headerText = headerText .. questInfo.title

	local header = self:CreateHeader(self, anchor, headerText)
	
	header:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, -10)

	return header
end

function BQT:CreateReadyToTurnIn(self, anchor)
	local turnInFont = self:CreateFont(self, anchor, " - Ready to turn in")
	turnInFont:SetTextColor(0.0, 0.7, 0.0)
	turnInFont:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, -2)

	return turnInFont
end

function BQT:CreateQuestObjective(self, anchor, objective)
	local objectiveFont = self:CreateFont(self, anchor, " - " .. objective.text)
	
	if objective.finished then
		objectiveFont:SetTextColor(HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b)
	end
	
	objectiveFont:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, -2)

	objective.gui = objectiveFont

	return objectiveFont
end

local function OnMouseUp(self)
	if IsShiftKeyDown() then
		local questID = GetQuestIDFromLogIndex(self.quest.index)
		for index, value in ipairs(QUEST_WATCH_LIST) do
			if value.id == questID then
				tremove(QUEST_WATCH_LIST, index)
			end
		end
		RemoveQuestWatch(self.quest.index)
		QuestWatch_Update()
	else
		if QuestLogEx then
			ShowUIPanel(QuestLogExFrame)
			QuestLogEx:QuestLog_SetSelection(self.quest.index)
			QuestLogEx:Maximize()
		elseif ClassicQuestLog then
			ShowUIPanel(ClassicQuestLog)
			QuestLog_SetSelection(self.quest.index)
		else
			ShowUIPanel(QuestLogFrame)
			QuestLog_SetSelection(self.quest.index)
			local valueStep = QuestLogListScrollFrame.ScrollBar:GetValueStep()
			QuestLogListScrollFrame.ScrollBar:SetValue(self.quest.index * valueStep / 2)
		end
	end
end

local function OnEnter(self)
	self.quest.gui.header:SetTextColor(HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b)
	
	for _, objective in ipairs(self.quest.objectives) do
		if objective.gui ~= nil then
			objective.gui:SetTextColor(HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b)
		end
	end
end

local function OnLeave(self)
	self.quest.gui.header:SetTextColor(NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b)
	
	for _, objective in ipairs(self.quest.objectives) do
		if objective.gui ~= nil then
			if objective.done then
				objective.gui:SetTextColor(HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b)
			else
				objective.gui:SetTextColor(.8, .8, .8)
			end
		end
	end
end

function BQT:SetClickFrame(quest)
	if not ClickFrames[quest.index] then
		ClickFrames[quest.index] = CreateFrame("Frame")
		ClickFrames[quest.index]:SetScript("OnMouseUp", OnMouseUp)
		ClickFrames[quest.index]:SetScript("OnEnter", OnEnter)
		ClickFrames[quest.index]:SetScript("OnLeave", OnLeave)
	end
	local f = ClickFrames[quest.index]
	f:SetAllPoints(quest.gui.header)
	f.quest = quest
end

function BQT:SetPosition(point, relativeTo, relativePoint, x, y)
	AnchorFrame:ClearAllPoints()
	AnchorFrame:SetPoint(point, relativeTo, relativePoint, x, y)
	self:ClearAllPoints()
	self:SetPoint("TOPRIGHT", AnchorFrame, "TOPRIGHT", 0, 0, true)
end

function BQT:ADDON_LOADED(addon)
	if addon == NAME then
		ns.Log.Info("ADDON_LOADED")

		if ButterQuestTrackerConfig.DeveloperMode then
			ns.Log.Info("Forcibly refreshing from defaults...")
			ButterQuestTrackerConfig = CopyTable(ns.CONSTANTS.DEFAULT_CONFIG)
			ButterQuestTrackerConfig.DeveloperMode = true
		elseif not ButterQuestTrackerConfig or not ButterQuestTrackerConfig.VERSION or ButterQuestTrackerConfig.VERSION < ns.CONSTANTS.DEFAULT_CONFIG.VERSION then
			ButterQuestTrackerConfig = CopyTable(ns.CONSTANTS.DEFAULT_CONFIG)
		end

		self:Initialize()
		self:SetPosition(unpack(ButterQuestTrackerConfig.Position))
		self:LoadQuests()
		self:UnregisterEvent("ADDON_LOADED")
	end
end

function BQT:QUEST_LOG_UPDATE()
	ns.Log.Info("QUEST_LOG_UPDATE")
	self:LoadQuests()
end

function BQT:ZONE_CHANGED_NEW_AREA()
	ns.Log.Info("ZONE_CHANGED_NEW_AREA")
	self:LoadQuests()
end

function BQT:MODIFIER_STATE_CHANGED()
	ns.Log.Info("MODIFIER_STATE_CHANGED")
	if self:IsMouseOver() or self:IsMouseEnabled() then
		self:RefreshFrame()
	end
end

function BQT:QUEST_WATCH_LIST_CHANGED()
	ns.Log.Info("QUEST_WATCH_LIST_CHANGED")
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

ns.BQT = BQT