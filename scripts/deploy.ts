import { ethers } from "hardhat";

async function main() {
  const voting = await ethers.deployContract("Voting", []);

  await voting.waitForDeployment();

  console.log(`Voting deployed to ${voting.target}`);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
//0xba4c6bf47A6F1Cb712B178d4eea6d99dee8D58cF
