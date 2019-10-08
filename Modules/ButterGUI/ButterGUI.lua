

local helper = LibStub:NewLibrary("ButterGUI-1.0", 1);

function helper:New(options)
    local frame = ButterGUIFrame();

    frame:UpdateSettings(options);

    return frame;
end
