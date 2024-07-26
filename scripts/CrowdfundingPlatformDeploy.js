const { ethers, upgrades } = require("hardhat");

async function main() {
    const CrowdfundingPlatformV1 = await ethers.getContractFactory("CrowdfundingPlatformV1");
    console.log("Start to deploy CrowdfundingPlatformV1...");
    const platform1 = await upgrades.deployProxy(CrowdfundingPlatformV1, ["0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266"], { initializer: "initialize" });

    await platform1.waitForDeployment();
    console.log("CrowdfundingPlatformV1 deployed to:", await platform1.getAddress());
    console.log("PlatformProxy deployed to:", platform1.target);
}

// npx hardhat run --network localhost scripts/CrowdfundingPlatformDeploy.js
main()
    .then(() => {
        console.log("CrowdfundingPlatformV1 Deployment completed");
        process.exit(0);
    })
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });