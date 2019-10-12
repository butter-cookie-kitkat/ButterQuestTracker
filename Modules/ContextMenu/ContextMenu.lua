local ButterQuestContext = LibStub:NewLibrary("ButterQuestTracker/ButterQuestContext", 1);

if not ButterQuestContext then return end

local ButterGUI = LibStub("ButterGUI-1.0");
local QLH = LibStub("QuestLogHelper-1.0");
local WowHeadPopup = LibStub("ButterQuestTracker/WowHeadPopup");

local DropdownMenu = ButterGUI:GetButter("DropdownMenu");
local ContextMenu = DropdownMenu(UIParent);
ContextMenu:SetStyle("CONTEXT_MENU");

function ButterQuestContext:On(event, ...)
    assert(tContains({ "Untrack", "View", "Abandon" }, event), "Invalid event type, expected an event of type 'Untrack', 'View', or 'Abandon'");

    ContextMenu:On(event, ...);
end

function ButterQuestContext:Off(event, ...)
    assert(tContains({ "Untrack", "View", "Abandon" }, event), "Invalid event type, expected an event of type 'Untrack', 'View', or 'Abandon'");
    
    ContextMenu:Off(event, ...);
end

function ButterQuestContext:Show(questID, trigger)
    assert(type(questID) == "number", "Expected the quest id to be a number.");

    local quest = QLH:GetQuest(questID);

    assert(type(quest) == "table", "Unable to find a quest for the given id. (" .. questID .. ")");

    local scale, x, y = UIParent:GetEffectiveScale(), GetCursorPosition();
    ContextMenu:SetTrigger(trigger);
    ContextMenu:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", x / scale, y / scale);
    ContextMenu:Clear("Render");

    ContextMenu:On("Render", function(self)
        self:Item({
            label = quest.title,
            color = NORMAL_FONT_COLOR,

            margin = {
                bottom = 10
            },

            clickable = false
        });

        self:Item({
            label = "Untrack Quest",

            textAlign = "LEFT"
        }):On("Click", function()
            RemoveQuestWatch(quest.index);

            ContextMenu:Fire("Untrack", {
                index = quest.index,
                questID = quest.questID
            });
        end);

        self:Item({
            label = "View Quest",

            textAlign = "LEFT"
        }):On("Click", function()
            QLH:ToggleQuest(quest.index);

            ContextMenu:Fire("View", {
                index = quest.index,
                questID = quest.questID
            });
        end);

        self:Item({
            label = "|cff33ff99Wowhead|r URL",

            textAlign = "LEFT"
        }):On("Click", function()
            WowHeadPopup:Show(quest.questID);
        end);

        self:Item({
            label = "Share Quest",
            disabled = true,

            textAlign = "LEFT"
        }):On("Click", function()
            ContextMenu:Fire("Share", {
                index = quest.index,
                questID = quest.questID
            });
        end);

        self:Item({
            label = "Cancel",

            textAlign = "LEFT"
        }):On("Click", function()
            ContextMenu:Fire("Cancel");
        end);

        self:Item({
            label = "|cffff0000Abandon|r Quest",

            margin = {
                top = 10
            },

            textAlign = "LEFT"
        }):On("Click", function()
            ContextMenu:Fire("Abandon", {
                index = quest.index,
                questID = quest.questID
            });
        end);
    end);

    ContextMenu:Render();
    ContextMenu:Show();
end

function ButterQuestContext:Hide()
    ContextMenu:Hide();
end