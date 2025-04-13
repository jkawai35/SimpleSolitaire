require("deck")
require("board")

function love.load()
  love.graphics.setDefaultFilter("nearest", "nearest")
  love.window.setTitle("Solitaire")
  love.window.setMode(800, 600)
  love.graphics.setBackgroundColor(0.2, 0.6, 0.2, 1)
  
  deck = Deck:new()
  deck:shuffle()
  board = Board:new(deck)
end

function love.draw()
  love.graphics.print("Solitaire!", 360, 550)
  board:draw()
end

function love.mousepressed(x, y, button)
  if button == 1 then
    -- Click within stock area
    if x >= 15 and x <= 50 and y >= 16 and y <= 80 then
      board:drawFromStock()
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
  