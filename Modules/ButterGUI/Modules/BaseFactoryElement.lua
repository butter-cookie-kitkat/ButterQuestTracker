local CreateClass = LibStub("Poncho-1.0");

local BaseElement = ButterGUIBaseElement;
ButterGUIBaseFactoryElement = CreateClass("Frame", "ButterGUIBaseFactoryElement", nil, nil, BaseElement);
local Factory = ButterGUIBaseFactoryElement;

function Factory:OnAcquire()
    BaseElement.OnAcquire(self);

    self.factory = true;
    self.db = {};
    self.initialRender = false;
    self:SetHeight(0);

    self:On("Show", function()
        if not self.initialRender then
            self:Render();
        end
    end);

    self:On("ElementAdded", function(element)
        tinsert(self.elements, element);
    end);
end

function Factory:OnRelease()
    BaseElement.OnRelease(self);

    if self.elements then
        for i, element in ipairs(self.elements) do
            element:Release();
        end
    end
end

function Factory:Render()
    self.initialRender = true;

    if self.elements then
        for _, element in ipairs(self.elements) do
            element:Release();
        end
    end

    self.elements = {};
    self:Fire("Render", self);

    for _, element in ipairs(self.elements) do
        if element.factory then
            element:Render();
        end
    end

    self:Order();
end

function Factory:Order()
    print(self:GetName() .. ": Failed to override order...");
end

-- Factories

function Factory:Group(options)
    local group = ButterGUIGroup(self);

    self:_setCommonOptions(options, group);

    group:On("Change", function(update)
        self:Fire("Change", update);
    end);

    self:Fire("ElementAdded", group);
    return group;
end

function Factory:Button(options)
    local button = ButterGUIButton(self);

    self:_setInputOptions(options, button);

    if options.checked ~= nil then
        button:SetChecked(options.checked);
    end

    self:Fire("ElementAdded", button);
    return button;
end

function Factory:Text(options)
    local text = ButterGUIText(self);

    self:_setInputOptions(options, text);

    if options.size ~= nil then
        text:SetFontSize(options.size);
    end

    self:Fire("ElementAdded", text);
    return text;
end

function Factory:Checkbox(options)
    local checkbox = ButterGUICheckbox(self);

    self:_setInputOptions(options, checkbox);

    if options.small ~= nil then
        checkbox:SetSmall(options.small);
    end

    self:Fire("ElementAdded", checkbox);
    return checkbox;
end

function Factory:Dropdown(options)
    local dropdown = ButterGUIDropdown(self);

    if options.options ~= nil then
        dropdown:SetOptions(options.options());
    end

    self:_setInputOptions(options, dropdown);

    self:Fire("ElementAdded", dropdown);
    return dropdown;
end

-- Helpers

function Factory:GetValueFromDB(type, key)
    if type == "global" and self.db.global then
        return self.db.global[key];
    elseif type == "char" and self.db.char then
        return self.db.char[key];
    end

    local parent = self:GetParent();

    if parent.factory then
        return parent:GetValueFromDB(type, key);
    end

    return nil;
end

function Factory:SetGlobalDB(global)
    self.db.global = global;
end

function Factory:SetCharacterDB(char)
    self.db.char = char;
end

function Factory:_setCommonOptions(options, element)
    element:On("Resize", function(delta)
        self:SetHeight(self:GetRealHeight() + delta);
    end);

    if options.margin ~= nil then
        element:SetMargin(options.margin);
    end

    if options.backgroundColor ~= nil then
        element:SetBackgroundColor(options.backgroundColor);
    end
end

function Factory:_setInputOptions(options, element)
    self:_setCommonOptions(options, element);

    element:On("Change", function(value)
        self:Fire("Change", {
            global = options.global,
            char = options.char,
            value = value
        });
    end);

    if options.label ~= nil then
        element:SetLabel(options.label);
    end

    if options.desc ~= nil then
        element:SetDesc(options.desc);
    end

    if options.disabled ~= nil then
        element:SetDisabled(options.disabled);
    end

    if options.tooltipEnabled ~= nil then
        element:SetTooltipEnabled(options.tooltipEnabled);
    end

    if options.value ~= nil then
        element:SetValue(options.value);
    elseif options.char ~= nil then
        element:SetValue(self:GetValueFromDB("char", options.char));
    elseif options.global ~= nil then
        element:SetValue(self:GetValueFromDB("global", options.global));
    end
end
