require("card")

Board = {}
Board.__index = Board

function Board:new(deck)
  local board = {}
  setmetatable(board, Board)

  board.tableau = {}
  board.stock = {}
  board.waste = {}
  board.foundations = {
    {}, {}, {}, {}
  }
  board.foundationPositions = {
    {x = 400, y = 3},
    {x = 500, y = 3},
    {x = 600, y = 3},
    {x = 700, y = 3}
  }
  board.draggedStack = nil
  
  board.draggedCard = nil
  board.dragOffsetX = 0
  board.dragOffsetY = 0
  
  blankStack = love.graphics.newImage("/Sprites/Card Back 3.png")

  self:createTableau(board)
  
  return board
end
 
function Board:update()
  local counter = 0
  for _, pile in ipairs(self.foundations) do
    if #pile == 13 then
      counter = counter + 1
    end
  end

  if counter == 4 then
    self.win = true
  end
end

function Board:draw()
  
  -- Check win condition
  if self.win then
    love.graphics.setFont(love.graphics.newFont(48))
    love.graphics.setColor(1, 1, 1) -- white text
    love.graphics.printf("YOU WIN!", 0, 250, 800, "center")
  end
  
  -- Draw card stack markers
  for i = 1, 4 do
    love.graphics.draw(blankStack, board.foundationPositions[i].x, board.foundationPositions[i].y)
    love.graphics.draw(blankStack, i * 100, 100)
  end

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
    love.graphics.setColor(0.4, 0.4, 0.4)
    love.graphics.rectangle("line", 15, 16, 50, 80)
    love.graphics.setColor(1, 1, 1)
  end

  -- Draw waste cards in groups of 3
  if #self.waste > 0 then
    -- Draw top 3 waste cards, fanned out to the right of the stock
    -- Offset is for the fan effect so you can see top 3 cards
    -- baseX and baseY are starter positions and you add offset to baseX to make fan effect
    -- Offset index tracks how many offsets away from the base a card has to be placed
    local offset = 20 
    local baseX = 100
    local baseY = 3
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
  
  -- Draw top card of ace piles if they exist
  for i, pile in ipairs(self.foundations) do
    local pos = self.foundationPositions[i]
    if #pile > 0 then
      pile[#pile]:draw(pos.x, pos.y)
    end
  end

  -- Redraw dragged card if moved
  if self.draggedCard then
    self.draggedCard:draw(self.draggedCard.x, self.draggedCard.y)
  end
  
  -- Redraw stack if stacks of cards are moved
  if self.draggedStack then
    for _, card in ipairs(self.draggedStack) do
      card:draw(card.x, card.y)
    end
  end
  
end

-- Drawing cards from stock and adding to waste table
function Board:drawFromStock()
  -- Update waste pile when cards are drawn
  if #self.stock > 0 then
    local drawCount = math.min(3, #self.stock)
    for i = 1, drawCount do
      local card = table.remove(self.stock)
      card.faceUp = true
      table.insert(self.waste, card)
      card.state = STATE_ENUM.WASTE
    end
  else
    -- Refill stock pile if empty, allow for redrawing
    for i = #self.waste, 1, -1 do
        local card = table.remove(self.waste, i)
        card.faceUp = false
        table.insert(self.stock, 1, card)
        card.state = STATE_ENUM.STOCK
    end
  end
end

-- Picking up cards
function Board:mousepressed(x, y, button)
  if button == 1 then 
    if self:tryPickTableauCard(x, y) then return end
    if self:tryPickWasteCard(x, y) then return end
    if self:tryPickFoundationCard(x, y) then return end
  end
end

-- Moving cards
function Board:mousemoved(x, y, dx, dy)
  if self.draggedCard and (self.draggedCard.state == STATE_ENUM.WASTE or self.draggedCard.state == STATE_ENUM.ACE) then
    self.draggedCard.x = x - self.dragOffsetX
    self.draggedCard.y = y - self.dragOffsetY
  elseif self.draggedStack then
    for index, card in ipairs(self.draggedStack) do
      card.x = x - self.dragOffsetX
      card.y = y - self.dragOffsetY + (index - 1) * 30
    end
  end
end

-- Release logic
-- Update cards or stacks based on where they are dropped
function Board:mousereleased(x, y, button)
  if button ~= 1 or not self.draggedCard then return end

  local state = self.draggedCard.state
  local handled = false

  if state == STATE_ENUM.WASTE then
    handled = self:handleWasteRelease(x, y)
  elseif state == STATE_ENUM.ACE then
    handled = self:handleFoundationRelease(x, y)
  else
    handled = self:handleTableauRelease(x, y)
  end

  if not handled then
    self:restoreDraggedCards()
  end

  self:resetDragState()
end

-- HELPER FUNCTIONS --

-- Check if released card is in a legal spot
function Board:isLegalSpot(card, pile)
  -- Check if pile is empty
  if #pile == 0 then
    -- Check if king
    return card.value == 13
  else
    local topCard = pile[#pile]
    -- Check alternating color and descending rank
    return card.color ~= topCard.color and card.value == topCard.value - 1
  end
end

-- Check if card is placed in a legal foundation pile
function Board:legalFoundation(card, foundation)
  -- Check if foundation is empty and if card is an ace
  if #foundation == 0 then
    if card.value == 1 then
      return true
    end
    return false
  else
    local topCard = foundation[#foundation]
    return topCard.suit == card.suit and card.value == topCard.value + 1
  end
end

-- Update card position
function Board:updatePosition(card, pile, targetX, targetY)
  card.x = targetX
  card.y = targetY
  card.prevX = targetX
  card.prevY = targetY
  table.insert(pile, card)
end

-- Update offset when card is dragged
function Board:updateOffset(x, y, newCard)
  self.draggedCard = newCard
  self.dragOffsetX = x - newCard.x
  self.dragOffsetY = y - newCard.y
  self.draggedCard.prevX = newCard.x
  self.draggedCard.prevY = newCard.y
end

-- Picking up card from Tableau
function Board:tryPickTableauCard(x, y)
  -- Check tableau piles from top to bottom
  for pileIndex, pile in ipairs(self.tableau) do
    for i = #pile, 1, -1 do
      local card = pile[i]

      -- Check if click occurs within the bounds of a card in the tableau
      if card.faceUp and x >= card.x and self:checkInBounds(card, x, y) then
        self:updateOffset(x, y, card)
        
        -- Add cards under picked card to drag a stack
        self.draggedStack = {}
        for r = i, #pile do
          table.insert(self.draggedStack, pile[r])
        end
        
        -- Keep track of the pile dragged from
        self.draggedFromPile = pileIndex
        return true
      end
    end
  end

  return false
  end
  
-- Picking up card from waste pile
function Board:tryPickWasteCard(x, y)
  local card = self.waste[#self.waste]
  if card and card.faceUp and self:checkInBounds(card, x, y) then
    self:updateOffset(x, y, card)
    table.remove(self.waste)
    self.draggedStack = nil
    self.draggedFromPile = nil
    return true
  end
  return false
end

-- Picking up card from foundation pile
function Board:tryPickFoundationCard(x, y)
  for i, foundation in ipairs(self.foundations) do
    local topCard = foundation[#foundation]
    if topCard and self:checkInBounds(topCard, x, y) then
      self:updateOffset(x, y, topCard)
      self.draggedFromFoundation = foundation
      table.remove(foundation)
      self.draggedStack = nil
      self.draggedFromPile = nil
      return true
    end
  end
  return false
end
  
-- Check if clicking within the bounds of a card
function Board:checkInBounds(card, x, y)
  return  x <= card.x + 70 and y >= card.y and y <= card.y + 100
end

-- Reset dragged card/pile variables
function Board:resetDragState()
  self.draggedCard = nil
  self.draggedStack = nil
  self.draggedFromPile = nil
  self.draggedFromFoundation = nil
end

-- Put card back to original position
-- Reset state if needed
function Board:restoreDraggedCards()
  for _, card in ipairs(self.draggedStack or {self.draggedCard}) do
    card.x = card.prevX
    card.y = card.prevY
  end

  if self.draggedCard.state == STATE_ENUM.WASTE then
    table.insert(self.waste, self.draggedCard)
  elseif self.draggedCard.state == STATE_ENUM.ACE and self.draggedFromFoundation then
    table.insert(self.draggedFromFoundation, self.draggedCard)
  end
end

-- Checking release over card area
function Board:isOverArea(x, y, areaX, areaY)
  return x >= areaX and x <= areaX + 70 and y >= areaY - 30 and y <= areaY + 100
end

-- Release card from waste
function Board:handleWasteRelease(x, y)
  return self:tryPlaceOnTableau(self.draggedCard, x, y) or self:tryPlaceOnFoundation(self.draggedCard, x, y)
end

-- Release card from foundation
function Board:handleFoundationRelease(x, y)
  return self:tryPlaceOnTableau(self.draggedCard, x, y) or self:tryPlaceOnFoundation(self.draggedCard, x, y)
end

-- Release card from tableau
function Board:handleTableauRelease(x, y)
  return self:tryPlaceStackOnTableau(x, y) or self:tryPlaceCardOnFoundation(x, y)
end

-- Placing card on tableau
function Board:tryPlaceOnTableau(card, x, y)
  -- Checking each pile in tablaeu and inserting card/stack if legal placement
  -- Update positions of cards and change state if legal placement
  for i, pile in ipairs(self.tableau) do
    local targetX = 100 + (i - 1) * 100
    local targetY = 100 + #pile * 30

    if self:isOverArea(x, y, targetX, targetY) and self:isLegalSpot(card, pile) then
      self:updatePosition(card, pile, targetX, targetY)
      card.state = STATE_ENUM.TABLEAU
      return true
    end
  end

  return false
end

-- Placeing card on foundation
function Board:tryPlaceOnFoundation(card, x, y)
  -- Check if legal placement into foundation piles
  -- Update positions and change state as before with waste pile cards
  for i, foundation in ipairs(self.foundations) do
    local pos = self.foundationPositions[i]
    if self:isOverArea(x, y, pos.x, pos.y) and self:legalFoundation(card, foundation) then
      self:updatePosition(card, foundation, pos.x, pos.y)
      self.draggedCard.state = STATE_ENUM.ACE
      return true
    end
  end
  
  return false
end

--  Placing stack on tableau
function Board:tryPlaceStackOnTableau(x, y)
  for i, pile in ipairs(self.tableau) do
    local targetX = 100 + (i - 1) * 100
    local targetY = 100 + #pile * 30
    
    if self:isOverArea(x, y, targetX, targetY) and self:isLegalSpot(self.draggedCard, pile) then
      local originalPile = self.tableau[self.draggedFromPile]
      self:removeStackFromPile(originalPile)
      self:addStackToPile(pile, targetX, targetY)
      return true
    end
  end
  return false
end

-- Placing card on foundation
function Board:tryPlaceCardOnFoundation(x, y)
  for i, foundation in ipairs(self.foundations) do
    local pos = self.foundationPositions[i]
    if self:isOverArea(x, y, pos.x, pos.y) and self:legalFoundation(self.draggedCard, foundation) then
      local sourcePile = self.tableau[self.draggedFromPile]
      self:removeCardFromPile(sourcePile, self.draggedCard)
      self:updatePosition(self.draggedCard, foundation, pos.x, pos.y)
      self.draggedCard.state = STATE_ENUM.ACE
      return true
    end
  end
  return false
end

function Board:removeStackFromPile(pile)
  for i = #pile, 1, -1 do
    if pile[i] == self.draggedStack[1] then
      for _ = i, #pile do
        table.remove(pile, i)
      end
      if #pile > 0 then
        pile[#pile].faceUp = true
      end
      break
    end
  end
end

-- Add stack to tableau pile
function Board:addStackToPile(pile, baseX, baseY)
  for i, card in ipairs(self.draggedStack) do
    local offsetY = (i - 1) * 30
    card.x, card.y = baseX, baseY + offsetY
    card.prevX, card.prevY = baseX, baseY + offsetY
    card.state = STATE_ENUM.TABLEAU
    table.insert(pile, card)
  end
end

-- Remove a card from a given pile
function Board:removeCardFromPile(pile, card)
  for i = #pile, 1, -1 do
    if pile[i] == card then
      table.remove(pile, i)
      if #pile > 0 then
        pile[#pile].faceUp = true
      end
      break
    end
  end
end

-- For creating tableau at beginning of game
function Board:createTableau(board)
    -- Create tableau
  for i = 1, 7 do
    board.tableau[i] = {}

    for j = 1, i do
      local card = table.remove(deck.cards)
      card.x = 100 + (i - 1) * 100
      card.y = 100 + (j - 1) * 30
      card.faceUp = (j == i)
      table.insert(board.tableau[i], card)
      card.state = STATE_ENUM.TABLEAU
    end
  end
  
  -- Insert leftover cards into stock
  for _, card in ipairs(deck.cards) do
    card.faceUp = false
    table.insert(board.stock, card)
    card.state = STATE_ENUM.TABLEAU
  end

  deck.cards = nil
  
end

