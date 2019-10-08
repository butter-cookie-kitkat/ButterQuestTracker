local CreateClass = LibStub("Poncho-1.0");

local BaseInputElement = ButterGUIBaseInputElement;
ButterGUICheckbox = CreateClass("Frame", "ButterGUICheckbox", nil, nil, BaseInputElement);
local Checkbox = ButterGUICheckbox;

Checkbox.SetValue = Checkbox.SetChecked;
Checkbox.GetValue = Checkbox.GetChecked;
Checkbox.GetLabel = Checkbox.GetText;

function Checkbox:OnCreate()
    self:SetFrameStrata("LOW");

    self.checkbox = self:CreateTexture(nil, "BORDER");
    self.checkbox:SetPoint("LEFT", -5, 0);
    self.checkbox:SetTexture("Interface\\Buttons\\UI-CheckBox-Up");

    self.highlight = self:CreateTexture(nil, "ARTWORK");
    self.highlight:SetAllPoints(self.checkbox);
    self.highlight:SetTexture("Interface\\Buttons\\UI-CheckBox-Highlight");
    self.highlight:SetBlendMode("ADD");
    self.highlight:SetAlpha(0);

    self.check = self:CreateTexture(nil, "OVERLAY");
    self.check:SetAllPoints(self.checkbox);

    self.font = self:CreateFontString();
    self.font:SetJustifyH("LEFT");

    self.font:ClearAllPoints();
    self.font:SetPoint("LEFT", self.checkbox, "RIGHT", 0, 0);
end

function Checkbox:OnAcquire()
    BaseInputElement.OnAcquire(self);

    self:SetSmall(false);
    self:SetValue(false);
    self:SetDisabled(false);

    self:On("MouseUp", function()
        if self.disabled then return end

        self.font:SetPoint("LEFT", self.checkbox, "RIGHT", 0, 0);
        self.checkbox:SetTexture("Interface\\Buttons\\UI-CheckBox-Up");
    end);

    self:On("MouseDown", function()
        if self.disabled then return end

        self.font:SetPoint("LEFT", self.checkbox, "RIGHT", 2, -2);
        self.checkbox:SetTexture("Interface\\Buttons\\UI-CheckBox-Down");
    end);

    self:On("Click", function()
        if self.disabled then return end

        PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON);

        local checked = not self:GetValue();
        self:SetValue(checked);
        self:Fire("Change", checked);
    end);

    self:On("Enter", function()
        if self.disabled then return end

        if IsMouseButtonDown("LeftButton") then
            self.font:SetPoint("LEFT", self.checkbox, "RIGHT", 2, -2);
        end

        self.highlight:SetAlpha(1);
    end);

    self:On("Leave", function()
        self.font:SetPoint("LEFT", self.checkbox, "RIGHT", 0, 0);
        self.highlight:SetAlpha(0);
    end);
end

function Checkbox:OnRelease()
    BaseInputElement.OnRelease(self);

	self:SetValue(nil);
end

function Checkbox:SetValue(value)
    BaseInputElement.SetValue(self, value);

    if self.value then
        self.check:SetAlpha(1);
    else
        self.check:SetAlpha(0);
    end
end

function Checkbox:SetLabel(label)
    BaseInputElement.SetLabel(self, label);

    self.font:SetText(self.label);

    self:SetWidth(self.checkbox:GetWidth() + self.font:GetWidth());
end

function Checkbox:SetDisabled(disabled)
    BaseInputElement.SetDisabled(self, disabled);

    if self.disabled then
        self.font:SetFontObject(self.font.disabled);
        self.check:SetTexture("Interface\\Buttons\\UI-CheckBox-Check-Disabled");
    else
        self.font:SetFontObject(self.font.normal);
        self.check:SetTexture("Interface\\Buttons\\UI-CheckBox-Check");
    end
end

function Checkbox:SetSmall(small)
    if small then
        self.font.disabled = "GameFontDisableSmall";
        self.font.normal = "GameFontHighlightSmall";

        self:SetHeight(16);
        self.checkbox:SetHeight(26);
        self.checkbox:SetWidth(26);
    else
        self.font.disabled = "GameFontDisable";
        self.font.normal = "GameFontHighlight";

        self:SetHeight(20);
        self.checkbox:SetHeight(30);
        self.checkbox:SetWidth(30);
    end

    self:SetWidth(self.checkbox:GetWidth() + self.font:GetWidth());
end
