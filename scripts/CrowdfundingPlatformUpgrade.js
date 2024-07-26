const { ethers, upgrades } = require("hardhat");

async function main() {
    const proxyAddress = "0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512"; // 替换为实际部署时的代理合约地址

    const CrowdfundingPlatformV2 = await ethers.getContractFactory("CrowdfundingPlatformV2");
    console.log("Upgrading to CrowdfundingPlatformV2...");
    const upgraded = await upgrades.upgradeProxy(proxyAddress, CrowdfundingPlatformV2);
    console.log("CrowdfundingPlatformV1 Upgraded to CrowdfundingPlatformV2");
    console.log("CrowdfundingPlatformV2 Deployed to:", upgraded.address);
}

// npx hardhat run --network localhost scripts/CrowdfundingPlatformUpgrade.js
main()
    .then(() => {
        console.log("Upgrade completed.");
        process.exit(0);
    })
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });