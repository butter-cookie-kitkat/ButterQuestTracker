local CreateClass = LibStub("Poncho-1.0");

local Button = ButterGUIButton;
ButterGUIToggleButton = CreateClass("Frame", "ButterGUIToggleButton", nil, nil, Button);
local ToggleButton = ButterGUIToggleButton;

function ToggleButton:OnCreate()
    Button.OnCreate(self);

    self.font = nil;
end

function ToggleButton:OnAcquire()
    Button.OnAcquire(self);

    self.textures.background:ClearAllPoints();
    self.textures.background:SetPoint("TOPRIGHT", 0, 0);
    self.textures.background:SetWidth(24);
    self.textures.background:SetHeight(24);

    self.textures.highlight:ClearAllPoints();
    self.textures.highlight:SetPoint("TOPRIGHT", 0, 0);
    self.textures.highlight:SetWidth(24);
    self.textures.highlight:SetHeight(24);

    self:SetWidth(24);
    self:SetHeight(24);

    self:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIcon-ScrollDown-Up");
    self:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIcon-ScrollDown-Down");
    self:SetDisabledTexture("Interface\\ChatFrame\\UI-ChatIcon-ScrollDown-Disabled");
    self:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight");
end

function ToggleButton:SetLabel(label)
    self.label = label;
end
