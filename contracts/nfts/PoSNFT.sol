// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "../cryptography/EIP712.sol";
import "./IPoSNFT.sol";

contract PoSNFT is ERC721Enumerable, EIP712, Ownable, IPoSNFT
{
    uint immutable public FIRST_GAME_TOKEN_ID;
    uint public next_token_id = 1;
    mapping (address => bool) public admins;
    bytes32 constant private MINT_TYPE_HASH = 0xb6b8501c5eb401a2c658dc6afbd8fc71e530ead458be2ac3f5f322d24727da99; 
    mapping(uint => bool) private withdraw_ids;

    constructor(string memory name, string memory symbol, string memory version, bytes32 salt, uint fist_game_token_id) ERC721(name, symbol) EIP712(name, version, salt)
    {
        FIRST_GAME_TOKEN_ID = fist_game_token_id;
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
        require(tokenId >= FIRST_GAME_TOKEN_ID, "invalid tokenId");
        require(withdraw_ids[withdrawId] == false && admins[EIP712.recoverSigner(generateMintHash(_msgSender(), tokenId, withdrawId), signature)] == true, "invalid signature");
        _mint(_msgSender(), tokenId);
        withdraw_ids[withdrawId] = true;
        emit NFTWithdrawn(_msgSender(), tokenId, withdrawId);
    }

    function cancelMintHash(uint tokenId, uint withdrawId, bytes memory signature) external override
    {
        require(withdraw_ids[withdrawId] == false && admins[EIP712.recoverSigner(generateMintHash(_msgSender(), tokenId, withdrawId), signature)] == true, "invalid signature");
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