Card = {}
Card.__index = Card

-- For tracking where a card is on the board
STATE_ENUM = {
  DECK = "Deck",
  WASTE = "Waste",
  ACE = "Ace",
  STOCK = "Stock",
  UNKNOWN = "Unknown",
  TABLEAU = "Tableau"
}

-- For tracking the color of a card
COLOR_ENUM = {
  RED = "Red",
  BLACK = "Black"
}

-- For tracking the suit of a card
CARD_ENUM = {
  HEARTS = "Hearts",
  DIAMONDS = "Diamonds",
  CLUBS = "Clubs",
  SPADES = "Spades"
}

-- Constructor for making a new card object
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
    state = STATE_ENUM.UNKNOWN,
    prevX,
    prevY,
    x = 0,
    y = 0
  }
  setmetatable(card, Card)
  return card
end

-- Flipping a card over
function Card:flip()
  self.faceUp = not self.faceUp
end

-- Drawing the card on the screen
function Card:draw(x,y)
  if self.faceUp then
    love.graphics.draw(self.frontImage, x, y)
  else
    love.graphics.draw(self.backImage, x, y)
  end
end

-- Update card position
function Card:updatePosition(pile, targetX, targetY)
  self.x = targetX
  self.y = targetY
  self.prevX = targetX
  self.prevY = targetY
  table.insert(pile, self)
end