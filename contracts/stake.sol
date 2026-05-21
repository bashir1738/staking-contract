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

    uint256 public constant STAKE_REWARD_RATE = 10;
    uint256 public constant SECONDS_IN_YEAR = 365 days;
    uint256 public constant DEFAULT_MIN_STAKING_PERIOD = 20 days;

    address public owner;
    uint256 public minStakingPeriod;

    struct Stake {
        uint256 amount;
        uint256 timestamp;
        uint256 stakedAt;
        uint256 reward;
    }

    enum StakingStatus {
        NotStaked,
        Staked,
        Unstaked
    }

    bool private locked;

    mapping(address => Stake) public stakes;
    mapping(address => StakingStatus) public stakingStatus;

    event Staked(address indexed user, uint256 amount);
    event RewardClaimed(address indexed user, uint256 amount);
    event Unstaked(address indexed user, uint256 stakedAmount, uint256 rewardAmount);
    event MinStakingPeriodUpdated(uint256 periodSeconds);

    constructor(address _stakingToken, address _rewardToken) {
        owner = msg.sender;
        stakingToken = IERC20(_stakingToken);
        rewardToken = IRewardToken(_rewardToken);
        minStakingPeriod = DEFAULT_MIN_STAKING_PERIOD;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    modifier nonReentrant() {
        require(!locked, "Reentrant call");
        locked = true;
        _;
        locked = false;
    }

    function setMinStakingPeriod(uint256 periodSeconds) external onlyOwner {
        minStakingPeriod = periodSeconds;
        emit MinStakingPeriodUpdated(periodSeconds);
    }

    function stake(uint256 amount) external nonReentrant {
        require(amount > 0, "Amount must be greater than 0");

        Stake storage user = stakes[msg.sender];
        _updateReward(msg.sender);

        if (user.amount == 0) {
            user.stakedAt = block.timestamp;
        }

        user.amount += amount;
        user.timestamp = block.timestamp;
        stakingStatus[msg.sender] = StakingStatus.Staked;
        require(stakingToken.transferFrom(msg.sender, address(this), amount), "Token transfer failed");
        emit Staked(msg.sender, amount);
    }

    function calculateReward(address staker) public view returns (uint256) {
        Stake memory stakeInfo = stakes[staker];
        if (stakeInfo.amount == 0) {
            return 0;
        }

        uint256 elapsed = block.timestamp - stakeInfo.timestamp;
        uint256 pendingReward = (stakeInfo.amount * STAKE_REWARD_RATE * elapsed) / SECONDS_IN_YEAR / 100;
        return stakeInfo.reward + pendingReward;
    }

    function _updateReward(address staker) internal {
        Stake storage stakeInfo = stakes[staker];
        if (stakeInfo.amount > 0) {
            stakeInfo.reward = calculateReward(staker);
            stakeInfo.timestamp = block.timestamp;
        }
    }

    function unstake() external nonReentrant {
        require(stakingStatus[msg.sender] == StakingStatus.Staked, "Not staked");

        _updateReward(msg.sender);

        Stake memory stakeInfo = stakes[msg.sender];
        require(block.timestamp >= stakeInfo.stakedAt + minStakingPeriod, "Minimum staking period not reached");
        uint256 amount = stakeInfo.amount;
        uint256 reward = stakeInfo.reward;
        delete stakes[msg.sender];
        stakingStatus[msg.sender] = StakingStatus.Unstaked;
        require(stakingToken.transfer(msg.sender, amount), "Stake transfer failed");

        if (reward > 0) {
            rewardToken.mint(msg.sender, reward);
        }

        emit Unstaked(msg.sender, amount, reward);
    }

    function claimReward() external nonReentrant {
        require(stakingStatus[msg.sender] == StakingStatus.Staked, "Not staked");
        _updateReward(msg.sender);
        require(block.timestamp >= stakes[msg.sender].stakedAt + minStakingPeriod, "Minimum staking period not reached");
        uint256 reward = stakes[msg.sender].reward;
        require(reward > 0, "No reward to claim");

        stakes[msg.sender].reward = 0;
        stakes[msg.sender].timestamp = block.timestamp;
        rewardToken.mint(msg.sender, reward);
        emit RewardClaimed(msg.sender, reward);
    }
}