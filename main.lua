require("deck")
require("board")

function love.load()
  love.window.setTitle("Solitaire")
  love.window.setMode(800, 600)
  
  deck = Deck:new()
  deck:shuffle()
  board = Board:new(deck)
end
function love.update()
end

function love.draw()
  love.graphics.print("Solitaire!", 350, 10)
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
  