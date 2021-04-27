// SPDX-License-Identifier: CC 0

pragma solidity ^0.7.0;

contract Faucet {
    function get() public {
        require(msg.sender.balance < 1 ether);
        msg.sender.transfer(1 ether);
    }
    
    function send(address payable reciver) public {
        require(reciver.balance < 1 ether);
        reciver.transfer(1 ether);
    }
    
    receive() external payable {}
    
    fallback() external payable {}
}