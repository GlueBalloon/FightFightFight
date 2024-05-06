--Baba Dagas
--by UberGoober

scores = { player1 = 0, player2 = 0 }

function setup()
    rectMode(CENTER)
    -- Global variables
    gameModel = {}
    playArea = {}
    flashScreen = false
    flashDuration = 0
    -- Global or appropriate scope variables
    animationRunning = false
    currentTween = nil
    currentCombatAnimation = nil
    -- Determine the longest and shortest sides
    local shortestSide = math.min(WIDTH, HEIGHT)
    local longestSide = math.max(WIDTH, HEIGHT)
    
    -- Define the play area as 19/20 of the shortest side and 3/5 of the longest side
    local playAreaWidth = shortestSide * 19 / 20
    local playAreaHeight = longestSide * 2.5 / 5
    playArea = {
        x = (WIDTH - playAreaWidth) / 2,
        y = (HEIGHT - playAreaHeight) / 2,
        width = playAreaWidth,
        height = playAreaHeight
    }
    
    -- Calculate the position of the play area to center it
    playArea.x = (WIDTH - playAreaWidth) / 2 + playAreaWidth / 2
    playArea.y = (HEIGHT - playAreaHeight) / 2 + playAreaHeight / 2
    
    -- Initialize the game model
    gameModel = GameModel(playArea)
    
    for i, unit in ipairs(gameModel.units) do
        animateUnit(unit)
    end
    
    -- Define the commit button parameters relative to the playArea
    commitButtonParams = {
        x = playArea.x - playArea.width / 2,  -- Starting at the left edge of the play area
        y = playArea.y - playArea.height / 2 - 60,  -- Positioned below the play area with a 60 pixel offset
        w = playArea.width,  -- Same width as the play area
        h = 50,  -- A fixed height for the button
        text = "Commit"
    }
    
    -- Define the parameters for the resign button
    resignButtonParams = {
        x = playArea.x - playArea.width / 2,  -- Starting at the left edge of the play area
        y = playArea.y + playArea.height / 2 + 10,  -- Positioned below the play area with a 60 pixel offset
        w = playArea.width,  -- Same width as the play area
        h = 50,  -- A fixed height for the button
        text = "Resign"
    }
    
    interactivity = Interactivity(gameModel, commitButtonParams, resignButtonParams)
end

function draw()
    -- Clear the screen with a default background
    if flashScreen then
        background(224, 204, 182)  -- Red background flash
        flashDuration = flashDuration - DeltaTime
        if flashDuration <= 0 then
            flashScreen = false
        end
    elseif fullscreenFlashColor then
        pushStyle()
        rectMode(CORNER)
        noStroke()
        fill(fullscreenFlashColor)
        rect(0, 0, WIDTH, HEIGHT)  -- Assuming coordinates start at (0,0)
        popStyle()
        return
    else
        background(225, 234, 235)  -- Normal background
    end
    
        -- Regular drawing code for the game
    --[[
    if gameModel.isGameOver then
        pushStyle()
        rectMode(CORNER)
        fill(74, 63, 105)  -- Semi-transparent overlay
        rect(0, 0, WIDTH, HEIGHT)
        
        -- Display game over text
        fill(255)
        fontSize(48)
        font("Helvetica-Bold")
        local gameOverText = "Game Over! Winner: Player " .. (gameModel.winner == Player.player1 and "1" or "2")
        text(gameOverText, WIDTH / 2, HEIGHT / 2)
        
        fontSize(32)
        text("Tap anywhere to continue", WIDTH / 2, HEIGHT / 2 - 60)
        popStyle()
    end
    ]]
       
    local borderColor = gameModel:ifPlayerIfOtherIfNone(
    Player.player1,
    color(182, 184, 215),
        color(215, 183, 183),
        color(205, 213, 203)
    )
    local currentPlayer = gameModel.turnManager:isPlayerTurn(Player.player1)
    
    -- Draw the play area using roundedRectangle
    fill(243, 240, 242) -- Interior fill color
    stroke(borderColor) -- Border color
    strokeWidth(30) -- Border width
    roundedRectangle{
        x = playArea.x,
        y = playArea.y,
        w = playArea.width,
        h = playArea.height,
        radius = 11
    }
    
        
        -- Check if it's a ready phase and draw the appropriate message
    if gameModel.turnManager:isReadyPhase() then
        local playerText = gameModel.turnManager.currentPhase 
        == Phase.READY1 and "PLAYER 1" 
        or "PLAYER 2"
        
        -- Drawing the text message with a shadow for effect
        pushStyle()  -- Save current graphic style settings
        fontSize(50)  -- Set font size large for visibility
        font("Helvetica-Bold")  -- Bold font for emphasis
        textWrapWidth(playArea.width * 0.75)
        -- Draw shadow first
        fill(161, 72)  -- Semi-transparent black for shadow
        text("TAP FOR " .. playerText .. " TURN", WIDTH / 2 + 2, HEIGHT / 2 - 2)
        
        -- Draw main text
        fill(borderColor)  -- Gold color for the text
        text("TAP FOR " .. playerText .. " TURN", WIDTH / 2, HEIGHT / 2)
        
        popStyle()  -- Restore previous graphic style settings
        return
    end
    
    if animatingUnits then 
        drawUnits(animatingUnits)
    else
        drawUnits(gameModel.units)
    end
        
    -- Check if there is an ongoing combat animation
    if currentCombatAnimation then
        local anim = currentCombatAnimation
        pushStyle()

        --overlay a dimming effect
        fill(98, 132)
        rect(WIDTH/2, HEIGHT/2, WIDTH, HEIGHT)  -- Assuming coordinates start at (0,0)
          
        -- Draw attacking arrow
        if currentCombatAnimation.shouldDrawArrow then
            stroke(currentCombatAnimation.attackerColor) -- Red for target lines
            local fromX = currentCombatAnimation.attackerPos.x
            local fromY = currentCombatAnimation.attackerPos.y
            local toX = currentCombatAnimation.defenderPos.x
            local toY = currentCombatAnimation.defenderPos.y
            drawArrow(fromX, fromY, toX, toY)
        end
        
        -- Calculate the position for the text at the top 1/3 of the screen
        local textPositionY = HEIGHT * 2.35 / 3
        font("Helvetica-Bold")
        fontSize(39)
        -- Draw shadow for the text
        fill(0, 0, 0, 128)  -- Semi-transparent black for shadow
        text("COMBAT RESULTS", WIDTH / 2 - 2, textPositionY - 2)  -- Slightly offset for shadow effect
        -- Draw the main text
        fill(255, 255, 255)  -- White color for text
        text("COMBAT RESULTS", WIDTH / 2, textPositionY)
        
        -- Draw attacker strength
        fontSize(currentCombatAnimation.attackerFontSize)
        fill(255)  -- White for attacker
        text(tostring(currentCombatAnimation.attackerStrength),
        currentCombatAnimation.attackerPos.x + currentCombatAnimation.attackerAnimOffset.x,
        currentCombatAnimation.attackerPos.y + currentCombatAnimation.attackerAnimOffset.y)
        
        -- Draw defender strength
        fontSize(currentCombatAnimation.defenderFontSize)
        fill(255)  -- Slightly transparent for defender
        text(tostring(currentCombatAnimation.defenderStrength),
        currentCombatAnimation.defenderPos.x + currentCombatAnimation.defenderAnimOffset.x,
        currentCombatAnimation.defenderPos.y + currentCombatAnimation.defenderAnimOffset.y)
        popStyle()
    end
    
    -- Handle animation phases
    if gameModel.turnManager:isAnimationPhase() then
        if #gameModel.turnsHistory ~= 0 then
            if not animationRunning then
                -- Start a tween for 1.5 seconds, after which it calls a function to advance the phase
                animationRunning = true
                local lastAttacks = gameModel.turnsHistory[#gameModel.turnsHistory]
                startCombatAnimation(lastAttacks)
            end
            return
        else
            gameModel:moveToNextPhase()
        end
    end

    if gameModel.isGameOver then
        pushStyle()
        rectMode(CORNER)
        fill(74, 63, 105, 220)  -- Semi-transparent overlay with increased opacity for better readability
        rect(0, 0, WIDTH, HEIGHT)
        
        -- Prepare text components
        local gameOver = "GAME"
        local over = "OVER!"
        local winnerText = "P" .. (gameModel.winner == Player.player1 and "1" or "2") .. " WINS"
        
        -- Font settings for main message
        fontSize(50)
        font("Helvetica-Bold")
        textWrapWidth(WIDTH - 40)  -- Ensure text fits within screen width with padding
        textAlign(LEFT)
        
        -- Text positioning
        local textHeight = HEIGHT / 5 * 3.5  -- Base height for the first line
        local lineHeight = 60  -- Height adjustment for each subsequent line
        
        -- Render each line of text with a shadow for better visibility
        -- Shadow for "GAME"
        fill(200, 156, 201, 214)  -- Semi-transparent black for shadow
        text(gameOver, WIDTH / 2 + 2, textHeight - 2)
        
        -- Main text "GAME"
        fill(255)  -- White for main text
        text(gameOver, WIDTH / 2, textHeight)
        
        -- Shadow for "OVER!"
        fill(200, 156, 201, 214)  -- Semi-transparent black for shadow
        text(over, WIDTH / 2 + 2, textHeight - lineHeight - 2)
        
        -- Main text "OVER!"
        fill(255)  -- White for main text
        text(over, WIDTH / 2, textHeight - lineHeight)
        
        -- Shadow for "P1 WINS" or "P2 WINS"
        fill(200, 156, 201, 214)  -- Semi-transparent black for shadow
        text(winnerText, WIDTH / 2 + 2, textHeight - 2 * lineHeight - 2)
        
        -- Main text "P1 WINS" or "P2 WINS"
        fill(255)  -- White for main text
        text(winnerText, WIDTH / 2, textHeight - 2 * lineHeight)
        
        -- Adjustments for secondary message
        fontSize(32)
        local continueText = "TAP ANYWHERE TO CONTINUE"
        
        -- Shadow for secondary text
        fill(200, 156, 201, 214)  -- Semi-transparent black for shadow
        text(continueText, WIDTH / 2 + 2, HEIGHT / 5 * 2 - 2)
        
        -- Secondary text
        fill(255)  -- White for text
        text(continueText, WIDTH / 2, HEIGHT / 5 * 2)
        
        popStyle()
        
        drawScore()
        
        return
    end

    drawScore()
    
    -- Draw the commit button using roundedRectangle
    local btn = commitButtonParams
    local phase = interactivity.gameModel.turnManager.currentPhase
    local btnColor, textColor, btnText
    
    local btnColor = gameModel:ifPlayerIfOtherIfNone(
    Player.player1,
    color(0, 0, 255),
    color(255, 0, 0),
    color(127, 127, 127)
    )
    local textColor = gameModel:ifPlayerIfOtherIfNone(
    Player.player1,
    color(255),
    color(255),
    color(200, 200, 200)
    )
    local btnText = gameModel:ifPlayerIfOtherIfNone(
    Player.player1,
    "Commit",
    "Commit",
    "Brawling Commenced..."
    )
    
    -- Set colors and styles for roundedRectangle
    fill(btnColor)
    stroke(btnColor)  -- If you want a border, set a different stroke color
    strokeWidth(3)  -- Adjust stroke width as needed
    
    -- Draw the rounded rectangle for the commit button
    roundedRectangle{
        x = btn.x + btn.w / 2,  -- x-coordinate (center of the rectangle)
        y = btn.y + btn.h / 2,  -- y-coordinate (center of the rectangle)
        w = btn.w,  -- width of the rectangle
        h = btn.h,  -- height of the rectangle
        radius = 10  -- corner radius
    }
    
    -- Draw the text on the button
    fill(textColor)
    text(btnText, btn.x + btn.w / 2, btn.y + btn.h / 2)  -- Position the text at the center of the button
    
    -- Draw the resign button
    local btn = resignButtonParams
    fill(225, 201, 191) -- Reddish color for resign button
    stroke(224, 164, 141)
    strokeWidth(3)
    roundedRectangle{
        x = btn.x + btn.w / 2, 
        y = btn.y + btn.h / 2,
        w = btn.w,
        h = btn.h,
        radius = 10
    }
    fill(255) -- White text
    text(btn.text, btn.x + btn.w / 2, btn.y + btn.h / 2)
    
  --  interactivity:debug()
end

function drawScore()
    -- Score Display Styling and Positioning
    pushStyle()  -- Save current graphic style settings
    fontSize(35)  -- Set font size large for visibility
    font("Helvetica-Bold")  -- Bold font for emphasis
    textMode(LEFT)  -- Align text to the left
    
    -- Calculate positions
    local scoreYOffset = 80  -- Distance above the resign button
    local scoreYPosition = resignButtonParams.y + resignButtonParams.h / 2 + scoreYOffset
    local scoreYPosition = resignButtonParams.y + resignButtonParams.h / 2 + scoreYOffset
    local textXPosition = WIDTH /2 - playArea.width / 2 + 5 -- Align with the left edge of the play area

    
    -- Draw shadow first
    fill(161, 77)  -- Semi-transparent black for shadow
    text("P1 WINS: " .. scores.player1, textXPosition + 2, scoreYPosition - 2)  -- Shadow offset
    text("P2 WINS: " .. scores.player2, textXPosition + 2, scoreYPosition - 40 - 2)  -- Shadow offset for second line
    
    -- Draw main text
    fill(182, 184, 215)
    text("P1 WINS: " .. scores.player1, textXPosition, scoreYPosition)
    fill(215, 183, 183)
    text("P2 WINS: " .. scores.player2, textXPosition, scoreYPosition - 40)  -- Second line for second player scorey
    
    popStyle()  -- Restore previous graphic style settings
end

-- Assuming 'gameInteractivity' is an instance of Interactivity
function touched(t)
    interactivity:update(t)
end


-- Draw function, called every frame
function drawUnits(units)
    -- First Pass: Draw all shadows and selected-unit indicators
    for i, unit in ipairs(units) do
        if unit.alive then
            local x = unit.position.x + unit.visualOffset.x
            local y = unit.position.y + unit.visualOffset.y
            
            -- Draw the shadow (a gray duplicate of the unit)
            fill(209)  -- Gray color for the shadow
            noStroke()
            local shadowOffset = -3
            roundedRectangle{
                x = x + shadowOffset,
                y = y + shadowOffset,
                w = unit.diameter,
                h = unit.diameter,
                radius = unit.diameter / 4,
                corners = 15
            }
        end
    end
    
    -- Draw the selected--unit indicator
    if gameModel.selectedUnit then
        local unit = gameModel.selectedUnit
        fill(255, 0)  -- Semi-transparent gold color for highlight
        local x = unit.position.x + unit.visualOffset.x
        local y = unit.position.y + unit.visualOffset.y
        stroke(255, 169, 0)
        strokeWidth(17.9)
        local highlightSize = unit.diameter * 1.65  -- Highlight is slightly larger than the unit
        roundedRectangle{
            x = x,
            y = y,
            w = highlightSize,
            h = highlightSize,
            radius = highlightSize / 2,
        }
    end
    
    -- Second Pass: Draw all units
--[[
    for i, unit in ipairs(units) do
        if unit.alive then
            local x = unit.position.x + unit.visualOffset.x
            local y = unit.position.y + unit.visualOffset.y
          --  local playerColor = unit.owner == Player.player1 and color(0, 0, 255) or color(255, 0, 0)
            
            -- Draw the unit with its actual color
            fill(unit.color)
            stroke(184, 67, 236)  -- Lavender stroke color for units
            strokeWidth(0.75)  -- Stroke width for unit outline
            roundedRectangle{
                x = x,
                y = y,
                w = unit.diameter,
                h = unit.diameter,
                radius = unit.diameter / 4,
                corners = 15
            }
        
            -- Text settings based on unit status
            pushStyle()
            local textSpec = gameModel:ifPlayerIfOtherIfNone(
            unit.owner,
            {
                font = unit.strengthRevealed and "Helvetica-Bold" or "Helvetica",
                color = unit.strengthRevealed and color(255) or color(255, 145),
                text = tostring(unit.strength)
            },
            {
                font = "Helvetica-Bold",
                color = color(255),
                text = unit.strengthRevealed and tostring(unit.strength) or "--"
            },
            {
                font = "Helvetica",
                color = color(255, 145),
                text = "--"
            }
            )
            fontSize(unit.animatedFontSize or 20)
            font(textSpec.font)
            fill(textSpec.color)
            text(textSpec.text, x, y)
            popStyle()
        end
    end
]]

    -- draw all current-player-unit outlines
    for i, unit in ipairs(units) do
        if unit.alive then
            local x = unit.position.x + unit.visualOffset.x
            local y = unit.position.y + unit.visualOffset.y
            
            -- Check if the unit belongs to the current player
            local isCurrentPlayerUnit = gameModel.turnManager:isPlayerTurn(unit.owner)
            
            -- Draw an additional outline for units belonging to the current player
            if not currentCombatAnimation and isCurrentPlayerUnit then
                noFill()  -- No fill for the outline
                stroke(225, 204, 126, 180)  -- Bright color for differentiation, e.g., golden yellow
                strokeWidth(108)  -- Slightly thicker stroke for visibility
                roundedRectangle{
                    x = x,  -- Slightly larger rectangle
                    y = y,
                    w = unit.diameter + 12,
                    h = unit.diameter + 12,
                    radius = (unit.diameter + 14) / 4,
                    corners = 15
                }
            end
        end
    end
    
    
    for i, unit in ipairs(units) do
        if unit.alive then
            local x = unit.position.x + unit.visualOffset.x
            local y = unit.position.y + unit.visualOffset.y
            
            -- Check if the unit belongs to the current player
            local isCurrentPlayerUnit = gameModel.turnManager:isPlayerTurn(unit.owner)
            
            -- Draw the unit with its actual color
            fill(unit.color)
            stroke(184, 67, 236)  -- Lavender stroke color for units
            strokeWidth(0.75)  -- Stroke width for unit outline
            roundedRectangle{
                x = x,
                y = y,
                w = unit.diameter,
                h = unit.diameter,
                radius = unit.diameter / 4,
                corners = 15
            }
            
            -- Text settings based on unit status
            pushStyle()
            local textSpec = gameModel:ifPlayerIfOtherIfNone(
            unit.owner,
            {
                font = unit.strengthRevealed and "Helvetica-Bold" or "HelveticaNeue-BoldItalic",
                color = unit.strengthRevealed and color(255) or color(255, 164),
                text = tostring(unit.strength)
            },
            {
                font = "Helvetica-Bold",
                color = color(255),
                text = unit.strengthRevealed and tostring(unit.strength) or "--"
            },
            {
                font = "Helvetica",
                color = color(255, 145),
                text = "--"
            }
            )
            fontSize(unit.animatedFontSize or 20)
            font(textSpec.font)
            fill(textSpec.color)
            text(textSpec.text, x, y)
            popStyle()
        end
    end
    
    -- Third Pass: Draw all targeting arrows
    stroke(140, 197, 17) -- Red for target lines
    for i, unit in ipairs(units) do
        if unit.alive then
            -- Draw the targeting line and arrow if a target is set
            if unit.target and gameModel.turnManager:isPlayerTurn(unit.owner) then
                local x = unit.position.x + unit.visualOffset.x
                local y = unit.position.y + unit.visualOffset.y
                local visualTargetX = unit.target.x + unit.target.visualOffset.x
                local visualTargetY = unit.target.y + unit.target.visualOffset.y
                drawArrow(x, y, visualTargetX, visualTargetY)
            end
        end
    end
end

function drawArrow(fromX, fromY, toX, toY)
    local arrowSize = 8  -- Size of the arrowhead
    local startOffset = 18   -- Offset for the start of the line from the center of the starting unit
    local stopDistanceLine = 0  -- Distance for the line to stop from the center of the target
    local stopDistanceArrow = 0  -- Distance for the arrowhead to stop from the center of the target
    strokeWidth(8)
    
    -- Calculate the direction from start to end
    local dx = toX - fromX
    local dy = toY - fromY
    local angle = math.atan(dy, dx)
    local distance = math.sqrt(dx^2 + dy^2)
    
    -- Calculate the new start and end points for the line
    local newStartX = fromX + dx * (startOffset / distance)
    local newStartY = fromY + dy * (startOffset / distance)
    local shortLineScale = (distance - stopDistanceLine - startOffset) / distance
    local shortEndX = fromX + dx * shortLineScale
    local shortEndY = fromY + dy * shortLineScale
    
    -- Draw the line from the new start to the shortened endpoint
    line(newStartX, newStartY, shortEndX, shortEndY)
    
    -- Calculate the position for the arrowhead, taking into account its size
    local arrowHeadScale = (distance - stopDistanceArrow - startOffset) / distance
    local arrowHeadX = fromX + dx * arrowHeadScale
    local arrowHeadY = fromY + dy * arrowHeadScale
    
    -- Apply transformation for the arrowhead
    pushMatrix()
    translate(arrowHeadX, arrowHeadY)
    rotate(angle * 180 / math.pi)
    
    -- Draw the arrowhead: a simple triangle
    strokeWidth(6)
    line(0, 0, -arrowSize, arrowSize / 1.2)
    line(0, 0, -arrowSize, -arrowSize / 1.2)
    line(-arrowSize, arrowSize / 1.2, -arrowSize, -arrowSize / 1.2)
    
    popMatrix()
end



