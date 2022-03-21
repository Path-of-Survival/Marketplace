// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./DropNFTmint.sol";

contract DropNFTFactory 
{
    event DropCreated(address _drop_contract_address, bytes32 _salt);

    function createDropNFTmint(bytes32 salt, address new_owner) public returns(address)
    {
        DropNFTmint drop_contract = new DropNFTmint(salt);
        drop_contract.transferOwnership(new_owner);
        address drop_contract_address = address(drop_contract);
        emit DropCreated(drop_contract_address, salt);
        return drop_contract_address;
    }
}