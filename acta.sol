pragma solidity ^0.5.1;

contract Acta {

    /*
     What does each proposal do? (by proposalId)
	 1 => new member join
	 2 => kick member out
	 3 => change required amount of confirmations for executing an action
	 4 => send x amount of contract's funds to specified address
    */

    //To notify external listeners of changes that have ocurred in the contract
	event JoinRequest(bytes32 eventName, address who, bytes32 name, uint fee);
	event ProposalSaved(bytes32 eventName, address proposer, uint proposalId, uint numData, bytes32 bytesData1, bytes32 bytesData2, address addrData);
	event ProposalExecuted(bytes32 eventName, uint proposalId, uint numData, bytes32 bytesData1, bytes32 bytesData2, address addrData);
	event ProposalVoted(bytes32 eventName, uint proposalIndex, uint nVotes, uint votesNeeded);
    event GatewayChanged(bytes32 eventName, bytes32 memberName, bytes32 newGateway);

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

    // @dev the creator of the contract gets automatically put as a registered member
    constructor(bytes32 name, bytes32 gateway) public {
        members[msg.sender] = Member({
            name: name,
            gateway: gateway,
            addr: msg.sender
        });
        isMember[msg.sender] = true;
        nMembers++;
    }

    // @dev the Proposals get externally proposed from other functions so that it's easier to call them and save code
    //     so they all get internally (hence private tag in function) organized and sent to this function which just adds them to the list
    // @param proposalId The ID of the proposal. The ID specifies the exact goal of the proposal
    // @param uint numData Used for: new nRequiredVotes (ID = 3) or balance to send (ID = 4)
    // @param bytes32 bytesData1 Used for: name of member to be accepted (ID = 1) or name of member to be kicked out (ID = 2)
    // @param bytes32 bytesData2 Used for: gateway (ID = 1)
    // @param address addrData Used for: Setting address for all except for ID = 3
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
    
    // @dev This function gets executed by any external Ethereum account, which wants to join the network. 
    //      it has to pay a fee of 0.1 ether (to avoid spam requests) and after that it will get formalised as a proposal
    // @param bytes32 name The Name it will have in the network
    // @param bytes32 gateway The gateway it will have in the network
    function joinRequest(bytes32 name, bytes32 gateway) public payable {
		require(isMember[msg.sender] == false);
		require(msg.value >= 0.1 ether);
		emit JoinRequest("JoinRequest", msg.sender, name, msg.value);
        internalActionProposal(1, 0, name, gateway, msg.sender);
    }
    
    // @dev The same as last function but it gets called by someone who is already a member
    //      organization so that the new member doesn't have to pay any fee (invitation)
    // @param address addr We add the address here, because the function doesn't get called
    //        by the wannabe member but rather by the already a-member, so the new member's
    //        address has to be specified
    function addMemberProposal(bytes32 name, bytes32 gateway, address addr) public {
        require(isMember[msg.sender] == true && isMember[addr] == false);
        internalActionProposal(1, 0, name, gateway, addr);
        votes[nProposals-1][msg.sender] = true;
        proposals[nProposals-1].nVotes++;
        if(nRequiredVotes == 1) executeProposal(nProposals-1);
    }

    // @dev Gets called by a member who specifies the member he wants to kick
    // @param bytes32 name The name of the member which the proposal aims to kick
    // @param address addr The address of the member which the proposal aims to kick
    function kickMemberProposal(bytes32 name, address addr) public {
        require(isMember[msg.sender] == true && isMember[addr] = true);
        internalActionProposal(2, 0, name, "", addr);
        votes[nProposals-1][msg.sender] = true;
        proposals[nProposals-1].nVotes++;
        if(nRequiredVotes == 1) executeProposal(nProposals-1);
    }

    // @dev Gets called by a member who wants to change the number of required votes
    //      to have a proposal executed
    // @param uint newRequirement The new required amount of necesary votes 
    function changeRequiredVotesProposal(uint newRequirement) public {
        require(isMember[msg.sender] == true);
        internalActionProposal(3, newRequirement, "", "", address(this));
        votes[nProposals-1][msg.sender] = true;
        proposals[nProposals-1].nVotes++;
        if(nRequiredVotes == 1) executeProposal(nProposals-1);
    }

    // @dev Gets called by a member. Proposal aims @amount of contract's funds to @receiverAddr
    // @param uint amount The amount to be sent
    // @param bytes32 receiverName Just so that members can know what the name of the funds's receiver is. For administrative purposes
    // @param address receiverAddr The address of the receiver of the funds
    function transferFundsProposal(uint amount, bytes32 receiverName, address receiverAddr) public {
        require(isMember[msg.sender] == true);
        internalActionProposal(4, amount, receiverName, "", receiverAddr);
        votes[nProposals-1][msg.sender] = true;
        proposals[nProposals-1].nVotes++;
        if(nRequiredVotes == 1) executeProposal(nProposals-1);
    }

    // @dev Member gets to vote a proposal and if gets enough amount of votes, gets executed
    // @param uint proposalIndex Proposals are ordered as a list. Specifier
    function voteProposal(uint proposalIndex) public {
		require(proposals[proposalIndex].proposalId > 0);
		require(isMember[msg.sender] == true);
		require(votes[proposalIndex][msg.sender] == false);
		votes[proposalIndex][msg.sender] = true;
		proposals[proposalIndex].nVotes++;
		emit ProposalVoted("ProposalVoted", proposalIndex, proposals[proposalIndex].nVotes, nRequiredVotes);
		if(proposals[proposalIndex].nVotes >= nRequiredVotes) executeProposal(proposalIndex);
    }

    // @dev The opposite of above's function. Proposals that have been executed can't be reverted
	function undoVoteProposal(uint proposalIndex) public {
        require(proposals[proposalIndex].proposalId > 0 && isMember[msg.sender] == true);
		require(votes[proposalIndex][msg.sender] == true);
	    votes[proposalIndex][msg.sender] = false;
		proposals[proposalIndex].nVotes--;
    }

    // @dev Can only be called internally. Executes proposals which have enough required votes
    // @param uint proposalIndex The index of the proposal you want to execute
    function executeProposal(uint proposalIndex) private {
    	require(proposals[proposalIndex].proposalId > 0);
        require(proposals[proposalIndex].nVotes >= nRequiredVotes);
        Proposal memory proposal = proposals[proposalIndex];

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
    
    // @dev Gets queried by members and non-members
    // @param address addr Function tells you if this address has membership
    // @returns a boolean value -> true if addr is a member and false if it isn't registered
    function _isMember(address addr) public view returns (bool) {
        if(isMember[addr]) return true;
        return false;
    }

    // @dev Gets queried by members and non-members
    // @param address addr The address of the member you wanna query info
    // @returns Data about the member (name, gateway)
    function getMember(address addr) public view returns (bytes32, bytes32) {
        require(isMember[addr] == true);
        return (members[addr].name, members[addr].gateway);
    }

    // @dev Lookup the ETH address of a member by using the name
    // @returns The address of the member with the input name
    function getAddressByName(bytes32 name) public view returns (address) {
        return nameToAddress[name];
    }

    // @dev Returns all the data about a proposal
    // @returns (id, numData, strData1, strData2, addrData, nVotes)
    function getProposal(uint proposalIndex) public view returns (uint, uint, bytes32, bytes32, address, uint) {
        return (proposals[proposalIndex].proposalId, proposals[proposalIndex].numData, proposals[proposalIndex].bytesData1,
        proposals[proposalIndex].bytesData2, proposals[proposalIndex].addrData, proposals[proposalIndex].nVotes);
    }

    // @dev Members call this function to change their gateways
    // @param bytes32 newGateway The new gateway for the member caller of the function
    function changeGateway(bytes32 newGateway) public {
        require(isMember[msg.sender] == true);
        members[msg.sender].gateway = newGateway;
        emit GatewayChanged("GatewayChanged", members[msg.sender].name, newGateway);
    }
    
    // @dev To be able to receive external funds. Fallback function.
    function() external payable {}
}
