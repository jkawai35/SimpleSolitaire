# Solitaire

## Programming Patterns
### State Pattern
#### Keeping track of where card is (stock, ace pile, waste, etc) was useful because the state of a card changes often when you move it to another place, so being able to simply check the state of the card took out some of the confusion when I was writing the release function code. Mainly used when a card is dropped in different locations and remembering where the card originally came from, such as the foundation pile, the waste pile, or a different pile in the tablaeu. This was also the only way I could get the release logic to work since I had issues with card positions being incorrectly assigned if I tried to combine the logic for all card states.

### Update Pattern
#### Checking the state of the board, and mainly checking for a win condition if all the foundation piles have a length of 13.

### Feedback
#### Tapesh Sankaran - Suggested avoiding string comparisions such as "Hearts" == "Hearts," so an enum-type system was implemented to avoid possible bugs with spelling errors. The same applied for the state of a card and what color it is.

## Postmortem
#### Overall, I think my refactoring made the program a lot more readable. Originally, my release and picking up logic was very long and all done within one function, now those functions are much shorter and understandable. In general, my functions got smaller, however there are more functions in the program because I wrote many helper functions that were reused. I think the quality of life changes, such as avoiding direct string comparisions also added to the readability of my program.

## Assets Used
### Card Assets: https://elvgames.itch.io/playing-cards-pixelart-asset-pack

## AI Assistance
### Dragging a stack in the tablaeu: https://chatgpt.com/share/67fddd5f-f910-8005-9bd4-b3758164374d

### Updating stack position to move with mouse cursor: https://chatgpt.com/share/67fddd71-daf8-8005-96c6-5612756a042c