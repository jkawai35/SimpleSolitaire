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

  -- Create tableau
  for i = 1, 7 do
    board.tableau[i] = {}

    for j = 1, i do
      local card = table.remove(deck.cards)
      card.x = 100 + (i - 1) * 100
      card.y = 100 + (j - 1) * 30
      card.faceUp = (j == i)
      table.insert(board.tableau[i], card)
      card.state = "TABLEAU"
    end
  end
  
  -- Insert leftover cards into stock
  for _, card in ipairs(deck.cards) do
    card.faceUp = false
    table.insert(board.stock, card)
    card.state = "STOCK"
  end

  deck.cards = nil

  return board
end
 
function Board:update()
  local counter = 0
  for _, pile in ipairs(self.foundations) do
    if #pile == 13 then
      counter = counter + 1
    else
      counter = 0
      break
    end
  end

  if counter == 4 then
    self.win = true
  end
end

function Board:draw()
  
  -- Check win condition
  if self.win then
    love.graphics.setColor(1, 1, 1) -- white text
    love.graphics.printf("YOU WIN!", 0, 300, 800, "center")
  end
  
  -- Draw card stack markers
  love.graphics.draw(blankStack, board.foundationPositions[1].x, board.foundationPositions[1].y)
  love.graphics.draw(blankStack, board.foundationPositions[2].x, board.foundationPositions[2].y)
  love.graphics.draw(blankStack, board.foundationPositions[3].x, board.foundationPositions[3].y)
  love.graphics.draw(blankStack, board.foundationPositions[4].x, board.foundationPositions[4].y)
  love.graphics.draw(blankStack, 100, 100)
  love.graphics.draw(blankStack, 200, 100)
  love.graphics.draw(blankStack, 300, 100)
  love.graphics.draw(blankStack, 400, 100)
  love.graphics.draw(blankStack, 500, 100)
  love.graphics.draw(blankStack, 600, 100)
  love.graphics.draw(blankStack, 700, 100)

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
      card.state = "WASTE"
    end
  else
    -- Refill stock pile if empty, allow for redrawing
    for i = #self.waste, 1, -1 do
        local card = table.remove(self.waste, i)
        card.faceUp = false
        table.insert(self.stock, 1, card)
        card.state = "STOCK"
    end
  end
end

function Board:mousepressed(x, y, button)
  if button == 1 then  -- left click
    
    -- Check tableau piles from top to bottom
    for pileIndex = 1, #self.tableau do
      local pile = self.tableau[pileIndex]
      for i = #pile, 1, -1 do
        local card = pile[i]

        -- Check if click occurs within the bounds of a card in the tableau
        if card.faceUp and x >= card.x and x <= card.x + 70 and y >= card.y and y <= card.y + 100 then
          self.draggedCard = card
          self.dragOffsetX = x - card.x
          self.dragOffsetY = y - card.y
          self.draggedCard.prevX = card.x
          self.draggedCard.prevY = card.y
          
          -- Add cards under picked card to drag a stack
          self.draggedStack = {}
          for r = i, #pile do
            table.insert(self.draggedStack, pile[r])
          end
          
          -- Keep track of the pile dragged from
          self.draggedFromPile = pileIndex
          return
        end
      end
    end
    
    -- Dragging cards from waste pile
    if #self.waste > 0 then
      local card = self.waste[#self.waste]
      
      -- Check if card from the waste pile is clicked on
      -- Remove card from table if clicked in appropriate  area
      if card.faceUp and x >= card.x and x <= card.x + 70 and y >= card.y and y <= card.y + 100 then
        self.draggedCard = card
        self.dragOffsetX = x - card.x
        self.dragOffsetY = y - card.y        
        self.draggedCard.prevX = card.x
        self.draggedCard.prevY = card.y
        
        table.remove(self.waste, #self.waste)

        self.draggedStack = nil
        self.draggedFromPile = nil
        return
      end
    end
    
    -- Check if any of the cards from the foundation piles are picked
    -- Remove card from table if clicked in appropriate area
    for i, foundation in ipairs(self.foundations) do
      local topCard = foundation[#foundation]
        if topCard and x >= topCard.x and x <= topCard.x + 70 and y >= topCard.y and y <= topCard.y + 100 then
          self.draggedCard = topCard
          self.dragOffsetX = x - topCard.x
          self.dragOffsetY = y - topCard.y
          self.draggedCard.prevX = topCard.x
          self.draggedCard.prevY = topCard.y
          self.draggedFromFoundation = foundation
          table.remove(foundation, #foundation)
          
          self.draggedStack = nil
          self.draggedFromPile = nil
          return
        end
    end
  end
end

-- Moving cards
function Board:mousemoved(x, y, dx, dy)
  if self.draggedCard then
    self.draggedCard.x = x - self.dragOffsetX
    self.draggedCard.y = y - self.dragOffsetY
  elseif self.draggedStack then
    for index, card in ipairs(self.draggedStack) do
      card.x = x - self.dragOffsetX
      card.y = y - self.dragOffsetY + (index - 1) * 30
    end
  end
end

-- Release mouse click logic
function Board:mousereleased(x, y, button)
  if button == 1 and self.draggedCard then

    -- Handle cards from waste pile
    if self.draggedCard.state == "WASTE" then
      -- Assume illegal drop
      local badDrop = true

      -- Checking each pile in tablaeu and inserting card/stack if legal placement
      -- Update positions of cards and change state if legal placement
      for i, pile in ipairs(self.tableau) do
        local targetX = 100 + (i - 1) * 100
        local targetY = 100 + #pile * 30

        if x >= targetX and x <= targetX + 70 and y >= targetY - 30 and y <= targetY + 100 then
          if self:isLegalSpot(self.draggedCard, pile) then
            self.draggedCard.x = targetX
            self.draggedCard.y = targetY
            self.draggedCard.prevX = targetX
            self.draggedCard.prevY = targetY
            table.insert(pile, self.draggedCard)
            self.draggedCard.state = "TABLEAU"
            badDrop = false
            break
          end
        end
      end
      
      -- Checking placement into foundation piles
      -- Update positions of cards and change state if legal placement
      for l, foundation in ipairs(self.foundations) do
        local pos = self.foundationPositions[l]
        if x >= pos.x and x <= pos.x + 70 and y >= pos.y and y <= pos.y + 100 then
          if self:legalFoundation(self.draggedCard, foundation) then
            self.draggedCard.x = pos.x
            self.draggedCard.y = pos.y
            self.draggedCard.prevX = pos.x
            self.draggedCard.prevY = pos.y
            table.insert(foundation, self.draggedCard)
            self.draggedCard.state ="ACE"
            badDrop = false
            break
          end
        end
      end

      -- If illegal drop or not placed over a pile then add back to waste pile
      if badDrop then
        self.draggedCard.x = self.draggedCard.baseX
        self.draggedCard.y = self.draggedCard.baseY
        table.insert(self.waste, self.draggedCard)
        self.draggedCard.state = "WASTE"
      end
      
    -- Checking placement of cards that came from foundation piles
    elseif self.draggedCard.state == "ACE" then
      local badDrop = true

      -- Check if legal placement into tablaeu
      -- Update positions and change state as before with waste pile cards
      for i, pile in ipairs(self.tableau) do
        local targetX = 100 + (i - 1) * 100
        local targetY = 100 + #pile * 30

        if x >= targetX and x <= targetX + 70 and y >= targetY - 30 and y <= targetY + 100 then
          if self:isLegalSpot(self.draggedCard, pile) then
            self.draggedCard.x = targetX
            self.draggedCard.y = targetY
            self.draggedCard.prevX = targetX
            self.draggedCard.prevY = targetY
            table.insert(pile, self.draggedCard)
            self.draggedCard.state = "TABLEAU"
            badDrop = false
            break
          end
        end
      end
      
      -- Check if legal placement into foundation piles
      -- Update positions and change state as before with waste pile cards
      for l, foundation in ipairs(self.foundations) do
        local pos = self.foundationPositions[l]
        if x >= pos.x and x <= pos.x + 70 and y >= pos.y and y <= pos.y + 100 then
          if self:legalFoundation(self.draggedCard, foundation) then
            self.draggedCard.x = pos.x
            self.draggedCard.y = pos.y
            table.insert(foundation, self.draggedCard)
            self.draggedCard.state = "ACE"
            badDrop = false
            break
          end
        end
      end

      -- Reset position and put back into correct foundation pile if illegal placement
      if badDrop then
        self.draggedCard.x = self.draggedCard.prevX
        self.draggedCard.y = self.draggedCard.prevY
        table.insert(self.draggedFromFoundation, self.draggedCard)
        
      end

    else
      -- Handle tableau-to-tableau movement
      local badDrop = true

      -- Check if placement into another pile is legal
      -- Update positions and state as before
      for i, pile in ipairs(self.tableau) do
        local targetX = 100 + (i - 1) * 100
        local targetY = 100 + #pile * 30

        -- Check which pile card is being placed into
        -- Remove dragged stack from the original pile if legal placement
        -- Make sure last card in original pile is face up
        -- Update positions
        if x >= targetX and x <= targetX + 70 and y >= targetY - 30 and y <= targetY + 100 and self.draggedCard.state ~= "ACE"  and self.draggedCard ~= "WASTE" then
          if self:isLegalSpot(self.draggedCard, pile) then
            local originalPile = self.tableau[self.draggedFromPile]
            for j = #originalPile, 1, -1 do
              if originalPile[j] == self.draggedStack[1] then
                for _ = j, #originalPile do
                  table.remove(originalPile, j)
                end
                if #originalPile > 0 then
                  originalPile[#originalPile].faceUp = true
                end
                break
              end
            end

            -- Add draggedStack to new pile and reposition
            for index, card in ipairs(self.draggedStack) do
              card.x = targetX
              card.y = targetY + (index - 1) * 30
              card.prevX = targetX
              card.prevY = targetY + (index - 1) * 30
              table.insert(pile, card)
              card.state = "TABLEAU"
            end
            badDrop = false
            break
          end
        end
        
        -- Check if placement into foundation pile
        -- Remove card from original pile if legal placement
        -- Make sure last card in original pile is now face up
        -- Update positions and change states
        for l, foundation in ipairs(self.foundations) do
            local pos = self.foundationPositions[l]
            if x >= pos.x and x <= pos.x + 70 and y >= pos.y and y <= pos.y + 100 then
              if self:legalFoundation(self.draggedCard, foundation) then
                local sourcePile = self.tableau[self.draggedFromPile]
                for j = #sourcePile, 1, -1 do
                  if sourcePile[j] == self.draggedCard then
                    table.remove(sourcePile, j)

                    -- Flip the new top card if needed
                    if #sourcePile > 0 then
                      sourcePile[#sourcePile].faceUp = true
                    end
                    break
                  end
                end
                self.draggedCard.x = pos.x
                self.draggedCard.y = pos.y
                table.insert(foundation, self.draggedCard)
                self.draggedCard.state = "ACE"
                badDrop = false
              end
            end
          end
      end

      -- If not dropped legally, restore positions
      if badDrop then
        for index, card in ipairs(self.draggedStack or {self.draggedCard}) do
          card.x = card.prevX
          card.y = card.prevY
        end
      end
    end
  end

  -- Reset drag state
  self.draggedCard = nil
  self.draggedStack = nil
  self.draggedFromPile = nil
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
  -- Check if pile is empty
  if #pile == 0 then
    -- Check if king
    return tonumber(card.value) == 13
  else
    local topCard = pile[#pile]
    -- Check alternating color and descending rank
    return card.color ~= topCard.color and tonumber(card.value) == tonumber((topCard.value - 1))
  end
end

-- Check if card is placed in a legal foundation pile
function Board:legalFoundation(card, foundation)
  -- Check if foundation is empty and if card is an ace
  if #foundation == 0 then
    if tonumber(card.value) == 1 then
      return true
    end
    return false
  else
    local topCard = foundation[#foundation]
    return topCard.suit == card.suit and tonumber(card.value) == tonumber((topCard.value + 1))
  end
end
