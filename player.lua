local menu = require "menu"
local world = require "world"

-- Access World, Sprites, Animations, and Sounds through getters
local World = world.GetWorld()
local Sprites = world.GetSprites()
local Animations = world.GetAnimations()
local Sounds = world.GetSounds()
local pendingPlayerPosition = world.GetPendingPlayerPosition()

PlayerStartX = 360
PlayerStartY = 100
Player = World:newRectangleCollider(PlayerStartX, PlayerStartY, 40, 100, {collision_class = "Player"})

function LoadPlayer()
    Player:setFixedRotation(true)
    Player:setUserData("Player")
    Player.speed = 260
    Player.animation = Animations.idle
    Player.isMoving = false
    Player.direction = 1
    Player.grounded = false
    Player.coyoteTime = 0.1
    Player.coyoteTimer = 0
end

function PlayerUpdate(dt)
    -- Update pending position if available
    if pendingPlayerPosition then
        Player:setPosition(pendingPlayerPosition.x, pendingPlayerPosition.y)
        pendingPlayerPosition = nil  -- Clear the pending position after updating
    end

    if Player.body then
        if not Player.grounded then
            Player.coyoteTimer = math.max(Player.coyoteTimer - dt, 0)
        end

        Player.isMoving = false
        local px = Player:getPosition()
        if love.keyboard.isDown('right') then
            Player:setX(px + Player.speed * dt)
            Player.isMoving = true
            Player.direction = 1
        end
        if love.keyboard.isDown('left') then
            Player:setX(px - Player.speed * dt)
            Player.isMoving = true
            Player.direction = -1
        end
    end

    if Player.grounded then
        if Player.isMoving then
            Player.animation = Animations.run
        else
            Player.animation = Animations.idle
        end
    else
        Player.animation = Animations.jump
    end
    Player.animation:update(dt)
end

function DrawPlayer()
    local px, py = Player:getPosition()
    Player.animation:draw(Sprites.playerSheet, px, py, nil, 0.25 * Player.direction, 0.25, 130, 300)
end

function HandlePlayerKeypress(key)
    if menu.IsGameState("running") then
        if key == 'up' then
            if Player.grounded or Player.coyoteTimer > 0 then
                Player:applyLinearImpulse(0, -4000)
                Sounds.jump:play()
                Player.coyoteTimer = 0
            end
        end
    end
end

function PlayerDeath()
    Sounds.death:play()
    menu.ChangeGameState("ended")
end