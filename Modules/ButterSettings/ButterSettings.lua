

local helper = LibStub:NewLibrary("ButterSettings-1.0", 1);

function helper:New(settings)
    local frame = ButterSettingsFrame();

    frame:UpdateSettings(settings);
    InterfaceOptions_AddCategory(frame);

    return frame;
end
