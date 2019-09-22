local NAME, ns = ...

local BQT = ButterQuestTracker

local function Spacer(o, size)
	size = size or "small";

    return {
        type = "description",
        order = o,
        name = " ",
        fontSize = size
    };
end

local function GetFromDB(info)
	return ButterQuestTrackerConfig[info.arg];
end

local function SetInDB(info, value)
	ButterQuestTrackerConfig[info.arg] = value;
end

local function SetAndReloadQuests(info, value)
	SetInDB(info, value);
	BQT:LoadQuests();
end

local options = {
	name = "Butter Quest Tracker " .. ns.CONSTANTS.DEFAULT_CONFIG.VERSION,
	type = "group",
	childGroups = "tab",

	get = GetFromDB,
	set = SetInDB,
	
	args = {
		filters = {
			name = "General",
			desc = "General Options",
			type = "group",
			order = 1,

			args = {
				filtersHeader = {
					name = "Filters",
					type = "header",
					order = 1
				},

				spacer1 = Spacer(2),

				currentZoneOnly = {
					name = "Current Zone Only",
					desc = "Displays quests relevant to the current zone / subzone.",
					arg = "CurrentZoneOnly",
					type = "toggle",
					width = "full",
					order = 3,
			
					set = SetAndReloadQuests
				},

				spacer2 = Spacer(4),

				questLimit = {
					name = "Quest Limit",
					desc = "Limits the number of quests visible on the screen at a given time.",
					arg = "QuestLimit",
					type = "range",
					width = 2.0,
					min = 1,
					max = 20,
					step = 1,
					order = 5,
			
					set = SetAndReloadQuests
				},

				frameOptionsHeader = {
					name = "Frame Options",
					type = "header",
					order = 6
				},

				spacer3 = Spacer(7),

				positionX = {
					name = "Position X",
					arg = "PositionX",
					type = "range",
					width = 1.7,
					min = 0,
					max = math.ceil(GetScreenWidth() * UIParent:GetEffectiveScale());
					step = 0.01,
					bigStep = 10,
					order = 8,
					
					get = function(info)
						return -ButterQuestTrackerConfig[info.arg]
					end,
					
					set = function(info, value)
						ButterQuestTrackerConfig[info.arg] = -value;
						BQT:RefreshPosition();
					end
				},

				positionY = {
					name = "Position Y",
					arg = "PositionY",
					type = "range",
					width = 1.7,
					min = 0,
					max = math.ceil(GetScreenHeight() * UIParent:GetEffectiveScale());
					step = 0.01,
					bigStep = 10,
					order = 11,
					
					get = function(info)
						return -ButterQuestTrackerConfig[info.arg]
					end,
					
					set = function(info, value)
						ButterQuestTrackerConfig[info.arg] = -value;
						BQT:RefreshPosition();
					end
				},

				spacer4 = Spacer(10),

				width = {
					name = "Width",
					arg = "Width",
					type = "range",
					width = 1.7,
					min = 100,
					max = 400,
					step = 1,
					bigStep = 10,
					order = 9,
			
					set = SetAndReloadQuests
				},

				maxHeight = {
					name = "Max Height",
					arg = "MaxHeight",
					type = "range",
					width = 1.7,
					min = 100,
					max = math.ceil(GetScreenHeight() * UIParent:GetEffectiveScale()),
					step = 1,
					bigStep = 10,
					order = 12,
			
					set = SetAndReloadQuests
				},

				spacer5 = Spacer(13),

				resetPosition = {
					name = "Reset Position",
					type = "execute",
					width = 0.8,
					order = 14,

					func = function()
						ButterQuestTrackerConfig.PositionX = ns.CONSTANTS.DEFAULT_CONFIG.PositionX;
						ButterQuestTrackerConfig.PositionY = ns.CONSTANTS.DEFAULT_CONFIG.PositionY;
						BQT:RefreshPosition();
					end
				},

				resetSize = {
					name = "Reset Size",
					type = "execute",
					width = 0.7,
					order = 15,

					func = function()
						ButterQuestTrackerConfig.Width = ns.CONSTANTS.DEFAULT_CONFIG.Width;
						ButterQuestTrackerConfig.MaxHeight = ns.CONSTANTS.DEFAULT_CONFIG.MaxHeight;
						BQT:LoadQuests();
					end
				},
				
				visualsHeaders = {
					name = "Visuals",
					type = "header",
					order = 16
				},

				spacer6 = Spacer(17),

				colorHeadersByDifficultyLevel = {
					name = "Color Headers By Difficulty Level",
					desc = "Color codes the quests by their difficulty level.",
					arg = "ColorHeadersByDifficultyLevel",
					type = "toggle",
					width = "full",
					order = 18,
			
					set = SetAndReloadQuests
				}
			}
		},

		advanced = {
			name = "Advanced",
			desc = "Advanced Options",
			type = "group",
			order = 2,
			
			args = {
				developerOptionsHeader = {
					name = "Developer Options",
					type = "header",
					order = 1,
				},

				spacer1 = Spacer(2),

				developerMode = {
					name = "Developer Mode",
					arg = "DeveloperMode",
					type = "toggle",
					width = "full",
					order = 3,
					
					set = function(info, value)
						SetInDB(info, value);
						BQT:RefreshFrame();
					end
				},

				spacer2 = Spacer(4),

				debugLevel = {
					name = "Debug Level",
					desc = "ERROR = 1\nWARN = 2\nINFO = 3\nTRACE = 4",
					arg = "DebugLevel",
					type = "range",
					min = 1,
					max = 4,
					step = 1,
					order = 5,

					disabled = function()
						return not ButterQuestTrackerConfig.DeveloperMode;
					end
				},

				resetHeader = {
					name = "Reset Butter Quest Tracker",
					type = "header",
					order = 6,
				},

				spacer3 = Spacer(7),

				resetDescription = {
					name = "Hitting this button will reset all Butter Quest Tracker configuration settings back to their default values.",
					type = "description",
					fontSize = "medium",
					order = 8,
				},

				spacer4 = Spacer(9),

				reset = {
					name = "Reset Butter Quest Tracker",
					desc = "Reset Butter Quest Tracker to the default values for all settings.",
					type = "execute",
					width = 1.3,
					order = 10,

					func = function()
						ButterQuestTrackerConfig = CopyTable(ns.CONSTANTS.DEFAULT_CONFIG);
						BQT:RefreshPosition();
						BQT:LoadQuests();
					end
				},

				spacer5 = Spacer(11),

				resetDescription = {
					name = "|c00FF9696Butter Quest Tracker is under active development for World of Warcraft: Classic. Please check out our GitHub for the alpha builds or to report issues. \n\nhttps://github.com/butter-cookie-kitkat/ButterQuestTracker",
					type = "description",
					fontSize = "medium",
					order = 12,
				},
			}
		},
	},
}

LibStub("AceConfig-3.0"):RegisterOptionsTable("ButterQuestTracker", options);
LibStub("AceConfigDialog-3.0"):AddToBlizOptions("ButterQuestTracker");

-- Handling ButterQuestTracker's options.
SLASH_BUTTER_QUEST_TRACKER_COMMAND1 = '/bqt'
SlashCmdList['BUTTER_QUEST_TRACKER_COMMAND'] = function(command)
	InterfaceOptionsFrame_OpenToCategory("ButterQuestTracker")
	InterfaceOptionsFrame_OpenToCategory("ButterQuestTracker")
end