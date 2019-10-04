local CreateClass = LibStub("Poncho-1.0");

TrackerHelperBase = CreateClass("Frame", "TrackerHelperBase");
local Base = TrackerHelperBase;

function Base:_distance(x1, y1, x2, y2)
	return math.sqrt( (x2-x1)^2 + (y2-y1)^2 );
end

function Base:_count(t)
    local _count = 0;
    if t then
        for _, _ in pairs(t) do _count = _count + 1 end
    end
    return _count;
end

function Base:_hex2rgb(hex)
    hex = hex:gsub("#","")
    if #hex == 8 then
        return {
            r = tonumber("0x" .. hex:sub(3,4)) / 255,
            g = tonumber("0x" .. hex:sub(5,6)) / 255,
            b = tonumber("0x" .. hex:sub(7,8)) / 255,
            a = tonumber("0x" .. hex:sub(1,2)) / 255
        };
    end

    return {
        r = tonumber("0x" .. hex:sub(1,2)) / 255,
        g = tonumber("0x" .. hex:sub(3,4)) / 255,
        b = tonumber("0x" .. hex:sub(5,6)) / 255,
        a = 1.0
    };
end

function Base:_normalizeColor(value)
    if type(value) == "string" then
        value = self:_hex2rgb(value);
    elseif type(value) == "table" then
        value.r = value.r or 0.0;
        value.g = value.g or 0.0;
        value.b = value.b or 0.0;
        value.a = value.a or 1.0;
    end

    return value;
end
