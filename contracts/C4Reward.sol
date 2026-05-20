// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

contract C4Rewards {
    uint256 public totalSupply;
    uint8 public constant decimals = 18;
    string public constant name = "C4 Reward";
    string public constant symbol = "CRW";
    address public stakingContract;

    mapping(address => uint256) public balanceOf;

    event Transfer(address indexed from, address indexed to, uint256 value);

    constructor() {
        stakingContract = msg.sender;
    }

    modifier onlyStaking() {
        require(msg.sender == stakingContract);
        _;
    }

    function setStakingContract(address _staking) external {
        require(msg.sender == stakingContract, "");
        stakingContract = _staking;
    }

    function mint(address to, uint256 amount) external onlyStaking {
        balanceOf[to] += amount;
        unchecked {
            totalSupply += amount;
        }
        emit Transfer(address(0), to, amount);
    }
}