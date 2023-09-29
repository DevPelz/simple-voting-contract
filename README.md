# Voting Smart Contract on SwissTron Blockchain

## Overview

This is a smart contract for managing voting on bids deployed on the SwissTron blockchain. It allows the owneer to create bids, register voters, and allow participants to cast votes. The contract is designed to ensure fair and secure voting processes in a Dao setting.

### Contract Address

- Contract Address: [0xba4c6bf47A6F1Cb712B178d4eea6d99dee8D58cF](https://explorer-evm.testnet.swisstronik.com/address/0xba4c6bf47A6F1Cb712B178d4eea6d99dee8D58cF)

## Features

### Bid Creation

- The contract owner can create bids with unique names and specify the voting duration.

### Voter Registration

- Registered participants can be added to the contract, and they receive voting rights.

### Voting

- Registered participants can cast "Yes" or "No" votes for specific bids.
- Each participant has a voting power of 1, which is reduced after each vote.
- Participants cannot vote more than once for the same bid.

### Bid Results

- After the voting duration has passed, the contract owner can determine the winning result.
- The result can be "Winning Bid is Positive," "Winning Bid is Negative," or "The Bid Ended in a Tie."

### Owner Functions

- The contract owner can change ownership to another address.
- The owner can revoke voting rights from registered participants.
- The owner can reset the registration status of all voters.

## Usage

### Creating Bids

To create a new bid, the contract owner can use the `createBid` function, specifying the bid name and voting duration. Only the owner can create bids.

### Registering Voters

The owner can register voters using the `addVoter` function. Participants must have unique addresses, and they cannot already be registered or have voting rights.

### Voting

Registered participants can use the `voteYes` and `voteNo` functions to cast their votes for specific bids. Votes can only be cast once per participant per bid.

### Bid Results

After the voting duration has ended, the owner can check the results using the `bidResults` function.

### Changing Ownership

The owner can transfer ownership to another address using the `changeOwner` function.

### Revoking Voting Rights

The owner can revoke voting rights from participants using the `revokeVotingRights` function.

### Resetting Voters

The owner can reset the registration status of all voters using the `resetVoters` function.

## License

This smart contract is open-source and licensed under the MIT License.
