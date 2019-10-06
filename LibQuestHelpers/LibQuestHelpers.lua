local ZH = LibStub("ZoneHelper-1.0");
local QLH = LibStub("QuestLogHelper-1.0");
local QWH = LibStub("QuestWatchHelper-1.0");
local HBD = LibStub("HereBeDragons-2.0");
local helper = LibStub:NewLibrary("LibQuestHelpers-1.0", 1);
local isWoWClassic = select(4, GetBuildInfo()) < 20000;

local timers = {};
local function debounce(name, func)
    if timers[name] then
        timers[name]:Cancel();
    end

    timers[name] = C_Timer.NewTimer(0.1, func);
end

local function refresh()
    debounce("refresh", function()
        if Questie then
            QuestieQuest:UpdateHiddenNotes();
        end
    end);
end

local function getWorldPlayerPosition()
    local uiMapID = C_Map.GetBestMapForUnit("player");
    local mapPosition = C_Map.GetPlayerMapPosition(uiMapID, "player");
    local _, worldPosition = C_Map.GetWorldPosFromMapPos(uiMapID, mapPosition);

    return worldPosition;
end

local function getDistance(x1, y1, x2, y2)
	return math.sqrt( (x2-x1)^2 + (y2-y1)^2 );
end

local zoneCache = {};
local function zoneNameToUIMapID(zone)
    if not zoneCache[zone] then
        local index = 1;
        local mapIDs = HBD:GetAllMapIDs();

        while not zoneCache[zone] and index <= table.getn(mapIDs) do
            local mapID = mapIDs[index];

            if HBD:GetLocalizedMap(mapID) == zone then
                zoneCache[zone] = mapID;
            end

            index = index + 1;
        end
    end

    return zoneCache[zone];
end

function helper:GetAddons()
    return {
        ["Built-In"] = not isWoWClassic,
        ClassicCodex = CodexQuest,
        Questie = Questie
    };
end

function helper:GetAddonNames()
    local names = {};

    for name in pairs(self:GetAddons()) do
        tinsert(names, name);
    end

    return names;
end

function helper:GetActiveAddons()
    local activeAddons = {};

    for name, active in pairs(self:GetAddons()) do
        if active then
            tinsert(activeAddons, name);
        end
    end

    return activeAddons;
end

function helper:IsSupported()
    return table.getn(self:GetActiveAddons()) > 0;
end

local function OnQuestWatchUpdated(quests)
    for _, quest in pairs(quests) do
        helper:SetIconsVisibility({
            index = quest.index,
            questID = quest.questID,
            visible = quest.watched
        });
    end
end

function helper:SetAutoHideQuestHelperIcons(autoHideIcons)
    self.autoHideIcons = autoHideIcons;

    if self.autoHideIcons then
        QWH:OnQuestWatchUpdated(OnQuestWatchUpdated);
        for questID, quest in pairs(QLH:GetQuests()) do
            self:SetIconsVisibility({
                index = quest.index,
                questID = questID,
                visible = IsQuestWatched(quest.index)
            });
        end
    else
        QWH:OffQuestWatchUpdated(OnQuestWatchUpdated);
        for questID, quest in pairs(QLH:GetQuests()) do
            self:SetIconsVisibility({
                index = quest.index,
                questID = questID,
                visible = true
            });
        end
    end
end

function helper:SetIconsVisibility(updatedQuest)
    if CodexQuest then
        if updatedQuest.visible then
            CodexQuest.updateQuestLog = true
            CodexQuest.updateQuestGivers = true
        else
            QLH:Select(updatedQuest.index);
            CodexQuest:HideCurrentQuest();
            QLH:RevertSelection();
        end
    end


    if Questie then
        local quest = QuestieDB:GetQuest(updatedQuest.questID);

        quest.HideIcons = not updatedQuest.visible;
    end

    if not isWoWClassic then
        -- TODO: Not sure if this is even supported
    end

    refresh();
end

function helper:GetDestinationCoordinates(questID, overrideAddon)
    local addons = self:GetAddons();

    local coordinates = {};
    if addons.ClassicCodex and (not overrideAddon or overrideAddon == "ClassicCodex") then
        local quest = QLH:GetQuest(questID);

        -- TODO: Find a way to avoid needing the quest object from the log...
        if not quest then return end

        local maps = CodexDatabase:SearchQuestById(questID, {
            questLogId = quest.index
        });

        for zone in pairs(maps) do
            for _, quests in pairs(CodexMap.nodes["CODEX"][zone]) do
                local node = quests[quest.title];
                if node then
                    -- TODO: Is there a better way to check if this is a completed node.. ?
                    local completionNode = node.texture and (string.find(node.texture, "available") or string.find(node.texture, "complete"));
                    if quest.completed and completionNode or not quest.completed and not completionNode then
                        local _, worldPosition = C_Map.GetWorldPosFromMapPos(ZH:GetUIMapID(zone), {
                            x = node.x / 100,
                            y = node.y / 100
                        });

                        tinsert(coordinates, {
                            x = worldPosition.x,
                            y = worldPosition.y
                        });
                    end
                end
            end
        end
    elseif addons.Questie and (not overrideAddon or overrideAddon == "Questie") then
        local quest = QuestieDB:GetQuest(questID);

        if not quest then return end;

        if QuestieQuest:IsComplete(quest) then
            local finisher;
            if quest.Finisher.Type == "monster" then
                finisher = QuestieDB:GetNPC(quest.Finisher.Id)
            elseif quest.Finisher.Type == "object" then
                finisher = QuestieDB:GetObject(quest.Finisher.Id)
            end

            if not finisher then return end;

            for zoneID, spawns in pairs(finisher.spawns) do
                for _, coords in pairs(spawns) do
                    local uiMapID = ZH:GetUIMapID(zoneID);

                    if uiMapID then
                        local _, worldPosition = C_Map.GetWorldPosFromMapPos(uiMapID, {
                            x = coords[1] / 100,
                            y = coords[2] / 100
                        });

                        tinsert(coordinates, {
                            x = worldPosition.x,
                            y = worldPosition.y
                        });
                    end
                end
            end
        elseif quest.Objectives then
            for _, objective in pairs(quest.Objectives) do
                for _, v in pairs(objective.AlreadySpawned) do
                    for _, mapRef in pairs(v.mapRefs) do
                        local _, worldPosition = C_Map.GetWorldPosFromMapPos(mapRef.data.UiMapID, {
                            x = mapRef.x / 100,
                            y = mapRef.y / 100
                        });

                        tinsert(coordinates, {
                            x = worldPosition.x,
                            y = worldPosition.y
                        });
                    end
                end
            end
        end
    elseif addons["Built-In"] and (not overrideAddon or overrideAddon == "Built-In") then
        local uiMapID = C_Map.GetBestMapForUnit("player");

        -- TODO: This function will only return POIs for the current map. :(
        -- Is there any way to workaround this limitation.. ?
        local pois = C_QuestLog.GetQuestsOnMap(uiMapID);

        for _, poi in pairs(pois) do
            if poi.questID == questID then
                local _, worldPosition = C_Map.GetWorldPosFromMapPos(uiMapID, {
                    x = poi.x,
                    y = poi.y
                });

                tinsert(coordinates, {
                    x = worldPosition.x,
                    y = worldPosition.y
                });
            end
        end
    end

    return coordinates;
end

function helper:GetDistanceToClosestObjective(questID, overrideAddon)
    local player = getWorldPlayerPosition();
    local coords = self:GetDestinationCoordinates(questID, overrideAddon);

    -- TODO: Find a way to avoid needing the quest object from the log...
    if not coords then return end

    local closestDistance;
    for _, coordinates in pairs(coords) do
        local distance = getDistance(player.x, player.y, coordinates.x, coordinates.y);
        if closestDistance == nil or distance < closestDistance then
            closestDistance = distance;
        end
    end

    return closestDistance;
end
