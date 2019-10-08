local CreateClass = LibStub("Poncho-1.0");

local Events = ButterEvents;
ButterGUIBaseElement = CreateClass("Frame", "ButterGUIBaseElement", nil, nil, Events);
local BaseElement = ButterGUIBaseElement;

function BaseElement:OnCreate()
    local setHeight = self.SetHeight;
    function self:SetHeight(height)
        local original = self:GetRealHeight();
        setHeight(self, math.max(1, height));
        self.height = height;
        self:Fire("Resize", self:GetRealHeight() - original);
    end
end

function BaseElement:OnAcquire()
    Events.OnAcquire(self);

    local parent = self:GetParent();

    self:SetMargin({
        top = 0,
        left = 0,
        right = 0,
        bottom = 0
    });
end

function BaseElement:On(event, listener)
    Events.On(self, event, listener);

    if event == "Resize" then
        listener(self:GetFullHeight());
    end
end

function BaseElement:OnRelease()
    Events.OnRelease(self);

    self.order = nil;
    self.margin = nil
    self:SetHeight(0);
end

function BaseElement:SetOrder(order)
    self.order = order;
end

function BaseElement:GetOrder()
    return self.order;
end

function BaseElement:SetDesc(desc)
    self.desc = desc;
end

function BaseElement:SetBackgroundColor(color)
    color = self:_normalizeColor(color);

    if color then
        if not self.texture then
            self.texture = self:CreateTexture(nil, "BACKGROUND");
            self.texture:SetAllPoints();
        end

        self.texture:Show();
        self.texture:SetColorTexture(color.r, color.g, color.b, color.a);
    elseif self.texture then
        self.texture:Hide();
    end
end

function BaseElement:SetMargin(margin)
    local parent = self:GetParent();

    local top = margin.top or margin.y or 0;
    local bottom = margin.bottom or margin.y or 0;
    local left = margin.left or margin.x or 0;
    local right = margin.right or margin.x or 0;

    local delta = top + bottom;
    if self.margin then
        delta = delta - (self.margin.top + self.margin.bottom);
    end

    self.margin = {
        top = top,
        bottom = bottom,
        left = left,
        right = right,
    };

    self:Fire("Resize", delta);
end

function BaseElement:GetRealHeight()
    return self.height or self:GetHeight();
end

function BaseElement:GetVerticalMargin()
    return self.margin.top + self.margin.bottom;
end

function BaseElement:GetHorizontalMargin()
    return self.margin.left + self.margin.right;
end

-- Height + Vertical Margin
function BaseElement:GetFullHeight()
    return self:GetRealHeight() + self:GetVerticalMargin();
end

-- Width + Horizontal Margin
function BaseElement:GetFullWidth()
    return self:GetWidth() + self:GetHorizontalMargin();
end

-- Helpers
local cache = {
    hex = {}
};
function BaseElement:_hex2rgb(hex)
    if not cache.hex[hex] then
        hex = hex:gsub("#", "");

        if #hex == 8 then
            cache.hex[hex] = {
                r = tonumber("0x" .. hex:sub(3,4)) / 255,
                g = tonumber("0x" .. hex:sub(5,6)) / 255,
                b = tonumber("0x" .. hex:sub(7,8)) / 255,
                a = tonumber("0x" .. hex:sub(1,2)) / 255
            };
        else
            cache.hex[hex] = {
                r = tonumber("0x" .. hex:sub(1,2)) / 255,
                g = tonumber("0x" .. hex:sub(3,4)) / 255,
                b = tonumber("0x" .. hex:sub(5,6)) / 255,
                a = 1.0
            };
        end
    end

    return cache.hex[hex];
end

function BaseElement:_normalizeColor(value)
    if not value then return end

    if type(value) == "string" then
        value = self:_hex2rgb(value);
    end

    return {
        r = value.r or 0.0,
        g = value.g or 0.0,
        b = value.b or 0.0,
        a = value.a or 1.0,
    };
end
