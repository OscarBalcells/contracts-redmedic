pragma solidity ^0.5.1;
import "./pphr.sol";
import "./acta.sol";

contract MasterPHR {

    struct PPHR {
        bytes32 providerName;
        address providerAddr;
				bytes32 gateway;
        address pphrAddr;
        bool exists;
    }

    address payable public constant actaAddr = 0x23702ecb660A2b10e6D1c47c6ECbC8F410980f56;
    Acta public acta = Acta(actaAddr);

    bytes32 public id;
    address private patientAddr;

		//important ones
    mapping (bytes32 => PPHR) private pphrs;
    mapping (bytes32 => PPHR) private pphrsUnconfirmed;

    mapping (address => bytes32) private addrToName;
    bytes32[] private providerNameList;
    mapping (bytes32 => uint) gatewayAtIndex;
    bytes32[] private gateways;

    constructor(bytes32 _id) public {
        id = _id;
        patientAddr = msg.sender;
    }

		//gets sent by the provider who establishes the pphr relationship
    function newPPHR(address pphrAddr) public {
        require(acta._isMember(msg.sender) == true);

        bytes32 providerName; bytes32 gateway;
        (providerName, gateway) = acta.getMember(msg.sender);

        require(pphrs[providerName].exists == false);
        require(pphrsUnconfirmed[providerName].exists == false);

        pphrsUnconfirmed[providerName] = PPHR({
            providerName: providerName,
            providerAddr: msg.sender,
						gateway: gateway,
            pphrAddr: pphrAddr,
            exists: true
        });

        addrToName[msg.sender] = providerName;
        addrToName[pphrAddr] = providerName;
    }

		//gets sent by the patient owner of this contract
    function confirmPPHR(bytes32 name) public {
				require(msg.sender == patientAddr);
        require(pphrs[name].exists == false);
        require(pphrsUnconfirmed[name].exists == true);

        pphrs[name] = pphrsUnconfirmed[name];
        gateways.push(pphrs[name].gateway);
        gatewayAtIndex[pphrs[name].gateway] = gateways.length-1;
        delete pphrsUnconfirmed[name];
    }

    ///Interaction with Partial PHR's

    function deletePPHR(bytes32 name) public {
        require(msg.sender == patientAddr);
        bytes32 gateway;

        if(pphrs[name].exists == true) {
            PartialPHR pphr = PartialPHR(pphrs[name].pphrAddr);
            gateway = pphrs[name].gateway;
            pphr.destroy();
        } else if(pphrsUnconfirmed[name].exists == true) {
            PartialPHR pphr = PartialPHR(pphrsUnconfirmed[name].pphrAddr);
            gateway = pphrs[name].gateway;
            pphr.destroy();
            return;
        } else {
            revert();
        }

				//delete the gateway from the list
        uint index = gatewayAtIndex[gateway];
        gateways[index] = gateways[gateways.length-1];
        gatewayAtIndex[gateways[index]] = index;
        gateways.length--;
    }

	function grantAccess(bytes32 name, address addr, bytes32 section, uint nHours) public {
		require(msg.sender == patientAddr);
		address pphrAddr = pphrs[name].pphrAddr;
		PartialPHR pphr = PartialPHR(pphrAddr);
		pphr.grantAccess(addr, section, nHours);
	}

	function revokeAccess(bytes32 name, address addr, bytes32 section) public {
		require(msg.sender == patientAddr);
		address pphrAddr = pphrs[name].pphrAddr;
		PartialPHR pphr = PartialPHR(pphrAddr);
		pphr.revokeAccess(addr, section);
	}

    ///EXTERNAL QUERY FUNCTIONS

    function returnGateways() public view returns (bytes32[] memory) {
        require(msg.sender == patientAddr);
        return gateways;
    }

    function getPPHR(bytes32 name) public view returns (address providerAddr,
    address pphrAddr, bytes32 gateway) {
        require(pphrs[name].exists == true);
        require(msg.sender == patientAddr);
        return (pphrs[name].providerAddr,
        pphrs[name].pphrAddr, pphrs[name].gateway);
    }
}
