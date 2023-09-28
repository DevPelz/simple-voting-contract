// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/// @title Voting Contract
/// @notice this contract is used for managing voting on bids.
contract Voting {
    /// @notice The address of the contract owner and identifier for bids created
    address private owner;
    uint private bidsId;

    /// @dev Custom errors
    error Voting_InvalidAddress();
    error Voting_AlreadyRegistered();
    error Voting_AlreadyHasVotingRights();
    error Voting_AlreadyVoted();
    error Voting_OwnerCantParticpate();

    /// @notice Events emitted
    event BidCreated(string indexed _name, uint indexed creationTime);
    event VotedYes(uint indexed _ID);
    event VotedNo(uint indexed _ID);
    event OwnerChanged(address indexed previousOwner, address indexed newOwner);
    event RevokedVotingRights(address _voter, uint bidId);

    struct Voter {
        uint votePower;
        bool hasVoted;
    }

    Voter[] private voters;
    address[] private registeredParticipants;

    /// @dev mappings used in the contract
    mapping(uint => mapping(address => Voter)) private voters_;
    mapping(address => bool) private _isRegistered;
    mapping(uint => Bids) private _idToBids;
    mapping(uint => bool) private _bidActive;
    mapping(uint => mapping(address => bool)) private _registeredAddressToBid;

    struct Bids {
        bytes name;
        uint positive_VoteCount;
        uint negative_VoteCount;
        uint voting_Duration;
    }

    /// @dev Contract constructor sets owner to deployer.
    constructor() {
        owner = msg.sender;
    }

    /// @dev Modifier to restrict access to only the contract owner.
    modifier onlyOwner() {
        require(owner == msg.sender, "Voting: only owner has access");
        _;
    }

    /// @notice Modifier to deny access to the contract owner.
    /// @dev This modifier ensures that the contract owner is not authorized to perform certain actions.
    modifier denyOwner() {
        require(msg.sender != owner, "Voting: Owner is Unauthorised");
        _;
    }

    /// @dev Modifier to restrict access to registered voters only.
    modifier isRegisteredVoter(uint _bidID) {
        require(
            _registeredAddressToBid[_bidID][msg.sender] == true,
            "Voting: Unauthorised Address"
        );
        _;
    }

    /// @dev Modifier to restrict access to voters who haven't voted yet.
    modifier hasVoted(uint _bidID) {
        require(
            voters_[_bidID][msg.sender].hasVoted == false,
            "Voting: voter already voted"
        );
        _;
    }

    modifier isBidActive() {
        require(
            _idToBids[_bidID].voting_Duration >= block.timestamp,
            "Voting: Bid expired"
        );
        _;
    }

    /// @dev Registers a list of voters.
    /// @param _voters An array of voter addresses to register.
    /// @param _bidID the id of the bid to register voters on.
    function registerVoters(
        address[] memory _voters,
        uint _bidID
    ) internal onlyOwner {
        for (uint i = 0; i < _voters.length; i++) {
            if (_voters[i] == address(0)) {
                revert Voting_InvalidAddress();
            }
            if (_voters[i] == owner) {
                revert Voting_OwnerCantParticpate();
            }
            if (_registeredAddressToBid[_bidID][_voters[i]] == true) {
                revert Voting_AlreadyRegistered();
            }
            if (voters_[_bidID][_voters[i]].votePower > 0) {
                revert Voting_AlreadyHasVotingRights();
            }
            if (voters_[_bidID][_voters[i]].hasVoted == true) {
                revert Voting_AlreadyVoted();
            }

            Voter storage _Voters = voters_[_bidID][_voters[i]];
            registeredParticipants.push(_voters[i]);
            voters.push(
                Voter({votePower: _Voters.votePower = 1, hasVoted: false})
            );
            _registeredAddressToBid[_bidID][_voters[i]] = true;
        }
    }

    /// @dev Adds a new voter.
    /// @param _newVoter The address of the new voter to add.
    function addVoter(
        address _newVoter,
        uint _bidID
    ) external onlyOwner hasVoted(_bidID) {
        require(_newVoter != address(0), "Voting: register a valid address");
        require(_isRegistered[_newVoter], "Voting: Already registered");
        require(
            voters_[_bidID][_newVoter].votePower < 1,
            "Voting: voter has voting rights already"
        );
        voters_[_bidID][_newVoter].votePower = 1;
        voters_[_bidID][_newVoter].hasVoted = false;
        _isRegistered[_newVoter] = true;
    }

    /// @dev Creates a new bid.
    /// @param _name The name of the bid.
    /// @param _voting_Duration The duration of the voting period in seconds.
    function createBid(
        address[] memory _voters,
        string memory _name,
        uint _voting_Duration
    ) external onlyOwner {
        bidsId++;
        bytes memory name_ = bytes(_name);
        Bids storage bids = _idToBids[bidsId];
        registerVoters(_voters, bidsId);
        bids.name = name_;
        bids.positive_VoteCount = 0;
        bids.negative_VoteCount = 0;
        bids.voting_Duration = _voting_Duration + block.timestamp;

        emit BidCreated(_name, block.timestamp);
    }

    /// @notice Allows a registered voter to cast a "Yes" vote for a specific bid.
    /// @param _bidID The unique identifier of the bid.
    /// @dev This function can only be called by registered voters who have not voted for this bid.
    /// It checks if the bid is still within the voting duration and updates the vote count accordingly.
    /// Emits a `VotedYes` event upon a successful vote.
    function voteYes(
        uint _bidID
    )
        external
        isBidActive
        denyOwner
        isRegisteredVoter(_bidID)
        hasVoted(_bidID)
    {
        voters_[_bidID][msg.sender].votePower -= 1;
        _idToBids[_bidID].positive_VoteCount += 1;
        voters_[_bidID][msg.sender].hasVoted = true;

        emit VotedYes(_bidID);
    }

    /// @notice Allows a registered voter to cast a "No" vote for a specific bid.
    /// @param _bidID The unique identifier of the bid.
    /// @dev This function can only be called by registered voters who have not voted for this bid.
    /// It checks if the bid is still within the voting duration and updates the vote count accordingly.
    /// Emits a `VotedNo` event upon a successful vote.
    function voteNo(
        uint _bidID
    )
        external
        isBidActive
        denyOwner
        isRegisteredVoter(_bidID)
        hasVoted(_bidID)
    {
        voters_[_bidID][msg.sender].votePower -= 1;
        _idToBids[_bidID].negative_VoteCount += 1;
        voters_[_bidID][msg.sender].hasVoted = true;

        emit VotedNo(_bidID);
    }

    /// @notice Retrieves the positive vote count for a specific bid.
    /// @param _bidID The unique identifier of the bid.
    /// @return The count of "Yes" votes for the specified bid.
    function getPositiveVoteCount(uint _bidID) external view returns (uint) {
        return _idToBids[_bidID].positive_VoteCount;
    }

    /// @notice Retrieves the negative vote count for a specific bid.
    /// @param _bidID The unique identifier of the bid.
    /// @return The count of "No" votes for the specified bid.
    function getNegativeVoteCount(uint _bidID) external view returns (uint) {
        return _idToBids[_bidID].negative_VoteCount;
    }

    /// @notice Determines the result of a bid after its voting period has ended.
    /// @param _bidID The unique identifier of the bid.
    /// @return A string indicating the winning result, either "Winning Bid is Positive" or "Winning Bid is Negative."
    /// @dev This function can only be called after the voting duration has passed.
    function bidResults(
        uint _bidID
    ) external view onlyOwner returns (string memory) {
        require(
            block.timestamp > _idToBids[_bidID].voting_Duration,
            "Voting: bid not ended yet"
        );
        if (
            _idToBids[_bidID].positive_VoteCount >
            _idToBids[_bidID].negative_VoteCount
        ) {
            return "Winning Bid is Positive";
        } else if (
            _idToBids[_bidID].positive_VoteCount ==
            _idToBids[_bidID].negative_VoteCount
        ) {
            return "The Bid Ended in a Tie";
        }

        return "Winning Bid is Negative";
    }

    /// @notice Revokes voting rights from a registered voter.
    /// @param _voter The address of the voter whose voting rights will be revoked.
    /// @dev This function can only be called by the contract owner.
    /// It removes the voter's information from the list of registered voters, effectively revoking their voting rights.
    function revokeVotingRights(
        address _voter,
        uint _bidID
    ) external onlyOwner hasVoted(_bidID) {
        require(
            _registeredAddressToBid[_bidID][_voter] == true,
            "Voting: not registered"
        );
        delete voters_[_bidID][_voter];
        _registeredAddressToBid[_bidID][_voter] = false;

        emit RevokedVotingRights(_voter, _bidID);
    }

    /// @notice Resets the registration status of all voters.
    /// @dev This function can only be called by the contract owner.
    function resetVoters(uint _bidID) external onlyOwner {
        for (uint i = 0; i < registeredParticipants.length; i++) {
            _registeredAddressToBid[_bidID][registeredParticipants[i]] = false;
            delete voters_[_bidID][registeredParticipants[i]];
        }
    }

    function changeOwner(address _newOwner) external onlyOwner {
        require(_newOwner != owner, "Already the owner");
        owner = _newOwner;

        emit OwnerChanged(owner, _newOwner);
    }
}
