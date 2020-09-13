pragma solidity >=0.5.0 <0.6.0;

// this is a rock-paper-scissors tournament
// players join, compete against one another until the tournament winner is declared
// players must commit their answers before revealing them
// there are time limits for each round
// after each tournament, a new one is automatically created; owner can change parameters

contract Game {

  // global position variable; used when players are joining
  uint position;

  // current game variables
  uint players;
  // amount of wins needed to win tournament (rounds) is linked to amount of players in tournament
  // e.g. if there are 16 players, player must win 4 games to win tournament
  uint rounds;
  // amount of time for players have each round to play, otherwise they automaticaly lose
  uint time;
  // entry fee for tournament; is distributed at end of tournament
  uint fee;

  // new game variables that take effect in the next tournament
  uint nPlayers;
  uint nRounds;
  uint nTime;
  uint nFee;

  address payable owner;

  // array holds all time limits
  uint[] public times;

  // mapping for storing hashes; players must hash their address, their sign (rock, paper or scissors = 1, 2 or 3) (uint)
  // and their secret (string variable)
  mapping (address => bytes32) commitments;

  // data structures
  // addresses maps to structs, addresses are stored in array
  mapping (address => player) public mPlayers;
  // array doesn't change size once all players have joined
  // instead, players are rearranged as tournament progresses
  // algoritim determines players' opponents as well as their new positions (if they win)
  address payable[] aPlayers;
  struct player {
    uint position;
    uint round;
    uint sign;
    bool commit;
  }

  // names owner and creates genisis tournament
  constructor() public {
    owner = msg.sender;

    nPlayers = 2;
    nRounds = 1;
    nTime = 3600;
    nFee = 0;

    advance();
  }


  modifier authority() {
    require(msg.sender == owner);
    _;
  }

  // allows owner to change tournament parameters (for next tournament)
  function update(uint _players, uint _rounds, uint _time, uint _fee) public authority {
    nPlayers = _players;
    nRounds = _rounds;
    nTime = _time;
    nFee = _fee;
  }


  // requires tournament to have room to join, players must have not joined beforehand
  // Ether sent must be correct amount
  modifier space() {
    require(position < players && mPlayers[msg.sender].position == 0 && msg.value == fee);
    _;
  }

  function join() public payable space {
    // players are assigned a position
    position++;
    mPlayers[msg.sender].position = position;

    // are added into the array (based on their position)
    aPlayers.push(msg.sender);

    // once all players have joined the tournament, time limits for all rounds are assigned
    if (position == players) {
      for (uint i = 1; i <= rounds; i++) {
        // if time limits are 60 seconds, time limit for round two will be 60 * 2 + now (current time)
        times.push(time * i + now);
      }
    }
  }


  // if player's position is zero, they are disqualified
  // can only commit once and must be within time limit for their round
  modifier ready() {
    require(mPlayers[msg.sender].position != 0 && mPlayers[msg.sender].commit == false && times[mPlayers[msg.sender].round] > now);
    _;
  }

  // stores hash, updates player's struct
  function commit(bytes32 _commitment) public ready {
    commitments[msg.sender] = _commitment;
    mPlayers[msg.sender].commit = true;
  }

  // must have committed
  modifier right() {
    require(mPlayers[msg.sender].commit == true);
    _;
  }

  // commit and reveal scheme:
  // player must send sign and secret, address is obtained through msg.sender
  // thus players cannot copy another player's hash; must be unique as player cannot fake having an address of another player
  function play(uint _sign, string memory _secret) public right {
    // must be one of three possibilities (rock, paper or scissors)
    if (_sign == 1 || _sign == 2 || _sign == 3) {

      // finds opponent
      address payable adversary = find(msg.sender);

      // if opponent has committed and answer matches with hash, player's sign is stored
      if (mPlayers[adversary].commit == true && keccak256(abi.encodePacked(msg.sender, _sign, _secret)) == commitments[msg.sender]) {

        mPlayers[msg.sender].sign = _sign;

        // if opponent has already played, the outcome of the game is determined
        if (mPlayers[adversary].sign != 0) {
          // determines the winner of the rock-paper-scissors game
          uint result = who(_sign, mPlayers[adversary].sign);

          // tie game, players' signs (and commits) are reset (allowing them to play again)
          if (result == 0) {
            mPlayers[msg.sender].sign = 0;
            mPlayers[msg.sender].commit = false;
            mPlayers[adversary].sign = 0;
            mPlayers[adversary].commit = false;
            // player wins
          } else if (result == 1) {
            update(msg.sender, adversary);
            // opponent wins
          } else {
            update(adversary, msg.sender);
          }
        }
      }
    }
  }


  // ensures time limit has passed
  modifier honest() {
    require(times[mPlayers[msg.sender].round] < now);
    _;
  }

  // if player's opponent has yet to commit or play, and the player has, they win automatically
  function automatic() public honest {
    address payable adversary = find(msg.sender);
    // player has committed, opponent has not
    if (mPlayers[adversary].commit == false && mPlayers[msg.sender].commit == true) {
      update(msg.sender, adversary);
    // player has played, opponent has not
    } else if (mPlayers[adversary].sign == 0 && mPlayers[msg.sender].sign != 0) {
      update(msg.sender, adversary);
    }
  }



  // advances the winner, disqualifies the loser
  function update(address payable _winner, address payable _loser) internal {
    // variables for determining whether player position is even or odd
    // from this their new position is determined
    uint x = mPlayers[_winner].position;
    uint y = mPlayers[_winner].round;
    uint z = (x - 1) / 2 ** y + 1;

    mPlayers[_winner].round++;

    // if player has won the tournament, the player receives the prize, the tournament is cleared
    // and a new tournament is created
    if (mPlayers[_winner].round == rounds) {
      // can change the distribution of the prize (e.g. owner takes 25% cut)
      _winner.transfer(fee * players);

      clear();
      advance();

    } else {
      // player's position only changes if it is even, otherwise it stays the same
      if (z % 2 == 0) {
        mPlayers[_winner].position = x - 2 ** y;
        // must subtract one from position because arrays start from zero
        aPlayers[(x - 2 ** y) - 1] = _winner;
      }
      // player's sign and commit is reset
      mPlayers[_winner].sign = 0;
      mPlayers[_winner].commit = false;

      // loser is disqualified
      mPlayers[_loser].position = 0;
    }
  }

  // for finding player's opponent, receives player's address and returns opponent's address
  function find(address payable _player) internal view returns (address payable) {
    // same as above: used to determine whether player's position is even or odd
    uint x = mPlayers[_player].position;
    uint y = mPlayers[_player].round;
    uint z = (x - 1) / 2 ** y + 1;

    uint opponent;

    // even number, opponent's position is 2 ** y (player's round) less than player's position
    if (z % 2 == 0) {
      // subtract one for array
      opponent = (x - 2 ** y) - 1;
      // odd number, opponent's position is 2 ** y more
    } else {
      opponent = (x + 2 ** y) - 1;
    }

    // opponent must be in same round as player
    if (mPlayers[aPlayers[opponent]].round == y) {
      return aPlayers[opponent];
    }
  }

  // clears all relevant arrays and mappings for new tournament
  function clear() internal {
    // for deleting mapping, iteration is required
    for (uint i = 0; i < aPlayers.length; i++) {
      delete mPlayers[aPlayers[i]];
    }
    delete aPlayers;
    delete times;
  }

  // creates the new tournament, is automatically called at the end of a tournament
  function advance() internal {
    // n variables remain the same, unless owner has changed them
    // if so, new tournament will run with new variables
    players = nPlayers;
    rounds = nRounds;
    time = nTime;
    fee = nFee;

    // global variable is reset
    position = 0;
  }

  // logic for determining winner of rock-paper-scissors game
  // e.g. 1 beats 3 or rock beats scissors
  function who(uint _one, uint _two) internal pure returns (uint) {
    if (_one == 1 && _two == 1) {
      return 0;
    } else if (_one == 1 && _two == 2) {
      return 2;
    } else if (_one == 1 && _two == 3) {
      return 1;
    } else if (_one == 2 && _two == 1) {
      return 1;
    } else if (_one == 2 && _two == 2) {
      return 0;
    } else if (_one == 2 && _two == 3) {
      return 2;
    } else if (_one == 3 && _two == 1) {
      return 2;
    } else if (_one == 3 && _two == 2) {
      return 1;
    } else if (_one == 3 && _two == 3) {
      return 0;
    }
  }
}
