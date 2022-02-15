// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract FixedPrice is Ownable, ERC721Holder
{
    using SafeERC20 for IERC20; 
    struct Item
    {
        address erc721_address;
        uint token_id;
        address owner;
        address erc20_address;
        uint price;
        uint commission_rate;      
        uint item_id;
    }    
    Item[] items;
    mapping(uint => uint) private id_to_index;
    uint private next_id = 1;
    uint public commission_rate_promille = 20;
    mapping(address => bool) public accepted_nfts;
    mapping(address => bool) public accepted_tokens;
    
    event Created(uint _item_id, address _nft_address, uint _token_id, address _owner, address _erc20_address, uint _price, uint _commission_rate);
    event Sold(uint _item_id, address _buyer);
    event Deleted(uint _item_id);
    event CommissionRateChanged(uint _commission_rate);
    
    constructor() 
    { 
//        accepted_tokens[0xd9145CCE52D386f254917e481eB44e9943F39138] = true;
    }
    
    function sellNFTForETH(address erc721_address, uint token_id, uint price) external
    {
        require(accepted_nfts[erc721_address] == true, "erc721_address is not supported");
        IERC721 erc721_smc = IERC721(erc721_address);
        require(erc721_smc.ownerOf(token_id) == _msgSender(), "you are not the owner");
        id_to_index[next_id] = items.length + 1;
        items.push(Item(erc721_address, token_id, _msgSender(), address(0), price, commission_rate_promille, next_id));
        erc721_smc.safeTransferFrom(_msgSender(), address(this), token_id);
        emit Created(next_id, erc721_address, token_id, _msgSender(), address(0), price, commission_rate_promille);
        next_id = next_id + 1;
    }

    function sellNFTForTokens(address erc721_address, uint token_id, address erc20_address, uint price) external
    {
        require(accepted_nfts[erc721_address] == true, "erc721_address is not supported");
        require(accepted_tokens[erc20_address] == true, "erc20_address is not supported");
        IERC721 erc721_smc = IERC721(erc721_address);
        require(erc721_smc.ownerOf(token_id) == _msgSender(), "you are not the owner");
        id_to_index[next_id] = items.length + 1;
        items.push(Item(erc721_address, token_id, _msgSender(), erc20_address, price, commission_rate_promille, next_id));
        erc721_smc.safeTransferFrom(_msgSender(), address(this), token_id);
        emit Created(next_id, erc721_address, token_id, _msgSender(), erc20_address, price, commission_rate_promille);
        next_id = next_id + 1;
    }

    function removeItem(uint item_id) external
    {
        uint item_index = id_to_index[item_id];
        require(item_index > 0, "nonexistent item");
        item_index = item_index - 1;
        require(items[item_index].owner == _msgSender(), "you are not the owner");
        _removeItem(item_id, item_index);
        emit Deleted(item_id);
    }
    
    function buyWithETH(uint item_id) external payable
    {
        uint item_index = id_to_index[item_id];
        require(item_index > 0, "nonexistent item");
        item_index = item_index - 1;
        require(items[item_index].erc20_address == address(0), "use buyWithTokens function");
        require(items[item_index].owner != _msgSender(), "you are the owner");
        require(msg.value == items[item_index].price, "msg.value must be equal to price");
        uint fee = (items[item_index].price*items[item_index].commission_rate)/1000;
        payable(owner()).transfer(fee);
        payable(items[item_index].owner).transfer(items[item_index].price - fee);
        IERC721 erc721_smc = IERC721(items[item_index].erc721_address);
        erc721_smc.safeTransferFrom(address(this), _msgSender(), items[item_index].token_id);
        emit Sold(item_id, _msgSender());
        _removeItem(item_id, item_index);          
    }

    function buyWithTokens(uint item_id) external
    {
        uint item_index = id_to_index[item_id];
        require(item_index > 0, "nonexistent item");
        item_index = item_index - 1;
        require(items[item_index].erc20_address != address(0), "use buyWithETH function");
        require(items[item_index].owner != _msgSender(), "you are the owner");
        IERC20 token = IERC20(items[item_index].erc20_address);
        uint fee = (items[item_index].price*items[item_index].commission_rate)/1000;
        token.safeTransferFrom(_msgSender(), owner(), fee);
        token.safeTransferFrom(_msgSender(), items[item_index].owner, items[item_index].price - fee);
        IERC721 erc721_smc = IERC721(items[item_index].erc721_address);
        erc721_smc.safeTransferFrom(address(this), _msgSender(), items[item_index].token_id);
        emit Sold(item_id, _msgSender());
        _removeItem(item_id, item_index);          
    }
      
    function getItem(uint item_id) view public returns(Item memory)
    {
        uint item_index = id_to_index[item_id];
        require(item_index > 0, "nonexistent item");
        return items[item_index - 1];
    }

    function exists(uint item_id) view public returns(bool)
    {
        uint item_index = id_to_index[item_id];
        if(item_index > 0)
            return true;
        else
            return false;
    }

    function _removeItem(uint item_id, uint item_index) private
    {
        items[item_index] = items[items.length - 1];
        id_to_index[items[items.length - 1].item_id] = item_index + 1;
        delete id_to_index[item_id];
        items.pop();     
    }

    function setCommission(uint new_commission_rate) external onlyOwner
    {
        commission_rate_promille = new_commission_rate;
        emit CommissionRateChanged(commission_rate_promille);
    }

    function addNFTAddress(address erc721_address) external onlyOwner
    {
        accepted_nfts[erc721_address] = true;
    }

    function removeNFTAddress(address erc721_address) external onlyOwner
    {
        accepted_nfts[erc721_address] = false;
    }

    function addTokenAddress(address erc20_address) external onlyOwner
    {
        accepted_tokens[erc20_address] = true;
    }

    function removeTokenAddress(address erc20_address) external onlyOwner
    {
        accepted_tokens[erc20_address] = false;
    }
  
}
