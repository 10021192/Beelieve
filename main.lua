local world = require "world"
local menu = require "menu"

function love.load()
    love.window.setMode(1920, 1080)

    -- Load menu and world first to ensure that all dependencies are met
    LoadWorld()
    local Sprites = world.GetSprites()
    menu.LoadMenus(Sprites)

    -- Require player and enemy after world initialization
    require('player')
    require('enemy')

    LoadPlayer()
end

function love.update(dt)
    UnlockPhysicsForLoading()
    if menu.IsGameState("running") then
        UpdateWorld(dt)
        PlayerUpdate(dt)
        UpdateEnemies(dt)
        CenterCamera()

        love.mouse.setVisible(false)
    elseif menu.IsGameState("won") then
        GameCompleted(dt)
    else
        love.mouse.setVisible(true)
    end
    GameMusic()
end

function love.draw()
    DrawWorld()
end

function love.keypressed(key)
    local Sounds = world.GetSounds()
    HandlePlayerKeypress(key)
    HandleMenuKeypress(key, Sounds)
end

function love.mousepressed(x, y, button)
    local Sounds = world.GetSounds()
    HandleMenuMousepress(x, y, button, Sounds)
end