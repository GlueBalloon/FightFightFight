--[[
-- Defining the pseudo-enum for turn phases
Phase = {
    PLAYER1 = 1,
    PLAYER2 = 2,
    RESOLVING_COMBAT = 3
}

TurnManager = class()

function TurnManager:init()
    self.currentPhase = Phase.PLAYER1
end

function TurnManager:nextPhase()
    if self.currentPhase == Phase.PLAYER1 then
        self.currentPhase = Phase.PLAYER2
    elseif self.currentPhase == Phase.PLAYER2 then
        self.currentPhase = Phase.RESOLVING_COMBAT
    else
        self.currentPhase = Phase.PLAYER1
    end
end

function TurnManager:isPlayerTurn(player)
    return (player == Player.player1 and self.currentPhase == Phase.PLAYER1) or
    (player == Player.player2 and self.currentPhase == Phase.PLAYER2)
end
]]

-- Defining the pseudo-enum for turn phases including ready states
Phase = {
    READY1 = 1,
    PLAYER1 = 2,
    READY2 = 3,
    PLAYER2 = 4,
    RESOLVING_COMBAT = 5
}

TurnManager = class()

function TurnManager:init()
    self.phases = {Phase.READY1, Phase.PLAYER1, Phase.READY2, Phase.PLAYER2, Phase.RESOLVING_COMBAT}
    self.currentPhase = 1  -- Start at the first phase
end

function TurnManager:nextPhase()
    -- Cycle through the phases in the defined order
    self.currentPhase = (self.currentPhase % #self.phases) + 1
end

function TurnManager:isPlayerTurn(player)
    if player == Player.player1 then
        return self.currentPhase == Phase.PLAYER1 
        or self.currentPhase == Phase.READY1
    elseif player == Player.player2 then
        return self.currentPhase == Phase.PLAYER2 
        or self.currentPhase == Phase.READY2
    end
    return false
end


Phase = {
    READY1 = 1,
    ANIMATE_RESULTS_P1 = 2,
    PLAYER1 = 3,
    READY2 = 4,
    ANIMATE_RESULTS_P2 = 5,
    PLAYER2 = 6,
    RESOLVING_COMBAT = 7
}

TurnManager = class()

function TurnManager:init()
    self.currentPhase = Phase.READY1
end

function TurnManager:nextPhase()
    self.currentPhase = self.currentPhase % 7 + 1
end

function TurnManager:isPlayerTurn(player)
    if player == Player.player1 then
        return self.currentPhase == Phase.PLAYER1 
        or self.currentPhase == Phase.READY1
        or self.currentPhase == Phase.ANIMATE_RESULTS_P1
    elseif player == Player.player2 then
        return self.currentPhase == Phase.PLAYER2 
        or self.currentPhase == Phase.READY2 
        or self.currentPhase == Phase.ANIMATE_RESULTS_P2
    end
end

function TurnManager:isReadyPhase()
    return self.currentPhase == Phase.READY1 
    or self.currentPhase == Phase.READY2
end

function TurnManager:isActivePhase()
    return self.currentPhase == Phase.PLAYER1 
    or self.currentPhase == Phase.PLAYER2
end

function TurnManager:isAnimationPhase()
    return self.currentPhase == Phase.ANIMATE_RESULTS_P1 
    or self.currentPhase == Phase.ANIMATE_RESULTS_P2
end

