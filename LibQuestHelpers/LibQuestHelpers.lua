local ZH = LibStub("ZoneHelper-1.0");
local QLH = LibStub("QuestLogHelper-1.0");
local QWH = LibStub("QuestWatchHelper-1.0");
local helper = LibStub:NewLibrary("LibQuestHelpers-1.0", 1);

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

function helper:IsSupported()
    return (Questie or CodexQuest) and true;
end

local function OnQuestWatchUpdated(quests)
    for index, quest in pairs(quests) do
        local questID = QLH:GetQuestIDFromIndex(index);
        helper:SetIconsVisibility(questID, quest.watched);
    end
end

function helper:SetAutoHideQuestHelperIcons(autoHideIcons)
    self.autoHideIcons = autoHideIcons;

    if self.autoHideIcons then
        QWH:OnQuestWatchUpdated(OnQuestWatchUpdated);
        for questID, quest in pairs(QLH:GetQuests()) do
            self:SetIconsVisibility(questID, IsQuestWatched(quest.index));
        end
    else
        QWH:OffQuestWatchUpdated(OnQuestWatchUpdated);
        for questID in pairs(QLH:GetQuests()) do
            self:SetIconsVisibility(questID, true);
        end
    end
end

function helper:SetIconsVisibility(questID, visible)
    if CodexQuest then
        if visible then
            CodexQuest.updateQuestLog = true
            CodexQuest.updateQuestGivers = true
        else
            local index = QLH:GetIndexFromQuestID(questID);
            QLH:Select(index);
            CodexQuest:HideCurrentQuest();
            QLH:RevertSelection();
        end
    elseif Questie then
        local quest = QuestieDB:GetQuest(questID);

        quest.HideIcons = not visible;
    end

    refresh();
end

function helper:GetDestinationCoordinates(questID)
    local coordinates = {};
    if CodexQuest then
        local quest = QLH:GetQuest(questID);
        local maps = CodexDatabase:SearchQuestById(questID, {
            questLogId = quest.index
        });

        for zone in pairs(maps) do
            for _, quests in pairs(CodexMap.nodes["CODEX"][zone]) do
                local node = quests[quest.title];
                if node then
                    -- TODO: Is there a better way to check if this is a completed node.. ?
                    local completionNode = node.texture and (string.find(node.texture, "available") or string.find(node.texture, "complete"));
                    if quest.isComplete and completionNode or not quest.isComplete and not completionNode then
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
    elseif Questie then
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
    end

    return coordinates;
end

function helper:GetDistanceToClosestObjective(questID)
    local player = getWorldPlayerPosition();
    local coords = self:GetDestinationCoordinates(questID);

    local closestDistance;
    for _, coordinates in pairs(coords) do
        local distance = getDistance(player.x, player.y, coordinates.x, coordinates.y);
        if closestDistance == nil or distance < closestDistance then
            closestDistance = distance;
        end
    end

    return closestDistance;
end
