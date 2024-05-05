-- Define the Player enumeration
Player = {
    player1 = 1,
    player2 = 2
}

-- Helper function to check if table contains a value
function tableContains(table, element)
    for _, value in pairs(table) do
        if value == element then
            return true
        end
    end
    return false
end

-- Define the Unit class
Unit = class()

function Unit:init(id, position, strength, diameter, color, owner)
    self.id = id
    self.x = position.x
    self.y = position.y
    self.w = diameter
    self.h = diameter
    self.position = position
    self.strength = strength
    self.maxStrength = strength  -- Initialize maxStrength at the same level as strength
    self.diameter = diameter
    self.color = color
    self.owner = owner
    self.target = nil
    self.strengthRevealed = false
    self.visualOffset = vec2(0, 0)  -- Visual offset for animations
    self.alive = true
end

function Unit:duplicate()
    local newUnit = Unit(
    self.id,
    vec2(self.position.x, self.position.y),  -- Copy the position
    self.strength,  -- Copy the current strength
    self.diameter,  -- Copy the diameter
    self.color,  -- Copy the color
    self.owner  -- Copy the owner
    )
    
    -- Additional properties to copy
    newUnit.maxStrength = self.maxStrength
    newUnit.strengthRevealed = self.strengthRevealed
    newUnit.visualOffset = vec2(self.visualOffset.x, self.visualOffset.y)
    newUnit.alive = self.alive
    
    return newUnit
end

function Unit:overlapsWith(other)
    local dx = other.position.x - self.position.x
    local dy = other.position.y - self.position.y
    local distance = math.sqrt(dx * dx + dy * dy)
    return distance < (self.diameter + other.diameter) / 2  -- Check if circles overlap
end

function Unit:performAttack()
    -- Determine if the attack does zero damage
    local attackValue = 0
    local doZeroDamage = math.random(1, self.maxStrength + 1) == 1
    if not doZeroDamage then
        if self.strength == 1 then
            attackValue = 1
        else
            print(self.strength)
            attackValue = math.random(1, self.strength)
        end
    end
    
    self.target.strength = self.target.strength - attackValue
    local result = {
        attackerId = self.id,
        defenderId = self.target.id,
        attackerColor = self.color,
        defenderColor = self.target.color,
        attackerPosition = self.position,
        defenderPosition = self.target.position,
        attackerStrength = self.strength,
        defenderStartingStrength = self.target.strength + attackValue,
        defenderEndingStrength = self.target.strength
    }
    self.strengthRevealed = true
    self.target.strengthRevealed = true
    return result
end


function Unit:performAttack()
    -- Calculate the potential damage based on attacker's strength minus defender's strength
    local potentialDamage = self.strength - self.target.strength
    
    -- Ensure damage is at least 1 if the potential damage is non-positive
    local actualDamage = math.max(1, potentialDamage)
    
    -- Apply the damage to the target
    self.target.strength = self.target.strength - actualDamage
    
    -- Construct the result with updated values
    local result = {
        attackerId = self.id,
        defenderId = self.target.id,
        attackerColor = self.color,
        defenderColor = self.target.color,
        attackerPosition = self.position,
        defenderPosition = self.target.position,
        attackerStrength = self.strength,
        defenderStartingStrength = self.target.strength + actualDamage,
        defenderEndingStrength = self.target.strength
    }
    
    -- Set strengths as revealed for both units
    self.strengthRevealed = true
    self.target.strengthRevealed = true
    
    return result
end

-- Define the GameModel class
GameModel = class()

function GameModel:init(playArea)
    self.playArea = playArea
    self.units = {}
    self.turnsCompleted = { [Player.player1] = false, [Player.player2] = false }
    self.turnsHistory = {}  -- Stores all the turns
    self.currentTurnRecord = {}  -- Stores the current turn's attacks
    self.turnManager = TurnManager() -- Assuming TurnManager is a class you've defined
    self.selectedUnit = nil
    self.isGameOver = false
    self.winner = nil
    self.scores = scores
    self:setupGame()
end

function GameModel:setupGame()
    -- Initialize all units at once
    self.units = self:createUnits()
    self.currentTurnRecord = self:newTurnRecord()
end

function GameModel:newTurnRecord()
    local newRecord = {
        units = self:duplicateUnits(self.units)
    }
    self:addUnitMap(newRecord.units, newRecord.units)
    return newRecord
end

function GameModel:addUnitMap(aTable, units)
    aTable.unitMap = {}
    for _, unit in ipairs(units) do
        aTable.unitMap[unit.id] = unit
    end
end

function GameModel:checkGameOver()
    local player1Alive = false
    local player2Alive = false
    
    -- Check the status of each player's units
    for _, unit in ipairs(self.units) do
        if unit.alive and unit.owner == Player.player1 then
            player1Alive = true
        elseif unit.alive and unit.owner == Player.player2 then
            player2Alive = true
        end
    end
    
    -- Check game over conditions
    if not player1Alive then
        self:gameWon(Player.player2)
        return true
    elseif not player2Alive then
        self:gameWon(Player.player1)
        return true
    end
    
    return false
end

function GameModel:gameWon(winningPlayer)
    print("Game Over. Player " .. winningPlayer .. " wins!")
    self.isGameOver = true
    self.winner = winningPlayer
    -- Increment the score for the winning player
    if winningPlayer == Player.player1 then
        self.scores.player1 = self.scores.player1 + 1
    else
        self.scores.player2 = self.scores.player2 + 1
    end
end

function GameModel:swapInNewTurnRecord()
    local currentRecord = self.currentTurnRecord
    table.insert(self.turnsHistory, currentRecord)
    self.currentTurnRecord = self:newTurnRecord()
end

function GameModel:recordWin(winningPlayer)
    if winningPlayer == Player.player1 then
        self.scores.player1 = self.scores.player1 + 1
    elseif winningPlayer == Player.player2 then
        self.scores.player2 = self.scores.player2 + 1
    end
end

function GameModel:duplicateUnits(originalUnits)
    local unitsCopy = {}
    for i, unit in ipairs(originalUnits) do
        unitsCopy[i] = unit:duplicate()
    end
    self:addUnitMap(unitsCopy, unitsCopy)
    return unitsCopy
end

function GameModel:endTurn()
    self:swapInNewTurnRecord()  -- Reset for the next turn
    self.turnManager:nextPhase()  -- Advance the turn phase
end

function GameModel:selectUnit(unit)
    if self.turnManager:isPlayerTurn(unit.owner) then
        self.selectedUnit = unit
    end
end

function GameModel:ifPlayerIfOtherIfNone(player, ifPlayerTurn, ifOpponentTurn, neutralValue)
    local opponent = player == Player.player1 and Player.player2 or Player.player1
    if self.turnManager:isPlayerTurn(player) then
        return ifPlayerTurn
    elseif self.turnManager:isPlayerTurn(opponent) then
        return ifOpponentTurn
    else
        return neutralValue or nil
    end
end

function randomPointInsideRect(lowerLeftX, lowerLeftY, w, h)
    local x = lowerLeftX + (math.random() * w)
    local y = lowerLeftY + (math.random() * h)
    return x, y
end

-- Check if two rectangles overlap
function rectOverlapsRect(rect1, rect2)
    local x1_min = rect1.x
    local x1_max = rect1.x + rect1.w
    local y1_min = rect1.y
    local y1_max = rect1.y + rect1.h
    
    local x2_min = rect2.x
    local x2_max = rect2.x + rect2.w
    local y2_min = rect2.y
    local y2_max = rect2.y + rect2.h
    
    return x1_min < x2_max and x1_max > x2_min and y1_min < y2_max and y1_max > y2_min
end

function GameModel:resetGame()
    self.units = self:createUnits()
    self.selectedUnit = nil
    self.turnManager.currentPhase = Phase.PLAYER1
    self.currentTurnRecord = {}
end

function GameModel:createUnits()
    local units = {}
    local idCounter = 0
    local strengths = {4, 4, 5, 5, 6, 6, 6, 6, 7, 7, 7, 9}  -- Assuming both players have units with the same strength distribution
    local strengths = {3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 10, 10, 12, 20}  
    local strengths = {10, 10, 12, 12, 14}  
    local baseDiameter = math.min(self.playArea.width, self.playArea.height) / 15
    
    -- Create units for both players within a single unified loop
    for playerNum = 1, 2 do  -- Assuming two players: Player.player1 and Player.player2
        for i, strength in ipairs(strengths) do
            idCounter = idCounter + 1
            local unitDiameter = baseDiameter + (baseDiameter * 0.35 * math.random())
            local x, y
            local unit, unitRect
            
            -- Adjust the safe padding to consider the current unit diameter
            local safePadding = unitDiameter * 2
            local lowerLeftX = self.playArea.x - (self.playArea.width / 2) + safePadding
            local lowerLeftY = self.playArea.y - (self.playArea.height / 2) + safePadding
            local effectiveWidth = self.playArea.width - (safePadding * 1.5)
            local effectiveHeight = self.playArea.height - (safePadding * 1.5)

            repeat
                x, y = randomPointInsideRect(lowerLeftX, lowerLeftY, effectiveWidth, effectiveHeight)
                unitRect = {
                    x = x - unitDiameter / 2,
                    y = y - unitDiameter / 2,
                    w = unitDiameter,
                    h = unitDiameter
                }
            until not anyUnitOverlaps(unitRect, units)
            
            unit = Unit(
            idCounter,
            vec2(unitRect.x + unitDiameter / 2, unitRect.y + unitDiameter / 2),
            strength,
            unitDiameter,
            playerNum == 1 and color(0, 0, 255) or color(255, 0, 0),
            playerNum == 1 and Player.player1 or Player.player2
            )
            table.insert(units, unit)
        end
    end
    self:addUnitMap(units, units)
    return units
end

-- Helper function to check if the given rectangle overlaps with any existing unit rectangles
function anyUnitOverlaps(newRect, units)
    for _, unit in ipairs(units) do
        local existingRect = {
            x = unit.position.x - unit.diameter / 2,
            y = unit.position.y - unit.diameter / 2,
            w = unit.diameter,
            h = unit.diameter
        }
        if rectOverlapsRect(newRect, existingRect) then
            return true
        end
    end
    return false
end

function GameModel:assignAttack(attacker, target)
    attacker.target = target
    -- Optionally add logic to visually represent the attack
end

function GameModel:resolveCombats()
    print("resolving")
    -- Shuffle the units to randomize attack order
    local shuffledUnits = {}
    for i = 1, #self.units do
        table.insert(shuffledUnits, self.units[i])
    end
    for i = #shuffledUnits, 2, -1 do -- Fisher-Yates shuffle
        local j = math.random(i)
        shuffledUnits[i], shuffledUnits[j] = shuffledUnits[j], shuffledUnits[i]
    end
    
    -- Process attacks in randomized order
    for i, unit in ipairs(shuffledUnits) do
        if not (unit.strength <= 0) then
        if unit.target then
            local target = unit.target
            if tableContains(self.units, target) 
                    and target.strength > 0 then
                local result = unit:performAttack()
                table.insert(self.currentTurnRecord, result)
                if target.strength <= 0 then
                    for j = #self.units, 1, -1 do
                        if self.units[j] == target then
                            self.units[j].alive = false
                            break
                        end
                    end
                end
            end
            unit.target = nil
        end
        end
    end
end

function GameModel:moveToNextPhase()
    -- Advance to the next phase
    self.turnManager:nextPhase()   
    -- Check if it's time to resolve combat
    if self.turnManager.currentPhase == Phase.RESOLVING_COMBAT then
        self:resolveCombats()
        self:endTurn()
    end
end