# Staking Contract Project

This project contains a simple staking system made of three contracts:

- `C4Token` is the token users stake.
- `C4Rewards` is the reward token.
- `Staking` handles staking, reward calculation over time, and the minimum staking period.

## How It Works

1. A user approves the staking contract to spend `C4Token`.
2. The user stakes tokens with `stake(amount)`.
3. Rewards grow over time while the tokens are staked.
4. The user can claim rewards with `claimReward()` after the minimum staking period.
5. The user can unstake with `unstake()`, which returns the staked tokens and also pays out any earned reward.

The default minimum staking period is 20 days, but the owner can change it with `setMinStakingPeriod()`.

## Run It

Compile the contracts:

```shell
npx hardhat compile
```

Run the tests:

```shell
npx hardhat test
```

Start a local Hardhat network:

```shell
npx hardhat node
```

Deploy the staking system:

```shell
npx hardhat ignition deploy ./ignition/modules/Stake.js --network sepolia
```

If you want to deploy to the default in-process Hardhat network instead:

```shell
npx hardhat ignition deploy ./ignition/modules/Stake.js
```
