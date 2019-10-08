local _, ns = ...

local QH = LibStub("LibQuestHelpers-1.0");

local BQT = ButterQuestTracker;
local BQTL = ButterQuestTrackerLocale;

ButterQuestTrackerSettings = LibStub("ButterSettings-1.0"):New({
    name = "ButterQuestTracker"
});

local settings = ButterQuestTrackerSettings;

settings:On("Render", function(self)
    print("Event(Render)");

    self:SetGlobalDB(BQT.db.global);
    self:SetCharacterDB(BQT.db.char);

    self:Group({
        margin = {
            y = 10,
            x = 10
        },

        backgroundColor = {
            r = 1.0,
            b = 1.0,
            a = 0.2
        }
    }):On("Render", function(self)
        print("Container:Event(Render)");

        self:Text({
            label = BQTL:GetString('SETTINGS_NAME', ns.CONSTANTS.VERSION),
            size = 16,

            backgroundColor = {
                r = 1.0,
                a = 0.2
            }
        });

        self:Checkbox({
            label = BQTL:GetString('SETTINGS_DISPLAY_DUMMY_DATA_NAME'),
            desc = BQTL:GetString('SETTINGS_DISPLAY_DUMMY_DATA_DESC'),
            global = "DisplayDummyData",

            margin = {
                top = 10
            },

            small = true,

            backgroundColor = {
                r = 1.0,
                a = 0.2
            }
        }):On("Change", function()
            BQT:RefreshView();
        end);

        self:Dropdown({
            label = BQTL:GetString('SETTINGS_SORTING_NAME'),
            desc = BQTL:GetString('SETTINGS_SORTING_DESC'),
            global = "Sorting",

            margin = {
                top = 10
            },

            options = function()
                local options = {};

                tinsert(options, {
                    value = "Disabled",
                    label = BQTL:GetString('SETTINGS_SORTING_DISABLED_OPTION')
                });

                tinsert(options, {
                    value = "ByLevel",
                    label = BQTL:GetString('SETTINGS_SORTING_BY_LEVEL_OPTION')
                });

                tinsert(options, {
                    value = "ByLevelReversed",
                    label = BQTL:GetString('SETTINGS_SORTING_BY_LEVEL_REVERSED_OPTION')
                });

                tinsert(options, {
                    value = "ByPercentCompleted",
                    label = BQTL:GetString('SETTINGS_SORTING_BY_PERCENT_COMPLETED_OPTION')
                });

                tinsert(options, {
                    value = "ByRecentlyUpdated",
                    label = BQTL:GetString('SETTINGS_SORTING_BY_RECENTLY_UPDATED_OPTION')
                });

                if QH:IsSupported() then
                    tinsert(options, {
                        value = "ByQuestProximity",
                        label = BQTL:GetString('SETTINGS_SORTING_BY_QUEST_PROXIMITY_OPTION')
                    });
                end

                return options;
            end
        }):On("Change", function(value)
            BQT:UpdateQuestProximityTimer();

            if value ~= "ByQuestProximity" then
                BQT:RefreshView();
            end
        end);
    end);

    -- local tabs = self:Tabs();

    -- tabs:Tab({
    --     label = "Filters & Sorting",
    --     value = "filters-and-sorting"
    -- }):On("Render", function(self)
    --     self:Group({
    --         orientation = "horizontal"
    --     }):On("Render", function(self)
    --         self:Checkbox({
    --             label = BQTL:GetStringWrap('SETTINGS_AUTO_TRACK_UPDATED_QUESTS_NAME'),
    --             desc = BQTL:GetStringWrap('SETTINGS_AUTO_TRACK_UPDATED_QUESTS_DESC'),
    --             global = "AutoTrackUpdatedQuests"
    --         }):On("Change", function(value)
    --             if value then return end

    --             BQT:ResetOverrides();
    --         end);

    --         self:Dropdown({
    --             label = "Automatically Track Updated Quests",
    --             global = "Sorting",

    --             options = function()
    --                 local options = {
    --                     Disabled = BQTL:GetString('SETTINGS_SORTING_DISABLED_OPTION'),
    --                     ByLevel = BQTL:GetString('SETTINGS_SORTING_BY_LEVEL_OPTION'),
    --                     ByLevelReversed = BQTL:GetString('SETTINGS_SORTING_BY_LEVEL_REVERSED_OPTION'),
    --                     ByPercentCompleted = BQTL:GetString('SETTINGS_SORTING_BY_PERCENT_COMPLETED_OPTION'),
    --                     ByRecentlyUpdated = BQTL:GetString('SETTINGS_SORTING_BY_RECENTLY_UPDATED_OPTION')
    --                 };

    --                 if QH:IsSupported() then
    --                     options['ByQuestProximity'] = BQTL:GetString('SETTINGS_SORTING_BY_QUEST_PROXIMITY_OPTION');
    --                 end

    --                 return options;
    --             end
    --         }):On("Change", function(value)
    --             BQT:UpdateQuestProximityTimer();

    --             if value ~= "ByQuestProximity" then
    --                 BQT:RefreshView();
    --             end
    --         end);
    --     end);

    --     self:Group({
    --         orientation = "horizontal"
    --     }):On("Render", function(self)
    --         self:Checkbox({
    --             label = BQTL:GetStringWrap('SETTINGS_AUTO_HIDE_QUEST_HELPER_ICONS_NAME'),
    --             desc = function() return BQTL:GetString('SETTINGS_AUTO_HIDE_QUEST_HELPER_ICONS_DESC', table.concat(QH:GetActiveAddons(), ", ")) end,
    --             global = "AutoHideQuestHelperIcons",

    --             disabled = not QH:IsSupported()
    --         }):On("Change", function(value)
    --             QH:SetAutoHideQuestHelperIcons(value);
    --         end);

    --         self:Slider({
    --             label = BQTL:GetStringWrap('SETTINGS_QUEST_LIMIT_NAME'),
    --             desc = BQTL:GetStringWrap('SETTINGS_QUEST_LIMIT_DESC'),
    --             global = "QuestLimit",

    --             min = 1,
    --             max = 20,
    --             step = 1
    --         }):On("Change", function()
    --             BQT:RefreshView();
    --         end);
    --     end);

    --     self:Header({
    --         label = "Filters"
    --     });

    --     self:Checkbox({
    --         label = BQTL:GetStringWrap('SETTINGS_DISABLE_FILTERS_NAME'),
    --         desc = BQTL:GetStringWrap('SETTINGS_DISABLE_FILTERS_DESC'),
    --         global = "DisableFilters"
    --     }):On("Change", function(value)
    --         if value == false then
    --             BQT:ResetOverrides();
    --         end

    --         BQT:RefreshQuestWatch();
    --     end);

    --     self:Checkbox({
    --         label = BQTL:GetStringWrap('SETTINGS_CURRENT_ZONE_ONLY_NAME'),
    --         desc = BQTL:GetStringWrap('SETTINGS_CURRENT_ZONE_ONLY_DESC'),
    --         global = "CurrentZoneOnly",

    --         disabled = function() return BQT.db.global.DisableFilters end
    --     }):On("Change", function()
    --         BQT:RefreshQuestWatch();
    --     end);

    --     self:Checkbox({
    --         label = BQTL:GetStringWrap('SETTINGS_HIDE_COMPLETED_QUESTS_NAME'),
    --         desc = BQTL:GetStringWrap('SETTINGS_HIDE_COMPLETED_QUESTS_DESC'),
    --         global = "HideCompletedQuests",

    --         disabled = function() return BQT.db.global.DisableFilters end
    --     }):On("Change", function()
    --         BQT:RefreshQuestWatch();
    --     end);

    --     self:Button({
    --         label = BQTL:GetStringWrap('SETTINGS_RESET_TRACKING_OVERRIDES_NAME'),
    --         desc = BQTL:GetStringWrap('SETTINGS_RESET_TRACKING_OVERRIDES_DESC'),
    --     }):On("Click", function()
    --         BQT:ResetOverrides();
    --     end);
    -- end);

    -- tabs:Tab({
    --     label = "Visual Settings",
    --     value = "visual-settings"
    -- });

    -- tabs:Tab({
    --     label = "Frame Settings",
    --     value = "frame-settings"
    -- });

    -- tabs:Tab({
    --     label = "Advanced",
    --     value = "advanced"
    -- });

    -- local container = self:AddContainer({
    --     margin = {
    --         x = 10,
    --         y = 10
    --     },

    --     backgroundColor = {
    --         r = 1.0,
    --         g = 1.0,
    --         b = 1.0,
    --         a = 0.1
    --     }
    -- });

    -- container:AddCheckbox({
    --     label = "Display Dummy Data",
    --     value = BQT.db.global.DisplayDummyData
    -- });

    -- local tabs = container:AddTabGroup({
    --     margin = {
    --         x = 10
    --     },

    --     value = 1,
    --     style = "Dialog",

    --     tabs = {
    --         "Filters & Sorting",
    --         "Visual Settings",
    --         "Frame Settings",
    --         "Advanced"
    --     }
    -- });

    -- local filtersAndSorting = container:AddContainer({
    --     margin = {
    --         x = 10,
    --         y = 10
    --     },

    --     backgroundColor = {
    --         r = 1.0,
    --         g = 1.0,
    --         b = 1.0,
    --         a = 0.1
    --     }
    -- });

    -- filtersAndSorting:AddCheckbox({
    --     label = "Automatically Track Updated Quests",
    --     value = BQT.db.global.AutoTrackUpdatedQuests,

    --     margin = {
    --         top = 10
    --     }
    -- });

    -- if BQT.db.global.DisplayDummyData then
    --     BQT:RefreshView();
    -- end
end);

settings:On("Show", function()
    if BQT.db.global.DisplayDummyData then
        BQT:RefreshView();
    end
end);

settings:On("Hide", function()
    if BQT.db.global.DisplayDummyData then
        BQT:RefreshView();
    end
end);

-- Handling ButterQuestTracker's options.
-- SLASH_BUTTER_QUEST_TRACKER_COMMAND1 = '/bqt'
-- SlashCmdList['BUTTER_QUEST_TRACKER_COMMAND'] = function(command)
--     if command == "" then
--         if InterfaceOptionsFrame:IsShown() then
--             InterfaceOptionsFrame:Hide();
--         else
--             InterfaceOptionsFrame:Show();
--             InterfaceOptionsFrame_OpenToCategory("ButterQuestTracker");
--         end
--     elseif command == "reset" then
--         print('command', command);
--     end
-- end
