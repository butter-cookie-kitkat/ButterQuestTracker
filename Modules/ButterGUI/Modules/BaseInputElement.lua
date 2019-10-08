local CreateClass = LibStub("Poncho-1.0");

local BaseElement = ButterGUIBaseElement;
ButterGUIBaseInputElement = CreateClass("Frame", "ButterGUIBaseInputElement", nil, nil, BaseElement);
local BaseInputElement = ButterGUIBaseInputElement;

function BaseInputElement:OnAcquire()
    BaseElement.OnAcquire(self);

    self:SetTooltipEnabled(true);

    self:On("Enter", function() self:ShowTooltip() end);
    self:On("Leave", function() self:HideTooltip() end);
end

function BaseInputElement:SetTooltipEnabled(tooltipEnabled)
    self.tooltipEnabled = tooltipEnabled;
end

function BaseInputElement:ShowTooltip()
    if self.disabled or not self.tooltipEnabled then return end

    GameTooltip:SetOwner(self, "ANCHOR_NONE");
    GameTooltip:SetPoint("BOTTOMLEFT", self, "TOPLEFT");

    if self.label ~= nil then
        GameTooltip:AddLine(self.label .. "\n", NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b, true);
    end

    if self.desc ~= nil then
        GameTooltip:AddLine(self.desc, HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b, true);
    end

    GameTooltip:Show();
end

function BaseInputElement:HideTooltip()
    GameTooltip:ClearLines();
    GameTooltip:Hide();
end

-- Getters & Setters

function BaseInputElement:SetLabel(label)
    self.label = label;
end

function BaseInputElement:GetLabel(label)
    return self.label;
end

function BaseInputElement:SetValue(value)
    self.value = value;
end

function BaseInputElement:GetValue()
    return self.value;
end

function BaseInputElement:SetDisabled(disabled)
    self.disabled = disabled;
end

function BaseInputElement:GetDisabled()
    return self.disabled;
end
