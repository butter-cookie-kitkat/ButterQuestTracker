local _, ns = ...

local Log = {}
function Log.Debug(type, bypass, ...)
	if bypass or (ButterQuestTrackerConfig.DeveloperMode and ButterQuestTrackerConfig.DebugLevel >= type.LEVEL) then
		print(ns.CONSTANTS.LOGGER.PREFIX .. type.COLOR, ...);
	end
end

function Log.Error(...)
    Log.Debug(ns.CONSTANTS.LOGGER.TYPES.ERROR, true, ...);
end

function Log.Warn(...)
    Log.Debug(ns.CONSTANTS.LOGGER.TYPES.WARN, false, ...);
end

function Log.Info(...)
    Log.Debug(ns.CONSTANTS.LOGGER.TYPES.INFO, false, ...);
end

function Log.Trace(...)
    Log.Debug(ns.CONSTANTS.LOGGER.TYPES.TRACE, false, ...);
end

ns.Log = Log