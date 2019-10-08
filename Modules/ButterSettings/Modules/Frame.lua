local CreateClass = LibStub("Poncho-1.0");

local Group = ButterGUIGroup;
ButterSettingsFrame = CreateClass("Frame", "ButterSettingsFrame", nil, nil, Group);
local Frame = ButterSettingsFrame;

function Frame:OnAcquire()
    Group.OnAcquire(self);

    self:Hide();

    self.okay = function()
        self:Fire("Okay");
    end

    self.cancel = function()
        self:Fire("Cancel");
    end

    self.default = function()
        self:Fire("Default");
    end

    self:On("Change", function(update)
        if update.global then
            self.db.global[update.global] = update.value;
        end

        if update.char then
            self.db.char[update.char] = update.value;
        end

        self:Render();
    end);
end

function Frame:UpdateSettings(settings)
    if settings.name ~= nil then
        self.name = settings.name;
    end
end

function Frame:Toggle()
    if self:IsVisible() then
        InterfaceOptionsFrame:Hide();
        self:Hide();
    else
        InterfaceOptionsFrame:Show();
        InterfaceOptionsFrame_OpenToCategory(self.name);
        self:Show();
    end
end

