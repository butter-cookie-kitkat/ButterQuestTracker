local _, ns = ...

local CONSTANTS = {
    DEFAULT_CONFIG = {
        VERSION = 0.2,
        Position = {
            "TOPRIGHT", 
            "MinimapCluster", 
            "BOTTOMRIGHT", 
            0, 
            0
        },
        CurrentZoneOnly = true,
        DeveloperMode = false,
        QuestLimit = 10
    },
    LOGGER = {
        PREFIX = "|r[|c00FF9696ButterQuestTracker|r]: |r",
        COLORS = {
            ERROR = "|c00FF0000",
            WARN = "|c00FF7F00",
            INFO = "|r"
        }
    }
}

ns.CONSTANTS = CONSTANTS