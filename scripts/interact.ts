import { ethers, network } from "hardhat";
import {
  encryptDataField,
  decryptNodeResponse,
} from "@swisstronik/swisstronik.js";
import { HttpNetworkConfig } from "hardhat/types";
import { HardhatEthersProvider } from "@nomicfoundation/hardhat-ethers/internal/hardhat-ethers-provider";
import { JsonRpcProvider } from "ethers";

const sendShieldedQuery = async (
  provider: JsonRpcProvider | HardhatEthersProvider,
  destination: string,
  data: string
) => {
  const rpclink = (network.config as HttpNetworkConfig).url;
  const [encryptedData, usedEncryptedKey] = await encryptDataField(
    rpclink,
    data
  );
  const response = await provider.call({
    to: destination,
    data: encryptedData,
  });
  return await decryptNodeResponse(rpclink, response, usedEncryptedKey);
};

async function main() {
  const votingCA = "0xba4c6bf47A6F1Cb712B178d4eea6d99dee8D58cF";

  const Voting = await ethers.getContractAt("IVoting", votingCA);
  const [signer] = await ethers.getSigners();

  const responseMessage = await sendShieldedQuery(
    signer.provider,
    votingCA,
    Voting.interface.encodeFunctionData("getPositiveVoteCount", [1])
  );

  console.log(
    "Positive VoteCount:",
    Voting.interface.decodeFunctionResult("bidResults", responseMessage)[1]
  );

  const responseMessage2 = await sendShieldedQuery(
    signer.provider,
    votingCA,
    Voting.interface.encodeFunctionData("getNegativeVoteCount", [1])
  );

  console.log(
    "Negative VoteCount:",
    Voting.interface.decodeFunctionResult("bidResults", responseMessage2)[2]
  );
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
