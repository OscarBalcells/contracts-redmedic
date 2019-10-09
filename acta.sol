pragma solidity ^0.5.1;

contract Acta {

  // Proposals:
	// 1 => new member join
	// 2 => kick member out
	// 3 => change required amount of confirmations for a certain action id
	// 4 => send x amount of contract's funds to specified address

	event JoinRequest(bytes32 eventName, address who, bytes32 name, uint fee);
	event ProposalSaved(bytes32 eventName, address proposer, uint proposalId, uint numData, bytes32 bytesData1, bytes32 bytesData2, address addrData);
	event ProposalExecuted(bytes32 eventName, uint proposalId, uint numData, bytes32 bytesData1, bytes32 bytesData2, address addrData);
	event ProposalVoted(bytes32 eventName, uint proposalIndex, uint nVotes, uint votesNeeded);

    struct Member {
	    bytes32 name;
	    bytes32 gateway;
	    address addr;
	}

    struct Proposal {
      uint proposalId;
			uint numData;
			bytes32 bytesData1;
			bytes32 bytesData2;
			address addrData;
			uint nVotes;
    }

    mapping (uint => mapping (address => bool)) public votes;
    mapping (address => bool) public isMember;
		mapping (address => Member) public members;
		mapping (bytes32 => address) public nameToAddress;
		mapping (uint => Proposal) public proposals;

		uint public nRequiredVotes = 1;
		uint public nProposals = 0;
		uint public nMembers = 0;

    constructor(bytes32 name, bytes32 gateway) public {
        require(nMembers == 0);
        members[msg.sender] = Member({
            name: name,
            gateway: gateway,
            addr: msg.sender
        });
        isMember[msg.sender] = true;
        nMembers++;
    }

    ///PROPOSAL CREATION

    function internalActionProposal(uint proposalId, uint numData, bytes32 bytesData1, bytes32 bytesData2, address addrData) private {
        proposals[nProposals] = Proposal({
            proposalId: proposalId,
            numData: numData,
            bytesData1: bytesData1,
            bytesData2: bytesData2,
            addrData: addrData,
            nVotes: 0
        });
        nProposals++;
        emit ProposalSaved("ProposalSaved", msg.sender, proposalId, numData, bytesData1, bytesData2, addrData);
    }

    function joinRequest(bytes32 name, bytes32 gateway) public payable {
			require(isMember[msg.sender] == false);
			require(msg.value >= 0.1 ether);
			emit JoinRequest("JoinRequest", msg.sender, name, msg.value);
        internalActionProposal(1, 0, name, gateway, msg.sender);
    }

    function addMemberProposal(bytes32 name, bytes32 gateway, address addr) public {
        require(isMember[msg.sender] == true);
        require(isMember[addr] == false);
        internalActionProposal(1, 0, name, gateway, addr);
        votes[nProposals-1][msg.sender] = true;
        proposals[nProposals-1].nVotes++;
        if(nRequiredVotes == 1) executeProposal(nProposals-1);
    }

    function kickMemberProposal(bytes32 name, address addr) public {
        require(isMember[msg.sender] == true);
        require(isMember[addr] == true);
        internalActionProposal(2, 0, name, "", addr);
        votes[nProposals-1][msg.sender] = true;
        proposals[nProposals-1].nVotes++;
        if(nRequiredVotes == 1) executeProposal(nProposals-1);
    }

    function changeRequiredVotesProposal(uint newRequirement) public {
        require(isMember[msg.sender] == true);
        internalActionProposal(3, newRequirement, "", "", address(this));
        votes[nProposals-1][msg.sender] = true;
        proposals[nProposals-1].nVotes++;
        if(nRequiredVotes == 1) executeProposal(nProposals-1);
    }

    function transferFundsProposal(uint amount, bytes32 receiverName, address receiverAddr) public {
        require(isMember[msg.sender] == true);
        internalActionProposal(4, amount, receiverName, "", receiverAddr);
        votes[nProposals-1][msg.sender] = true;
        proposals[nProposals-1].nVotes++;
        if(nRequiredVotes == 1) executeProposal(nProposals-1);
    }

    ////PROPOSAL VOTING & REVOKING

    function voteProposal(uint proposalIndex) public {
			require(proposals[proposalIndex].proposalId > 0);
			require(isMember[msg.sender] == true);
			require(votes[proposalIndex][msg.sender] == false);
		  votes[proposalIndex][msg.sender] = true;
			proposals[proposalIndex].nVotes++;
			emit ProposalVoted("ProposalVoted", proposalIndex, proposals[proposalIndex].nVotes, nRequiredVotes);
			if(proposals[proposalIndex].nVotes >= nRequiredVotes) executeProposal(proposalIndex);
    }

		function undoVoteProposal(uint proposalIndex) public {
      require(proposals[proposalIndex].proposalId > 0);
			require(isMember[msg.sender] == true);
			require(votes[proposalIndex][msg.sender] == true);
	    votes[proposalIndex][msg.sender] = false;
			proposals[proposalIndex].nVotes--;
    }

    ///PROPOSAL EXECUTION

    function executeProposal(uint proposalIndex) private {
    		require(proposals[proposalIndex].proposalId > 0);
        require(proposals[proposalIndex].nVotes >= nRequiredVotes);
        require(proposals[proposalIndex].proposalId > 0);
        Proposal memory proposal = proposals[proposalIndex];
        delete proposals[proposalIndex];
        nProposals--;

        if(proposal.proposalId == 1) {
            isMember[proposal.addrData] = true;
            members[proposal.addrData] = Member({
                name: proposal.bytesData1,
                gateway: proposal.bytesData2,
                addr: proposal.addrData
            });
            nameToAddress[proposal.bytesData1] = proposal.addrData;
            nMembers++;
        } else if(proposal.proposalId == 2) {
            isMember[proposal.addrData] = false;
            depragma solidity ^0.5.1;

contract Acta {

  // Proposals:
	// 1 => new member join
	// 2 => kick member out
	// 3 => change required amount of confirmations for a certain action id
	// 4 => send x amount of contract's funds to specified address

	event JoinRequest(bytes32 eventName, address who, bytes32 name, uint fee);
	event ProposalSaved(bytes32 eventName, address proposer, uint proposalId, uint numData, bytes32 bytesData1, bytes32 bytesData2, address addrData);
	event ProposalExecuted(bytes32 eventName, uint proposalId, uint numData, bytes32 bytesData1, bytes32 bytesData2, address addrData);
	event ProposalVoted(bytes32 eventName, uint proposalIndex, uint nVotes, uint votesNeeded);

    struct Member {
	    bytes32 name;
	    bytes32 gateway;
	    address addr;
	}

    struct Proposal {
      uint proposalId;
			uint numData;
			bytes32 bytesData1;
			bytes32 bytesData2;
			address addrData;
			uint nVotes;
    }

    mapping (uint => mapping (address => bool)) public votes;
    mapping (address => bool) public isMember;
		mapping (address => Member) public members;
		mapping (bytes32 => address) public nameToAddress;
		mapping (uint => Proposal) public proposals;

		uint public nRequiredVotes = 1;
		uint public nProposals = 0;
		uint public nMembers = 0;

    constructor(bytes32 name, bytes32 gateway) public {
        require(nMembers == 0);
        members[msg.sender] = Member({
            name: name,
            gateway: gateway,
            addr: msg.sender
        });
        isMember[msg.sender] = true;
        nMembers++;
    }

    ///PROPOSAL CREATION

    function internalActionProposal(uint proposalId, uint numData, bytes32 bytesData1, bytes32 bytesData2, address addrData) private {
        proposals[nProposals] = Proposal({
            proposalId: proposalId,
            numData: numData,
            bytesData1: bytesData1,
            bytesData2: bytesData2,
            addrData: addrData,
            nVotes: 0
        });
        nProposals++;
        emit ProposalSaved("ProposalSaved", msg.sender, proposalId, numData, bytesData1, bytesData2, addrData);
    }

    function joinRequest(bytes32 name, bytes32 gateway) public payable {
			require(isMember[msg.sender] == false);
			require(msg.value >= 0.1 ether);
			emit JoinRequest("JoinRequest", msg.sender, name, msg.value);
        internalActionProposal(1, 0, name, gateway, msg.sender);
    }

    function addMemberProposal(bytes32 name, bytes32 gateway, address addr) public {
        require(isMember[msg.sender] == true);
        require(isMember[addr] == false);
        internalActionProposal(1, 0, name, gateway, addr);
        votes[nProposals-1][msg.sender] = true;
        proposals[nProposals-1].nVotes++;
        if(nRequiredVotes == 1) executeProposal(nProposals-1);
    }

    function kickMemberProposal(bytes32 name, address addr) public {
        require(isMember[msg.sender] == true);
        require(isMember[addr] == true);
        internalActionProposal(2, 0, name, "", addr);
        votes[nProposals-1][msg.sender] = true;
        proposals[nProposals-1].nVotes++;
        if(nRequiredVotes == 1) executeProposal(nProposals-1);
    }

    function changeRequiredVotesProposal(uint newRequirement) public {
        require(isMember[msg.sender] == true);
        internalActionProposal(3, newRequirement, "", "", address(this));
        votes[nProposals-1][msg.sender] = true;
        proposals[nProposals-1].nVotes++;
        if(nRequiredVotes == 1) executeProposal(nProposals-1);
    }

    function transferFundsProposal(uint amount, bytes32 receiverName, address receiverAddr) public {
        require(isMember[msg.sender] == true);
        internalActionProposal(4, amount, receiverName, "", receiverAddr);
        votes[nProposals-1][msg.sender] = true;
        proposals[nProposals-1].nVotes++;
        if(nRequiredVotes == 1) executeProposal(nProposals-1);
    }

    ////PROPOSAL VOTING & REVOKING

    function voteProposal(uint proposalIndex) public {
			require(proposals[proposalIndex].proposalId > 0);
			require(isMember[msg.sender] == true);
			require(votes[proposalIndex][msg.sender] == false);
		  votes[proposalIndex][msg.sender] = true;
			proposals[proposalIndex].nVotes++;
			emit ProposalVoted("ProposalVoted", proposalIndex, proposals[proposalIndex].nVotes, nRequiredVotes);
			if(proposals[proposalIndex].nVotes >= nRequiredVotes) executeProposal(proposalIndex);
    }

		function undoVoteProposal(uint proposalIndex) public {
      require(proposals[proposalIndex].proposalId > 0);
			require(isMember[msg.sender] == true);
			require(votes[proposalIndex][msg.sender] == true);
	    votes[proposalIndex][msg.sender] = false;
			proposals[proposalIndex].nVotes--;
    }

    ///PROPOSAL EXECUTION

    function executeProposal(uint proposalIndex) private {
    		require(proposals[proposalIndex].proposalId > 0);
        require(proposals[proposalIndex].nVotes >= nRequiredVotes);
        require(proposals[proposalIndex].proposalId > 0);
        Proposal memory proposal = proposals[proposalIndex];
        delete proposals[proposalIndex];
        nProposals--;

        if(proposal.proposalId == 1) {
            isMember[proposal.addrData] = true;
            members[proposal.addrData] = Member({
                name: proposal.bytesData1,
                gateway: proposal.bytesData2,
                addr: proposal.addrData
            });
            nameToAddress[proposal.bytesData1] = proposal.addrData;
            nMembers++;
        } else if(proposal.proposalId == 2) {
            isMember[proposal.addrData] = false;
            delete members[proposal.addrData];
            delete nameToAddress[proposal.bytesData1];
            nMembers--;
        } else if(proposal.proposalId == 3) {
            require(proposal.numData <= nMembers);
            nRequiredVotes = proposal.numData;
        } else if(proposal.proposalId == 4) {
            require(proposal.numData <= address(this).balance);
            address payable receiverAddr = address(uint160(address(proposal.addrData)));
            receiverAddr.transfer(proposal.numData);
        }
        emit ProposalExecuted("ProposalExecuted", proposal.proposalId, proposal.numData, proposal.bytesData1, proposal.bytesData2, proposal.addrData);
    }

    //EXTERNAL QUERY FUNCTIONS

    function _isMember(address addr) public view returns (bool) {
        if(isMember[addr]) return true;
        else return false;
    }

    function getMember(address addr) public view returns (bytes32, bytes32) {
        return (members[addr].name, members[addr].gateway);
    }

    function getAddressByName(bytes32 name) public view returns (address) {
        return nameToAddress[name];
    }

    function getProposal(uint proposalIndex) public view returns (uint, uint, bytes32, bytes32, address, uint) {
        return (proposals[proposalIndex].proposalId, proposals[proposalIndex].numData, proposals[proposalIndex].bytesData1,
        proposals[proposalIndex].bytesData2, proposals[proposalIndex].addrData, proposals[proposalIndex].nVotes);
    }
}
lete members[proposal.addrData];
            delete nameToAddress[proposal.bytesData1];
            nMembers--;
        } else if(proposal.proposalId == 3) {
            require(proposal.numData <= nMembers);
            nRequiredVotes = proposal.numData;
        } else if(proposal.proposalId == 4) {
            require(proposal.numData <= address(this).balance);
            address payable receiverAddr = address(uint160(address(proposal.addrData)));
            receiverAddr.transfer(proposal.numData);
        }
        emit ProposalExecuted("ProposalExecuted", proposal.proposalId, proposal.numData, proposal.bytesData1, proposal.bytesData2, proposal.addrData);
    }

    //EXTERNAL QUERY FUNCTIONS

    function _isMember(address addr) public view returns (bool) {
        if(isMember[addr]) return true;
        else return false;
    }

    function getMember(address addr) public view returns (bytes32, bytes32) {
        return (members[addr].name, members[addr].gateway);
    }

    function getAddressByName(bytes32 name) public view returns (address) {
        return nameToAddress[name];
    }

    function getProposal(uint proposalIndex) public view returns (uint, uint, bytes32, bytes32, address, uint) {
        return (proposals[proposalIndex].proposalId, proposals[proposalIndex].numData, proposals[proposalIndex].bytesData1,
        proposals[proposalIndex].bytesData2, proposals[proposalIndex].addrData, proposals[proposalIndex].nVotes);
    }
}
