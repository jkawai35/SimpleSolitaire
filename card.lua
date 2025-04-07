Card = {}
Card.__index = Card

function Card:new(suit, value, image1, image2, color)
  local card =  {
    suit = suit,
    value = value,
    frontImage = image1,
    backImage = image2,
    faceUp = false,
    baseX = 0,
    baseY = 0,
    color = color,
    wasWaste = false,
    prevX,
    prevY,
    x = 0,
    y = 0
  }
  setmetatable(card, Card)
  return card
end

function Card:flip()
  self.faceUp = not self.faceUp
end

function Card:draw(x,y)
  if self.faceUp then
    love.graphics.draw(self.frontImage, x, y)
  else
    love.graphics.draw(self.backImage, x, y)
  end
end