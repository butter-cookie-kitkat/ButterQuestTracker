local Tracker = LibStub:NewLibrary("ButterQuestTracker/Tracker", 1);

if not Tracker then return end

local ButterUtils = LibStub("ButterUtils-1.0");
local ButterEvents = LibStub("ButterEvents-1.0");
local ButterGUI = LibStub("ButterGUI-1.0");
local QH = LibStub("LibQuestHelpers-1.0");
local QLH = LibStub("QuestLogHelper-1.0");
local QWH = LibStub("QuestWatchHelper-1.0");
local ZH = LibStub("ZoneHelper-1.0");

local ContextMenu = LibStub("ButterQuestTracker/ButterQuestContext");

local Group = ButterGUI:GetButter("Group");
local tracker = Group(UIParent);
-- TODO: Implement
-- Tracker:AllowScrolling(true);

local config = {
    DeveloperMode = false
};

local marks = {
    refresh = false,
    render = false
};
tracker:On("Update", function()
    if marks.render then
        marks.render = false;
        marks.refresh = false; -- render trumps refresh

        Tracker:Render();
    elseif marks.refresh then
        marks.refresh = false;

        Tracker:Refresh();
    end
end);

function Tracker:Render()
    tracker:Render();
end

function Tracker:Refresh()
    tracker:Refresh();
end

function Tracker:SetConfig(conf)
    assert(type(conf) == "table", "Invalid configuration format.");

    if conf.BackgroundColor ~= nil then
        self:SetBackgroundColor(conf.BackgroundColor);
    end

    if conf.DeveloperMode ~= nil then
        self:SetDeveloperMode(conf.DeveloperMode);
    end

    if conf.MaxHeight ~= nil then
        self:SetMaxHeight(conf.MaxHeight);
    end

    if type(conf.Position) == "table" then
        self:SetPosition(conf.Position.x, conf.Position.y);
    end

    if conf.Width ~= nil then
        self:SetMinAndMaxWidth(conf.Width);
    end
end

function Tracker:SetMarkForRender(mark)
    marks.refresh = mark;
end

-- This returns the coordinates as if the the TOPRIGHT of the screen is the coordinate starting position.
function Tracker:GetPosition()
    local x = tracker:GetRight();
    local y = tracker:GetTop();

    local inversedX = x - GetScreenWidth();
    local inversedY = y - GetScreenHeight();

    return inversedX, inversedY;
end

-- Setters

function Tracker:SetPosition(x, y)
    assert(type(x) == "number", "Expected the X position to be a number");
    assert(type(y) == "number", "Expected the Y position to be a number");

    tracker:SetPoint("TOPRIGHT", UIParent, "TOPRIGHT", x, y);
end

function Tracker:SetDeveloperMode(debug)
    assert(type(debug) == "boolean", "Debug must be a boolean.");

    if debug == config.debug then return end

    config.debug = debug;
    marks.render = true;
end

function Tracker:SetMinAndMaxWidth(width)
    assert(type(width) == "number", "Width must be a number.");

    tracker:SetMinWidth(width);
    tracker:SetMaxWidth(width);
end

function Tracker:SetMaxHeight(height)
    assert(type(height) == "number", "Height must be a number.");

    tracker:SetMaxHeight(height);
end

function Tracker:SetBackgroundColor(color)
    tracker:SetBackgroundColor(color);
end

-- NOTE: This renders an individual quest and its objectives.
function OnRenderQuest(quest)
    return function(self)
        self:Text({
            label = "[" .. quest.level .. "] " .. quest.title,

            color = NORMAL_FONT_COLOR,
            hoverColor = HIGHLIGHT_FONT_COLOR
        });

        for _, objective in pairs(quest.objectives) do
            self:Text({
                label = " - " .. objective.text,

                color = {
                    r = 0.8,
                    g = 0.8,
                    b = 0.8
                },

                hoverColor = HIGHLIGHT_FONT_COLOR,

                margin = {
                    top = 2.5,
                    left = 3
                }
            });
        end
    end
end

-- NOTE: This renders a quest group, meaning the clickable bit.
function OnRenderQuestGroup(quest)
    return function(self)
        local questGroup = self:Group({
            margin = {
                top = 10,
                left = 10
            },

            tooltip = {
                position = "ON_LEFT",
                header = quest.title,
                body = quest.summary,

                lines = function()
                    local lines = {};

                    tinsert(lines, { "Quest ID:", quest.questID });
                    tinsert(lines, { "Quest Index:", quest.index });

                    for _, addon in ipairs(QH:GetActiveAddons()) do
                        local distance = QH:GetDistanceToClosestObjective(quest.questID, addon);
                        if distance then
                            tinsert(lines, { addon .. " (distance):", string.format("%.1fm", distance) });
                        else
                            tinsert(lines, { addon .. " (distance):", "N/A" });
                        end
                    end

                    return lines;
                end
            },

            backgroundColor = {
                g = 1.0,
                a = 0.2
            },

            -- Effectively makes the text think it's being hovered over, also blocks the native events on the children.
            eventMode = "FORWARD",

            minWidth = "100%"
        });

        questGroup:On("Click", function(self, button)
            if button == "LeftButton" then
                QLH:ToggleQuest(quest.index);
            elseif button == "RightButton" then
                ContextMenu:Show(quest.questID, self);
            end
        end);

        questGroup:On({ "MouseDown", "MouseUp", "Enter", "Leave" }, ButterEvents.noop); -- We want these events to be forwarded
        
        questGroup:On("Render", OnRenderQuest(quest));
    end
end

-- NOTE: This renders all of the quests and their zones if relevant.
local function OnRenderQuests(self)
    local quests = QLH:GetWatchedQuests();
    
    local zoneGroups = {};
    for _, quest in pairs(quests) do
        if not zoneGroups[quest.zone] then
            local header = self:Text({
                label = quest.zone,

                margin = {
                    top = 10,
                    left = 5
                },

                color = NORMAL_FONT_COLOR,
                hoverColor = HIGHLIGHT_FONT_COLOR,

                backgroundColor = {
                    b = 1.0,
                    a = 0.5
                }
            });
            
            header:On("Click", function()
                PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON);
                zoneGroups[quest.zone]:ToggleCollapsed();
            end);

            header:On("MouseDown", function(self)
                self:AdjustFontPosition(2, -2);
            end);
    
            header:On("MouseUp", function(self)
                self:ResetFontPosition(2, -2);
            end);

            zoneGroups[quest.zone] = self:Group({
                margin = {
                    left = 5
                },

                minWidth = "100%"
            });
        end

        -- If zone headers are active then we want to use the zone header, otherwise we'll use the overall quests group...
        (zoneGroups[quest.zone] or self):On("Render", OnRenderQuestGroup(quest));
    end
end

-- NOTE: This renders the quest header and the entire quests group to enable us to collapse everything.
tracker:On("Render", function(self)
    local quests = QLH:GetWatchedQuests();
    local questCount = ButterUtils.Tables:Count(quests);

    local questsGroup;
    self:Text({
        label = "Quests (" .. questCount .. "/" .. C_QuestLog.GetMaxNumQuests() .. ")",

        color = NORMAL_FONT_COLOR,
        hoverColor = HIGHLIGHT_FONT_COLOR,
        
        backgroundColor = config.DeveloperMode and {
            r = 1.0,
            g = 1.0,
            a = 0.2
        }
    }):On("Click", function(_, button)
        if button == "LeftButton" then
            PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON);
            questsGroup:ToggleCollapsed();
        end
    end);

    questsGroup = self:Group();
    
    questsGroup:On("Render", OnRenderQuests);
end);

Tracker:SetPosition(0, -300);

QWH:OnQuestWatchUpdated(function()
    marks.render = true;
end);

QLH:OnQuestUpdated(function()
    marks.render = true;
end);

ZH:OnZoneChanged(function()
    marks.render = true;
end);