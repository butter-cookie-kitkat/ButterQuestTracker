local helper = LibStub:NewLibrary("TrackerHelper-1.0", 1);
local isWoWClassic = select(4, GetBuildInfo()) < 20000;

local frame;
local indexes;
local elements = {
    fonts = {},
    containers = {}
};

local function normalizePadding(padding)
    padding = padding or 0;

    if type(padding) == "number" then
        padding = {
            top = padding,
            bottom = padding,
            left = padding,
            right = padding
        };
    elseif padding.x or padding.y then
        padding.top = padding.top or padding.y;
        padding.bottom = padding.bottom or padding.y;
        padding.left = padding.left or padding.x;
        padding.right = padding.right or padding.x;
    end

    padding.top = padding.top or 0;
    padding.bottom = padding.bottom or 0;
    padding.left = padding.left or 0;
    padding.right = padding.right or 0;

    return padding;
end

local function normalizeFontOptions(options)
    options = options or {};

    options.size = options.size or 12;
    options.style = "Fonts\\" .. (options.style or "FRIZQT__.TTF");
    options.padding = normalizePadding(options.padding);
    options.color = options.color or {
        r = 1.0,
        g = 1.0,
        b = 1.0
    };
    options.container = options.container or helper:GetFrame().content;

    return options;
end

local function normalizeContainerOptions(options)
    options = options or {};

    options.events = options.events or {};
    options.padding = normalizePadding(options.padding);

    return options;
end

-- {}
-- /dump LibStub("TrackerHelper-1.0"):UpdateFrame({
--
-- })
function helper:UpdateFrame(options)
    if not options then return end

    local frame = self:GetFrame();

    if options.clamp ~= nil then
        frame:SetClampedToScreen(options.clamp);
    end

    if options.layer ~= nil then
        frame:SetFrameStrata(options.layer);
    end

    if options.x ~= nil or options.y ~= nil then
        self:UpdatePosition(options.x, options.y);
    end

    if options.width ~= nil then
        self:UpdateWidth(options.width);
    end

    if options.maxHeight ~= nil then
        self.maxHeight = options.maxHeight;
        self:UpdateHeight();
    end

    if options.backgroundColor ~= nil then
        frame.backgroundFrame.texture:SetColorTexture(options.backgroundColor.r, options.backgroundColor.g, options.backgroundColor.b, options.backgroundColor.a)
    end

    if options.backgroundAlwaysVisible ~= nil then
        self.backgroundAlwaysVisible = options.backgroundAlwaysVisible;
        self:SetBackgroundVisibility();
    end
end

function helper:Clear()
    indexes = { containers = 1 };

    local frame = self:GetFrame();
    frame.content:SetSize(1, 1);
    frame.content:SetPoint("TOP", frame, 0, -5);
    frame.content:SetPoint("LEFT", frame, 5, 0);
    frame.content:SetPoint("RIGHT", frame, -5, 0);

    for i, font in pairs(elements.fonts) do
        font:Hide();
        elements.fonts[i] = nil;
    end

    for i, container in pairs(elements.containers) do
        container:Hide();
    end
end

-- /dump LibStub("TrackerHelper-1.0"):GetFrame()
function helper:GetFrame()
    if not frame then
        frame = CreateFrame("Frame", nil, UIParent);
        frame:SetSize(1, 1);
        frame:SetFrameStrata("BACKGROUND");
        frame:SetMovable(true);
        frame:EnableMouseWheel(true);
        frame:SetClipsChildren(true);

        frame:SetScript("OnMouseWheel", function(self, value)
            local _, _, _, _, y = frame.content:GetPoint("TOP");
            frame.content:SetPoint("TOP", frame, 0, y + 10 * -value);

            if frame.content:GetTop() + 5 < frame:GetTop() then
                frame.content:SetPoint("TOP", frame, 0, -5);
            elseif frame.content:GetBottom() - 5 > frame:GetBottom() then
                frame.content:SetPoint("TOP", frame, 0, frame.content:GetHeight() - frame:GetHeight() + 5);
            end
        end);

        frame.content = CreateFrame("Frame", nil, frame);
        frame.content.elements = {};

        frame.content.SetRealHeight = frame.content.SetHeight;
        function frame.content:SetHeight(height)
            helper:UpdateHeight(height);
        end

        frame.backgroundFrame = CreateFrame("Frame", nil, frame);
        frame.backgroundFrame:SetSize(1, 1);
        frame.backgroundFrame:SetAllPoints();

        frame.backgroundFrame.texture = frame.backgroundFrame:CreateTexture(nil, "BACKGROUND");
        frame.backgroundFrame.texture:SetAllPoints();
        frame.backgroundFrame.texture:SetColorTexture(0, 0, 0, 0.5);

        self:SetDebugMode();
        self:UpdateWidth(250);
        self:UpdatePosition(0, 0);
        self:Clear();
    end

    return frame;
end

local function refreshElementSize(element, parent)
    if element.elements then
        element:SetSize(1, 1);

        for _, childElement in pairs(element.elements) do
            refreshElementSize(childElement, element);
        end

        if parent then
            local parentHeight = parent:GetHeight();

            element:SetPoint("TOP", parent, 0, -parentHeight - element.metadata.padding.top);
            element:SetPoint("LEFT", parent, "LEFT", element.metadata.padding.left, 0);
            element:SetPoint("RIGHT", parent, "RIGHT", -element.metadata.padding.right, 0);

            local deltaHeight = element:GetHeight() + element.metadata.padding.top + element.metadata.padding.bottom;
            parent:SetHeight(parentHeight + deltaHeight);
        end
    else
        local parentHeight = parent:GetHeight();

        element:ClearAllPoints();
        element:SetPoint("TOP", parent, 0, -parentHeight - element.metadata.padding.top);
        element:SetPoint("LEFT", parent, "LEFT", element.metadata.padding.left, 0);
        element:SetPoint("RIGHT", parent, "RIGHT", -element.metadata.padding.right, 0);

        local deltaHeight = element:GetHeight() + element.metadata.padding.top + element.metadata.padding.bottom;
        parent:SetHeight(parentHeight + deltaHeight);
    end
end

function helper:UpdateHeight(height)
    local frame = self:GetFrame();
    height = height or frame.content:GetHeight();

    if self.maxHeight then
        frame:SetHeight(math.min(height + 10, self.maxHeight));
    else
        frame:SetHeight(height + 10);
    end

    frame.content:SetRealHeight(height);
end

function helper:UpdateWidth(width)
    local frame = self:GetFrame();

    if width ~= frame:GetWidth() then
        frame:SetWidth(width);

        -- Refresh all of the text positions and sizes
        refreshElementSize(frame.content);
    end
end

function helper:UpdatePosition(x, y)
    if x == nil or y == nil then
        local currentX, currentY = self:GetPosition();

        x = x or currentX;
        y = y or currentY;
    end

    local frame = self:GetFrame();
    frame:ClearAllPoints();
    frame:SetPoint("TOPRIGHT", UIParent, "TOPRIGHT", x, y);
end

function helper:GetPosition()
    local frame = self:GetFrame();

    local x = frame:GetRight();
    local y = frame:GetTop();

    local inversedX = x - GetScreenWidth();
    local inversedY = y - GetScreenHeight();

    return inversedX, inversedY;
end

function helper:SetBackgroundVisibility(visible)
    self.initial = self.initial == nil or self.initial;
    local from = (self.backgroundAlwaysVisible or visible) and 0 or 1;
    local to = (self.backgroundAlwaysVisible or visible) and 1 or 0;

    local frame = self:GetFrame();

    if self.initial then
        frame.backgroundFrame:SetAlpha(to);
        self.initial = false;
    elseif frame.backgroundFrame:GetAlpha() ~= to then
        if not frame.backgroundFrame.group then
            frame.backgroundFrame.group = frame.backgroundFrame:CreateAnimationGroup();
            frame.backgroundFrame.group.fade = frame.backgroundFrame.group:CreateAnimation("Alpha");
            frame.backgroundFrame.group.fade:SetDuration(0.125);
        end

        local group = frame.backgroundFrame.group;
        local fade = group.fade;

        fade:SetFromAlpha(from);
        fade:SetToAlpha(to);
        fade:SetSmoothing("OUT")
        fade:SetScript("OnFinished", function()
            group:Stop();
            frame.backgroundFrame:SetAlpha(to);
        end);

        group:Play();
    end
end

function helper:SetDebugMode(debug)
    self.debug = debug == nil and self.debug or debug;

    self:SetBackgroundVisibility(self.debug);

    for i, container in pairs(elements.containers) do
        if self.debug then
            container:SetBackdropColor(0, 1, 0, 0.5);
        else
            container:SetBackdropColor(0, 0, 0, 0);
        end
    end
end

function helper:CreateContainer(options)
    options = normalizeContainerOptions(options);

    local frame = self:GetFrame();
    local contentHeight = frame.content:GetHeight();

    if not elements.containers[indexes.containers] then
        elements.containers[indexes.containers] = CreateFrame("Frame", nil, frame.content);
        tinsert(frame.content.elements, elements.containers[indexes.containers]);
    end

    local container = elements.containers[indexes.containers];
    container.elements = {};
    container.metadata = {
        padding = options.padding
    };
    container:SetHeight(0);
    container:SetSize(1, 1);
    container:ClearAllPoints();
    container:SetPoint("TOP", frame.content, 0, -contentHeight - options.padding.top);
    container:SetPoint("LEFT", frame.content, "LEFT", options.padding.left, 0);
    container:SetPoint("RIGHT", frame.content, "RIGHT", -options.padding.right, 0);
    container:Show();

    container:EnableMouse(true);
    container:RegisterForDrag("LeftButton");
    container:SetMovable(true);

    container:SetScript("OnDragStart", options.events.OnDragStart);
    container:SetScript("OnDragStop", options.events.OnDragStop);
    container:SetScript("OnEnter", options.events.OnEnter);
    container:SetScript("OnLeave", options.events.OnLeave);

    if options.events.OnMouseUp or options.events.OnMouseDown then
        local originalPosition;
        container:SetScript("OnMouseUp", function(...)
            if originalPosition then
                container:ClearAllPoints();
                container:SetPoint("TOPLEFT", frame.content, originalPosition.left, originalPosition.top);
                container:SetPoint("RIGHT", frame.content, "RIGHT", originalPosition.right, 0);
                originalPosition = nil;
            end

            if options.events.OnMouseUp then
                options.events.OnMouseUp(...);
            end
        end);

        container:SetScript("OnMouseDown", function(...)
            local _, _, _, left, top = container:GetPoint("TOPLEFT");
            local _, _, _, right = container:GetPoint("RIGHT");
            originalPosition = {
                top = top,
                left = left,
                right = right
            };

            container:ClearAllPoints();
            container:SetPoint("TOPLEFT", frame.content, originalPosition.left + 2, originalPosition.top - 2);
            container:SetPoint("RIGHT", frame.content, "RIGHT", originalPosition.right + 2, 0);

            if options.events.OnMouseDown then
                options.events.OnMouseDown(...);
            end
        end);

        container:SetScript("OnDragStop", function(...)
            if originalPosition then
                container:ClearAllPoints();
                container:SetPoint("TOPLEFT", frame.content, originalPosition.left, originalPosition.top);
                container:SetPoint("RIGHT", frame.content, "RIGHT", originalPosition.right, 0);
                originalPosition = nil;
            end

            if options.events.OnDragStop then
                options.events.OnDragStop(...);
            end
        end);

        container:SetScript("OnEnter", function(...)
            for i, element in pairs(container.elements) do
                local hoverColor = element.metadata.hoverColor;

                if hoverColor then
                    element:SetTextColor(hoverColor.r, hoverColor.g, hoverColor.b);
                end
            end

            if options.events.OnEnter then
                options.events.OnEnter(...);
            end
        end);

        container:SetScript("OnLeave", function(...)
            if originalPosition then
                container:ClearAllPoints();
                container:SetPoint("TOPLEFT", frame.content, originalPosition.left, originalPosition.top);
                container:SetPoint("RIGHT", frame.content, "RIGHT", originalPosition.right, 0);
                originalPosition = nil;
            end

            for i, element in pairs(container.elements) do
                local color = element.metadata.color;

                if color then
                    element:SetTextColor(color.r, color.g, color.b);
                end
            end

            if options.events.OnLeave then
                options.events.OnLeave(...);
            end
        end);
    else
        container:SetScript("OnMouseUp", nil);
        container:SetScript("OnMouseDown", nil);
    end

    container:SetBackdrop({ bgFile = "Interface/Tooltips/UI-Tooltip-Background" });

    if self.debug then
        container:SetBackdropColor(0, 1, 0, 0.5);
    else
        container:SetBackdropColor(0, 0, 0, 0);
    end

    frame.content:SetHeight(contentHeight + options.padding.top + options.padding.bottom);

    indexes.containers = indexes.containers + 1;
    return container;
end

-- /dump LibStub("TrackerHelper-1.0"):DrawFont({ label = "Hello World!", padding = 10 })
function helper:DrawFont(options)
    options = normalizeFontOptions(options);

    local frame = self:GetFrame();

    local font = frame.content:CreateFontString(nil, nil, "GameFontNormal");
    font:SetFont(options.style, options.size);

    local containerHeight = options.container:GetHeight();

    font.metadata = {
        color = options.color,
        hoverColor = options.hoverColor,
        padding = options.padding
    };

    font:SetText(options.label);
    font:SetJustifyH("LEFT");
    font:SetTextColor(options.color.r, options.color.g, options.color.b);
    font:SetWordWrap(true);
    font:SetNonSpaceWrap(true);

    font:ClearAllPoints();
    font:SetPoint("TOP", options.container, 0, -containerHeight - options.padding.top);
    font:SetPoint("LEFT", options.container, "LEFT", options.padding.left, 0);
    font:SetPoint("RIGHT", options.container, "RIGHT", -options.padding.right, 0);

    local deltaHeight = font:GetHeight() + options.padding.top + options.padding.bottom;
    options.container:SetHeight(containerHeight + deltaHeight);

    if options.container ~= frame.content then
        local contentHeight = frame.content:GetHeight();
        frame.content:SetHeight(contentHeight + deltaHeight);
    end

    tinsert(options.container.elements, font);
    tinsert(elements.fonts, font);
    return font;
end
