--[[
Draft 1 - Basic Movement Prototype

This was the first test version of my Love2D game.
The main goal of this draft was to learn how player movement works
before adding the maze, coins, enemy AI, levels, or game objectives.

In this version, the player is represented using a simple imported sprite image
instead of a basic shape. The player sprite can move freely around the screen
using either the arrow keys or WASD controls.

This draft helped create the foundation for the final maze game,
which later added levels, enemies, collectibles, UI elements,
and a full gameplay loop.

To run this draft, create an assets folder and add:
assets/player.png
]]

-- Store the player's position on the screen.
local playerX = 100
local playerY = 100

-- Controls how fast the player moves.
local playerSpeed = 200

-- Variable that will store the player sprite image.
local playerSprite

function love.load()
    love.window.setTitle("Draft 1 - Basic Movement")
    love.window.setMode(600, 400)

    -- Load the player sprite image from the assets folder.
    playerSprite = love.graphics.newImage("assets/player.png")
end

function love.update(dt)

    -- Move up.
    if love.keyboard.isDown("up", "w") then
        playerY = playerY - playerSpeed * dt
    end

    -- Move down.
    if love.keyboard.isDown("down", "s") then
        playerY = playerY + playerSpeed * dt
    end

    -- Move left.
    if love.keyboard.isDown("left", "a") then
        playerX = playerX - playerSpeed * dt
    end

    -- Move right.
    if love.keyboard.isDown("right", "d") then
        playerX = playerX + playerSpeed * dt
    end
end

function love.draw()

    -- Draw the player sprite on the screen.
    love.graphics.draw(playerSprite, playerX, playerY)

    -- Draw instructions and labels.
    love.graphics.print("Draft 1: Basic Sprite Movement Test", 20, 20)
    love.graphics.print("Use Arrow Keys or WASD to move", 20, 45)
end