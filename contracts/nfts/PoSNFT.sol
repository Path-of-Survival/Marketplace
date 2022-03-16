// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "../cryptography/EIP712.sol";
import "./IPoSNFT.sol";

contract PoSNFT is ERC721, EIP712, Ownable, IPoSNFT
{
    uint constant public FIRST_GAME_TOKEN_ID = 1000000;
    uint public next_token_id = 1;
    mapping (address => bool) public admins;
    bytes32 constant private MINT_TYPE_HASH = 0x4be54700c1c588568e41c1f2f24fd476dee9ec8f1e71f088d4a8e24bda925241; 
    mapping(uint => bool) private withdraw_ids;

    constructor() ERC721("PoSNFT", "PNFT") EIP712("PoSNFT", "1.0", 0x58af7b5043c35f089c99b49c810a9708a9e3adf6e16f94503cad160c62c64408)
    {
        admins[_msgSender()] = true;
    }

    function mintByAdmin(address to, uint quantity) public override
    {
        require(admins[_msgSender()] == true, "the caller does not have permissions");
        require(next_token_id + quantity <= FIRST_GAME_TOKEN_ID, "Exceeds reserved quantity");
        for(uint i=0; i < quantity; i++)
        {
            _mint(to, next_token_id++);
        }
    }
    
    function generateMintHash(address to, uint tokenId, uint withdrawId) pure internal returns(bytes32)
    {
        return keccak256(abi.encode(MINT_TYPE_HASH, to, tokenId, withdrawId));
    }

    function mintWithHash(uint tokenId, uint withdrawId, bytes memory signature) external override
    {
        require(withdraw_ids[withdrawId] == false && admins[EIP712.verify(generateMintHash(_msgSender(), tokenId, withdrawId), signature)] == true, "invalid signature");
        _mint(_msgSender(), tokenId);
        withdraw_ids[withdrawId] = true;
        emit NFTWithdrawn(_msgSender(), tokenId, withdrawId);
    }

    function cancelMintHash(uint tokenId, uint withdrawId, bytes memory signature) external override
    {
        require(withdraw_ids[withdrawId] == false && admins[EIP712.verify(generateMintHash(_msgSender(), tokenId, withdrawId), signature)] == true, "invalid signature");
        withdraw_ids[withdrawId] = true;
        emit WithdrawRequestCancelled(withdrawId);
    }

    function addAdmin(address admin) external onlyOwner
    {
        admins[admin] = true;
    }

    function removeAdmin(address admin) external onlyOwner
    {
        admins[admin] = false;
    }
}