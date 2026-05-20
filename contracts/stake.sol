// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

interface IERC20 {
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
    function transfer(address to, uint256 amount) external returns (bool);
}

interface IRewardToken {
    function mint(address to, uint256 amount) external;
}

contract Staking {
    IERC20 public immutable stakingToken;
    IRewardToken public immutable rewardToken;

    bool private locked;

    mapping(address => uint256) public stakedBalance;
    mapping(address => uint256) public rewards;

    event Staked(address indexed user, uint256 amount);
    event Unstaked(address indexed user, uint256 amount);
    event RewardClaimed(address indexed user, uint256 amount);

    constructor(address _stakingToken, address _rewardToken) {
        stakingToken = IERC20(_stakingToken);
        rewardToken = IRewardToken(_rewardToken);
    }

    modifier nonReentrant() {
        require(!locked);
        locked = true;
        _;
        locked = false;
    }

    function stake(uint256 amount) external nonReentrant {
        require(amount > 0);
        require(stakingToken.transferFrom(msg.sender, address(this), amount));
        stakedBalance[msg.sender] += amount;
        rewards[msg.sender] += amount;
        emit Staked(msg.sender, amount);
    }

    function unstake(uint256 amount) external nonReentrant {
        require(stakedBalance[msg.sender] >= amount);
        stakedBalance[msg.sender] -= amount;
        rewards[msg.sender] = 0;
        require(stakingToken.transfer(msg.sender, amount));
        
        emit Unstaked(msg.sender, amount);
    }

    function claimReward() external nonReentrant {
        uint256 reward = rewards[msg.sender];
        require(reward > 0);
        rewards[msg.sender] = 0;
        rewardToken.mint(msg.sender, reward);
        
        emit RewardClaimed(msg.sender, reward);
    }
}