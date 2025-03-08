// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.2 <0.9.0;

contract TimeUnit {
    function getTimestamp() public view returns (uint256) {
        return block.timestamp;
    }
}
