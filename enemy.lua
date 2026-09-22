local world = require "world"

-- Access World, Sprites, Animations, and Sounds through getters
local World = world.GetWorld()
local Sprites = world.GetSprites()
local Animations = world.GetAnimations()
local Sounds = world.GetSounds()
local ShockwaveEffects = world.GetShockWaveEffect()

local CATEGORY_MUSHROOM = 4
local CATEGORY_BEE = 2
local CATEGORY_PROJECTILE = 1

Enemies = {}
Projectiles = {}

function SpawnEnemy(x, y, enemyType)
    local enemy

    if enemyType == 'moving' then
        enemy = World:newRectangleCollider(x, y, 70, 90, {collision_class = 'Danger'})
        -- Assign category and mask for bee
        enemy:setCategory(CATEGORY_BEE)
        enemy:setMask(CATEGORY_MUSHROOM, CATEGORY_BEE) -- Do not collide with mushrooms
        enemy.direction = 1
        enemy.speed = 250
        enemy.animation = Animations.enemy
    elseif enemyType == 'shooting' then
        enemy = World:newRectangleCollider(x, y, 55, 100, {collision_class = 'Danger'})
        enemy.direction = -1
        enemy.frames = Sprites.plantFrames
        enemy.currentFrame = 1
        enemy.animationSpeed = 0.8
    end
    enemy.grounded = true
    enemy:setUserData("Danger")
    enemy.type = enemyType
    enemy.timer = 0
    table.insert(Enemies, enemy)
end

function UpdateEnemies(dt)
    for i, e in pairs(Enemies) do
        local ex, ey = e:getPosition()

        if e.type == 'moving' then
            e.animation:update(dt)

            -- Define the raycast callback function
            local foundPlatform = false
            local function rayCastCallback(fixture, x, y, xn, yn, fraction)
                if fixture:getUserData() == "Platform" then
                    foundPlatform = true
                    return 0 -- Stop the raycast once a platform is found
                end
                return -1 -- Continue the raycast otherwise
            end

            -- Cast a ray from slightly ahead of the enemy downwards to check for platform
            local rayStartX = ex + (10 * e.direction) -- Slightly ahead of enemy
            local rayEndX = rayStartX
            local rayEndY = ey + 50 -- Distance downwards to check for platform

            -- Perform the raycast with the callback
            World:rayCast(rayStartX, ey, rayEndX, rayEndY, rayCastCallback)

            -- If no platform is detected, reverse direction
            if not foundPlatform then
                e.direction = e.direction * -1
            end

            e:setX(ex + e.speed * dt * e.direction)
        elseif e.type == 'shooting' then
            e.timer = e.timer + dt

            -- Cycle through animation frames
            if e.timer >= e.animationSpeed then
                e.currentFrame = e.currentFrame % #e.frames + 1
                e.timer = 0 -- Reset timer for next frame

                -- Spawn projectile when on the fourth frame (bite frame)
                if e.currentFrame == 4 then
                    SpawnProjectile(ex, ey, e.direction)
                end
            end
        end
    end
    UpdateProjectiles(dt)
end

function DrawEnemies()
    for i, e in ipairs(Enemies) do
        local ex, ey = e:getPosition()

        if e.type == 'moving' then
            e.animation:draw(Sprites.enemySheet, ex, ey, nil, e.direction, 1, 50, 65)
        elseif e.type == 'shooting' then
            -- Dynamically calculate offsets based on the frame’s dimensions
            local offsetX = e.frames[e.currentFrame]:getWidth() / 2
            local offsetY = e.frames[e.currentFrame]:getHeight() / 2
            love.graphics.draw(e.frames[e.currentFrame], ex + 10, ey - 5, nil, 0.08 * e.direction, 0.07, offsetX, offsetY)
        end
    end
    DrawProjectiles()
end

function SpawnProjectile(x, y, direction)
    -- Offset values for the plant's mouth (calculated relative to the plant's position)
    local offset_x = 30 -- Adjust this value to align with the mouth horizontally
    local offset_y = -50 -- Adjust this value to align with the mouth vertically

    -- Set the projectile spawn point relative to the plant
    local spawn_x = x + (direction * offset_x)
    local spawn_y = y + offset_y

    local projectile = World:newCircleCollider(spawn_x, spawn_y, 11, {collision_class = "Projectile"})
    projectile:setUserData("Projectile")
    projectile:setGravityScale(0)
    projectile:setCategory(CATEGORY_PROJECTILE)
    projectile:setMask(CATEGORY_MUSHROOM)

    projectile.speed = 300
    projectile.direction = direction
    projectile.lifespan = 8
    projectile.age = 0
    projectile.animation = Animations.projectile
    table.insert(Projectiles, projectile)
end

function UpdateProjectiles(dt)

    for i = #Projectiles, 1, -1 do
        local p = Projectiles[i]
        p.age = p.age + dt
        p:setLinearVelocity(p.speed * p.direction, 0)

        if p.age > p.lifespan or p:enter('Platform') then
            HandleProjectileDestruction(p)
            table.remove(Projectiles, i)
        end
    end

    for i = #ShockwaveEffects, 1, -1 do
        local shockwave = ShockwaveEffects[i]
        shockwave.age = shockwave.age + dt

        if shockwave.age >= shockwave.lifespan then
            table.remove(ShockwaveEffects, i)
        end
    end
end

function DrawProjectiles()
    for _, p in ipairs(Projectiles) do
        local px, py = p:getPosition()
        p.animation:draw(Sprites.bubble, px, py, nil, 0.4 * p.direction, 0.4, 32, 30)
    end

    for _, shockwave in ipairs(ShockwaveEffects) do
        love.graphics.draw(Sprites.bubblePop, shockwave.x, shockwave.y, nil, 0.15, 0.15, Sprites.bubblePop:getWidth() / 2, Sprites.bubblePop:getHeight() / 2)
    end
end

function HandleProjectileDestruction(projectile)
    local px, py = projectile:getPosition()

    local shockwaveEffect = {
        x = px,
        y = py,
        age = 0,
        lifespan = 0.15
    }
    table.insert(ShockwaveEffects, shockwaveEffect)

    Sounds.bubblePop:setVolume(0.3)
    Sounds.bubblePop:play()
    projectile:destroy()
end