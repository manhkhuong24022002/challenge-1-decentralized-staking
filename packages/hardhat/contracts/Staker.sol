// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "hardhat/console.sol";
import "./ExampleExternalContract.sol";

contract Staker {
    ExampleExternalContract public exampleExternalContract;
    
    mapping(address => uint256) public balances;
    uint256 public constant threshold = 1 ether;
    uint256 public deadline = block.timestamp + 72 hours;
    bool public openForWithdraw;
    bool public isExecutionCompleted = false;
    
    event Stake(address staker, uint256 amount);

    constructor(address exampleExternalContractAddress) {
        exampleExternalContract = ExampleExternalContract(exampleExternalContractAddress);
    }
    
    modifier notCompleted() {
        require(!isExecutionCompleted, "Example Contract is already executed!");
        _;
    }

    // Stake function for users to deposit ETH
    function stake() public payable {
        require(block.timestamp < deadline, "Staking period is over");
        balances[msg.sender] += msg.value;
        emit Stake(msg.sender, msg.value);
    }

    // Check the remaining time before the deadline
    function timeLeft() public view returns (uint256) {
        if (block.timestamp >= deadline) {
            return 0;
        } else {
            return deadline - block.timestamp;
        }
    }

    // Execute function to finalize the staking
    function execute() public notCompleted {
        require(block.timestamp >= deadline, "Deadline not reached yet");
        if (address(this).balance >= threshold) {
            isExecutionCompleted = true;
            exampleExternalContract.complete{value: address(this).balance}();
        } else {
            openForWithdraw = true;
        }
    }

    // Withdraw function for users to retrieve their funds if threshold not met
    function withdraw() public payable notCompleted {
        if (openForWithdraw == true) {
        uint256 amount = balances[msg.sender];

        require(amount > 0, "You don't have balances to withdraw");
        balances[msg.sender] = 0;

        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "Unable to withdraw!!!");
        
        openForWithdraw = false;
        }
  }

    // Special receive function to accept ETH directly
    receive() external payable {
        stake();
    }
}
