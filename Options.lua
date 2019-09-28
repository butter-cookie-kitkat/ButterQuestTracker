local NAME, ns = ...

local ACD = LibStub("AceConfigDialog-3.0");
local QLH = LibStub("QuestLogHelper-1.0");
local BQTL = ButterQuestTrackerLocale;
local TH = LibStub("TrackerHelper-1.0");

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

local function SetAndRefreshQuestWatch(info, value)
    SetInDB(info, value);
    BQT:RefreshQuestWatch();
end

local function SetAndRefreshView(info, value)
    SetInDB(info, value);
    BQT:RefreshView();
end

local options = {
    name = function() return BQTL:GetString('SETTINGS_NAME', ns.CONSTANTS.VERSION) end,
    type = "group",
    childGroups = "tab",

    get = GetFromDB,
    set = SetInDB,

    args = {
        filtersAndSorting = {
            name = BQTL:GetStringWrap('SETTINGS_FILTERS_AND_SORTING_TAB'),
            type = "group",
            order = order(),

            args = {
                currentZoneOnly = {
                    name = BQTL:GetStringWrap('SETTINGS_CURRENT_ZONE_ONLY_NAME'),
                    desc = BQTL:GetStringWrap('SETTINGS_CURRENT_ZONE_ONLY_DESC'),
                    arg = "CurrentZoneOnly",
                    type = "toggle",
                    width = 2.4,
                    order = order(),

                    set = SetAndRefreshQuestWatch
                },

                sorting = {
                    name = BQTL:GetStringWrap('SETTINGS_SORTING_NAME'),
                    desc = BQTL:GetStringWrap('SETTINGS_SORTING_DESC'),
                    arg = "Sorting",
                    type = "select",
                    order = order(),

                    values = function()
                        return {
                            Disabled = BQTL:GetString('SETTINGS_SORTING_DISABLED_OPTION'),
                            ByLevel = BQTL:GetString('SETTINGS_SORTING_BY_LEVEL_OPTION'),
                            ByLevelReversed = BQTL:GetString('SETTINGS_SORTING_BY_LEVEL_REVERSED_OPTION'),
                            ByPercentCompleted = BQTL:GetString('SETTINGS_SORTING_BY_PERCENT_COMPLETED_OPTION'),
                            ByRecentlyUpdated = BQTL:GetString('SETTINGS_SORTING_BY_RECENTLY_UPDATED_OPTION')
                        };
                    end,

                    sorting = {
                        "Disabled",
                        "ByLevel",
                        "ByLevelReversed",
                        "ByPercentCompleted",
                        "ByRecentlyUpdated"
                    },

                    set = SetAndRefreshView
                },

                hideCompletedQuests = {
                    name = BQTL:GetStringWrap('SETTINGS_HIDE_COMPLETED_QUESTS_NAME'),
                    desc = BQTL:GetStringWrap('SETTINGS_HIDE_COMPLETED_QUESTS_DESC'),
                    arg = "HideCompletedQuests",
                    type = "toggle",
                    width = 2.4,
                    order = order(),

                    set = SetAndRefreshQuestWatch
                },

                questLimit = {
                    name = BQTL:GetStringWrap('SETTINGS_QUEST_LIMIT_NAME'),
                    desc = BQTL:GetStringWrap('SETTINGS_QUEST_LIMIT_DESC'),
                    arg = "QuestLimit",
                    type = "range",
                    width = 1.0,
                    min = 1,
                    max = 20,
                    step = 1,
                    order = order(),

                    set = SetAndRefreshView
                },

                spacer1 = Spacer(),

                autoTrackUpdatedQuests = {
                    name = BQTL:GetStringWrap('SETTINGS_AUTO_TRACK_UPDATED_QUESTS_NAME'),
                    desc = BQTL:GetStringWrap('SETTINGS_AUTO_TRACK_UPDATED_QUESTS_DESC'),
                    arg = "AutoTrackUpdatedQuests",
                    type = "toggle",
                    width = 1.5,
                    order = order(),

                    set = function(info, value)
                        SetInDB(info, value);

                        if not value then
                            BQT:ResetOverrides();
                        end
                    end
                },

                spacer2 = Spacer(),

                reset = {
                    name = BQTL:GetStringWrap('SETTINGS_RESET_TRACKING_OVERRIDES_NAME'),
                    desc = BQTL:GetStringWrap('SETTINGS_RESET_TRACKING_OVERRIDES_DESC'),
                    type = "execute",
                    width = 1.3,
                    order = order(),

                    func = function()
                        BQT:ResetOverrides();
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
                    name = BQTL:GetStringWrap('SETTINGS_COLOR_HEADERS_BY_DIFFICULTY_NAME'),
                    desc = BQTL:GetStringWrap('SETTINGS_COLOR_HEADERS_BY_DIFFICULTY_DESC'),
                    arg = "ColorHeadersByDifficultyLevel",
                    type = "toggle",
                    width = 2.4,
                    order = order(),

                    set = SetAndRefreshView
                },

                trackerHeaderFormat = {
                    name = BQTL:GetStringWrap('SETTINGS_TRACKER_HEADER_FORMAT_NAME'),
                    desc = BQTL:GetStringWrap('SETTINGS_TRACKER_HEADER_FORMAT_DESC'),
                    arg = "TrackerHeaderFormat",
                    type = "select",
                    order = order(),

                    values = function()
                        return {
                            Classic = BQTL:GetString('SETTINGS_TRACKER_HEADER_FORMAT_CLASSIC_OPTION'),
                            Quests = BQTL:GetString('SETTINGS_TRACKER_HEADER_FORMAT_QUESTS_OPTION'),
                            QuestsNumberVisible = BQTL:GetString('SETTINGS_TRACKER_HEADER_FORMAT_QUESTS_NUMBER_VISIBLE_OPTION')
                        };
                    end,

                    sorting = {
                        "Classic",
                        "Quests",
                        "QuestsNumberVisible"
                    },

                    set = SetAndRefreshView
                },

                trackerHeaderFontSize = {
                    name = BQTL:GetStringWrap('SETTINGS_TRACKER_HEADER_FONT_SIZE_NAME'),
                    arg = "TrackerHeaderFontSize",
                    type = "range",
                    min = 10,
                    max = 20,
                    step = 1,
                    order = order(),

                    set = SetAndRefreshView
                },

                questHeaderFontSize = {
                    name = BQTL:GetStringWrap('SETTINGS_QUEST_HEADER_FONT_SIZE_NAME'),
                    arg = "QuestHeaderFontSize",
                    type = "range",
                    min = 10,
                    max = 20,
                    step = 1,
                    order = order(),

                    set = SetAndRefreshView
                },

                spacer1 = Spacer(),

                objectiveFontSize = {
                    name = BQTL:GetStringWrap('SETTINGS_OBJECTIVE_FONT_SIZE_NAME'),
                    arg = "ObjectiveFontSize",
                    type = "range",
                    min = 10,
                    max = 20,
                    step = 1,
                    order = order(),

                    set = SetAndRefreshView
                },

                spacer2 = Spacer(),

                questPadding = {
                    name = BQTL:GetStringWrap('SETTINGS_QUEST_PADDING_NAME'),
                    arg = "QuestPadding",
                    type = "range",
                    min = 0,
                    max = 20,
                    step = 1,
                    order = order(),

                    set = SetAndRefreshView
                },

                spacerEnd = Spacer("large"),
            }
        },

        frameSettings = {
            name = BQTL:GetStringWrap('SETTINGS_FRAME_TAB'),
            type = "group",
            order = order(),

            args = {
                positionX = {
                    name = BQTL:GetStringWrap('SETTINGS_POSITIONX_NAME'),
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
                        TH:UpdatePosition(-value);
                    end
                },

                positionY = {
                    name = BQTL:GetStringWrap('SETTINGS_POSITIONY_NAME'),
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
                        TH:UpdatePosition(nil, -value);
                    end
                },

                spacer1 = Spacer(),

                width = {
                    name = BQTL:GetStringWrap('SETTINGS_WIDTH_NAME'),
                    arg = "Width",
                    type = "range",
                    width = 1.6,
                    min = 100,
                    max = 400,
                    step = 1,
                    bigStep = 10,
                    order = order(),

                    set = function(info, value)
                        SetInDB(info, value);

                        TH:UpdateFrame({
                            width = value
                        });
                    end
                },

                maxHeight = {
                    name = BQTL:GetStringWrap('SETTINGS_MAX_HEIGHT_NAME'),
                    arg = "MaxHeight",
                    type = "range",
                    width = 1.6,
                    min = 100,
                    max = math.ceil(GetScreenHeight() * UIParent:GetEffectiveScale()),
                    step = 1,
                    bigStep = 10,
                    order = order(),

                    set = function(info, value)
                        SetInDB(info, value);

                        TH:UpdateFrame({
                            maxHeight = value
                        });
                    end
                },

                spacer2 = Spacer(),

                resetPosition = {
                    name = BQTL:GetStringWrap('SETTINGS_RESET_POSITION_NAME'),
                    type = "execute",
                    width = 0.8,
                    order = order(),

                    func = function()
                        BQT.DB.Global.PositionX = ns.CONSTANTS.DEFAULT_CONFIG.PositionX;
                        BQT.DB.Global.PositionY = ns.CONSTANTS.DEFAULT_CONFIG.PositionY;
                        TH:UpdatePosition(BQT.DB.Global.PositionX, BQT.DB.Global.PositionY);
                    end
                },

                resetSize = {
                    name = BQTL:GetStringWrap('SETTINGS_RESET_SIZE_NAME'),
                    type = "execute",
                    width = 0.7,
                    order = order(),

                    func = function()
                        BQT.DB.Global.Width = ns.CONSTANTS.DEFAULT_CONFIG.Width;
                        BQT.DB.Global.MaxHeight = ns.CONSTANTS.DEFAULT_CONFIG.MaxHeight;

                        TH:UpdateFrame({
                            width = BQT.DB.Global.Width,
                            maxHeight = BQT.DB.Global.MaxHeight
                        });
                    end
                },

                spacerEnd = Spacer("large"),
            }
        },

        advanced = {
            name = BQTL:GetStringWrap('SETTINGS_ADVANCED_TAB'),
            type = "group",
            order = order(),

            args = {
                developerOptionsHeader = {
                    name = BQTL:GetStringWrap('SETTINGS_DEVELOPER_HEADER'),
                    type = "header",
                    order = order(),
                },

                spacer1 = Spacer(),

                developerMode = {
                    name = BQTL:GetStringWrap('SETTINGS_DEVELOPER_MODE_NAME'),
                    desc = BQTL:GetStringWrap('SETTINGS_DEVELOPER_MODE_DESC'),
                    arg = "DeveloperMode",
                    type = "toggle",
                    order = order(),

                    set = function(info, value)
                        SetInDB(info, value);
                        TH:SetDebugMode(value);
                    end
                },

                spacer2 = Spacer(),

                debugLevel = {
                    name = BQTL:GetStringWrap('SETTINGS_DEBUG_LEVEL_NAME'),
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

                spacer3 = Spacer(),

                localeHeader = {
                    name = BQTL:GetStringWrap('SETTINGS_LOCALE_HEADER'),
                    type = "header",
                    order = order(),
                },

                spacer4 = Spacer(),

                locale = {
                    name = BQTL:GetStringWrap('SETTINGS_LOCALE_NAME'),
                    type = "select",
                    style = 'dropdown',
                    order = order(),

                    values = {
                        ['enUS'] = 'English',
                        -- ['esES'] = 'Español',
                        -- ['ptBR'] = 'Português',
                        -- ['frFR'] = 'Français',
                        -- ['deDE'] = 'Deutsch',
                        -- ['ruRU'] = 'русский',
                        -- ['zhCN'] = '简体中文',
                        -- ['zhTW'] = '正體中文',
                        -- ['koKR'] = '한국어'
                    },

                    get = function() return BQTL:GetLocale() end,
                    set = function(input, locale)
                        BQT.DB.Global.Locale = locale;
                        BQTL:SetLocale(locale);
                    end,
                },

                spacer5 = Spacer(),

                resetHeader = {
                    name = BQTL:GetStringWrap('SETTINGS_RESET_HEADER'),
                    type = "header",
                    order = order(),
                },

                spacer6 = Spacer(),

                resetDescription = {
                    name = BQTL:GetStringWrap('SETTINGS_RESET_TEXT'),
                    type = "description",
                    fontSize = "medium",
                    order = order(),
                },

                spacer7 = Spacer(),

                reset = {
                    name = BQTL:GetStringWrap('SETTINGS_RESET_NAME'),
                    desc = BQTL:GetStringWrap('SETTINGS_RESET_DESC'),
                    type = "execute",
                    width = 1.0,
                    order = order(),

                    func = function()
                        BQT.DB.Global = CopyTable(ns.CONSTANTS.DEFAULT_CONFIG);
                        BQT.DB.Char = CopyTable(ns.CONSTANTS.DEFAULT_CHARACTER_CONFIG);

                        TH:UpdateFrame({
                            x = BQT.DB.Global.PositionX,
                            y = BQT.DB.Global.PositionY,
                            width = BQT.DB.Global.Width,
                            maxHeight = BQT.DB.Global.MaxHeight
                        });

                        TH:SetDebugMode(BQT.DB.Global.DeveloperMode);
                        BQT:RefreshQuestWatch();
                    end
                },

                spacer8 = Spacer(),

                advert = {
                    name = BQTL:GetStringWrap('SETTINGS_ADVERT_TEXT'),
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
ACD:AddToBlizOptions("ButterQuestTracker");

-- Handling ButterQuestTracker's options.
SLASH_BUTTER_QUEST_TRACKER_COMMAND1 = '/bqt'
SlashCmdList['BUTTER_QUEST_TRACKER_COMMAND'] = function(command)
    if command == "" then
        ACD:Open("ButterQuestTracker")
    elseif command == "reset" then
        print('command', command);
    end
end
