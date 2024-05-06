Interactivity = class()

function Interactivity:init(gameModel, commitButtonParams, resignButtonParams)
    self.gameModel = gameModel
    -- Set up the commit button sensor
    self.commitButtonSensor = Sensor{
        parent = commitButtonParams,
        xywhMode = CORNER  -- Assuming you are using CORNER mode for drawing
    }
    self.commitButtonSensor:onTap(function(event)
        self.gameModel.selectedUnit = nil
        self.gameModel:moveToNextPhase()
    end)
    -- Setup the resign button sensor
    self.resignButton = Sensor{parent = resignButtonParams, xywhMode = CORNER}
    self.resignButton:onTap(function(event)
        print("resigned")
        -- Determine which player pressed the resign button based on who's turn it is
        if gameModel.turnManager:isPlayerTurn(Player.player1) then
            print("Player 1 resigned. Point to Player 2.")
            gameModel:gameWon(Player.player2)
        else
            gameModel:gameWon(Player.player1)
            print("Player 2 resigned. Point to Player 1.")
        end
    end)
    self.screenSensor = Sensor{parent = {x=0,y=0,w=WIDTH,h=HEIGHT}}
    self.screenSensor:onTap( function(event) 
        if gameModel.selectedUnit then
            gameModel.selectedUnit.target = nil
            gameModel.selectedUnit = nil
        end
    end )
    self:setUnitSensors(gameModel.units)
    self:setPlayAreaSensor(gameModel.playArea)
    self:setGameOverSensor()
end

function Interactivity:setGameOverSensor()
    self.gameOverSensor = Sensor{parent = {x=0, y=0, w=WIDTH, h=HEIGHT}}
    self.gameOverSensor:onTap(function(event)
        if self.gameModel.isGameOver then
            print("Game over screen tapped")
            setup()
        end
    end)
end

function Interactivity:setUnitSensors(units)
    self.unitSensors = {}
    for i, unit in ipairs(gameModel.units) do
        local sensor = Sensor{parent = unit, xywhMode = CENTER}
        sensor:onTap(function(event)
            self:unitTapHandler(unit)
        end)
        table.insert(self.unitSensors, sensor)
    end
end

function Interactivity:setPlayAreaSensor(playArea)
    -- Set up the sensor with the play area's lower-left corner as the origin
    self.playAreaSensor = Sensor{parent={x=playArea.x - playArea.width / 2, y=playArea.y - playArea.height / 2, w=playArea.width, h=playArea.height}}
    self.playAreaSensor:onTap(function(event)
        -- Only react to taps if in one of the ready phases
        if gameModel.turnManager.currentPhase == Phase.READY1 or gameModel.turnManager.currentPhase == Phase.READY2 then
            gameModel.turnManager:nextPhase()
        end
    end)
end

function Interactivity:unitTapHandler(unit)
    print("tapped unit")
    if not unit.alive then return end
    local isUnitsTurn = self.gameModel.turnManager:isPlayerTurn(unit.owner)
    local selectedAssigned = self.gameModel.selectedUnit ~= nil
    local unitOwner = unit.owner
    local selectedOwner = selectedAssigned and self.gameModel.selectedUnit.owner or "n/a"
    local unitOwnerNotSelectedOwner = unitOwner ~= selectedOwner
    print ("isUnitsTurn: ", isUnitsTurn,
    "selectedAssigned: ", selectedAssigned,
    "unitOwner: ", unitOwner,
    "selectedOwner: ", selectedOwner,
    "unitOwnerNotSelectedOwner: ", unitOwnerNotSelectedOwner)
    if isUnitsTurn == false and selectedAssigned then
        if self.gameModel.selectedUnit.target == unit then
            self.gameModel.selectedUnit.target = nil
        else
            self.gameModel.selectedUnit.target = unit  -- Set target if the tapped unit is an enemy 
        end
    elseif isUnitsTurn then
        if gameModel.selectedUnit == unit then
            unit.target = nil
        else
            self.gameModel:selectUnit(unit)  -- Set the unit as selected if it's the unit's turn
        end
    else
        flashScreen = true  -- Trigger the flash
        flashDuration = 0.15  -- Set the duration of the flash
    end
end

function Interactivity:unitTapHandler(unit)
    print("tapped unit")
    if not unit.alive then return end
    local selectedUnit = self.gameModel.selectedUnit
    
    -- Deselect if the same unit is tapped again
    if selectedUnit == unit then
        selectedUnit.target = nil
        self.gameModel.selectedUnit = nil
        return
    end
    
    -- If there is a selected unit, set or change the target
    if selectedUnit then
        selectedUnit.target = unit
    else
        -- No unit is selected
        if self.gameModel.turnManager:isPlayerTurn(unit.owner) then
            -- Select the unit if it belongs to the current player
            self.gameModel:selectUnit(unit)
        else
            -- Flash the screen if the unit belongs to the opponent and no unit is selected
            flashScreen = true
            flashDuration = 0.15
        end
    end
end

function Interactivity:update(t)
    if self.gameModel.isGameOver then
        if self.gameOverSensor:touched(t) then return true end
        return
    end
    local isReadyPhase = self.gameModel.turnManager.currentPhase == Phase.READY1 or self.gameModel.turnManager.currentPhase == Phase.READY2
    local isResolving = self.gameModel.turnManager.currentPhase == Phase.RESOLVING_COMBAT
    if isReadyPhase then
        if self.playAreaSensor:touched(t) then return true end
    end
    for _, sensor in ipairs(self.unitSensors) do
        if sensor:touched(t) then return true end
    end
    if (not isResolving) then
        if self.commitButtonSensor:touched(t) then
            return true
        elseif self.resignButton:touched(t) then
            return true
        end     
    end
    self.screenSensor:touched(t)
end

function Interactivity:debug()
    -- Use whatever drawing methods are appropriate for your framework (assuming Codea)
    -- The following example uses Codea's drawing functions
    pushStyle()  -- Save current drawing style
    noFill()  -- No fill for the rectangles
    stroke(0, 255, 117)  -- Cyan color for the debug rectangles
    strokeWidth(3)  -- Set the stroke width to 1 pixel
    
    -- Draw debug outlines for each unit sensor
    for _, sensor in ipairs(self.unitSensors) do
        local x, y, w, h = sensor:xywh()  -- Assuming the sensor's parent (the unit) has an xywh method
        rect(x, y, w, h)
    end
    
    -- Draw debug outline for the commit button
    local x, y, w, h = self.commitButtonSensor:xywh()
    stroke(255, 69, 0)  -- Red color for the commit button
    rect(x, y, w, h)
    
    -- Draw debug outline for the resign button
    x, y, w, h = self.resignButton:xywh()
    stroke(255, 165, 0)  -- Orange color for the resign button
    rect(x, y, w, h)
    
    popStyle()  -- Restore previous drawing style
end
