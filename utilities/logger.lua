local _, ns = ...

local Log = {}
function Log.Debug(type, ...)
	if ButterQuestTrackerConfig.DeveloperMode then
		print(ns.CONSTANTS.LOGGER.PREFIX .. ns.CONSTANTS.LOGGER.COLORS[type], ...)
	end
end

function Log.Error(...)
    Log.Debug("ERROR", ...)
end

function Log.Warn(...)
    Log.Debug("WARN", ...)
end

function Log.Info(...)
    Log.Debug("INFO", ...)
end

ns.Log = Log