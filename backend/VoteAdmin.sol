// SPDX-License-Identifier: CC 0

pragma solidity ^0.8.0;

interface faucetInterface {
    function send(address des) external;
}

interface adminInterface {
    function voteTo(address votorAddress, Vote votingAddress) external;
    function rightTo(address votorAddress, Vote votingAddress) external;
}

contract Vote {
    address public chairperson;
    bytes32 public name;
    Proposal[] public proposals;
    mapping(address => Voter) public voters;
    uint public createTime;
    bool public ended;
    uint public endTime;
    address public adminAddress;
    address public faucetAddress;
    faucetInterface faucetInstance;
    adminInterface adminInstance;
    
    struct Voter {
        bool voted;
        uint8 weight;
        uint8 vote;
        uint voteTime;
    }
    
    struct Proposal {
        bytes32 name;
        uint voteCount;
    }
    
    /// You will create a vote named `voteName`.
    /// You can't edit this name later.
    constructor(address sendChairperson, bytes32 voteName, address admin, address faucet) {
        name = voteName;
        chairperson = sendChairperson;
        voters[chairperson].weight = 1;
        ended = false;
        createTime = block.timestamp;
        adminAddress = admin;
        faucetAddress = faucet;
        faucetInstance = faucetInterface(faucetAddress);
        adminInstance = adminInterface(adminAddress);
    } 
    
    /// Only can use by chairperson.
    /// You will create a new proposal named `proposalName`.
    /// You can edit this name later.
    function newProposal(bytes32 proposalName) public {
        require(msg.sender == chairperson, "Only Chairperson can do this.");
        require(!ifEnded(), "This voting had ended.");
        proposals.push(Proposal({
            name: proposalName,
            voteCount: 0
        }));
    }
    
    /// Only can use by chairperson.
    /// You will create `proposalsName.length` proposals.
    function newProposals(bytes32[] memory proposalsName) public {
        require(msg.sender == chairperson, "Only Chairperson can do this.");
        require(!ifEnded(), "This voting had ended.");
        for (uint i = 0; i < proposalsName.length; i++) {
            newProposal(proposalsName[i]);
        }
    }
    
    /// Only can use by chairperson.
    /// You will change a proposal's name from `proposals[proposalNumber].name` to `newProposalName`.
    function setProposal(uint proposalNumber, bytes32 newProposalName) public {
        require(msg.sender == chairperson, "Only Chairperson can do this.");
        require(!ifEnded(), "This voting had ended.");
        proposals[proposalNumber].name = newProposalName;
    }
    
    /// Only can use by chairperson.
    /// You will set end time for this vote.
    /// You only can set a time after now, and no way to cancel.
    /// No way to reopen this voting after it is ended.
    function setEndTime(uint newEndTime) public {
        require(msg.sender == chairperson, "Only Chairperson can do this.");
        require(!ifEnded(), "This voting had ended.");
        require(block.timestamp < newEndTime, "End time should later than now.");
        endTime = newEndTime;
    }
    
    /// Only can use by chairperson.
    /// You will get Voting-right to `person`.
    /// No way to cancel the right.
    function giveRightTo(address person) public {
        require(msg.sender == chairperson, "Only Chairperson can do this.");
        voters[person].weight = 1;
        adminInstance.rightTo(person, this);
        if (person.balance <= 1000000000000 wei) {
            faucetInstance.send(person);
        }
    }
    
    /// You will vote to `proposals[proposalNumber].name`
    /// You can't switch to another proposal later.
    function vote(uint proposalNumber) public {
        require(!ifEnded(), "This voting had ended.");
        require(voters[msg.sender].weight != 0, "You should get the voting right from chairperson.");
        require(!voters[msg.sender].voted, "You had voted.");
        proposals[proposalNumber].voteCount += 1;
        voters[msg.sender].voted = true;
        voters[msg.sender].voteTime = block.timestamp;
        adminInstance.voteTo(msg.sender, this);
    }
    
    /// You will get the wining proposal of this voting.
    function getWinner() public view returns (uint winnerNumber) {
        uint winnerVoteCount;
        for (uint i = 0; i < proposals.length; i++) {
            if (proposals[i].voteCount > winnerVoteCount) {
                winnerNumber = i;
                winnerVoteCount = proposals[i].voteCount;
            }
        }
    }
    
    function ifEnded() private returns(bool isEnded) {
        if (ended) {
            isEnded = true;
        } else if (block.timestamp > endTime && endTime != 0) {
            ended = true;
            isEnded = true;
        } else {
            isEnded = false;
        }
    }
    
    /// You will end this voting.
    /// If you do not set end time, you can end it any time.
    /// If you have set end time, you only can end it after end time.
    /// No way to reopen this voting.
    function endVote() public returns (uint winnerNumber) {
        require(!ifEnded(), "This voting had ended.");
        if (endTime == 0) {
            require(msg.sender == chairperson, "Only Chairperson can do this.");
        } else {
            require(block.timestamp > endTime, "You only can end this voting after end time.");
        }
        ended = true;
        winnerNumber = getWinner();
    }
    
    receive() external payable {}
    
    fallback() external payable {}
}

contract VoteAdmin {
    address public defaultAdminAddress;
    address public defaultFaucetAddress;
    address public administor;
    mapping(address => Vote[]) public created;
    mapping(address => Vote[]) public voted;
    mapping(address => Vote[]) public righted;
    
    constructor() {
        administor = msg.sender;
    }
    
    function create(bytes32 votingName) public returns (Vote votingAddress) {
        votingAddress = new Vote(msg.sender, votingName, defaultAdminAddress, defaultFaucetAddress);
        created[msg.sender].push(votingAddress);
    }
    
    function voteTo(address votorAddress, Vote votingAddress) public {
        voted[votorAddress].push(votingAddress);
    }
    
    function rightTo(address votorAddress, Vote votingAddress) public {
        righted[votorAddress].push(votingAddress);
    }
    
    function setAdmin(address admin) public {
        defaultAdminAddress = admin;
    }
    
    function setFaucet(address faucet) public {
        defaultFaucetAddress = faucet;
    }
    
    function getCreated() public view returns (Vote[] memory votes) {
        votes = created[msg.sender];
    }
    
    function getVoted() public view returns (Vote[] memory votes) {
        votes = voted[msg.sender];
    }
    
    function getRighted() public view returns (Vote[] memory votes) {
        votes = righted[msg.sender];
    }
}