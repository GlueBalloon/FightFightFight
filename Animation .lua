function animateUnit(unit)
    -- Function to start a new tween from the current visual offset
    local function startTween()
        local targetX, targetY
        
        if unit.visualOffset.x == 0 and unit.visualOffset.y == 0 then
            -- If currently centered, calculate a new offset
            local angle = math.random() * 2 * math.pi  -- Random angle for direction
            local offset = math.random() * 3  -- Random offset from 0 to 2 pixels
            targetX = math.cos(angle) * offset
            targetY = math.sin(angle) * offset
        else
            -- If currently offset, return to the center
            targetX = 0
            targetY = 0
        end
        
        -- Tween to the new visual offset
        tween(0.5, unit.visualOffset, {x = targetX, y = targetY}, tween.easing.linear, function()
            -- After reaching the target, initiate another tween to continue the motion
            startTween()
        end)
    end
    
    -- Initialize the visualOffset if not present
    if not unit.visualOffset then
        unit.visualOffset = vec2(0, 0)
    end
    
    -- Start the first tween
    startTween()
end

function startCombatAnimation(attackRecords)
    print("startCombatAnimation")
    if #attackRecords > 0 then
        animatingUnits = gameModel:duplicateUnits(attackRecords.units)
    end
    animateAttackSequence(attackRecords, 1)
end

function changeAllUnitColors(units, aColor)
    for i, unit in ipairs(units) do
        unit.color = aColor
    end
end

function changeAllUnitStrengthRevealed(units, value)
    for i, unit in ipairs(units) do
        unit.strengthRevealed = value
    end
end

function animateAttackSequence(attackRecords, index)
    print("animateAttackSequence", attackRecords, #attackRecords, index)
    if index > #attackRecords or not animationRunning then
        animatingUnits = nil
        currentCombatAnimation = nil
        animationRunning = false
        gameModel:checkGameOver()
        gameModel:moveToNextPhase()  -- End of combat animation
        return
    end
    
    local currentAttack = attackRecords[index]
    -- Set strengthRevealed to true for animation units
    local attackerUnit = animatingUnits.unitMap[currentAttack.attackerId]
    local defenderUnit = animatingUnits.unitMap[currentAttack.defenderId]
    attackerUnit.strengthRevealed = true
    defenderUnit.strengthRevealed = true
    
    currentCombatAnimation = {
        attackerPos = vec2(currentAttack.attackerPosition.x, currentAttack.attackerPosition.y),
        defenderPos = vec2(currentAttack.defenderPosition.x, currentAttack.defenderPosition.y),
        attackerStrength = currentAttack.attackerStrength,
        defenderStrength = currentAttack.defenderStartingStrength,
        attackerFontSize = 16,
        defenderFontSize = 16,
        attackerAnimOffset = vec2(0, 0),
        defenderAnimOffset = vec2(0, 0),
        shouldDrawArrow = true,
        attackerColor = attackerUnit.color
    }
    print("defined currentCombatAnimation")
    print("attackRecords.unitMap", animatingUnits.unitMap)
    print("attackRecords.unitMap[currentAttack.attackerId]", animatingUnits.unitMap[currentAttack.attackerId])
     
    -- Start the enlargement animation
    enlargeStrengthsAnimation(function()
        -- When enlargement is complete, start jittering both simultaneously
        local jitterDuration = 0.35
        local jitterIntensity = 3
        local numJitters = 28
        local jitterCompleteCount = 0
        
        local function onJitterComplete()
        --    jitterCompleteCount = jitterCompleteCount + 1
       --     if jitterCompleteCount == 2 then  -- Ensure both jitters are complete
                moveAttackerToDefender(currentAttack, function()
                    currentCombatAnimation.attackerFontSize = 0
                    flashFullScreen(function()
                        -- Update the strengths post-collision
                        currentCombatAnimation.defenderStrength = currentAttack.defenderEndingStrength
                        defenderUnit.strength = currentAttack.defenderEndingStrength
                        if defenderUnit.strength <= 0 then
                            defenderUnit.alive = false
                        end
                        shrinkStrengthAnimation(function()
                            animateAttackSequence(attackRecords, index + 1)  -- Proceed to the next attack
                        end)
                        end)
                    end)
           -- end
        end
        
        createChainedJitterTween(currentCombatAnimation, 'attackerAnimOffset', jitterDuration, jitterIntensity, numJitters, onJitterComplete)
      --  createChainedJitterTween(currentCombatAnimation, 'defenderAnimOffset', jitterDuration, jitterIntensity, numJitters, onJitterComplete)
    end)
end

function enlargeStrengthsAnimation(callback)
    print("enlargeStrengthsAnimation")
    -- Start animation tweens for font size
    tween(0.25, currentCombatAnimation, {attackerFontSize = 45, defenderFontSize = 30}, tween.easing.outQuad, function()
        callback()
    end)
end

function shrinkStrengthAnimation(callback)
    -- Start animation tweens for font size
    tween(0.35, currentCombatAnimation, {defenderFontSize = 20}, tween.easing.outQuad, function()
        callback()
    end)
end

function createChainedJitterTween(target, key, duration, intensity, numJitters, onComplete)
    local function jitterStep(currentStep)
        if currentStep > numJitters then
            -- End of the jitter sequence
            target[key] = vec2(0, 0)  -- Reset jitter offset
            if onComplete then onComplete() end
            return
        end
        
        -- Generate a new random offset for this step
        local randomOffset = vec2(
        (math.random() - 0.5) * 2 * intensity, 
        (math.random() - 0.5) * 2 * intensity
        )
        
        -- Create a temporary update object to pass to the tween function
        local updateObject = {}
        updateObject[key] = randomOffset
        
        -- Set this new jitter offset
        tween(duration / numJitters, target, updateObject, tween.easing.linear, function()
            -- Continue to the next jitter step
            jitterStep(currentStep + 1)
        end)
    end
    
    -- Initialize the jitter sequence
    jitterStep(1)
end



function moveAttackerToDefender(currentAttack, callback)
    -- Target position is the defender's position
    local targetX = currentAttack.defenderPosition.x
    local targetY = currentAttack.defenderPosition.y
    
    -- Calculate new offsets to move the attacker directly towards the defender
    local attackerOffsetX = targetX - currentAttack.attackerPosition.x
    local attackerOffsetY = targetY - currentAttack.attackerPosition.y
    
    -- Animate the attacker moving towards the defender
    tween(0.2, currentCombatAnimation, 
    {
        attackerAnimOffset = vec2(attackerOffsetX, attackerOffsetY)
    }, 
    tween.easing.quadIn, function()
        -- Reset attacker's animation offset after reaching the defender to maintain a clean state
        currentCombatAnimation.attackerAnimOffset = vec2(0, 0)
        callback()
    end)
end



function flashFullScreen(callback)
    -- Simulate a flash
    fullscreenFlashColor = color(239, 239, 234)
    fullscreenFlashDuration = 0.25
    tween(fullscreenFlashDuration, {}, {}, tween.easing.linear, function()
        fullscreenFlashColor = nil
        fullscreenFlashDuration = 0
        callback()
    end)
end
