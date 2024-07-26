const { ethers, upgrades } = require("hardhat");

async function main() {
    const TestContractV1 = await ethers.getContractFactory("TestContractV1");
    console.log("Start to deploy TestContractV1...");
    const testcontract1 = await upgrades.deployProxy(TestContractV1, [50], { initializer: "initialize" });

    await testcontract1.waitForDeployment();
    console.log("TestContractV1 deployed to:", await testcontract1.getAddress());
    console.log("TestProxy deployed to:", testcontract1.target);
}

// npx hardhat run --network localhost scripts/TestContractDeploy.js
main()
    .then(() => {
        console.log("TestContractV1 Deployment completed.");
        process.exit(0);
    })
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });