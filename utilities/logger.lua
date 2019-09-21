local _, ns = ...

local Log = {}
function Log.Debug(type, ...)
	if ButterQuestTrackerConfig.DeveloperMode and ButterQuestTrackerConfig.DebugLevel >= type.LEVEL then
		print(ns.CONSTANTS.LOGGER.PREFIX .. type.COLOR, ...)
	end
end

function Log.Error(...)
    Log.Debug(ns.CONSTANTS.LOGGER.TYPES.ERROR, ...)
end

function Log.Warn(...)
    Log.Debug(ns.CONSTANTS.LOGGER.TYPES.WARN, ...)
end

function Log.Info(...)
    Log.Debug(ns.CONSTANTS.LOGGER.TYPES.INFO, ...)
end

function Log.Trace(...)
    Log.Debug(ns.CONSTANTS.LOGGER.TYPES.TRACE, ...)
end

ns.Log = Log