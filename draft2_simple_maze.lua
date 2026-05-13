--[[
Draft 2 - Simple Maze Prototype

This was the second test version of my Love2D game.
The goal of this draft was to build on Draft 1 by adding a simple
tile-based maze system.

In Draft 1, I only tested moving a player sprite around the screen.
In this version, I started turning that movement test into an actual game
by adding a small maze, wall tiles, coins, and a portal.

This draft uses a mix of graphics:
- The player is an imported sprite image
- The portal is an imported sprite image
- The walls are drawn in Lua using rectangles
- The coins are drawn in Lua using circles
- The floor is drawn in Lua as a dark background tile

The main purpose of this draft was to test:
- Tile-based maps
- Drawing a maze from text characters
- Wall collision
- Coin collection
- A simple portal/exit tile
- Using sprites and Love2D shapes together

This draft helped create the foundation for the final maze game,
which later added an enemy, multiple levels, score UI, lives,
title screen, game over screen, and restart options.

To run this draft, create an assets folder and add:
assets/player.png
assets/portal.png
]]

-- Size of each square tile in the maze.
local tileSize = 32

-- Position where the maze starts on the screen.
local offsetX = 80
local offsetY = 80

-- Player position in grid coordinates.
-- These are tile positions, not pixel positions.
local player = {
    gridX = 2,
    gridY = 2,
    moveCooldown = 0
}

-- Score increases when the player collects coins.
local score = 0

-- This variable keeps track of whether the player reached the portal.
local reachedPortal = false

-- These variables store the imported sprite images.
local playerSprite
local portalSprite

-- Simple text-based map.
-- # = wall
-- . = coin
-- P = player start
-- X = portal / exit
-- space = empty floor
local mapText = {
    "##########",
    "#P...#..X#",
    "#.##.#.#.#",
    "#....#...#",
    "####.###.#",
    "#........#",
    "##########"
}

-- This table will store an editable version of the map.
local map = {}

-- Converts a string row into a table of individual characters.
local function stringToTable(str)
    local result = {}
    for i = 1, #str do
        result[i] = str:sub(i, i)
    end
    return result
end

-- Reads a tile from the map.
local function getTile(x, y)
    if map[y] and map[y][x] then
        return map[y][x]
    end

    -- Anything outside the map counts as a wall.
    return "#"
end

-- Changes a tile in the map.
local function setTile(x, y, value)
    if map[y] and map[y][x] then
        map[y][x] = value
    end
end

-- Checks whether the tile is a wall.
local function isWall(x, y)
    return getTile(x, y) == "#"
end

-- Draws a sprite scaled to one tile.
local function drawSprite(sprite, x, y)
    local scaleX = tileSize / sprite:getWidth()
    local scaleY = tileSize / sprite:getHeight()
    love.graphics.draw(sprite, x, y, 0, scaleX, scaleY)
end

-- Loads the map and finds the player's starting position.
local function loadMap()
    map = {}

    for y, row in ipairs(mapText) do
        map[y] = stringToTable(row)

        for x, tile in ipairs(map[y]) do
            if tile == "P" then
                player.gridX = x
                player.gridY = y

                -- Replace the P with empty floor after storing the start position.
                setTile(x, y, " ")
            end
        end
    end
end

-- Attempts to move the player by one tile.
local function tryMovePlayer(dx, dy)
    local nextX = player.gridX + dx
    local nextY = player.gridY + dy

    -- Stop the player if the next tile is a wall.
    if isWall(nextX, nextY) then
        return
    end

    player.gridX = nextX
    player.gridY = nextY

    local tile = getTile(player.gridX, player.gridY)

    -- Collect the coin if the player steps on it.
    if tile == "." then
        score = score + 10
        setTile(player.gridX, player.gridY, " ")
    end

    -- End the draft when the player reaches the portal.
    if tile == "X" then
        reachedPortal = true
    end
end

function love.load()
    love.window.setTitle("Draft 2 - Simple Maze Prototype")
    love.window.setMode(520, 360)
    love.graphics.setDefaultFilter("nearest", "nearest")

    -- Load the imported sprite images.
    playerSprite = love.graphics.newImage("assets/player.png")
    portalSprite = love.graphics.newImage("assets/portal.png")

    -- Set up the maze.
    loadMap()
end

function love.update(dt)
    -- Stop movement after reaching the portal.
    if reachedPortal then
        return
    end

    -- Cooldown keeps the player from moving too quickly through tiles.
    if player.moveCooldown > 0 then
        player.moveCooldown = player.moveCooldown - dt
    end

    if player.moveCooldown <= 0 then
        if love.keyboard.isDown("up", "w") then
            tryMovePlayer(0, -1)
            player.moveCooldown = 0.15
        elseif love.keyboard.isDown("down", "s") then
            tryMovePlayer(0, 1)
            player.moveCooldown = 0.15
        elseif love.keyboard.isDown("left", "a") then
            tryMovePlayer(-1, 0)
            player.moveCooldown = 0.15
        elseif love.keyboard.isDown("right", "d") then
            tryMovePlayer(1, 0)
            player.moveCooldown = 0.15
        end
    end
end

function love.draw()
    -- Draw score and instructions.
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("Draft 2: Simple Maze Prototype", 20, 20)
    love.graphics.print("Score: " .. score, 20, 45)
    love.graphics.print("Use Arrow Keys or WASD to move", 20, 330)

    -- Draw the map.
    for y, row in ipairs(map) do
        for x, tile in ipairs(row) do
            local screenX = offsetX + (x - 1) * tileSize
            local screenY = offsetY + (y - 1) * tileSize

            -- Draw floor background.
            love.graphics.setColor(0.12, 0.12, 0.16)
            love.graphics.rectangle("fill", screenX, screenY, tileSize, tileSize)

            if tile == "#" then
                -- Draw wall as a blue rectangle.
                love.graphics.setColor(0.2, 0.35, 0.85)
                love.graphics.rectangle("fill", screenX, screenY, tileSize, tileSize)
            elseif tile == "." then
                -- Draw coin as a yellow circle.
                love.graphics.setColor(1, 0.85, 0.2)
                love.graphics.circle("fill", screenX + tileSize / 2, screenY + tileSize / 2, 6)
            elseif tile == "X" then
                -- Draw portal using the imported portal sprite.
                love.graphics.setColor(1, 1, 1)
                drawSprite(portalSprite, screenX, screenY)
            end

            -- Draw a thin grid outline.
            love.graphics.setColor(0, 0, 0, 0.25)
            love.graphics.rectangle("line", screenX, screenY, tileSize, tileSize)
        end
    end

    -- Draw the player sprite.
    local playerX = offsetX + (player.gridX - 1) * tileSize
    local playerY = offsetY + (player.gridY - 1) * tileSize

    love.graphics.setColor(1, 1, 1)
    drawSprite(playerSprite, playerX, playerY)

    -- Show a simple message when the player reaches the portal.
    if reachedPortal then
        love.graphics.setColor(1, 1, 1)
        love.graphics.printf("You reached the portal! This later became the level clear system.", 0, 300, 520, "center")
    end
end