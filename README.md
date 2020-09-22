# Rock-Paper-Scissors Tournament

**This is a Rock-Paper-Scissors Tournament on Ethereum.** Ethereum's inherent properties make it ideal for blockchain gaming; this smart contract takes full advantage of these properties. Users can play, knowing that what is written in the smart contract will occur. This is especially important considering users can play for money in this tournament; there is an entry fee for the tournament and a prize for the tournament winner. 

In this rock-paper-scissors tournament, there are time limits, a commit and reveal scheme and an option to change tournament parameters. The smart contract has been extensively tested in Remix (Ethereum IDE). 

## The functions

### Join
Players can join the tournament if there is room available.

### Commit
Part of the commit and reveal scheme; allows players to send the hash of their address, sign (rock, paper or scissors) and their secret. This is for security purposes; to ensure players cannot know what their opponent has played.

### Play
Allows players to send their sign (and secret). After ensuring their information matches with their hash, the smart contract stores this. If a player's opponent has already sent their sign, the winner is declared. The winner then advances in the tournament and the loser is disqualified.

### Automatic
Players can call this if the time limit (for their round) has passed and their opponent hasn't sent their sign (or hash). If these two conditions are filled, the player automatically wins the game and advances in tournament.

### Update
Only the contract owner can call this function; allows owner to change tournament parameters such as players in tournament, time limits for each round (e.g. 60 seconds), and entry fees. Changes only execute at the end of the current tournament; a new tournament is automatically created at the end of the previous tournament.

## Additional Files
In addition to the smart contract, a python program is included; it's purpose is to test the smart contract. It hashes a player's address, their sign and their secret.

