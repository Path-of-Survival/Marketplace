// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./PoSNFT.sol";

contract TestPoSNFT is PoSNFT
{
    uint constant public fist_game_token_id = 1000000;
    string base_uri = "https://mydomain.com/";
    constructor() PoSNFT("TestPoSNFT", "PoSTNFT", "1.0", 0x4fee8aba7062d1d9525c383a8d7b7bd91c3524dfa82069b3571291aec685184c, fist_game_token_id) 
    {
    
    }

    function mint() public
    {
        _mint(_msgSender(), totalSupply());
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
