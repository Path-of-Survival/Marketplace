// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";


contract TestNFT is Ownable, ERC721Enumerable
{
    enum TYPE { TYPE1, TYPE2, TYPE3 }
    enum RARITY { COMMON, UNCOMMON, RARE, EPIC, LEGENDARY }

    struct ImmutableMetadata
    {
        TYPE _type;
        RARITY _rarity;
    }

    ImmutableMetadata[] public metadata;
    mapping(uint => uint) public _index_to_token_id;
    mapping(uint => uint) public _token_id_to_index;

    constructor() ERC721("TestNFT", "TNFT") 
    {
        mint(owner(), 1, TYPE.TYPE1, RARITY.LEGENDARY);
    }

    function getMetadata(uint token_id) public view returns( ImmutableMetadata memory) 
    {
        require(_exists(token_id), "ERC721: operator query for nonexistent token");
        return metadata[_token_id_to_index[token_id]];
    }
    
    function mint(address account, uint token_id, TYPE _type, RARITY _rarity) public onlyOwner
    {
        _mint(account, token_id);
        addTokenMetadata(token_id, ImmutableMetadata(_type, _rarity) );
    }

    function burn(uint256 token_id) public  
    {
        require(super._isApprovedOrOwner(_msgSender(), token_id), "caller is not owner nor approved");
        super._burn(token_id);
        removeTokenMetadata(token_id);
    }

    function addTokenMetadata(uint token_id, ImmutableMetadata memory land_metadata) internal
    {
        _index_to_token_id[metadata.length] = token_id;
        _token_id_to_index[token_id] = metadata.length;
        metadata.push(land_metadata);
    }
    
    function removeTokenMetadata(uint token_id) internal
    {        
        ImmutableMetadata memory last_token_metadata = metadata[metadata.length - 1];
        uint last_token_id = _index_to_token_id[metadata.length - 1];

        uint toremove_index = _token_id_to_index[token_id];

        metadata[toremove_index] = last_token_metadata; 
        _index_to_token_id[toremove_index] = last_token_id;
        _token_id_to_index[last_token_id] = toremove_index; 
      
        delete _token_id_to_index[token_id];
        delete _index_to_token_id[metadata.length - 1];
        metadata.pop();
    }
    
    function _baseURI() internal view virtual override returns (string memory)
    {
        return "https://my_domain.com/";
    }
   
}


