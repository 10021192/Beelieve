local Anim8 = require 'libraries/anim8/anim8'
local Sti = require 'libraries/Simple-Tiled-Implementation/sti'
local CameraFile = require 'libraries/hump/camera'
local Wf = require 'libraries/windfield/windfield'
local menu = require "menu"

local worldModule = {}

local CATEGORY_FLAG = 8
local CATEGORY_MUSHROOM = 4
local CATEGORY_BEE = 2

local World, GameMap, Cam, Platforms, Mushrooms, ShockwaveEffects
local Sounds, Sprites, Animations, FlagX, FlagY
local lastPosition = 0  -- Variable to store the last playback position
local wonTimer = 0
local pendingPlayerPosition = nil
local pendingMapLoad = nil
local FlagCollider

function LoadWorld()
    -- Initialize Windfield World
    World = Wf.newWorld(0, 800, false)

    -- Add collision classes
    World:addCollisionClass('Platform')
    World:addCollisionClass('Player')
    World:addCollisionClass('Danger')
    World:addCollisionClass('Flag')
    World:addCollisionClass("Projectile", {ignores = {'Danger'}})

    Cam = CameraFile()

    DangerZone = World:newRectangleCollider(-650, 1000, 5500, 50, {collision_class = "Danger"})
    DangerZone:setType('static')
    DangerZone:setUserData("Danger")

    Platforms = {}
    Mushrooms = {}
    ShockwaveEffects = {}

    FlagX, FlagY = 0, 0

    Sounds = {}
    Sounds.jump = love.audio.newSource("assets/audio/jump.wav", "static")
    Sounds.music = love.audio.newSource("assets/audio/music.mp3", "stream")
    Sounds.musicmuffled = love.audio.newSource("assets/audio/music.mp3", "stream")
    Sounds.death = love.audio.newSource("assets/audio/death.wav", "static")
    Sounds.levelcleared = love.audio.newSource("assets/audio/levelpassed.wav", "static")
    Sounds.showPaused = love.audio.newSource("assets/audio/UISounds/switch-a.ogg", "static")
    Sounds.hidePaused = love.audio.newSource("assets/audio/UISounds/switch-b.ogg", "static")
    Sounds.click = love.audio.newSource("assets/audio/UISounds/click-b.ogg", "static")
    Sounds.victory = love.audio.newSource("assets/audio/victory.mp3", "static")
    Sounds.bubblePop = love.audio.newSource("assets/audio/bubblepop.mp3", "static")

    Sprites = {}
    Sprites.playerSheet = love.graphics.newImage('assets/playerSheet.png')
    Sprites.enemySheet = love.graphics.newImage('assets/enemySheet.png')
    Sprites.background = love.graphics.newImage('assets/background.png')
    Sprites.mushroomTiny = love.graphics.newImage('assets/tinyShroom_red.png')
    Sprites.mushroomTall = love.graphics.newImage('assets/tallShroom_red.png')
    Sprites.bubble = love.graphics.newImage('assets/bubbles.png')
    Sprites.bubblePop = love.graphics.newImage('assets/shockwave.png')
    Sprites.buttonsBlue = love.graphics.newImage('assets/UI/PNG/Blue/Double/button_rectangle_depth_flat.png')
    Sprites.buttonsGreen = love.graphics.newImage('assets/UI/PNG/Green/Double/button_rectangle_depth_flat.png')
    Sprites.buttonsYellow = love.graphics.newImage('assets/UI/PNG/Yellow/Double/button_rectangle_depth_flat.png')
    Sprites.plantFrames = {
        love.graphics.newImage('assets/red_01.png'),
        love.graphics.newImage('assets/red_02.png'),
        love.graphics.newImage('assets/red_03.png'),
        love.graphics.newImage('assets/red_04.png')
    }

    local grid = Anim8.newGrid(614, 564, Sprites.playerSheet:getWidth(), Sprites.playerSheet:getHeight())
    local enemyGrid = Anim8.newGrid(100, 79, Sprites.enemySheet:getWidth(), Sprites.enemySheet:getHeight())
    local bubbleGrid = Anim8.newGrid(64, 64, Sprites.bubble:getWidth(), Sprites.bubble:getHeight())

    Animations = {}
    Animations.idle = Anim8.newAnimation(grid('1-15', 1), 0.05)
    Animations.jump = Anim8.newAnimation(grid('1-7', 2), 0.05)
    Animations.run = Anim8.newAnimation(grid('1-15', 3), 0.05)
    Animations.enemy = Anim8.newAnimation(enemyGrid('1-2', 1), 0.03)
    Animations.projectile = Anim8.newAnimation(bubbleGrid('1-9', 1), 0.1)

    Fonts = {}
    -- Load custom fonts with different sizes
    Fonts[32] = love.graphics.newFont("assets/UI/Font/Kenney Future.ttf", 32) -- Font size for buttons
    Fonts[64] = love.graphics.newFont("assets/UI/Font/Kenney Future.ttf", 64) -- Font size for "You won!" and "You lost!" messages
    Fonts[128] = love.graphics.newFont("assets/UI/Font/Kenney Future.ttf", 128)-- Font size for title

    World:setCallbacks(beginContact, endContact)
end

function UpdateWorld(dt)
    World:update(dt)
    GameMap:update(dt)
end

-- Collision Callbacks
function beginContact(a, b, coll)
    local userDataA = a:getUserData()
    local userDataB = b:getUserData()

    -- Player vs Platform
    if (userDataA == "Player" and userDataB == "Platform") or
       (userDataB == "Player" and userDataA == "Platform") then
        local _, ny = coll:getNormal()
        if ny > 0 then  -- Player colliding from above
            Player.grounded = true
            Player.coyoteTimer = Player.coyoteTime
        end
    end

    -- Player vs Danger
    if (userDataA == "Player" and userDataB == "Danger") or
       (userDataB == "Player" and userDataA == "Danger") then
        PlayerDeath()
    end

    -- Player vs Flag
    if (userDataA == "Player" and userDataB == "Flag") or
       (userDataB == "Player" and userDataA == "Flag") then
        LevelProgression()
    end

    -- Player vs Projectile
    if (userDataA == "Player" and userDataB == "Projectile") or
       (userDataB == "Player" and userDataA == "Projectile") then
        Sounds.bubblePop:setVolume(0.3)
        Sounds.bubblePop:play()
        PlayerDeath()
    end
end

function endContact(a, b, coll)
    local userDataA = a:getUserData()
    local userDataB = b:getUserData()

    -- Player vs Platform
    if (userDataA == "Player" and userDataB == "Platform") or
       (userDataB == "Player" and userDataA == "Platform") then
        Player.grounded = false
    end
end

function DrawWorld()
    love.graphics.draw(Sprites.background, 0, 0, nil, 1.85, 1.4)
    if menu.IsGameState("running") then
        Cam:zoomTo(1.5)
        Cam:attach()
            GameMap:drawLayer(GameMap.layers["Tile Layer 1"])
            DrawPlayer()
            DrawEnemies()
            DrawMushrooms()
        Cam:detach()
    else
        menu.DrawMenus()
    end
end

function CenterCamera()
    local px = Player:getPosition()
    local py = (love.graphics.getHeight()/2) / 1.5
    Cam:lookAt(px, py)
end

function GameMusic()
    if menu.IsGameState("running") then
        -- Ensure only the normal music plays in the running state
        if not Sounds.music:isPlaying() then
            -- Save position from muffled music if it was playing
            if Sounds.musicmuffled:isPlaying() then
                lastPosition = Sounds.musicmuffled:tell()
                Sounds.musicmuffled:stop()
            end
            -- Resume or start normal music from last position
            Sounds.music:seek(lastPosition)
            Sounds.music:setLooping(true)
            Sounds.music:setVolume(0.5) -- Set consistent baseline volume for normal music
            Sounds.music:play()
        end
    elseif menu.IsGameState("paused") then
        -- Ensure only the muffled music plays in the paused state
        if not Sounds.musicmuffled:isPlaying() then
            -- Save position from normal music if it was playing
            if Sounds.music:isPlaying() then
                lastPosition = Sounds.music:tell()
                Sounds.music:stop()
            end
            -- Apply muffled effect and resume muffled music from last position
            love.audio.setEffect("muffled", {
                type = "equalizer",
                volume = 0.2,        -- Further reduce the base volume
                highgain = -24.0,    -- Keep high frequencies reduced
                lowgain = -12.0      -- Reduce low frequencies as well
            })
            Sounds.musicmuffled:setEffect("muffled")
            Sounds.musicmuffled:seek(lastPosition)
            Sounds.musicmuffled:setLooping(true)
            Sounds.musicmuffled:setVolume(0.15) -- Set a lower volume for muffled music
            Sounds.musicmuffled:play()
        end
    else
        -- Stop all music when in other states (like menu)
        lastPosition = 0
        Sounds.music:stop()
        Sounds.musicmuffled:stop()
    end
end

function SpawnPlatform(x, y, width, height)
    if width > 0 and height > 0 then
        local platform = World:newRectangleCollider(x, y, width, height, {collision_class = "Platform"})
        platform:setType('static')
        platform:setUserData("Platform")
        table.insert(Platforms, platform)
    end
end

function SpawnMushrooms(x, y, mushroomType)
    local mushroom
    if mushroomType == 'tiny' then
        mushroom = World:newRectangleCollider(x, y, 40, 30, {collision_class = 'Danger'})
    elseif mushroomType == 'tall' then
        mushroom = World:newRectangleCollider(x, y, 51, 58, {collision_class = 'Danger'})
    end
    mushroom:setUserData("Danger")

    -- Assign category and mask
    mushroom:setCategory(CATEGORY_MUSHROOM)
    mushroom:setMask(CATEGORY_BEE)  -- Do not collide with bees

    mushroom.type = mushroomType
    table.insert(Mushrooms, mushroom)
end

function DrawMushrooms()
    for i, m in ipairs(Mushrooms) do
        local mx, my = m:getPosition()
        if m.type == "tiny" then
            love.graphics.draw(Sprites.mushroomTiny, mx, my, 0, 1, 1, 33, 55)
        elseif m.type == "tall" then
            love.graphics.draw(Sprites.mushroomTall, mx, my, 0, 1.2, 1.4, 33, 49)
        end
    end
end

function CreateFlag()
    FlagCollider = World:newRectangleCollider(FlagX, FlagY, 20, 50, {collision_class = "Flag"})
    FlagCollider:setType('static')
    FlagCollider:setUserData("Flag")
    FlagCollider:setCategory(CATEGORY_FLAG)
    FlagCollider:setMask(CATEGORY_BEE)
end

function LevelProgression()
    if CurrentLevel == "level1" then
        Sounds.levelcleared:play()
        pendingMapLoad = "level2"
    elseif CurrentLevel == "level2" then
        Sounds.levelcleared:play()
        pendingMapLoad = "level3"
    elseif CurrentLevel == "level3" then
        Sounds.levelcleared:play()
        pendingMapLoad = "level4"
    elseif CurrentLevel == "level4" then
        Sounds.levelcleared:play()
        pendingMapLoad = "level5"
    elseif CurrentLevel == "level5" then
        Sounds.victory:play()
        pendingMapLoad = "levelComplete"
    end
end

function UnlockPhysicsForLoading()
    -- Always attempt to load the pending map first
    if pendingMapLoad then
        if pendingMapLoad == "levelComplete" then
            menu.ChangeGameState("won")  -- Set the game state to won
            pendingMapLoad = nil  -- Clear the pending map load after loading
        else
            LoadMap(pendingMapLoad)
            pendingMapLoad = nil  -- Clear the pending map load after loading
        end
    end

    -- Set player position if pending position is set
    if pendingPlayerPosition then
        Player:setPosition(pendingPlayerPosition.x, pendingPlayerPosition.y)
        pendingPlayerPosition = nil  -- Clear the pending position after updating
    end
end

function DestroyAll()
    local i = #Platforms
    while i > -1 do
        if Platforms[i] ~= nil then
            Platforms[i]:destroy()
        end
        table.remove(Platforms, i)
        i = i - 1
    end

    local i = #Enemies
    while i > -1 do
        if Enemies[i] ~= nil then
            Enemies[i]:destroy()
        end
        table.remove(Enemies, i)
        i = i - 1
    end

    local i = #Projectiles
    while i > -1 do
        if Projectiles[i] ~= nil then
            Projectiles[i]:destroy()
        end
        table.remove(Projectiles, i)
        i = i - 1
    end

    local i = #ShockwaveEffects
    while i > -1 do
        table.remove(ShockwaveEffects, i)
        i = i - 1
    end

    local i = #Mushrooms
    while i > -1 do
        if Mushrooms[i] ~= nil then
            Mushrooms[i]:destroy()
        end
        table.remove(Mushrooms, i)
        i = i - 1
    end

    if FlagCollider ~= nil then
        FlagCollider:destroy()
        FlagCollider = nil
    end
end

function LoadMap(mapName)
    CurrentLevel = mapName
    DestroyAll()
    GameMap = Sti("assets/map/" .. mapName .. ".lua")

    -- Set player starting position using pending position
    for i, obj in pairs(GameMap.layers["Start"].objects) do
        PlayerStartX = obj.x
        PlayerStartY = obj.y
    end
    -- Use pending position to avoid locked physics world issues
    pendingPlayerPosition = {x = PlayerStartX, y = PlayerStartY}

    for i, obj in pairs(GameMap.layers["Platforms"].objects) do
        SpawnPlatform(obj.x, obj.y, obj.width, obj.height)
    end

    for i, obj in pairs(GameMap.layers["Enemies"].objects) do
        local enemyType = obj.properties["bee"] or obj.properties["plant"]
        if enemyType == "moving" then
            SpawnEnemy(obj.x, obj.y, enemyType)
        elseif enemyType == "shooting" then
            SpawnEnemy(obj.x, obj.y, enemyType)
        end
    end

    for i, obj in pairs(GameMap.layers["Mushrooms"].objects) do
        local mushroomType = obj.properties["tiny"] or obj.properties["tall"]
        if mushroomType == "tiny" then
            SpawnMushrooms(obj.x, obj.y, mushroomType)
        elseif mushroomType == "tall" then
            SpawnMushrooms(obj.x, obj.y, mushroomType)
        end
    end

    for i, obj in pairs(GameMap.layers["Flag"].objects) do
        FlagX = obj.x
        FlagY = obj.y

        CreateFlag()
    end
end


function GameCompleted(dt)
    wonTimer = wonTimer + dt
    if wonTimer >= 2.5 then
        menu.ChangeGameState("menu")
        wonTimer = 0
    end
end

-- Getter functions to access internal variables from other modules
function worldModule.GetWorld()
    return World
end

function worldModule.GetPlatforms()
    return Platforms
end

function worldModule.GetSprites()
    return Sprites
end

function worldModule.GetAnimations()
    return Animations
end

function worldModule.GetShockWaveEffect()
    return ShockwaveEffects
end

function worldModule.GetSounds()
    return Sounds
end

function worldModule.GetCamera()
    return Cam
end

function worldModule.GetPendingPlayerPosition()
    return pendingPlayerPosition
end

function worldModule.ClearPendingPlayerPosition()
    pendingPlayerPosition = nil
end

return worldModule