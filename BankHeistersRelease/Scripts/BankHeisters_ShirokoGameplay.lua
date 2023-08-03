local GAME_SPEED = GameConfiguration.GetGameSpeedType()
local GAME_SPEED_MULTIPLIER = GameInfo.GameSpeeds[GAME_SPEED] and GameInfo.GameSpeeds[GAME_SPEED].CostMultiplier / 100 or 1
local SHIROKO_PILLAGE_GOLD_BASE_VALUE = 15
local GAME_COST_ESCALATION = GameInfo.GlobalParameters["GAME_COST_ESCALATION"].Value or 1000

function OnPillage(iUnitPlayerID :number, iUnitID :number, eImprovement :number, eBuilding :number, eDistrict :number, iPlotIndex :number)

	if(iUnitPlayerID == NO_PLAYER) then
		return;
	end

	local pUnitPlayer :object = Players[iUnitPlayerID];
	if(pUnitPlayer == nil) then
		print("ERROR: pUnitPlayer missing");
		return;
	end

	local pUnit :object = UnitManager.GetUnit(iUnitPlayerID, iUnitID);
	if (pUnit == nil) then
		print("ERROR: pillaging unit missing");
		return;
	end

	if HasTrait("TRAIT_LEADER_BANK_JOB",iUnitPlayerID) then
		local techProgress = GetTechProgress(pUnitPlayer)
		local civicProgress = GetCivicProgress(pUnitPlayer)
		local costEscalation = (GAME_COST_ESCALATION / 100) -1
		local pillageMultiplier = (1 + costEscalation * math.floor( math.max(techProgress, civicProgress) * 100 ) / 100) * GAME_SPEED_MULTIPLIER
		local pillageAmount = math.floor(SHIROKO_PILLAGE_GOLD_BASE_VALUE * pillageMultiplier)
	
		local pPlot = Map.GetPlotByIndex(iPlotIndex)
		local eOwner = pPlot:GetOwner();

		Players[eOwner]:GetTreasury():ChangeGoldBalance(-pillageAmount);
		pUnitPlayer:GetTreasury():ChangeGoldBalance(pillageAmount);
		local goldMessage = Locale.Lookup("LOC_KILL_GOLD", pillageAmount);
		Game.AddWorldViewText(0, goldMessage, pUnit:GetX(), pUnit:GetY());

		local plunderType = "NO_PLUNDER" -- reset it on every pillage to avoid issues.

		if eDistrict >= 0 then -- when not pillaging a district, the param will be -1.
			plunderType = GameInfo.Districts[eDistrict].PlunderType;
		end

		if eBuilding >= 0 then -- when not pillaging a building, the param will be -1.
			buildingPrereqDistrict = GameInfo.Buildings[eBuilding].PrereqDistrict
			plunderType = GameInfo.Districts[buildingPrereqDistrict].PlunderType
		end

		if( plunderType == "PLUNDER_GOLD") then
			pUnitPlayer:GetCulture():ChangeCurrentCulturalProgress(pillageAmount)
			local message = Locale.Lookup("LOC_KILL_CULTURE", pillageAmount);
			Game.AddWorldViewText(0, message, pUnit:GetX(), pUnit:GetY());
		end
	end
end

GameEvents.OnPillage.Add(OnPillage);


-- Helper functions

function HasTrait( traitName:string, playerId:number )
	if playerId == nil then playerId = Game.GetLocalPlayer(); end
	if playerId == -1 then return false; end	-- Autoplay.
	
	local config :table = PlayerConfigurations[playerId];
	if(config ~= nil) then
		local leaderType:string = config:GetLeaderTypeName();
		local civType	:string = config:GetCivilizationTypeName();
		if leaderType then
			for row in GameInfo.LeaderTraits() do
				if row.LeaderType==leaderType and row.TraitType == traitName then
					return true;
				end
			end
		end
		if civType then
			for row in GameInfo.CivilizationTraits() do
				if row.CivilizationType== civType then
					if row.TraitType == traitName then
						return true;
					end
				end
			end
		end
	end
	return false;
end

function GetTechProgress(pUnitPlayer)
	local pUnitPlayerTechs = pUnitPlayer:GetTechs()
	local i, total = 0, 0
	for row in GameInfo.Technologies() do
		if pUnitPlayerTechs:HasTech(row.Index) then
			i = i + 1
		end
		total = total + 1
	end
	return total ~= 0 and i / total or 0
end

function GetCivicProgress(pUnitPlayer)
	local pUnitPlayerCulture = pUnitPlayer:GetCulture()
	local i, total = 0, 0
	for row in GameInfo.Civics() do
		if pUnitPlayerCulture:HasCivic(row.Index) then
			i = i + 1
		end
		total = total + 1
	end
	return total ~= 0 and i / total or 0
end