require("card")

Deck = {}
Deck.__index = Deck

CardImages = {}

io.stdout:setvbuf("no")


local suits = {"Hearts", "Diamonds", "Clubs", "Spades"}
local values = {"1", "2", "3", "4", "5", "6", "7", "8", "9", "10", "11", "12", "13"}

function Deck:new()
  local deck = {}
  setmetatable(deck, Deck)
  deck.cards = {}
  
  for _, suit in ipairs(suits) do
    for _, value in ipairs(values) do
      local image = love.graphics.newImage("Sprites/" .. suit .. " " .. value .. ".png")
      local image2 = love.graphics.newImage("Sprites/Card Back 1.png")
      local color
      
      if suit == "Clubs" or suit == "Spades" then
        color = "black"
      else
        color = "red"
      end
      
      local card = Card:new(suit, value, image, image2, color)
      
      table.insert(deck.cards, card)
    end
  end
  
  return deck
end

function Deck:shuffle()
  for i = #self.cards, 2, -1 do
    local j = love.math.random(1, i)
    self.cards[i], self.cards[j] = self.cards[j], self.cards[i]
  end
end