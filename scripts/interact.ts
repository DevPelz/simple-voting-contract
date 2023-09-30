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

  console.log("=========Getting VoteCounts==========");
  console.log(
    "Positive VoteCount:",
    Voting.interface.decodeFunctionResult(
      "getPositiveVoteCount",
      responseMessage
    )[0]
  );

  const responseMessage2 = await sendShieldedQuery(
    signer.provider,
    votingCA,
    Voting.interface.encodeFunctionData("getNegativeVoteCount", [1])
  );

  console.log(
    "Negative VoteCount:",
    Voting.interface.decodeFunctionResult(
      "getNegativeVoteCount",
      responseMessage2
    )[0]
  );
  console.log("============================================");

  const bidResult = await sendShieldedQuery(
    signer.provider,
    votingCA,
    Voting.interface.encodeFunctionData("bidResults", [1])
  );

  console.log("=========Getting Results==========");
  console.log(
    "Bid Result:",
    Voting.interface.decodeFunctionResult("bidResults", bidResult)[0]
  );
  console.log("============================================");

  const _resetVoters = await sendShieldedQuery(
    signer.provider,
    votingCA,
    Voting.interface.encodeFunctionData("resetVoters", [1])
  );

  console.log("=========Resetting Voters==========");
  console.log(
    "Reset:",
    Voting.interface.decodeFunctionResult("resetVoters", _resetVoters)[0]
  );
  console.log("============================================");
}
// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
