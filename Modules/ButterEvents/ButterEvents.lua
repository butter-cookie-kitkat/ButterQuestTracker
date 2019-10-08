local CreateClass = LibStub("Poncho-1.0");

ButterEvents = CreateClass("Frame", "ButterEvents");
local Events = ButterEvents;

local function findIndex(t, value)
    for i, element in ipairs(t) do
        if element == value then
            return i;
        end
    end

    return nil;
end

function Events:OnAcquire()
    self.listeners = {};

    self:On("MouseUp", function(...)
        if MouseIsOver(self) then
            self:Fire("Click", ...);
        end
    end);
end

function Events:OnRelease()
    for event in pairs(self.listeners) do
        if self:IsNativeEvent(event) and self:GetScript("On" .. event) == nil then
            self:SetScript("On" .. event, nil);
        end
    end

    self.listeners = {};
end

-- Registers an event listener.
function Events:On(event, listener)
    if not self.listeners[event] then
        self.listeners[event] = {};
    end

    if self:IsNativeEvent(event) and self:GetScript("On" .. event) == nil then
        self:SetScript("On" .. event, function(...)
            self:Fire(event, ...);
        end);
    end

    tinsert(self.listeners[event], listener);
end

-- Registers an event listener to be invoked only once.
function Events:Once(event, listener)
    local function once(...)
        listener(...);
        self:Off(event, once);
    end

    self:On(event, once);
end

-- Unregisters an event listener.
function Events:Off(event, listener)
    if not self.listeners[event] then return end

    local index = findIndex(self.listeners[event], listener);

    if not index then return end

    table.remove(self.listeners[event], index);

    if #self.listeners[event] == 0 and self:IsNativeEvent(event) then
        self:SetScript("On" .. event, nil);
    end
end

-- Uses lua's error handling to determine if the event is supported by this frame.
function Events:IsNativeEvent(event)
    -- Is there a way to check if an event exists.. ?
    local ok = pcall(function()
        return self:GetScript("On" .. event);
    end);

    return ok;
end

function Events:Fire(event, ...)
    if not self.listeners[event] then return end

    for _, listener in ipairs(self.listeners[event]) do
        listener(...);
    end
end
