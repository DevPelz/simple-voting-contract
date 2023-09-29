import { ethers } from "hardhat";

async function main() {
  const votingCA = "0xba4c6bf47A6F1Cb712B178d4eea6d99dee8D58cF";

  const Voting = await ethers.getContractAt("IVoting", votingCA);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
