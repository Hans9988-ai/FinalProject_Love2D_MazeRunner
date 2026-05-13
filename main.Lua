--[[
Maze Runner - Mixed Graphics Version
Author: Kevin Dowd

PROJECT DESCRIPTION:
This project is a small arcade-style maze game made in Lua using the Love2D framework.
The player moves through multiple maze levels while collecting coins, avoiding an enemy,
and trying to reach the exit portal. This version uses a mix of imported sprites and
simple Love2D drawn graphics.

The player, enemy, and portal are imported PNG sprites. The walls, floor, and coins are
still drawn directly in Love2D using rectangles and circles. I chose this approach because
it keeps the project simple while still showing that I can use outside sprite graphics.
It also makes the important objects stand out more from the basic maze tiles.

The sprites can be simple. A good size is 32x32 pixels because the game uses 32x32 tiles,
but the code will scale them to fit if they are a different size.

HOW THE GAME WORKS:
The player controls the character using either the arrow keys or WASD.
Coins are spread throughout each maze and must all be collected before the portal works.
An enemy moves around the maze and tries to catch the player.
If the enemy touches the player, the player loses a life and restarts the current level.
When every coin is collected, the player can move onto the portal tile to go to the next level.
After finishing all levels, the player wins the game.

]]

-- Tile settings. The whole maze is built from square 32x32 tiles.
local tileSize = 32
local offsetX = 64
local offsetY = 96

-- This table stores only the imported sprites.
-- Walls, floors, and coins are still drawn with Love2D shapes.
local sprites = {}

-- Game states let us switch between title, gameplay, win, and game over screens.
local gameState = "title"

-- Player data. gridX and gridY are tile positions, not pixel positions.
local player = {
    gridX = 2,
    gridY = 2,
    lives = 3,
    moveCooldown = 0
}

-- Enemy data. The enemy moves one tile at a time using a simple chasing system.
local enemy = {
    gridX = 1,
    gridY = 1,
    timer = 0,
    moveDelay = 0.45
}

local currentLevel = 1
local score = 0
local coinsLeft = 0
local message = ""

-- Each level is a small text map.
-- # = wall
-- . = coin
-- P = player start
-- E = enemy start
-- X = exit portal
-- space = empty floor
local levels = {
    {
        "###############",
        "#P....#......X#",
        "#.##..#..##...#",
        "#....##....##.#",
        "#.##....##....#",
        "#....##....##.#",
        "#.##....##....#",
        "#......E......#",
        "###############"
    },

    {
        "###############",
        "#P.....#.....X#",
        "#.###..#..###.#",
        "#...#.....#...#",
        "###...###...###",
        "#...#.....#...#",
        "#.###..#..###.#",
        "#.....E#......#",
        "###############"
    },

    {
        "###############",
        "#P....#.......#",
        "#.##..#..##...#",
        "#....##....##X#",
        "#.##....##....#",
        "#....##....##.#",
        "#.##....##....#",
        "#......E......#",
        "###############"
    }
}

-- This table stores the level as editable rows.
local map = {}

-- Convert a string into a table of characters.
local function stringToTable(str)

    local result = {}

    for i = 1, #str do
        result[i] = str:sub(i, i)
    end

    return result
end

-- Reads a tile from the current map.
local function getTile(x, y)

    if map[y] and map[y][x] then
        return map[y][x]
    end

    -- Treat outside the map as a wall.
    return "#"
end

-- Changes a tile in the current map.
local function setTile(x, y, value)

    if map[y] and map[y][x] then
        map[y][x] = value
    end
end

-- Checks if a tile blocks movement.
local function isWall(x, y)
    return getTile(x, y) == "#"
end

-- Draws a sprite scaled to exactly one tile.
local function drawSprite(sprite, x, y)

    local scaleX = tileSize / sprite:getWidth()
    local scaleY = tileSize / sprite:getHeight()

    love.graphics.draw(sprite, x, y, 0, scaleX, scaleY)
end

-- Loads a level and finds important starting positions.
local function loadLevel(levelNumber)

    map = {}
    coinsLeft = 0

    for y, row in ipairs(levels[levelNumber]) do

        map[y] = stringToTable(row)

        for x, tile in ipairs(map[y]) do

            if tile == "P" then

                player.gridX = x
                player.gridY = y
                setTile(x, y, " ")

            elseif tile == "E" then

                enemy.gridX = x
                enemy.gridY = y
                setTile(x, y, " ")

            elseif tile == "." then

                coinsLeft = coinsLeft + 1
            end
        end
    end
end

-- Starts the whole game from level 1.
local function restartGame()

    currentLevel = 1
    score = 0
    player.lives = 3
    gameState = "playing"

    loadLevel(currentLevel)
end

-- Moves the player if the target space is not a wall.
local function tryMovePlayer(dx, dy)

    local nextX = player.gridX + dx
    local nextY = player.gridY + dy

    if isWall(nextX, nextY) then
        return
    end

    player.gridX = nextX
    player.gridY = nextY

    local tile = getTile(player.gridX, player.gridY)

    -- Collect coins.
    if tile == "." then

        score = score + 10
        coinsLeft = coinsLeft - 1

        setTile(player.gridX, player.gridY, " ")
    end

    -- Portal only works after collecting every coin.
    if tile == "X" then

        if coinsLeft == 0 then

            if currentLevel < #levels then

                currentLevel = currentLevel + 1
                loadLevel(currentLevel)

            else
                gameState = "win"
            end

        else
            message = "Collect all coins first!"
        end
    end
end

-- Removes a life and reloads the level.
local function loseLife()

    player.lives = player.lives - 1

    if player.lives <= 0 then
        gameState = "gameover"

    else
        loadLevel(currentLevel)
    end
end

-- Enemy AI movement.
local function moveEnemy()

    local dx = 0
    local dy = 0

    local horizontalDistance = player.gridX - enemy.gridX
    local verticalDistance = player.gridY - enemy.gridY

    if math.abs(horizontalDistance) > math.abs(verticalDistance) then
        dx = horizontalDistance > 0 and 1 or -1
    else
        dy = verticalDistance > 0 and 1 or -1
    end

    local nextX = enemy.gridX + dx
    local nextY = enemy.gridY + dy

    if not isWall(nextX, nextY) then
        enemy.gridX = nextX
        enemy.gridY = nextY
    end
end

function love.load()

    love.window.setTitle("Maze Runner")
    love.window.setMode(620, 440)

    love.graphics.setDefaultFilter("nearest", "nearest")

    -- Load imported sprite images.
    sprites.player = love.graphics.newImage("assets/player.png")
    sprites.enemy = love.graphics.newImage("assets/enemy.png")
    sprites.portal = love.graphics.newImage("assets/portal.png")
end

function love.update(dt)

    if gameState ~= "playing" then
        return
    end

    -- Prevents movement from happening too fast.
    if player.moveCooldown > 0 then
        player.moveCooldown = player.moveCooldown - dt
    end

    if player.moveCooldown <= 0 then

        if love.keyboard.isDown("up", "w") then
            tryMovePlayer(0, -1)
            player.moveCooldown = 0.12

        elseif love.keyboard.isDown("down", "s") then
            tryMovePlayer(0, 1)
            player.moveCooldown = 0.12

        elseif love.keyboard.isDown("left", "a") then
            tryMovePlayer(-1, 0)
            player.moveCooldown = 0.12

        elseif love.keyboard.isDown("right", "d") then
            tryMovePlayer(1, 0)
            player.moveCooldown = 0.12
        end
    end

    enemy.timer = enemy.timer + dt

    if enemy.timer >= enemy.moveDelay then
        enemy.timer = 0
        moveEnemy()
    end

    -- Check collision between player and enemy.
    if player.gridX == enemy.gridX and player.gridY == enemy.gridY then
        loseLife()
    end
end

-- Handles keyboard presses that only need to happen once.
-- This is different from love.keyboard.isDown() because it activates
-- only when the key is first pressed.
function love.keypressed(key)

    -- Start the game from the title screen.
    if key == "return" and gameState == "title" then
        restartGame()

    -- Restart the game anytime by pressing R.
    elseif key == "r" then
        restartGame()

    -- Close the game window.
    elseif key == "escape" then
        love.event.quit()
    end
end

-- Converts maze grid coordinates into screen pixel coordinates.
-- This makes it easier to place objects inside the tile map.
local function gridToScreen(gridX, gridY)

    return offsetX + (gridX - 1) * tileSize,
           offsetY + (gridY - 1) * tileSize
end

-- Draws the title screen before the game starts.
local function drawTitle()

    love.graphics.setColor(1, 1, 1)

    love.graphics.printf("MAZE RUNNER", 0, 120, 620, "center")

    love.graphics.printf(
        "Press ENTER to Start",
        0,
        190,
        620,
        "center"
    )
end

-- Draws every tile in the maze.
-- Walls and coins are drawn with Lua shapes.
-- The portal uses an imported sprite image.
local function drawMap()

    for y, row in ipairs(map) do

        for x, tile in ipairs(row) do

            local screenX, screenY =
                gridToScreen(x, y)

            -- Draw floor background.
            love.graphics.setColor(0.12, 0.12, 0.16)

            love.graphics.rectangle(
                "fill",
                screenX,
                screenY,
                tileSize,
                tileSize
            )

            -- Draw wall tiles.
            if tile == "#" then

                love.graphics.setColor(0.2, 0.35, 0.85)

                love.graphics.rectangle(
                    "fill",
                    screenX,
                    screenY,
                    tileSize,
                    tileSize
                )

            -- Draw collectible coin.
            elseif tile == "." then

                love.graphics.setColor(1, 0.85, 0.2)

                love.graphics.circle(
                    "fill",
                    screenX + tileSize / 2,
                    screenY + tileSize / 2,
                    6
                )

            -- Draw portal sprite.
            elseif tile == "X" then

                love.graphics.setColor(1, 1, 1)

                drawSprite(
                    sprites.portal,
                    screenX,
                    screenY
                )
            end
        end
    end
end

-- Draw the player and enemy sprites.
local function drawCharacters()

    local playerX, playerY =
        gridToScreen(player.gridX, player.gridY)

    local enemyX, enemyY =
        gridToScreen(enemy.gridX, enemy.gridY)

    love.graphics.setColor(1, 1, 1)

    -- Draw player sprite.
    drawSprite(
        sprites.player,
        playerX,
        playerY
    )

    -- Draw enemy sprite.
    drawSprite(
        sprites.enemy,
        enemyX,
        enemyY
    )
end

-- Draw user interface information.
local function drawUI()

    love.graphics.setColor(1, 1, 1)

    love.graphics.print("Score: " .. score, 64, 24)

    love.graphics.print(
        "Lives: " .. player.lives,
        220,
        24
    )

    love.graphics.print(
        "Level: " .. currentLevel,
        340,
        24
    )

    love.graphics.print(
        "Coins Left: " .. coinsLeft,
        440,
        24
    )

    love.graphics.print(
        "R = Restart",
        64,
        54
    )

    love.graphics.print(
        message,
        64,
        390
    )
end

-- Main drawing function.
-- Love2D automatically runs this every frame.
function love.draw()

    -- Set background color.
    love.graphics.setBackgroundColor(
        0.05,
        0.05,
        0.08
    )

    -- Draw different screens depending on the game state.
    if gameState == "title" then

        drawTitle()

    elseif gameState == "playing" then

        drawUI()
        drawMap()
        drawCharacters()

    elseif gameState == "win" then

        love.graphics.setColor(1, 1, 1)

        love.graphics.printf(
            "YOU WIN!",
            0,
            140,
            620,
            "center"
        )

        love.graphics.printf(
            "Final Score: " .. score,
            0,
            190,
            620,
            "center"
        )

        love.graphics.printf(
            "Press R to play again",
            0,
            240,
            620,
            "center"
        )

    elseif gameState == "gameover" then

        love.graphics.setColor(1, 1, 1)

        love.graphics.printf(
            "GAME OVER",
            0,
            140,
            620,
            "center"
        )

        love.graphics.printf(
            "Final Score: " .. score,
            0,
            190,
            620,
            "center"
        )

        love.graphics.printf(
            "Press R to restart",
            0,
            240,
            620,
            "center"
        )
    end
end