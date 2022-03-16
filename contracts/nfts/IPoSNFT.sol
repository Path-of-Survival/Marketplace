// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IPoSNFT
{
    function mintByAdmin(address to, uint quantity) external;
  
    function mintWithHash(uint tokenId, uint withdrawId, bytes memory signature) external;

    function cancelMintHash(uint tokenId, uint withdrawId, bytes memory signature) external;
        
    event NFTWithdrawn(address _to, uint tokenId, uint _withdrawId);
 
    event WithdrawRequestCancelled(uint _withdrawId);
}