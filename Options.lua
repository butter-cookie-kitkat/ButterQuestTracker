local NAME, ns = ...

local QLH = LibStub("QuestLogHelper-1.0");

local BQT = ButterQuestTracker

local _order = 0;
local function order()
	_order = _order + 1;
	return _order;
end

local function Spacer(size)
	size = size or "small";

    return {
        type = "description",
        order = order(),
        name = " ",
        fontSize = size
    };
end

local function GetFromDB(info)
    return BQT.DB.Global[info.arg];
end

local function SetInDB(info, value)
    BQT.DB.Global[info.arg] = value;
end

local function SetAndRefreshTracker(info, value)
	SetInDB(info, value);
	BQT:Refresh();
end

local options = {
	name = "Butter Quest Tracker " .. ns.CONSTANTS.VERSION,
	type = "group",
	childGroups = "tab",

	get = GetFromDB,
	set = SetInDB,

	args = {
        filtersAndSorting = {
            name = "Filters & Sorting",
            type = "group",
            order = order(),

            args = {
				currentZoneOnly = {
					name = "Current Zone Only",
					desc = "Displays quests relevant to the current zone / subzone.",
					arg = "CurrentZoneOnly",
					type = "toggle",
					width = 2.4,
					order = order(),

					set = SetAndRefreshTracker
                },

				sorting = {
					name = "Sorting",
					desc = "How the quests are sorted in the tracker.",
					arg = "Sorting",
					type = "select",
					order = order(),

					values = {
						Disabled = "Don't Sort",
						ByLevel = "By Level",
						ByLevelReversed = "By Level (Reversed)",
						ByPercentCompleted = "By % Completed"
					},

					sorting = {
						"Disabled",
						"ByLevel",
						"ByLevelReversed",
						"ByPercentCompleted"
					},

					set = SetAndRefreshTracker
                },

				hideCompletedQuests = {
					name = "Hide Completed Quests",
					desc = "Displays quests that have been completed.",
					arg = "HideCompletedQuests",
					type = "toggle",
					width = 2.4,
					order = order(),

					set = SetAndRefreshTracker
                },

				questLimit = {
					name = "Quest Limit",
					desc = "Limits the number of quests visible on the screen at a given time.",
					arg = "QuestLimit",
					type = "range",
					width = 1.0,
					min = 1,
					max = 20,
					step = 1,
					order = order(),

					set = SetAndRefreshTracker
				},

				reset = {
					name = "Reset Tracking Overrides",
					desc = "Reset's all manual quest watch overrides.",
					type = "execute",
					width = 1.3,
					order = order(),

                    func = function()
                        for questID, tracked in pairs(BQT.DB.Char.MANUALLY_TRACKED_QUESTS) do
                            local index = QLH:GetIndexFromQuestID(questID);
                            if index then
                                RemoveQuestWatch()
                            end
                        end

                        BQT.DB.Char.MANUALLY_TRACKED_QUESTS = {};
						BQT:Refresh();
					end
				},

				spacerEnd = Spacer("large"),
            }
        },

        frameSettings = {
			name = "Frame Settings",
			type = "group",
			order = order(),

			args = {
				positionX = {
					name = "Position X",
					arg = "PositionX",
					type = "range",
					width = 1.6,
					min = 0,
					max = math.ceil(GetScreenWidth() * UIParent:GetEffectiveScale());
					step = 0.01,
					bigStep = 10,
					order = order(),

                    get = function(info)
                        return -GetFromDB(info);
					end,

                    set = function(info, value)
                        SetInDB(info, -value);
						BQT:RefreshPosition();
					end
				},

				positionY = {
					name = "Position Y",
					arg = "PositionY",
					type = "range",
					width = 1.6,
					min = 0,
					max = math.ceil(GetScreenHeight() * UIParent:GetEffectiveScale());
					step = 0.01,
					bigStep = 10,
					order = order(),

					get = function(info)
                        return -GetFromDB(info);
					end,

					set = function(info, value)
                        SetInDB(info, -value);
						BQT:RefreshPosition();
					end
				},

				spacer1 = Spacer(),

				width = {
					name = "Width",
					arg = "Width",
					type = "range",
					width = 1.6,
					min = 100,
					max = 400,
					step = 1,
					bigStep = 10,
					order = order(),

					set = SetAndRefreshTracker
				},

				maxHeight = {
					name = "Max Height",
					arg = "MaxHeight",
					type = "range",
					width = 1.6,
					min = 100,
					max = math.ceil(GetScreenHeight() * UIParent:GetEffectiveScale()),
					step = 1,
					bigStep = 10,
					order = order(),

					set = SetAndRefreshTracker
				},

				spacer2 = Spacer(),

				resetPosition = {
					name = "Reset Position",
					type = "execute",
					width = 0.8,
					order = order(),

                    func = function()
                        BQT.DB.Global.PositionX = ns.CONSTANTS.DEFAULT_CONFIG.PositionX;
                        BQT.DB.Global.PositionY = ns.CONSTANTS.DEFAULT_CONFIG.PositionY;
						BQT:RefreshPosition();
					end
				},

				resetSize = {
					name = "Reset Size",
					type = "execute",
					width = 0.7,
					order = order(),

					func = function()
                        BQT.DB.Global.Width = ns.CONSTANTS.DEFAULT_CONFIG.Width;
                        BQT.DB.Global.MaxHeight = ns.CONSTANTS.DEFAULT_CONFIG.MaxHeight;
						BQT:Refresh();
					end
				},

				spacerEnd = Spacer("large"),
            }
        },

		visuals = {
			name = "Visual Settings",
			type = "group",
			order = order(),

			args = {
				colorHeadersByDifficultyLevel = {
					name = "Color Headers By Difficulty Level",
					desc = "Color codes the quests by their difficulty level.",
					arg = "ColorHeadersByDifficultyLevel",
					type = "toggle",
					width = 2.4,
					order = order(),

					set = SetAndRefreshTracker
                },

				trackerHeaderFormat = {
					name = "Tracker Header Format",
					desc = "How should we format the tracker header?",
					arg = "TrackerHeaderFormat",
					type = "select",
					order = order(),

					values = {
						Classic = "Classic (Disabled)",
						Quests = "Quests",
						QuestsNumberVisible = "Quests (10/20)"
					},

					sorting = {
						"Classic",
						"Quests",
						"QuestsNumberVisible"
					},

					set = SetAndRefreshTracker
                },

				trackerHeaderFontSize = {
					name = "Tracker Header Font Size",
					arg = "TrackerHeaderFontSize",
					type = "range",
					min = 10,
					max = 20,
					step = 1,
                    order = order(),

					set = SetAndRefreshTracker
				},

				questHeaderFontSize = {
					name = "Quest Header Font Size",
					arg = "QuestHeaderFontSize",
					type = "range",
					min = 10,
					max = 20,
					step = 1,
					order = order(),

					set = SetAndRefreshTracker
				},

				spacer1 = Spacer(),

				objectiveFontSize = {
					name = "Objective Font Size",
					arg = "ObjectiveFontSize",
					type = "range",
					min = 10,
					max = 20,
					step = 1,
					order = order(),

					set = SetAndRefreshTracker
				},

				spacerEnd = Spacer("large"),
			}
		},

		advanced = {
			name = "Advanced",
			desc = "Advanced Options",
			type = "group",
			order = order(),

			args = {
				developerOptionsHeader = {
					name = "Developer Options",
					type = "header",
					order = order(),
				},

				spacer1 = Spacer(),

				developerMode = {
                    name = "Developer Mode",
                    desc = "Enables logging and other visual helpers.",
					arg = "DeveloperMode",
					type = "toggle",
					order = order(),

					set = function(info, value)
						SetInDB(info, value);
						BQT:RefreshFrame();
					end
				},

				spacer2 = Spacer(),

				debugLevel = {
					name = "Debug Level",
					desc = "ERROR = 1\nWARN = 2\nINFO = 3\nTRACE = 4",
					arg = "DebugLevel",
					type = "range",
					min = 1,
					max = 4,
					step = 1,
					order = order(),

					disabled = function()
                        return not BQT.DB.Global.DeveloperMode;
					end
				},

				resetHeader = {
					name = "Reset Butter Quest Tracker",
					type = "header",
					order = order(),
				},

				spacer3 = Spacer(),

				resetDescription = {
					name = "Hitting this button will reset all Butter Quest Tracker configuration settings back to their default values.",
					type = "description",
					fontSize = "medium",
					order = order(),
				},

				spacer4 = Spacer(),

				reset = {
					name = "Reset Butter Quest Tracker",
					desc = "Reset Butter Quest Tracker to the default values for all settings.",
					type = "execute",
					width = 1.3,
					order = order(),

                    func = function()
                        BQT.DB.Global = CopyTable(ns.CONSTANTS.DEFAULT_CONFIG);
                        BQT.DB.Char = CopyTable(ns.CONSTANTS.DEFAULT_CHARACTER_CONFIG);
						BQT:RefreshPosition();
						BQT:Refresh();
					end
				},

				spacer5 = Spacer(),

				advert = {
					name = "|c00FF9696Butter Quest Tracker is under active development for World of Warcraft: Classic. Please check out our GitHub for the alpha builds or to report issues. \n\nhttps://github.com/butter-cookie-kitkat/ButterQuestTracker",
					type = "description",
					fontSize = "medium",
					order = order(),
				},

				spacerEnd = Spacer("large"),
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
