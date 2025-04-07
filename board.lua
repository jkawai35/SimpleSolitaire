require("card")

Board = {}
Board.__index = Board

function Board:new(deck)
  local board = {}
  setmetatable(board, Board)

  board.tableau = {}
  board.stock = {}
  board.waste = {}
  
  board.draggedCard = nil
  board.dragOffsetX = 0
  board.dragOffsetY = 0

  -- Create tableau
  for i = 1, 7 do
    board.tableau[i] = {}

    for j = 1, i do
      local card = table.remove(deck.cards)
      card.x = 100 + (i - 1) * 100
      card.y = 100 + (j - 1) * 30
      card.faceUp = (j == i)
      table.insert(board.tableau[i], card)
    end
  end
  
  -- Insert leftover cards into stock
  for _, card in ipairs(deck.cards) do
    card.faceUp = false
    table.insert(board.stock, card)
  end

  deck.cards = nil

  return board
end

function Board:draw()
  -- Draw tableau
  for _, pile in ipairs(self.tableau) do
    for _, card in ipairs(pile) do
      card:draw(card.x, card.y)
    end
  end
  
  -- Create stock pile
  if #self.stock > 0 then
  local topCard = self.stock[#self.stock]
  topCard.x = 50
  topCard.y = 500
  topCard.faceUp = false
  topCard:draw()
  else
    -- Draw empty placeholder for stock
    love.graphics.setColor(0.5, 0.5, 0.5)
    love.graphics.rectangle("line", 15, 16, 50, 80)
    love.graphics.setColor(1, 1, 1)
  end

  -- Draw waste cards in groups of 3
  if #self.waste > 0 then
    -- Draw top 3 waste cards, fanned out to the right of the stock
    local offset = 20  -- Offset for each card in the fan
    local baseX = 100  -- Starting x position for the waste pile cards
    local baseY = 3  -- Starting y position for the waste pile cards
    local offsetIndex = 1
    
    -- Draw waste cards in correct order
    for i = math.max(1, #self.waste - 2), math.max(1, #self.waste) do
      local card = self.waste[i]
      
      -- Set the x position with offset for the fan effect
      if card ~= self.draggedCard then
        card.x = baseX + (offsetIndex - 1) * offset
        card.y = baseY
        card.baseX = card.x
        card.baseY = card.y
        offsetIndex = offsetIndex + 1
      end
      
      card:draw(card.x, card.y)  -- Draw the card with updated position
    end
  end

  -- Update position of dragged card
  if self.draggedCard then
    self.draggedCard:draw(self.draggedCard.x, self.draggedCard.y)
  end
  
end

-- Drawing cards from stock and adding to waste table
function Board:drawFromStock()
  -- Update waste pile when cards are drawn
  local drawCount = math.min(3, #self.stock)
  for i = 1, drawCount do
    local card = table.remove(self.stock)
    card.faceUp = true
    card.wasWaste = true
    table.insert(self.waste, card)
  end
end

-- Mouse pressed to drag cards
function Board:mousepressed(x, y, button)
  if button == 1 then  -- left click
    
    -- check tableau piles from top to bottom
    for pileIndex = 1, #self.tableau do
      local pile = self.tableau[pileIndex]
      for i = #pile, 1, -1 do
        local card = pile[i]

        -- Check if click occurs within the bounds of a card
        if card.faceUp and x >= card.x and x <= card.x + 70 and y >= card.y and y <= card.y + 100 then
          self.draggedCard = card
          self.dragOffsetX = x - card.x
          self.dragOffsetY = y - card.y
          self.draggedCard.prevX = card.x
          self.draggedCard.prevY = card.y
          --return
        end
      end
    end
    
    -- Dragging cards from waste pile
    if #self.waste > 0 then
      local card = self.waste[#self.waste]
      if card.faceUp and x >= card.x and x <= card.x + 70 and y >= card.y and y <= card.y + 100 then
        self.draggedCard = card
        self.dragOffsetX = x - card.x
        self.dragOffsetY = y - card.y
        
        table.remove(self.waste, #self.waste)

        --return
      end
    end
  end
end

-- Moving cards
function Board:mousemoved(x, y, dx, dy)
  if self.draggedCard then
    self.draggedCard.x = x - self.dragOffsetX
    self.draggedCard.y = y - self.dragOffsetY
  end
end

-- Release mouse hold
function Board:mousereleased(x, y, button)
  if button == 1 and self.draggedCard then
    
    -- Check for valid drop on a tableau pile
    for i, pile in ipairs(self.tableau) do
      local lastCard = pile[#pile]
      local targetX = 100 + (i - 1) * 100
      local targetY = 100 + #pile * 30
      
      -- Check if released over this pile
      if x >= targetX and x <= targetX + 70 and y >= targetY - 30 and y <= targetY + 100 then
        if self:isLegalSpot(self.draggedCard, pile) then
          
          -- Move card from waste to tableau
          if self:isCardInWaste(self.draggedCard) then
            table.remove(self.waste, #self.waste)
          else
            -- Remove card from pile and flip over last card in pile
            for _, pile in ipairs(self.tableau) do
              for j = #pile, 1, -1 do
                if pile[j] == self.draggedCard then
                  table.remove(pile, j)
                  
                  if #pile > 0 then
                    pile[#pile].faceUp = true;
                  end
                  break
                end
              end
            end
          end
          
          -- Insert card into pile if in a legal spot and snap to line up with other cards
          self.draggedCard.x = targetX
          self.draggedCard.y = targetY
          table.insert(pile, self.draggedCard)
          self.draggedCard.wasWaste = false
          break
        else
          
          -- Move card back to waste pile and original position if in illegal spot
          -- For cards that are from the waste pile
          if self.draggedCard.wasWaste then
            self.draggedCard.x = self.draggedCard.baseX
            self.draggedCard.y = self.draggedCard.baseY
            table.insert(self.waste, #self.waste + 1, self.draggedCard)
            break
          else
            -- All other cards that are in illegal position but not from waste are moved back
            -- to origial position 
            self.draggedCard.x = self.draggedCard.prevX
            self.draggedCard.y = self.draggedCard.prevY
          end
        end
      end
      
      -- Move cards back to original position if moved to random place (not over pile)
      if self.draggedCard.wasWaste then
            self.draggedCard.x = self.draggedCard.baseX
            self.draggedCard.y = self.draggedCard.baseY
            table.insert(self.waste, #self.waste + 1, self.draggedCard)
            break
      else
        -- All other cards not from waste pile but dragged to somewhere random
        -- are moved back to their original position
        self.draggedCard.x = self.draggedCard.prevX
        self.draggedCard.y = self.draggedCard.prevY
      end
    end
  end

  self.draggedCard = nil
end

-- Check if card is in waste pile
function Board:isCardInWaste(card)
  for i = 1, #self.waste do
    if self.waste[i] == card then
      return true
    end
  end
  return false
end

-- Check if released card is in a legal spot
function Board:isLegalSpot(card, pile)
  if #pile == 0 then
    -- Check if king
    return card.value == 13
  else
    local topCard = pile[#pile]
    -- Check alternating color and descending rank
    return card.color ~= topCard.color and tonumber(card.value) == tonumber((topCard.value - 1))
  end
end

-- Obtain index of card within a table
function indexOfCard(cardTable, targetCard)
  for i, card in ipairs(cardTable) do
    if card == targetCard then
      return i
    end
  end
  return nil -- not found
end
