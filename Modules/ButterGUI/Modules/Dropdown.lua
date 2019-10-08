local CreateClass = LibStub("Poncho-1.0");

local BaseInputElement = ButterGUIBaseInputElement;
ButterGUIDropdown = CreateClass("Frame", "ButterGUIDropdown", nil, nil, BaseInputElement);
local Dropdown = ButterGUIDropdown;

local ToggleButton = ButterGUIToggleButton;
local DropdownMenu = ButterGUIDropdownMenu;

function Dropdown:OnCreate()
    -- Initial Setup

    -- self:SetBackdrop({
    --     bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
    --     edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    --     tile = true,
    --     insets = { left = 5, right = 4, top = 4, bottom = 4 },
    --     tileSize = 16,
    --     edgeSize = 16
    -- });
    -- self:SetBackdropBorderColor(TOOLTIP_DEFAULT_COLOR.r, TOOLTIP_DEFAULT_COLOR.g, TOOLTIP_DEFAULT_COLOR.b);
    -- self:SetBackdropColor(TOOLTIP_DEFAULT_BACKGROUND_COLOR.r, TOOLTIP_DEFAULT_BACKGROUND_COLOR.g, TOOLTIP_DEFAULT_BACKGROUND_COLOR.b);

    -- self:SetHeight(20);
    -- self:SetWidth(100);

    self.borders = {};
    self.borders.left = self:CreateTexture(nil, "BORDER");
	self.borders.left:SetPoint("BOTTOMLEFT", -17, -20);
	self.borders.left:SetSize(25, 64);
	self.borders.left:SetTexture("Interface\\Glues\\CharacterCreate\\CharacterCreate-LabelFrame");
	self.borders.left:SetTexCoord(0, 0.1953125, 0, 1);

	self.borders.middle = self:CreateTexture(nil, "BORDER");
	self.borders.middle:SetPoint("LEFT", self.borders.left, "RIGHT");
	self.borders.middle:SetSize(115, 64);
	self.borders.middle:SetTexture("Interface\\Glues\\CharacterCreate\\CharacterCreate-LabelFrame");
    self.borders.middle:SetTexCoord(0.1953125, 0.8046875, 0, 1);

	self.borders.right = self:CreateTexture(nil, "BORDER");
	self.borders.right:SetPoint("LEFT", self.borders.middle, "RIGHT");
	self.borders.right:SetSize(25, 64);
	self.borders.right:SetTexture("Interface\\Glues\\CharacterCreate\\CharacterCreate-LabelFrame");
	self.borders.right:SetTexCoord(0.8046875, 1, 0, 1);

    self.fonts = {};
    self.fonts.label = self:CreateFontString(nil, nil, "GameFontNormalSmall");
    self.fonts.label:SetPoint("BOTTOMLEFT", self.borders.left, "TOPLEFT", 17, -16);
    self.fonts.label:SetText("Hello");

    self.fonts.value = self:CreateFontString(nil, nil, "GameFontHighlightSmall");
    self.fonts.value:SetPoint("RIGHT", self.borders.right, -43, 2);
    self.fonts.value:SetText("World");

    self:SetWidth(160);
    self:SetHeight(38);

    self.borders.middle:SetWidth(self:GetWidth() - 17);

    self.toggle = ToggleButton(self);
    self.toggle:ClearAllPoints();
    self.toggle:SetPoint("RIGHT", self.borders.right, "LEFT", 9, 0);
    self.toggle:SetPoint("LEFT", self.borders.left, 17, 0);

    self.toggle:On("Click", function()
        if not self.menu then
            self.menu = ButterGUIDropdownMenu();
            self.menu:ClearAllPoints();
            self.menu:SetPoint("TOPLEFT", self, "BOTTOMLEFT");
            self.menu:SetWidth(self:GetWidth());
            self.menu:SetOptions(self.options);
            self.menu:SetValue(self.value);
            self.menu:Show();

            self.menu:On("Change", function(value)
                self:SetValue(value);
                self:Fire("Change", value);
                self.menu:Release();
                self.menu = nil;
            end);
        else
            self.menu:Release();
            self.menu = nil;
        end
    end);
end

function Dropdown:OnAcquire()
    BaseInputElement.OnAcquire(self);

    self:SetTooltipEnabled(false);
end

function Dropdown:SetLabel(label)
    BaseInputElement.SetLabel(self, label);

    self.fonts.label:SetText(self.label);
    self.toggle:SetLabel(self.label);
end

function Dropdown:SetDesc(desc)
    BaseInputElement.SetDesc(self, desc);

    self.toggle:SetDesc(self.desc);
end

function Dropdown:SetValue(value)
    self.value = value;

    self.fonts.value:SetText(self:_getLabelForValue(self.value));
end

function Dropdown:SetOptions(options)
    self.options = options;

    self.fonts.value:SetText(self:_getLabelForValue(self.value));
end

function Dropdown:_getLabelForValue(value)
    if self.options then
        for _, option in pairs(self.options) do
            if option.value == value then
                return option.label;
            end
        end
    end

    return nil;
end
