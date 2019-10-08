local CreateClass = LibStub("Poncho-1.0");

local BaseFactoryElement = ButterGUIBaseFactoryElement;
ButterGUIGroup = CreateClass("Frame", "ButterGUIGroup", nil, nil, BaseFactoryElement);
local Group = ButterGUIGroup;

function Group:SetOrientation(orientation)
    self.orientation = orientation;
end

function Group:Order()
    local keys = {};
    for i, element in pairs(self.elements) do keys[#keys + 1] = i end
    table.sort(keys, function(a, b)
        local order = self.elements[a]:GetOrder();
        local otherOrder = self.elements[b]:GetOrder();

        if order == otherOrder then return false;
        elseif order == nil and otherOrder ~= nil then return true;
        elseif otherOrder == nil and order ~= nil then return false;
        else return order > otherOrder end
    end);

    local previousElement = nil;
    for _, key in pairs(keys) do
        local element = self.elements[key];

        local top = -element.margin.top;
        local left = element.margin.left;
        local right = -element.margin.right;

        element:ClearAllPoints();
        if previousElement then
            print(previousElement:GetName());
            element:SetPoint("TOP", previousElement, "BOTTOM", 0, top - previousElement.margin.bottom);
            element:SetPoint("LEFT", previousElement, left, 0);
        else
            print(element:GetName());
            element:SetPoint("TOP", self, 0, top);
            element:SetPoint("LEFT", self, left, 0);
        end

        previousElement = element;
    end
end
