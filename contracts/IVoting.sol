// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface IVoting {
    function createBid(
        address[] memory _voters,
        string memory _name,
        uint _voting_Duration
    ) external;

    function addVoter(address _newVoter, uint _bidID) external;

    function voteYes(uint _bidID) external;

    function voteNo(uint _bidID) external;

    function getPositiveVoteCount(uint _bidID) external returns (uint);

    function getNegativeVoteCount(uint _bidID) external returns (uint);

    function bidResults(uint _bidID) external returns (string memory);

    function revokeVotingRights(address _voter, uint _bidID) external;

    function resetVoters(uint _bidID) external;

    function changeOwner(address _newOwner) external;
}
