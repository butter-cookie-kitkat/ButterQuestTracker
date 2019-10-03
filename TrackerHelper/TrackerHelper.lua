

local CreateClass = LibStub("Poncho-1.0");
local helper = LibStub:NewLibrary("TrackerHelper-1.0", 2);

local class = CreateClass("Frame", "ButterQuestTrackerFrame", UIParent);

helper.settings = {
    width = 200,
    maxHeight = 500,
    backgroundColor = {
        r = 0,
        g = 0,
        b = 0,
        a = 0.5
    },
    backgroundVisible = false,
    locked = false
};

helper.frame = class();
helper.frame:SetClipsChildren(true);
helper.frame:SetClampedToScreen(true);
helper.frame:SetFrameStrata("BACKGROUND");
helper.frame:SetSize(1, 1);
helper.frame:EnableMouseWheel(true);

local function hex2rgb(hex)
    hex = hex:gsub("#","")
    if #hex == 6 then
        return tonumber("0x" .. hex:sub(1,2)) / 255, tonumber("0x" .. hex:sub(3,4)) / 255, tonumber("0x" .. hex:sub(5,6)) / 255;
    end

    return tonumber("0x" .. hex:sub(3, 4)) / 255, tonumber("0x" .. hex:sub(5, 6)) / 255, tonumber("0x" .. hex:sub(7, 8)) / 255, tonumber("0x" .. hex:sub(1,2)) / 255;
end

local function getDistance(x1, y1, x2, y2)
	return math.sqrt( (x2-x1)^2 + (y2-y1)^2 );
end

local function clampScrollFrame(scrollFrame)
    local parent = scrollFrame:GetParent();

    if scrollFrame:GetTop() < parent:GetTop() then
        scrollFrame:SetPoint("TOP", parent, 0, 0);
    elseif scrollFrame:GetBottom() > parent:GetBottom() then
        scrollFrame:SetPoint("TOP", parent, 0, scrollFrame:GetHeight() - parent:GetHeight());
    end
end

helper.frame:SetScript("OnMouseWheel", function(_, value)
    local _, _, _, _, y = helper.frame.content:GetPoint("TOP");
    helper.frame.content:SetPoint("TOP", helper.frame, 0, y + 10 * -value);

    clampScrollFrame(helper.frame.content);
end);

helper.frame.content = class();
helper.frame.content:SetParent(helper.frame);
helper.frame.content:SetSize(1, 1);
helper.frame.content:SetPoint("TOP", 0, 0);
helper.frame.content:SetPoint("LEFT", 0, 0);
helper.frame.content:SetPoint("RIGHT", 0, 0);
helper.frame.content.elements = {};

helper.frame.background = class();
helper.frame.background:SetParent(helper.frame);
helper.frame.background:SetAllPoints();
helper.frame.background.texture = helper.frame.background:CreateTexture(nil, "BACKGROUND");
helper.frame.background.texture:SetAllPoints();

local function count(t)
    local _count = 0;
    if t then
        for _, _ in pairs(t) do _count = _count + 1 end
    end
    return _count;
end

local function findPriorElement(elements, predicateElement)
    local previousElement;
    for _, element in pairs(elements) do
        if element == predicateElement then
            return previousElement;
        end
        previousElement = element;
    end
end

local function normalizeColor(color, defaultValue)
    color = color or defaultValue or {};

    if type(color) == "string" then
        local r, g, b, a = hex2rgb(color);

        color = {
            r = r,
            g = g,
            b = b,
            a = a or 1.0
        };
    end

    color.r = color.r or 0;
    color.g = color.g or 0;
    color.b = color.b or 0;
    color.a = color.a or 0;

    return color;
end

local function normalizeSharedOptions(options)
    options = options or {};

    options.container = options.container or helper.frame.content;
    options.events = options.events or false;
    options.padding = options.padding or {};
    options.padding.top = options.padding.top or options.padding.y or 0;
    options.padding.bottom = options.padding.bottom or options.padding.y or 0;
    options.padding.left = options.padding.left or options.padding.x or 0;
    options.padding.right = options.padding.right or options.padding.x or 0;

    local numberOfSiblings = count(options.container.elements);
    if numberOfSiblings > 0 then
        options._previousElement = options.container.elements[numberOfSiblings];

        options.padding.left = options.padding.left + options.container:GetLeft() - options._previousElement:GetLeft();
    end

    if options.events then
        local noop = function() end;

        options.events.OnEnter = options.events.OnEnter or noop;
        options.events.OnLeave = options.events.OnLeave or noop;
        options.events.OnMouseDown = options.events.OnMouseDown or noop;
        options.events.OnMouseUp = options.events.OnMouseUp or noop;

        options.events.OnButterMouseUp = options.events.OnButterMouseUp or noop;
        options.events.OnButterDragStart = options.events.OnButterDragStart or noop;
        options.events.OnButterDragStop = options.events.OnButterDragStop or noop;
    end

    return options;
end

local function normalizeContainerOptions(options)
    options = normalizeSharedOptions(options);

    options.hidden = options.hidden or false;
    options.backgroundColor = normalizeColor(options.backgroundColor);

    return options;
end

local function normalizeFontOptions(options)
    options = normalizeSharedOptions(options);

    options.size = options.size or 12;
    options.color = normalizeColor(options.color, NORMAL_FONT_COLOR);
    options.hoverColor = normalizeColor(options.hoverColor, HIGHLIGHT_FONT_COLOR);

    return options;
end

local function UpdateParentsHeight(element, delta)
    local x, y = helper:GetPosition();

    local hidden = element.hidden or false;
    local parent = element:GetParent();
    while parent do
        if parent.hidden then
            hidden = true;
        end

        if not hidden then
            if parent == helper.frame then
                parent:SetHeight(math.min(helper.frame.content:GetHeight(), helper.settings.maxHeight));
            else
                parent:SetHeight(parent:GetHeight() + delta);
            end
        end

        parent = parent:GetParent();
    end

    clampScrollFrame(helper.frame.content);

    -- Workaround to the frame from jumping around on sizing changes.
    helper:SetPosition(x, y);
end

function helper:UpdateSettings(settings)
    if settings.maxHeight ~= nil then
        self:SetMaxHeight(settings.maxHeight);
    end

    if settings.width ~= nil then
        self:SetWidth(settings.width);
    end

    if settings.backgroundColor ~= nil then
        self:SetBackgroundColor(settings.backgroundColor);
    end

    if settings.position ~= nil then
        self:SetPosition(settings.position.x, settings.position.y);
    end

    if settings.backgroundVisible ~= nil then
        self:SetBackgroundVisibility(settings.backgroundVisible);
    end

    if settings.locked ~= nil then
        self:SetLocked(settings.locked);
    end
end

function helper:SetLocked(locked)
    self.settings.locked = locked;

    self.frame:SetMovable(not locked);
end

function helper:SetBackgroundColor(backgroundColor)
    self.settings.backgroundColor = backgroundColor;

    helper.frame.background.texture:SetColorTexture(backgroundColor.r, backgroundColor.g, backgroundColor.b, backgroundColor.a);
end

function helper:SetBackgroundVisibility(visible)
    -- TODO
    self.initial = self.initial == nil or self.initial;
    local from = visible and 0 or 1;
    local to = visible and 1 or 0;

    if self.initial then
        self.frame.background:SetAlpha(to);
        self.initial = false;
    elseif self.frame.background:GetAlpha() ~= to then
        if not self.frame.background.group then
            self.frame.background.group = self.frame.background:CreateAnimationGroup();
            self.frame.background.group.fade = self.frame.background.group:CreateAnimation("Alpha");
            self.frame.background.group.fade:SetDuration(0.125);
        end

        local group = self.frame.background.group;
        local fade = group.fade;

        fade:SetFromAlpha(from);
        fade:SetToAlpha(to);
        fade:SetSmoothing("OUT")
        fade:SetScript("OnFinished", function()
            group:Stop();
            self.frame.background:SetAlpha(to);
        end);

        group:Play();
    end
end

-- /dump LibStub("TrackerHelper-1.0"):SetPosition()
function helper:SetPosition(x, y)
    if x == nil or y == nil then
        local currentX, currentY = self:GetPosition();

        x = x or currentX;
        y = y or currentY;
    end

    self.frame:ClearAllPoints();
    self.frame:SetPoint("TOPRIGHT", UIParent, "TOPRIGHT", x, y);
end

function helper:SetWidth(width)
    self.settings.width = width;

    self.frame:SetWidth(self.settings.width);
    self:Refresh();
end

function helper:SetMaxHeight(maxHeight)
    self.settings.maxHeight = maxHeight;

    self.frame:SetHeight(math.min(self.settings.maxHeight, self.frame.content:GetHeight()));
end

function helper:GetPosition()
    local x = self.frame:GetRight();
    local y = self.frame:GetTop();

    local inversedX = x - GetScreenWidth();
    local inversedY = y - GetScreenHeight();

    return inversedX, inversedY;
end

-- /dump LibStub("TrackerHelper-1.0"):Clear()
function helper:Clear(element)
    element = element or helper.frame.content;

    for key, child in pairs(element.elements) do
        if child.elements then
            self:Clear(child);
        end
        child:Hide();
        element.elements[key] = nil;
    end

    element.elements = {};
    element:SetHeight(1);
end

-- /dump LibStub("TrackerHelper-1.0"):Refresh()
function helper:Refresh(element)
    element = element or self.frame.content;

    if element.elements then
        element:SetHeight(1);

        if element.metadata then
            UpdateParentsHeight(element, element:GetHeight() + element.metadata.padding.top + element.metadata.padding.bottom);
        end

        for _, child in pairs(element.elements) do
            self:Refresh(child);
        end
    else
        UpdateParentsHeight(element, element:GetHeight() + element.metadata.padding.top + element.metadata.padding.bottom);
    end
end

function helper:Container(options)
    options = normalizeContainerOptions(options);

    local container = class();
    container.metadata = {
        padding = options.padding
    };

    container:SetParent(options.container);
    if options._previousElement then
        container:SetPoint("TOPLEFT", options._previousElement, "BOTTOMLEFT", options.padding.left, -options.padding.top - options._previousElement.metadata.padding.bottom);
        container:SetPoint("RIGHT", options._previousElement, -options.padding.right, 0);
    else
        container:SetPoint("TOPLEFT", options.container, options.padding.left, -options.padding.top);
        container:SetPoint("RIGHT", options.container, -options.padding.right, 0);
    end

    container:SetHeight(1);
    container.hidden = false;
    container.texture = container:CreateTexture(nil, "BACKGROUND");
    container.texture:SetAllPoints();
    container.texture:SetColorTexture(options.backgroundColor.r, options.backgroundColor.g, options.backgroundColor.b, options.backgroundColor.a);
    container.elements = {};

    function container:SetHidden(hidden)
        local previouslyHidden = self.hidden;
        self.hidden = hidden;
        local previousElement = findPriorElement(options.container.elements, self);

        if hidden and not previouslyHidden then -- If we're hiding this element and it's not already hidden
            if previousElement then
                self:SetPoint("TOPLEFT", previousElement, "BOTTOMLEFT", options.padding.left, -previousElement.metadata.padding.bottom);
            else
                self:SetPoint("TOPLEFT", self.metadata.container, options.padding.left, 0);
            end

            self:Hide();
            helper:Refresh();
        elseif not hidden and previouslyHidden then -- If we're showing this element and it's not already shown
            if previousElement then
                self:SetPoint("TOPLEFT", previousElement, "BOTTOMLEFT", self.metadata.padding.left, -self.metadata.padding.top - previousElement.metadata.padding.bottom);
            else
                self:SetPoint("TOPLEFT", self.metadata.container, self.metadata.padding.left, -self.metadata.padding.top);
            end

            self:Show();
            helper:Refresh();
        end

    end

    function container:Toggle()
        local hidden = not self.hidden;

        self:SetHidden(hidden);

        return hidden;
    end

    if options.events then
        container:EnableMouse(true);
        container:SetScript('OnEnter', function(...)
            for _, element in pairs(container.elements) do
                element:SetTextColor(element.metadata.hoverColor.r, element.metadata.hoverColor.g, element.metadata.hoverColor.b);
            end

            options.events.OnEnter(...);
        end);

        container:SetScript('OnLeave', function(...)
            for _, element in pairs(container.elements) do
                element:SetTextColor(element.metadata.color.r, element.metadata.color.g, element.metadata.color.b);
            end

            options.events.OnLeave(...);
        end);

        local originalMouseLocation = {};
        local dragTimer, dragged;
        container:SetScript('OnMouseDown', function(...)
            originalMouseLocation.x, originalMouseLocation.y = GetCursorPosition();
            dragged = false;

            if count(container.elements) > 0 then
                local firstElement = container.elements[1];
                firstElement:SetPoint("TOPLEFT", 2, -2);
                firstElement:SetPoint("RIGHT", 2, 0);
            end

            local _, button = ...;
            if button == "LeftButton" and not helper.settings.locked then
                dragTimer = C_Timer.NewTicker(0.1, function()
                    local cursorX, cursorY = GetCursorPosition();
                    local distance = getDistance(originalMouseLocation.x, originalMouseLocation.y, cursorX, cursorY);

                    if distance ~= 0 then
                        dragged = true;
                        dragTimer:Cancel();
                        options.events.OnButterDragStart();
                    end
                end);
            end

            options.events.OnMouseDown(...);
        end);

        container:SetScript('OnMouseUp', function(...)
            if dragTimer then
                dragTimer:Cancel();
            end

            if count(container.elements) > 0 then
                local firstElement = container.elements[1];
                firstElement:SetPoint("TOPLEFT", 0, 0);
                firstElement:SetPoint("RIGHT", 0, 0);
            end

            if dragged then
                options.events.OnButterDragStop();
            else
                options.events.OnButterMouseUp(...);
            end
            options.events.OnMouseUp(...);
        end);
    else
        container:EnableMouse(false);
    end

    local deltaHeight = container:GetHeight() + options.padding.top + options.padding.bottom;
    UpdateParentsHeight(container, deltaHeight);

    tinsert(options.container.elements, container);
    container:SetHidden(options.hidden);
    return container;
end

function helper:Font(options)
    options = normalizeFontOptions(options);

    local font = self.frame:CreateFontString(nil, nil, "GameFontNormal");

    font.metadata = {
        padding = options.padding,
        color = options.color,
        hoverColor = options.hoverColor
    };

    font:SetParent(options.container);
    font:SetText(options.label);
    font:SetJustifyH("LEFT");

    if count(options.container.elements) > 0 then
        local previousElement = options.container.elements[count(options.container.elements)];
        font:SetPoint("TOPLEFT", previousElement, "BOTTOMLEFT", options.padding.left, -options.padding.top - previousElement.metadata.padding.bottom);
        font:SetPoint("RIGHT", previousElement, -options.padding.right, 0);
    else
        font:SetPoint("TOPLEFT", options.container, options.padding.left, -options.padding.top);
        font:SetPoint("RIGHT", options.container, -options.padding.right, 0);
    end

    font:SetTextColor(font.metadata.color.r, font.metadata.color.g, font.metadata.color.b);
    font:SetFont(font:GetFont(), options.size);

    local deltaHeight = font:GetHeight() + options.padding.top + options.padding.bottom;
    UpdateParentsHeight(font, deltaHeight);

    tinsert(options.container.elements, font);

    return font;
end

helper:UpdateSettings(helper.settings);
