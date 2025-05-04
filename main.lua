require("deck")
require("board")

local resetButton = {
  x = 12,
  y = 560,
  width = 100,
  height = 30,
  label = "Reset"
}

function love.load()
  love.graphics.setDefaultFilter("nearest", "nearest")
  love.window.setTitle("Solitaire")
  love.window.setMode(800, 600)
  love.graphics.setBackgroundColor(0.2, 0.6, 0.2, 1)
  
  deck = Deck:new()
  deck:shuffle()
  board = Board:new(deck)
end

function love.update()
  board:update()
end

function love.draw()
  board:draw()
  
  love.graphics.setColor(0.8, 0.8, 0.8)
  love.graphics.rectangle("fill", resetButton.x, resetButton.y, resetButton.width, resetButton.height)

  love.graphics.setColor(0, 0, 0)
  love.graphics.printf(resetButton.label, resetButton.x, resetButton.y + 8, resetButton.width, "center")
  love.graphics.setColor(1, 1, 1)

end

function love.mousepressed(x, y, button)
  if button == 1 then
    -- Click within stock area
    if x >= 15 and x <= 50 and y >= 16 and y <= 80 then
      board:drawFromStock()
    elseif x >= resetButton.x and x <= resetButton.x + resetButton.width and y >= resetButton.y and y <= resetButton.y + resetButton.height then
      deck = Deck:new()
      deck:shuffle()
      board = Board:new(deck)
    else
      board:mousepressed(x, y, button)
    end
  end
end

function love.mousemoved(x, y, dx, dy)
  board:mousemoved(x, y, dx, dy)
end
function love.mousereleased(x, y, button)
  board:mousereleased(x, y, button)
end
  