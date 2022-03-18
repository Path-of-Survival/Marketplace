// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./PoSNFT.sol";

contract TestNFT is PoSNFT
{
    uint constant public fist_game_token_id = 50;
    string base_uri = "https://mydomain.com/";
    constructor() PoSNFT("NFT TEST", "NFTTEST", "1.0", 0x4fee8aba7062d1d9525c383a8d7b7bd91c3524dfa82069b3571291aec685184c, fist_game_token_id) 
    {
        for(uint i=0;i<50;i++)
            _mint(0x8626f6940E2eb28930eFb4CeF49B2d1F2C9C1199, fist_game_token_id + 2*i);
    }

    function mint(uint tokenId) public
    {
        _mint(_msgSender(), tokenId);
    }

    function setBaseURI(string memory new_base_uri) external
    {
        base_uri = new_base_uri;
        
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return base_uri;
    }

    function burn(uint256 tokenId) public {
        require(super._isApprovedOrOwner(_msgSender(), tokenId), "ERC721Burnable: caller is not owner nor approved");
        super._burn(tokenId);
    }
   
}
