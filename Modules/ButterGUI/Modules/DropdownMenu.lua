local CreateClass = LibStub("Poncho-1.0");

local Group = ButterGUIGroup;
ButterGUIDropdownMenu = CreateClass("Frame", "ButterGUIDropdownMenu", nil, nil, Group);
local DropdownMenu = ButterGUIDropdownMenu;

function DropdownMenu:OnCreate()
    Group.OnCreate(self);

    self:SetFrameStrata("DIALOG");
    self:SetBackdrop({
		bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
		edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
		insets = {
            left = 8,
            bottom = 8,
            right = 9,
            top = 9,
        },
        tile = true,
        tileSize = 28,
        edgeSize = 28
    });

    self:SetBackdropBorderColor(TOOLTIP_DEFAULT_COLOR.r, TOOLTIP_DEFAULT_COLOR.g, TOOLTIP_DEFAULT_COLOR.b);
    self:SetBackdropColor(0, 0, 0, 1.0);
end

function DropdownMenu:OnAcquire()
    Group.OnAcquire(self);

    self:Hide();

    self:On("Render", function()
        if not self.options then return end

        local list = self:Group({
            margin = {
                y = 20,
                x = 10
            },

            backgroundColor = {
                r = 1.0,
                a = 0.2
            }
        });

        -- list:On("Render", function()
        --     for _, option in pairs(self.options) do
        --         local button = list:Button({
        --             label = option.label,
        --             checked = self.value == option.value,
        --             tooltipEnabled = false
        --         });

        --         button:SetHeight(UIDROPDOWNMENU_BUTTON_HEIGHT);
        --         button:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight");

        --         button:On("Click", function()
        --             self:Fire("Change", option.value);
        --         end);
        --     end
        -- end);
    end);
end

function DropdownMenu:OnRelease()
    Group.OnRelease(self);

    self:Hide();
end

function DropdownMenu:SetOptions(options)
    self.options = options;
end

function DropdownMenu:SetValue(value)
    self.value = value;
end
