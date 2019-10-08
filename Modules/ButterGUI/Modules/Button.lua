local CreateClass = LibStub("Poncho-1.0");

local BaseInputElement = ButterGUIBaseInputElement;
ButterGUIButton = CreateClass("Frame", "ButterGUIButton", nil, nil, BaseInputElement);
local Button = ButterGUIButton;

function Button:OnCreate()
    BaseInputElement.OnCreate(self);

    self.state = {};

    self.textures = {};
    self.textures.background = self:CreateTexture(nil, "BACKGROUND");
    self.textures.background:SetAllPoints();

    self.textures.highlight = self:CreateTexture(nil, "ARTWORK");
    self.textures.highlight:SetAllPoints();
    self.textures.highlight:SetBlendMode("ADD");
    self.textures.highlight:SetAlpha(0);

    self.textures.check = self:CreateTexture(nil, "ARTWORK");
    self.textures.check:SetPoint("LEFT");
    self.textures.check:SetTexture("Interface\\Buttons\\UI-CheckBox-Check");
    self.textures.check:SetWidth(20);
    self.textures.check:SetHeight(20);

    self.font = self:CreateFontString(nil, nil, "GameFontHighlightSmall");
    self.font:SetPoint("LEFT", 30, 0);
end

function Button:OnAcquire()
    BaseInputElement.OnAcquire(self);

    self:SetChecked(false);
    self:SetHeight(UIDROPDOWNMENU_BUTTON_HEIGHT);

    self:On("MouseDown", function()
        if self.disabled then return end

        self.textures.background:SetTexture(self.state.pushed or self.state.normal);
    end);

    self:On("MouseUp", function()
        self.textures.background:SetTexture(self.state.normal);
    end);

    self:On("Click", function()
        PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON);
    end);

    self:On("Enter", function()
        if self.disabled then return end

        if IsMouseButtonDown("LeftButton") then
            self.textures.background:SetTexture(self.state.pushed or self.state.normal);
        end

        self.textures.highlight:SetAlpha(1);
    end);

    self:On("Leave", function()
        self.textures.background:SetTexture(self.state.normal);
        self.textures.highlight:SetAlpha(0);
    end);
end

function Button:OnRelease()
    BaseInputElement.OnRelease(self);

    self:SetNormalTexture(nil);
    self:SetPushedTexture(nil);
    self:SetDisabledTexture(nil);
    self:SetHighlightTexture(nil);
    self:SetDisabled(false);
    self.textures.highlight:SetAlpha(0);
end

function Button:SetChecked(checked)
    self.checked = checked;

    if self.checked then
        self.textures.check:Show();
    else
        self.textures.check:Hide();
    end
end

function Button:SetLabel(label)
    BaseInputElement.SetLabel(self, label);

    self.font:SetText(label);
end

function Button:SetNormalTexture(texture)
    self.state.normal = texture;

    self:RefreshTexture();
end

function Button:SetPushedTexture(texture)
    self.state.pushed = texture;

    self:RefreshTexture();
end

function Button:SetDisabledTexture(texture)
    self.state.disabled = texture;

    self:RefreshTexture();
end

function Button:SetHighlightTexture(texture)
    self.textures.highlight:SetTexture(texture);
end

function Button:SetDisabled(disabled)
    BaseInputElement.SetDisabled(self, disabled);

    self:RefreshTexture();
end

function Button:RefreshTexture()
    self.textures.background:SetTexture(self.disabled and self.state.disabled or self.state.normal);
end
