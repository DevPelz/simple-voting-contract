import { ethers, network } from "hardhat";
import {
  encryptDataField,
  decryptNodeResponse,
} from "@swisstronik/swisstronik.js";
import { HttpNetworkConfig } from "hardhat/types";
import { HardhatEthersSigner } from "@nomicfoundation/hardhat-ethers/signers";

const sendShieldedTransaction = async (
  signer: HardhatEthersSigner,
  destination: string,
  data: string,
  value: number
) => {
  // Get the RPC link from the network configuration
  const rpclink = (network.config as HttpNetworkConfig).url;

  // Encrypt transaction data
  const [encryptedData] = await encryptDataField(rpclink, data);

  // Construct and sign transaction with encrypted data
  return await signer.sendTransaction({
    from: signer.address,
    to: destination,
    data: encryptedData,
    value,
  });
};

async function main() {
  // Address of the deployed contract
  const votingCA = "0xba4c6bf47A6F1Cb712B178d4eea6d99dee8D58cF";
  const Voting = await ethers.getContractAt("IVoting", votingCA);

  // Get the signer (your account)
  const [signer] = await ethers.getSigners();

  const participants = [
    "0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2",
    "0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db",
    "0x78731D3Ca6b7E34aC0F824c42a7cC18A495cabaB",
    "0x617F2E2fD72FD9D5503197092aC168c91465E7f2",
  ];

  const testBid1 = "TESTING!";

  // Send a shielded transaction to set a message in the contract
  const createBidTx = await sendShieldedTransaction(
    signer,
    votingCA,
    Voting.interface.encodeFunctionData("createBid", [
      participants,
      testBid1,
      10000,
    ]),
    0
  );
  await createBidTx.wait();

  //It should return a TransactionResponse object
  console.log("Transaction Receipt: ", createBidTx);

  // Revoke rights
  const revokeVotingRightsTx = await sendShieldedTransaction(
    signer,
    votingCA,
    Voting.interface.encodeFunctionData("revokeVotingRights", [
      "0x78731D3Ca6b7E34aC0F824c42a7cC18A495cabaB",
      1,
    ]),
    0
  );
  await revokeVotingRightsTx.wait();

  console.log("Transaction Receipt: ", revokeVotingRightsTx);

  // Reset Voters
  const resetVoterstx = await sendShieldedTransaction(
    signer,
    votingCA,
    Voting.interface.encodeFunctionData("resetVoters", [1]),
    0
  );
  await resetVoterstx.wait();

  console.log("Transaction Receipt: ", resetVoterstx);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
