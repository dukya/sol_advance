/*
```js
const { expect } = require("chai");

describe("Box", function() {
  it('works', async () => {
    const Box = await ethers.getContractFactory("Box");
    const BoxV2 = await ethers.getContractFactory("BoxV2");
    
    const instance = await upgrades.deployProxy(Box, [42]);
    const upgraded = await upgrades.upgradeProxy(await instance.getAddress(), BoxV2);
    
    const value = await upgraded.value();
    expect(value.toString()).to.equal('42');
  });
});
```
*/
const { ethers, upgrades } = require("hardhat");

async function main() {
  // const UPGRADEABLE_PROXY = "Insert your proxy contract address here"; // 替换为实际部署时的代理合约地址
  const UPGRADEABLE_PROXY = "0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512"; // 替换为实际部署时的代理合约地址

  const TestContractV2 = await ethers.getContractFactory("TestContractV2");
  console.log("Upgrading to TestContractV2...");
  const upgraded = await upgrades.upgradeProxy(UPGRADEABLE_PROXY, TestContractV2);
  console.log("TestContractV1 Upgraded to TestContractV2");
  console.log("TestContractV2 Deployed To:", upgraded.address)
  console.log("TestContractV2 upgraded:", (await upgraded.value()).toString());
}

// npx hardhat run --network localhost scripts/TestContractUpgrade.js
main()
  .then(() => {
    console.log("Upgrade completed.");
    process.exit(0);
  })
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });