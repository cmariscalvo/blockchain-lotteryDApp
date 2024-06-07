// SPDX-License-Identifier: MIT

// Info on VRF: https://docs.chain.link/vrf/v2-5/getting-started
// Info on Keepers: https://docs.chain.link/chainlink-automation/guides/compatible-contracts

pragma solidity ^0.8.7;

error Raffle__NotEnoughETHEntered();
error Raffle_TransferFailed();
error Raffle_NotOpen();
error Raffle__UpkeepNotNeeded(uint256 currentBalance, uint256 numPlayers, uint256 raffleState);

/** @title A sample lottery contract
  * @author Christian Mariscal
  * @notice This contract creates an untamperable decentralized smart contract.
  * @dev Implements Chainlink VRF v2 and Chainlink Keepers
 */

import "@chainlink/contracts/src/v0.8/vrf/VRFConsumerBaseV2.sol";
import "@chainlink/contracts/src/v0.8/vrf/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/automation/interfaces/AutomationCompatibleInterface.sol";

contract Raffle is VRFConsumerBaseV2, AutomationCompatibleInterface{
    /* Type declarations */
    enum RaffleState{OPEN,CALCULATING}

    /* State variables*/
    uint256 private immutable i_entranceFee; //storage variable
    address payable[] private s_players;
    bytes32 private immutable i_gasLane;
    uint64 private immutable i_subscriptionId;
    uint32 private immutable i_callbackGasLimit; 
    uint256 private immutable i_interval;
    uint256 private s_lastTimeStamp;
    bool private s_isOpen;
    VRFCoordinatorV2Interface private immutable i_vrfCoordinator;
    RaffleState private s_raffleState;

    /* constants */
    uint32 private constant NUM_WORDS = 1;
    uint16 private constant REQUEST_CONFIRMATIONS = 3;
    
    // Lottery variables
    address private s_recentWinner;
    
    /*Events*/
    event RaffleEnter(address indexed player);
    event RequestedRaffleWinner(uint256 indexed requestId);
    event WinnerPicked(address indexed winner);
    // indexed variables within a contract allow to easily search in the smart contract logs later. 
    // maximum of 3 indexed vars. rest of them go to the logs too, but need ABI to decode easily.
    // events are gas efficient as smart contract can not read from the logs where events are stored
   
    constructor(address vrfCoordinatorV2, uint256 entranceFee, bytes32 gasLane, uint64 subscriptionId, 
    uint32 callbackGasLimit, uint256 interval) VRFConsumerBaseV2(vrfCoordinatorV2){
        i_entranceFee = entranceFee;
        // i_vrfCoordinator forwards to a contract(vrfCoordinatorV2) that implements the functions of the interface. 
        // It makes easier to know which functions are available for calling (they're the ones defined in the interface)
        // Interfaces are the scaffolding for inherited contracts. You can define a new contract implementing the functions
        // of the interface, or you can forward to an existing contract that inherits the interface.
        i_vrfCoordinator =  VRFCoordinatorV2Interface(vrfCoordinatorV2);
        i_gasLane = gasLane;
        i_subscriptionId = subscriptionId;
        i_callbackGasLimit = callbackGasLimit;
        s_raffleState = RaffleState.OPEN;
        i_interval = interval;
        s_lastTimeStamp = block.timestamp;
    }

    /* Functions */
    function enterRaffle() payable public{
        // require(msg.value > i_entranceFee, "Not enough ETH!") --> uses more GAS 
        if(msg.value < i_entranceFee){revert Raffle__NotEnoughETHEntered();} // this approach is more gas efficient
        if (s_raffleState != RaffleState.OPEN){revert Raffle_NotOpen();}
        s_players.push(payable(msg.sender));
        emit RaffleEnter(msg.sender);
    }

    /**
    @dev This is the function that the Chainlink Keeper nodes call. They look for the 'upkeepNeeded' to return true
     */

    /*
    1. our time interval should pass
    2. lottery should have at least one player
    3. our subscription is funded with LINK
    4. lottery should be in 'open' state
    */

    function checkUpkeep(bytes memory /*checkData*/) public override returns(bool upkeepNeeded, bytes memory /*performData*/){
        bool isOpen = (RaffleState.OPEN == s_raffleState); 
        bool timePassed = ((block.timestamp - s_lastTimeStamp) > i_interval);
        bool hasPlayers = (s_players.length > 0);
        bool hasBalance = address(this).balance > 0;
        upkeepNeeded = (isOpen && timePassed && hasPlayers && hasBalance) ; 
    }
     

    function performUpkeep(bytes calldata /*performData*/) external{
        (bool upkeepNeeded,) = checkUpkeep("");
        if( !upkeepNeeded ){ 
            revert Raffle__UpkeepNotNeeded(
            address(this).balance, 
            s_players.length, 
            uint256(s_raffleState)
            );
            }
            s_raffleState = RaffleState.CALCULATING;
            uint256 requestId = i_vrfCoordinator.requestRandomWords(
            i_gasLane, 
            i_subscriptionId, 
            REQUEST_CONFIRMATIONS, 
            i_callbackGasLimit,
            NUM_WORDS
        );
        emit RequestedRaffleWinner(requestId);
    }
    function fulfillRandomWords(uint256 /*requestId*/, uint256[] memory randomWords) internal override{
        uint256 indexOfWinner = randomWords[0] % s_players.length;
        address payable recentWinner = s_players[indexOfWinner];
        s_recentWinner = recentWinner;

        s_raffleState = RaffleState.OPEN;
        s_players = new address payable[](0);
        s_lastTimeStamp = block.timestamp;
        (bool success, ) = recentWinner.call{value: address(this).balance}("");
        if(!success){
            revert Raffle_TransferFailed();
        }
        emit WinnerPicked(s_recentWinner);
        

    }
    function getEntranceFee() public view returns (uint256){
        return i_entranceFee;
    }

    function getPlayer(uint256 index) public view returns(address){
        return s_players[index];
    }

    function getRecentWinner() public view returns(address){
        return s_recentWinner;
    }

    function getRaffleState() public view returns(RaffleState){
        return s_raffleState;
    }

    function getNumWords() public pure returns(uint256){
        return NUM_WORDS;
    }

    function getNumPlayers() public view returns(uint256){
        return s_players.length;
    }

    function getLatestTimestamp() public view returns(uint256){
        return s_lastTimeStamp;
    }

    function getRequestConfirmations() public pure returns(uint256){
        return REQUEST_CONFIRMATIONS;
    }


}