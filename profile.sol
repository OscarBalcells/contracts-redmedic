pragma solidity ^0.5.1;
import "./acta.sol";

contract Profile {

    struct Permissions {
        bool fullAccess;
        uint fullAccessRevokeAt;
        bytes32[] cats;
        bool exists;
    }
    
    struct Relationship {
        bytes32 name;
        address addr;
		bytes32 gateway;
        mapping(address => Permissions) public permissions;        
        bool exists;
    }

    address payable public constant actaAddr = 0x23702ecb660A2b10e6D1c47c6ECbC8F410980f56;
    Acta public acta = Acta(actaAddr);
    address private admin;    
    uint nRelationships;
    mapping (bytes32 => Relationship) private relationships;
    bytes32[] names;

    constructor() public {
        admin = msg.sender;
    }
    
    @dev Function gets called by health provider, which must be certified in the acta, which establishes relationship with patient owner of this contract @admin
    function newRelationship() public {
        //query Acta to see if it's a certified member
        require(acta._isMember(msg.sender) == true);

        bytes32 name, gateway;
        (name, gateway) = acta.getMember(msg.sender); //query data about certified member
        require(relationships[name].exists == false); //it can't already be added
        
        relationships[name] = Relationship({
            name: name,
            addr: msg.sender,
            gateway: gateway,
            exists: true
        });
        names.push(name);
    }

    @dev admin of the contract ends a relationship. Data of the relationship will be kept to avoid computations but it will be marked as non-existent
    @param bytes32 name Name of the relationship (the name of the provider)
    function deleteRelationship(bytes32 name) public {
        require(msg.sender == admin);
        if(relationships[name].exists == false) { revert(); }
        
        //delete the name
        for(uint i = 0; i < nRelationships; i++) {
            if(names[i] == name) {
                if(i < nRelationships-1) names[i] = names[nRelationships-1];
                names.length--;
                break;
            }
        }
        nRelationships--;
        relationships[name].exists = false;
    }

    @dev admin grants a certain address @addr access to a section of a relationship's data for an indefinite or specific amount of time
    @param bytes32 name The name of the relationship the admin changes access permissions (Can't be "all")
    @param address addr The address / Ethereum account which will be granted access to some information
    @param bytes32 section The section the address will be able to see (Can be "all" for full access)
    @param uint nHours The number of hours the address will be granted access. If nHours == 0 it will have access until it manually gets revoked by admin
	function grantAccess(bytes32 name, address addr, bytes32 section, uint nHours) public {
		require(msg.sender == admin);
        if(nHours > 0) relationships[name].permissions[addr].fullAccessRevokeAt = block.timestamp + (1 hours * nHours);
        else if(section == "all") relationships[name].permissions[addr].fullAccess = true;
        else relationships[name].permissions[addr].cats.push(section)
	}

    @dev admin revokes a certain address @addr access to the section (Can be "all") to the data included in a relationship, which goes by name @name
    @param bytes32 name The name of the relationship
    @param address addr The address which will be taken out access
    @param bytes32 section The name of the section
	function revokeAccess(bytes32 name, address addr, bytes32 section) public {
		require(msg.sender == admin);
        if(section == "all") relationships[name].permissions[addr].fullAccess = false;
        else {
            bytes32[] memory cats = relationships[name].permissions[addr].cats;
            for(uint i = cats.length-1; i >= 0; i--) {
                if(cats[i] == section) {
                    cats[i] = cats[cats.length-1];
                    cats.length--;
                }
            }
            relationships[name].permissions[addr].cats = cats;
        }
	}

    @dev Function to query the contract if a certain address @addr has access to @section included in relationship called @name
    @param bytes32 name Name of the relationship which includes the data
    @param address addr The address we want to know the data about
    @param bytes32 section The section of the data inside the relationship
    @returns Returns true if @addr has access to that section inside that relationship, otherwise returns false
    function hasAccess(bytes32 name, address addr, bytes32 section) public view returns (bool) {
        require(relationships[name].exists == true);
        if(addr == admin || relationships[name].permissions[addr].fullAccess == true) return true;
        else if(relationships[name].permissions[addr].fullAccessRevokeAt > block.timestamp) return true;
        for(uint i = 0; i < relationships[name].permissions[addr].cats; i++) if(section == relationships[name].permissions[addr].cats[i]) return true;
        return false;
    }

    @dev Function to query the contract the list of all the API gateways which store data about the admin of the contract
    @returns Returns a list of strings, whereas each string is an IP and a Port to access the API
    function returnGateways() public view returns (bytes32[] memory) {
        bytes32[] memory out;
        for(uint i = 0; i < nRelationships; i++) {
            out.push(relationships[names[i]].name);
        }
        return out;
    }

    @dev Function to query the contract the list of all relationships the admin of the contract has
    @returns Returns a list of strings, whereas each string is the name of a provider, which has a relationship with the admin of the contract
    function returnNames() public view returns (bytes32[] memory) {
        bytes32[] memory out;
        for(uint i = 0; i < nRelationships; i++) {
            out.push(names[i]);
        }
        return out;
    }

    @param bytes32 name The name of the relationship you want to query
    @returns Returns some data about the relationship including: the address of the health provider, gateway to access its API
    function getRelationship(bytes32 name) public view returns (address, bytes32) {
        require(relationships[name].exists == true);
        return (relationships[name].addr, relationsips[name].gateway);
    }
}

