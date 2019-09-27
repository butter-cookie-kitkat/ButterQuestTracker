local _, ns = ...

local CONSTANTS = {
    VERSION = "1.6.7",

    DEFAULT_CONFIG = {
        -- Filters & Sorting

        Sorting = "Disabled",
        CurrentZoneOnly = false,
        HideCompletedQuests = false,
        QuestLimit = 10,

        -- Frame Settings

        PositionX = 0,
        PositionY = -240,
        Width = 250,
        MaxHeight = 600,

        -- Visuals

        TrackerHeaderFormat = "QuestsNumberVisible",
        ColorHeadersByDifficultyLevel = false,
        TrackerHeaderFontSize = 12,
        QuestHeaderFontSize = 12,
        ObjectiveFontSize = 12,

        -- Advanced

        DeveloperMode = false,
        DebugLevel = 3
    },

    DEFAULT_CHARACTER_CONFIG = {
        -- Backend

        MANUALLY_TRACKED_QUESTS = {}
    },

    LOGGER = {
        PREFIX = "|r[|c00FF9696ButterQuestTracker|r]: |r",
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
    }
}

ns.CONSTANTS = CONSTANTS
