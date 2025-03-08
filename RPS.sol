// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.2 <0.9.0;

// นำเข้า CommitReveal และ TimeUnit
import "./CommitReveal.sol";
import "./TimeUnit.sol";

contract RPSGame is CommitReveal, TimeUnit {
    uint public numPlayer = 0;
    uint public reward = 0;
    mapping(address => bytes32) public playerCommit; 
    mapping(address => uint) public playerChoice;
    mapping(address => bool) public hasRevealed;
    address[] public players;
    uint public revealDeadline;

    address[4] private allowedPlayers = [
        0x5B38Da6a701c568545dCfcB03FcB875f56beddC4,
        0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2,
        0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db,
        0x78731D3Ca6b7E34aC0F824c42a7cC18A495cabaB
    ];

    modifier onlyAllowedPlayers() {
        bool allowed = false;
        for (uint i = 0; i < allowedPlayers.length; i++) {
            if (msg.sender == allowedPlayers[i]) {
                allowed = true;
                break;
            }
        }
        require(allowed, "Not an allowed player");
        _;
    }

    function addPlayer(bytes32 commitHash) public payable onlyAllowedPlayers {
        require(numPlayer < 2, "Game is full");
        require(msg.value == 1 ether, "Must send exactly 1 ether");
        if (numPlayer > 0) require(msg.sender != players[0], "Same player twice");
        
        reward += msg.value;
        players.push(msg.sender);
        playerCommit[msg.sender] = commitHash;
        numPlayer++;

        if (numPlayer == 2) {
            revealDeadline = block.timestamp + 5 minutes;
        }
    }

    function revealChoice(uint choice, bytes32 secret) public {
        require(numPlayer == 2, "Game not ready");
        require(!hasRevealed[msg.sender], "Already revealed");
        require(getHash(keccak256(abi.encodePacked(choice, secret))) == playerCommit[msg.sender], "Invalid reveal");

        playerChoice[msg.sender] = choice;
        hasRevealed[msg.sender] = true;

        if (hasRevealed[players[0]] && hasRevealed[players[1]]) {
            _checkWinnerAndPay();
        }
    }

    function _checkWinnerAndPay() private {
        uint p0 = playerChoice[players[0]];
        uint p1 = playerChoice[players[1]];
        address payable player0 = payable(players[0]);
        address payable player1 = payable(players[1]);

        if ((p0 + 1) % 3 == p1) {
            player1.transfer(reward);
        } else if ((p1 + 1) % 3 == p0) {
            player0.transfer(reward);
        } else {
            player0.transfer(reward / 2);
            player1.transfer(reward / 2);
        }

        _resetGame();
    }

    function _resetGame() private {
        numPlayer = 0;
        reward = 0;
        delete players;
    }

    function forceWithdraw() public {
        require(numPlayer == 1 || (numPlayer == 2 && block.timestamp > revealDeadline), "Cannot withdraw yet");

        if (numPlayer == 1) {
            payable(players[0]).transfer(reward);
        } else {
            if (hasRevealed[players[0]]) {
                payable(players[0]).transfer(reward);
            } else if (hasRevealed[players[1]]) {
                payable(players[1]).transfer(reward);
            }
        }
        _resetGame();
    }
}


