const { buildModule } = require("@nomicfoundation/hardhat-ignition/modules");

const INITIAL_SUPPLY = 1_000_000n * 10n ** 18n;

module.exports = buildModule("StakingModule", (m) => {
  const initialSupply = m.getParameter("initialSupply", INITIAL_SUPPLY);

  const c4Token = m.contract("C4Token", [initialSupply]);

  const c4Rewards = m.contract("C4Rewards");

  const staking = m.contract("Staking", [c4Token, c4Rewards]);

  m.call(c4Rewards, "setStakingContract", [staking]);

  return { c4Token, c4Rewards, staking };
});
