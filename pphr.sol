pragma solidity ^0.5.1;
import "./acta.sol";
import "./mphr.sol";

contract PartialPHR {

    event Notification(bytes32 eventName);

    address private patient;
    address public provider;
    address payable actaAddr = 0x23702ecb660A2b10e6D1c47c6ECbC8F410980f56;
    Acta acta;

    mapping(bytes32 => mapping(address => bool)) public access;
    mapping(address => bool) fullAccess;
    mapping(bytes32 => mapping(address => uint)) public accessRevokeAt;
    mapping(address => uint) public fullAccessRevokeAt;

    mapping(bytes32 => uint) public indexOfSection;
    bytes32[] public sectionList;

    //gets created by provider
    constructor(address _patient, bytes32[] memory sections) public {

        patient = _patient;
        provider = msg.sender;

        acta = Acta(actaAddr);
        require(acta._isMember(provider) == true);

        /*
        MPHR masterPHR = MPHR(patient);
        masterPHR.newPartialPHR(provider, name);
        */

        for(uint i = 0; i < sections.length; i++) {
            sectionList.push(sections[i]);
            indexOfSection[sections[i]] = i;
        }

        fullAccess[provider] = true;
        fullAccess[patient] = true;
    }

		//edit permissions
		//if nHours == 0 -> indefinite amount of time
		//else finite amount of time
		//
		//if section == all -> will be able to access all sections
		//else only access sections marked
    function grantAccess(address account, bytes32 section, uint nHours) public {
        require(msg.sender == patient);
		if(section == "all") {
			if(nHours == 0) {
			    fullAccess[account] = true;
			} else {
				uint willBeRevokedAt = block.timestamp + 1 hours * nHours;
				fullAccessRevokeAt[account] = willBeRevokedAt;
			}
	    } else {
			if(nHours == 0) {
				access[section][account] = true;
			} else {
				uint willBeRevokedAt = block.timestamp + 1 hours * nHours;
				accessRevokeAt[section][account] = willBeRevokedAt;
			}
		}
    }

    function revokeAccess(address account, bytes32 section) public {
        require(msg.sender == patient);
		if(section == "all") {
			fullAccess[account] = true;
			fullAccessRevokeAt[account] = 0;
			//we have to take out all permissions
			for(uint i = 0; i < sectionList.length; i++) {
				access[sectionList[i]][account] = false;
				accessRevokeAt[sectionList[i]][account] = 0;
			}
		} else {
			//revoke everything related to this section
			access[section][account] = false;
			accessRevokeAt[section][account] = 0;
		}
    }

    ///modify sections

    function addSection(bytes32 newSection) public {
        require(msg.sender == provider);
        sectionList.push(newSection);
        indexOfSection[newSection] = sectionList.length-1;
    }

    function deleteSection(bytes32 deletedSection) public {
        require(msg.sender == provider);
        uint index = indexOfSection[deletedSection];
        if(sectionList.length > 1) {
            sectionList[index] = sectionList[sectionList.length-1];
        }
        sectionList.length--; //automatically clears last element from array
    }

    ///external query functions

    function hasAccess(address account, bytes32 section) public view returns (bool) {
        if(fullAccess[account] == true) return true;
        else if(fullAccessRevokeAt[account] > block.timestamp) return true;

				if(access[section][account] == false && accessRevokeAt[section][account] < block.timestamp) {
					return false;
				}
        return true;
    }

    function getSections() public view returns (bytes32[] memory) {
        return sectionList;
    }

    ///SELFDESTROY

    function destroy() public {
        require(msg.sender == patient);
        address payable actaPayableAddr = address(uint160(address(actaAddr)));
        selfdestruct(actaPayableAddr);
    }

    ///INFO INSIDE PPHR CHANGED, SO WE EMIT NOTIFICATION

    function emitNotification() public {
        require(msg.sender == provider);
        emit Notification("InformationEdited");
    }

}
