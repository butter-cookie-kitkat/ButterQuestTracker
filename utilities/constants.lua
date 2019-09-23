local _, ns = ...

local CONSTANTS = {
    DEFAULT_CONFIG = {
        VERSION = "1.1.0",
        PositionX = 0,
        PositionY = -240,
        Width = 250,
        MaxHeight = 600,
        CurrentZoneOnly = false,
        ColorHeadersByDifficultyLevel = false,
        QuestLimit = 10,
        DeveloperMode = false,
        DebugLevel = 3
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