# Solitaire

## Programming Patterns
### State Pattern
#### Keeping track of where card is (stock, ace pile, waste, etc) was useful because the state of a card changes often when you move it to another place, so being able to simply check the state of the card took out some of the confusion when I was writing the release function code. Mainly used when a card is dropped in different locations and remembering where the card originally came from, such as the foundation pile, the waste pile, or a different pile in the tablaeu. This was also the only way I could get the release logic to work since I had issues with card positions being incorrectly assigned if I tried to combine the logic for all card states.

### Update Pattern
#### Checking the state of the board, and mainly checking for a win condition if all the foundation piles have a length of 13.

## Postmortem
#### If I had to do this assignment again, I would probably try and use the update pattern more and perhaps implement something like the grabber class from one of the class demos. The only reason why I didn't is because I looked up the documentation and found the mousepressed, mousemoved, and mousereleased functions and just decided to continue with those. I also would try and find a cleaner way to write the dropping cards logic since I took a more brute force route and there probably was some redundancy in parts of my code.

## Assets Used
### Card Assets: https://elvgames.itch.io/playing-cards-pixelart-asset-pack

## AI Assistance
### Dragging a stack in the tablaeu: https://chatgpt.com/share/67fddd5f-f910-8005-9bd4-b3758164374d

### Updating stack position to move with mouse cursor: https://chatgpt.com/share/67fddd71-daf8-8005-96c6-5612756a042c