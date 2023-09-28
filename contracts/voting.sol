// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/// @title Voting Contract
/// @notice this contract is used for managing voting on bids.
contract Voting {
    /// @notice The address of the contract owner and identifier for bids create
    address private owner;
    uint private bidsId;

    /// @dev Custom errors
    error Voting_InvalidAddress();
    error Voting_AlreadyRegistered();
    error Voting_HasVotingRights();
    error Voting_AlreadyVoted();

    /// @notice Events emitted
    event BidCreated(string indexed _name, uint indexed creationTime);
    event VotedYes(uint indexed _ID);
    event VotedNo(uint indexed _ID);

    struct Voter {
        address voter;
        uint votePower;
        bool hasVoted;
    }

    Voter[] private voters;

    mapping(address => Voter) private voters_;
    mapping(address => bool) private _isRegistered;
    mapping(uint => Bids) private _idToBids;

    struct Bids {
        bytes name;
        uint positive_VoteCount;
        uint negative_VoteCount;
        uint voting_Duration;
    }

    /// @dev Contract constructor.
    /// @param _owner The address that deploys and owns the contract.
    constructor(address _owner) {
        owner = _owner;
    }

    /// @dev Modifier to restrict access to only the contract owner.
    modifier onlyOwner() {
        require(owner == msg.sender, "Voting: only owner has access");
        _;
    }

    /// @dev Modifier to restrict access to registered voters only.
    modifier isRegisteredVoter() {
        require(!_isRegistered[msg.sender], "Voting: Unauthorised Address");
        _;
    }

    /// @dev Modifier to restrict access to voters who haven't voted yet.
    modifier hasVoted() {
        require(!voters_[msg.sender].hasVoted, "Voting: voter already voted");
        _;
    }

    /// @dev Registers a list of voters.
    /// @param _voters An array of voter addresses to register.
    function registerVoters(address[] memory _voters) external onlyOwner {
        for (uint i = 0; i <= _voters.length; i++) {
            if (_voters[i] == address(0)) {
                revert Voting_InvalidAddress();
            }
            if (!_isRegistered[_voters[i]]) {
                revert Voting_AlreadyRegistered();
            }
            if (voters_[_voters[i]].votePower > 0) {
                revert Voting_HasVotingRights();
            }
            if (!voters_[_voters[i]].hasVoted) {
                revert Voting_AlreadyVoted();
            }

            uint _votepower = voters_[_voters[i]].votePower + 1;
            bool _hasVoted = voters_[_voters[i]].hasVoted;

            voters.push(
                Voter({
                    voter: _voters[i],
                    votePower: _votepower,
                    hasVoted: _hasVoted
                })
            );
            _isRegistered[_voters[i]] = true;
        }
    }

    /// @dev Adds a new voter.
    /// @param _newVoter The address of the new voter to add.
    function addVoter(address _newVoter) external onlyOwner hasVoted {
        require(_newVoter != address(0), "Voting: register a valid address");
        require(!_isRegistered[_newVoter], "Voting: Already registered");
        require(
            voters_[_newVoter].votePower < 1,
            "Voting: voter has voting rights already"
        );
        voters_[_newVoter].votePower = 1;
        voters_[_newVoter].hasVoted = false;
        _isRegistered[_newVoter] = true;
    }

    /// @dev Creates a new bid.
    /// @param _name The name of the bid.
    /// @param _voting_Duration The duration of the voting period in seconds.
    function createBids(
        string memory _name,
        uint _voting_Duration
    ) external onlyOwner {
        bidsId++;
        bytes memory name_ = bytes(_name);
        Bids storage bids = _idToBids[bidsId];
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
    function voteYes(uint _bidID) external isRegisteredVoter hasVoted {
        require(
            _idToBids[_bidID].voting_Duration >= block.timestamp,
            "Voting: Bid expired"
        );
        voters_[msg.sender].votePower -= 1;
        _idToBids[_bidID].positive_VoteCount += 1;
        voters_[msg.sender].hasVoted = true;

        emit VotedYes(_bidID);
    }

    /// @notice Allows a registered voter to cast a "No" vote for a specific bid.
    /// @param _bidID The unique identifier of the bid.
    /// @dev This function can only be called by registered voters who have not voted for this bid.
    /// It checks if the bid is still within the voting duration and updates the vote count accordingly.
    /// Emits a `VotedNo` event upon a successful vote.
    function voteNo(uint _bidID) external isRegisteredVoter hasVoted {
        require(
            _idToBids[_bidID].voting_Duration >= block.timestamp,
            "Voting: Bid expired"
        );
        voters_[msg.sender].votePower -= 1;
        _idToBids[_bidID].negative_VoteCount += 1;
        voters_[msg.sender].hasVoted = true;

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
    function bidResults(uint _bidID) external view returns (string memory) {
        require(
            block.timestamp > _idToBids[_bidID].voting_Duration,
            "Voting: bid not ended yet"
        );
        if (
            _idToBids[_bidID].positive_VoteCount >
            _idToBids[_bidID].negative_VoteCount
        ) {
            return "Winning Bid is Positive";
        }
        return "Winning Bid is Negative";
    }

    /// @notice Resets the registration status of all voters.
    /// @dev This function can only be called by the contract owner.
    function resetVoters() external onlyOwner {
        for (uint i = 0; i <= voters.length; i++) {
            _isRegistered[voters[i].voter] = false;
        }
        delete voters;
    }
}
