// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

contract TestNFT is ERC721Enumerable
{
    uint constant public MAX_SUPPLY = 50;
    string base_uri = "https://mydomain.com/";
    constructor() ERC721("NFT TEST", "NFTTEST") 
    {
        for(uint i=1;i<=MAX_SUPPLY;i++)
            _mint(0x8626f6940E2eb28930eFb4CeF49B2d1F2C9C1199, 2*i);
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
