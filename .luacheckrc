std = "lua51"
max_line_length = false
exclude_files = {
    ".luacheckrc"
}

quiet = 1

exclude_files = {
    "Libs/*"
}

ignore = {
    "211/_.*", -- Unused local variable starting with _
    "212", -- Unused argument
    "542", -- empty if branch
    "432/self" -- shadowing upvalue self
}

globals = {
    "ButterQuestTracker",
    "ButterQuestTrackerLocale",
    "ButterQuestTrackerCharacterConfig",
    "SLASH_BUTTER_QUEST_TRACKER_COMMAND1",
    "SlashCmdList",

    -- Tracker Helper
    "TrackerHelperBase",
    "TrackerHelperBaseElement",
    "TrackerHelperContainer",
    "TrackerHelperFont",
    "TrackerHelperBackgroundFrame",
    "TrackerHelperFrame",

    "StaticPopupDialogs",

    -- Constants
    "MAX_WATCHABLE_QUESTS",

    -- Bad things ahoy
    "IsQuestWatched",
    "GetNumQuestWatches",
    "GetNumQuestLeaderBoards",

    -- Classic Codex Addon Frame / Functions
    "CodexQuest",
}

read_globals = {
    -- Global Shorthands
    "tinsert",
    "table",

    -- Third Party addon functions
    "LibStub",

    -- Questie Addon Frame / Functions
    "Questie",
    "QuestieDB",
    "QuestieQuest",

    -- Classic Codex Addon Frame / Functions
    "CodexDatabase",
    "CodexMap",

    -- Quest Log Addons
    "QuestGuru",
    "ClassicQuestLog",
    "QuestLogEx",
    "QuestLogExFrame",

    -- API functions
    "AddQuestWatch",
    "C_Timer",
    "C_Map",
    "C_QuestLog",
    "CreateFrame",
    "GetRealZoneText",
    "GetMinimapZoneText",
    "RemoveQuestWatch",
    "StaticPopup_Show",
    "IsShiftKeyDown",
    "PlaySound",
    "IsAltKeyDown",
    "IsControlKeyDown",
    "ChatEdit_InsertLink",
    "UIDropDownMenu_Initialize",
    "UIDropDownMenu_AddButton",
    "CloseDropDownMenus",
    "GetScreenWidth",
    "GetScreenHeight",
    "GetBuildInfo",
    "GetQuestLogSelection",
    "GetCVar",
    "SetCVar",
    "UnitClass",
    "GetQuestLogTitle",
    "SelectQuestLogEntry",
    "SetAbandonQuest",
    "GetQuestLogPushable",
    "AbandonQuest",
    "QuestLogPushQuest",
    "GetQuestLogQuestText",
    "GetTime",
    "HideUIPanel",
    "ShowUIPanel",
    "QuestLog_SetSelection",
    "UnitLevel",
    "GetNumQuestLogEntries",
    "GetLocale",
    "UnitInParty",
    "ToggleDropDownMenu",
    "GetCursorPosition",
    "GameTooltip",

    -- FrameXML Frames
    "UIParent",
    "InterfaceOptionsFrame",
    "InterfaceOptionsFrame_OpenToCategory",
    "QuestWatchFrame",
    "QuestLogFrame",
    "ObjectiveTrackerFrame",
    "QuestLogListScrollFrame",

    -- FrameXML Misc
    "MapCanvasDataProviderMixin",
    "MapCanvasPinMixin",

    -- Constants
    "CLOSE",
    "NORMAL_FONT_COLOR",
    "HIGHLIGHT_FONT_COLOR",
    "SOUNDKIT",
    "UIDROPDOWNMENU_OPEN_MENU",

    -- Bad things ahoy
    "hooksecurefunc",
}
