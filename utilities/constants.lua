local NAME, ns = ...

local CONSTANTS = {
    VERSION = "1.8.0-beta.1",
    NAME = "Butter Quest Tracker",
    NAME_SQUASHED = "ButterQuestTracker",
    CURSEFORGE_SLUG = "butter-quest-tracker",
    BRAND_COLOR = "|c00FF9696",
    PATHS = {},
    COLORS = {
        OBJECTIVE = {
            r = 0.8,
            g = 0.8,
            b = 0.8
        }
    }
};

CONSTANTS.PATHS.MEDIA = "Interface\\AddOns\\" .. NAME .. "\\Media\\";
CONSTANTS.PATHS.LOGO = "|T" .. CONSTANTS.PATHS.MEDIA .. "BQT_logo:24:24:0:-8" .. "|t";

CONSTANTS.DB_DEFAULTS = {
    global = {
        -- Filters & Sorting

        DisableFilters = false,
        Sorting = "Disabled",
        CurrentZoneOnly = false,
        HideCompletedQuests = false,
        QuestLimit = 10,
        AutoTrackUpdatedQuests = false,

        -- Visuals

        BackgroundAlwaysVisible = false,
        ['BackgroundColor-R'] = 0.0,
        ['BackgroundColor-G'] = 0.0,
        ['BackgroundColor-B'] = 0.0,
        ['BackgroundColor-A'] = 0.5,

        TrackerHeaderFormat = "QuestsNumberVisible",
        ColorHeadersByDifficultyLevel = false,

        TrackerHeaderFontSize = 12,
        QuestHeaderFontSize = 12,
        ObjectiveFontSize = 12,
        QuestPadding = 10,

        -- Frame Settings

        PositionX = 0,
        PositionY = -240,
        Width = 250,
        MaxHeight = 450,

        -- Advanced

        DeveloperMode = false,
        DebugLevel = 3
    },

    char = {
        -- Backend

        MANUALLY_TRACKED_QUESTS = {},
        QUESTS_LAST_UPDATED = {}
    }
};

CONSTANTS.LOGGER = {
    PREFIX = "|r[" .. CONSTANTS.BRAND_COLOR .. CONSTANTS.NAME_SQUASHED .. "|r]: |r",
    TYPES = {
        ERROR = {
            COLOR = "|c00FF0000",
            LEVEL = 1
        },
        WARN = {
            COLOR = "|c00FF7F00",
            LEVEL = 2
        },
        INFO = {
            COLOR = "|r",
            LEVEL = 3
        },
        TRACE = {
            COLOR = "|c00ADD8E6",
            LEVEL = 4
        }
    }
};

ns.CONSTANTS = CONSTANTS
