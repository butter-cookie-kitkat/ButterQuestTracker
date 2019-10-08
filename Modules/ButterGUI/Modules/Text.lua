local CreateClass = LibStub("Poncho-1.0");

local BaseInputElement = ButterGUIBaseInputElement;
ButterGUIText = CreateClass("Frame", "ButterGUIText", nil, nil, BaseInputElement);
local Text = ButterGUIText;

function Text:OnCreate()
    self.font = self:CreateFontString(nil, nil, "GameFontNormal");
    self.font:SetParent(self);
    self.font:SetJustifyH("LEFT");

    self.font:ClearAllPoints();
    self.font:SetPoint("TOPLEFT", 0, 0);
end

function Text:OnAcquire()
    BaseInputElement.OnAcquire(self);

    -- self:SetColor(NORMAL_FONT_COLOR);
    -- self:SetHoverColor(HIGHLIGHT_FONT_COLOR);
    -- self:SetHovering(false);

    -- self:RefreshColor();
    self:Show();
end

function Text:SetLabel(label)
    self.font:SetText(label);

    -- Wait for the next frame to update the text size
    self:Once("Update", function()
        self:SetHeight(self.font:GetHeight());
        self:SetWidth(self.font:GetWidth());
    end);
end

function Text:SetFontSize(size)
    self.font:SetFont(self.font:GetFont(), size);
end
