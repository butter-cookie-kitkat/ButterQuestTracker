local WowHeadPopup = LibStub:NewLibrary("ButterQuestTracker/WowHeadPopup", 1);

if not WowHeadPopup then return end

local ButterGUI = LibStub("ButterGUI-1.0");
local QLH = LibStub("QuestLogHelper-1.0");

local Dialog = ButterGUI:GetButter("Dialog");
local popup = Dialog(UIParent);
popup:SetMinWidth(150);
popup:ClearAllPoints();
popup:SetPoint("TOP", 0, -200);

function WowHeadPopup:Show(questID, header)
    assert(type(questID) == "number", "Expected the quest id to be a number.");

    local quest = QLH:GetQuest(questID);

    assert(type(quest) == "table", "Unable to find a quest for the given id. (" .. questID .. ")");

    header = header or "Wowhead URL";

    popup:Once("Render", function(self)
        self:Text({
            label = header,
            disabled = true,

            margin = {
                bottom = 20
            },

            align = "CENTER",
            minWidth = "100%"
        });
        
        self:Text({
            label = "|cffff7f00" .. quest.title .. "|r",
            disabled = true,

            margin = {
                bottom = 20
            },

            align = "CENTER",
            minWidth = "100%"
        });
        
        self:TextArea({
            value = QLH:GetWowheadURL(quest.questID),
            focus = true,

            margin = {
                bottom = 20
            },

            minWidth = "100%"
        });
        
        self:Button({
            label = "Close",

            margin = {
                x = "auto"
            }
        }):On("Click", function()
            popup:Hide();
        end);
    end);

    popup:Render();
    popup:Show();
end