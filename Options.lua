local _, ns = ...

local frame = CreateFrame("Frame", nil, InterfaceOptionsFramePanelContainer)
frame.name = "ButterQuestTracker"
frame:Hide()

frame:SetScript("OnShow", function(self)
	self:CreateOptions()
	self:SetScript("OnShow", nil)
end)

local function createCheckBox(parent, anchor, number, property, label, tooltip)
	local checkbox = CreateFrame("CheckButton", "ButterQuestTrackerCheckBox" .. number, parent, "ChatConfigCheckButtonTemplate")
	checkbox:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 16, number * -26)

	local checkboxLabel = _G[checkbox:GetName() .. "Text"]
	checkboxLabel:SetText(label)
	checkboxLabel:SetPoint("TOPLEFT", checkbox, "RIGHT", 5, 7)

	checkbox.tooltip = tooltip
	checkbox:SetChecked(property)

	return checkbox
end

local function createSlider(parent, anchor, number, property, label, tooltip, min, max, step, overrideLabels)
	min = min or 0
	max = max or 100
	step = step or 1
	overrideLabels = overrideLabels or {}

	local slider = CreateFrame("Slider", "ButterQuestTrackerSlider" .. number, parent, "OptionsSliderTemplate")
	slider:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 16, number * -26 - 13)
	slider:SetWidth(300)

	getglobal(slider:GetName() .. "Low"):SetText(property == min and overrideLabels.min or min)
	getglobal(slider:GetName() .. "High"):SetText(property == max and overrideLabels.max or property)
	getglobal(slider:GetName() .. "Text"):SetText(label)

	slider.tooltipText = tooltip
	slider:SetMinMaxValues(min, max)
	slider:SetValueStep(step)
	slider:SetStepsPerPage(step)
	slider:SetObeyStepOnDrag(true)
	slider:SetValue(property)

	slider:SetScript("OnValueChanged", function(self, value)
		getglobal(slider:GetName() .. "High"):SetText(value == max and overrideLabels.max or value)
	end)

	return slider
end

function frame:CreateOptions()
	local title = self:CreateFontString(nil, nil, "GameFontNormalLarge")
	title:SetPoint("TOPLEFT", 16, -16)
	title:SetText("ButterQuestTracker v" .. ns.CONSTANTS.DEFAULT_CONFIG.VERSION)

	local currentZoneOnly = createCheckBox(self, title, 1, ButterQuestTrackerConfig.CurrentZoneOnly, "Current Zone Only", "Only displays quests relevant to the current zone.")
	currentZoneOnly:SetScript("PostClick", function(self, button, down)
		ButterQuestTrackerConfig.CurrentZoneOnly = self:GetChecked()
        ns.BQT:LoadQuests()
    end)

	local questLimit = createSlider(self, title, 2, ButterQuestTrackerConfig.QuestLimit, "Quest Limit", "Limits the number of visible Quests.", 1, 20)
	questLimit:HookScript("OnValueChanged", function(self, value)
		ButterQuestTrackerConfig.QuestLimit = value
		ns.BQT:LoadQuests()
	end)

	local developerMode = createCheckBox(self, title, 4, ButterQuestTrackerConfig.DeveloperMode, "Developer Mode", "Enables logging and visual changes to make Development easier.")
	developerMode:SetScript("PostClick", function(self, button, down)
        ButterQuestTrackerConfig.DeveloperMode = self:GetChecked()
        ns.BQT:RefreshFrame()
	end)

	self:refresh()
end

InterfaceOptions_AddCategory(frame)

-- Handling ButterQuestTracker's options.
SLASH_BQT_COMMAND1 = '/bqt'
SlashCmdList['BQT_COMMAND'] = function(command)
	InterfaceOptionsFrame_OpenToCategory("ButterQuestTracker")
	InterfaceOptionsFrame_OpenToCategory("ButterQuestTracker")
end
