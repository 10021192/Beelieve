local button = require "button"

local game = {
    state = {
        menu = true,
        paused = false,
        running = false,
        ended = false,
        won = false,
    }
}

local buttons = {
    menu_state = {},
    ended_state = {},
    paused_state = {}
}

local function ChangeGameState(state)
    game.state["menu"] = state == "menu"
    game.state["paused"] = state == "paused"
    game.state["running"] = state == "running"
    game.state["ended"] = state == "ended"
    game.state["won"] = state == "won"
end

local function StartNewGame()
    if game.state["menu"] then
        CurrentLevel = "level1"
        LoadMap(CurrentLevel)
    else
        LoadMap(CurrentLevel)
    end
    ChangeGameState("running")
    Player:setPosition(PlayerStartX, PlayerStartY)
    Player:setLinearVelocity(0, 0)
end

local function LoadMenus(Sprites)
    buttons.menu_state.play_game = button("Play", StartNewGame, nil, 300, 100, 32, Sprites.buttonsGreen)
    buttons.menu_state.exit_game = button("Exit", love.event.quit, nil, 300, 100, 32, Sprites.buttonsBlue)

    buttons.ended_state.replay_game = button("Replay", StartNewGame, nil, 300, 100, 32, Sprites.buttonsYellow)
    buttons.ended_state.menu = button("Menu", ChangeGameState, "menu", 300, 100, 32, Sprites.buttonsBlue)
    buttons.ended_state.exit_game = button("Exit", love.event.quit, nil, 300, 100, 32, Sprites.buttonsYellow)

    buttons.paused_state.resume_game = button("Resume", ChangeGameState, "running", 300, 100, 32, Sprites.buttonsGreen)
    buttons.paused_state.menu = button("Menu", ChangeGameState, "menu", 300, 100, 32, Sprites.buttonsYellow)
    buttons.paused_state.exit_game = button("Exit", love.event.quit, nil, 300, 100, 32, Sprites.buttonsGreen)
end

local function DrawMenus()
    if game.state["menu"] then
        love.graphics.setFont(Fonts[128])
        love.graphics.setColor(1, 0.5, 0)
        love.graphics.printf("Beelieved", 20, 100, love.graphics.getWidth(), "center")
        love.graphics.setColor(1, 1, 1)
        buttons.menu_state.play_game:draw(810, 420, 50, 15)
        buttons.menu_state.exit_game:draw(810, 560, 10, 20)
    elseif game.state["ended"] then
        love.graphics.setFont(Fonts[64])
        love.graphics.setColor(1, 0.5, 0)
        love.graphics.printf("You lost!", 0, 200, love.graphics.getWidth(), "center")
        love.graphics.setColor(1, 1, 1)
        buttons.ended_state.replay_game:draw(810, 340, 50, 15)
        buttons.ended_state.menu:draw(810, 480, 10, 20)
        buttons.ended_state.exit_game:draw(810, 620, 10, 20)
    elseif game.state["won"] then
        love.graphics.setFont(Fonts[64])
        love.graphics.setColor(1, 0.5, 0)
        love.graphics.printf("You won!", 0, 200, love.graphics.getWidth(), "center")
        love.graphics.setColor(1, 1, 1)
    elseif game.state["paused"] then
        buttons.paused_state.resume_game:draw(810, 340, 50, 15)
        buttons.paused_state.menu:draw(810, 480, 10, 20)
        buttons.paused_state.exit_game:draw(810, 620, 10, 20)
    end
end

function HandleMenuKeypress(key, sounds)
    if not game.state["menu"] and not game.state["ended"] and not game.state["won"] then
        if key == 'escape' then
            if game.state["paused"] then
                ChangeGameState("running")
                sounds.hidePaused:play()
            else
                ChangeGameState("paused")
                sounds.showPaused:play()
            end
        end
    end
end

function HandleMenuMousepress(x, y, button, sounds)
    if not game.state["running"] then
        if button == 1 then
            if game.state["menu"] then
                for index in pairs(buttons.menu_state) do
                    buttons.menu_state[index]:checkPressed(x, y, sounds)
                end
            elseif game.state["ended"] then
                for index in pairs(buttons.ended_state) do
                    buttons.ended_state[index]:checkPressed(x, y, sounds)
                end
            elseif game.state["paused"] then
                for index in pairs(buttons.paused_state) do
                    buttons.paused_state[index]:checkPressed(x, y, sounds)
                end
            end
        end
    end
end

-- Getter for checking game state
local function IsGameState(state)
    return game.state[state] or false
end

-- Public functions to access from other modules
local menu = {
    ChangeGameState = ChangeGameState,
    StartNewGame = StartNewGame,
    IsGameState = IsGameState,
    LoadMenus = LoadMenus,
    DrawMenus = DrawMenus,
}

return menu