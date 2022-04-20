// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract Auction is Ownable, ERC721Holder
{
    using SafeERC20 for IERC20; 
    struct Item
    {
        uint start_epoch;
        uint end_epoch;
        address erc721_address;
        uint token_id;
        address owner;
        address erc20_address;
        uint last_price;
        uint min_price;
        uint price_step;
        address last_bidder;
        uint commission_rate;      
        uint item_id;     
    }
    
    uint curr_epoch = 1; // block.timestamp 
    
    uint constant public extend_time = 5; //minutes
    
    Item[] private items;
    mapping(uint => uint) private id_to_index;
    uint public next_id = 1;
    uint public commission_rate_promille = 20;
    mapping(address => bool) public accepted_nfts;
    mapping(address => bool) public accepted_tokens;
    
    event Created(uint _item_id, uint _start_epoch, uint _end_epoch, address _nft_address, uint _token_id, address _owner, address _erc20_address, uint _min_price, uint _price_step, uint _commission_rate);
    event Bid(uint _item_id, uint _end_epoch, address _bidder, uint _last_price);
    event Finished(uint _item_id);
    event CommissionRateChanged(uint _commission_rate);
    
    constructor() 
    { 

    }
    
    function sellNFTForETH(uint start_epoch, uint end_epoch, address erc721_address, uint token_id, uint min_price, uint price_step) public
    {
//        require(accepted_nfts[erc721_address] == true, "erc721_address is not supported");
        require(start_epoch > curr_epoch && start_epoch < end_epoch, "start_epoch/end_epoch is not valid");
        IERC721 erc721_smc = IERC721(erc721_address);
        require(erc721_smc.ownerOf(token_id) == _msgSender(), "you are not the owner");
        id_to_index[next_id] = items.length + 1;
        items.push(Item(start_epoch, end_epoch, erc721_address, token_id, _msgSender(), address(0), 0, min_price, price_step, _msgSender(), commission_rate_promille, next_id));
        erc721_smc.safeTransferFrom(_msgSender(), address(this), token_id);
        emit Created(next_id, start_epoch, end_epoch, erc721_address, token_id, _msgSender(), address(0), min_price, price_step, commission_rate_promille);
        next_id = next_id + 1;
    }

    function sellNFTForTokens(uint start_epoch, uint end_epoch, address erc721_address, uint token_id, address erc20_address, uint min_price, uint price_step) public
    {
//        require(accepted_nfts[erc721_address] == true, "erc721_address is not supported");
//        require(accepted_tokens[erc20_address] == true, "erc20_address is not supported");
        require(start_epoch > curr_epoch && start_epoch < end_epoch, "start_epoch/end_epoch is not valid");
        IERC721 erc721_smc = IERC721(erc721_address);
        require(erc721_smc.ownerOf(token_id) == _msgSender(), "you are not the owner");
        id_to_index[next_id] = items.length + 1;
        items.push(Item(start_epoch, end_epoch, erc721_address, token_id, _msgSender(), erc20_address, 0, min_price, price_step, _msgSender(), commission_rate_promille, next_id));
        erc721_smc.safeTransferFrom(_msgSender(), address(this), token_id);
        emit Created(next_id, start_epoch, end_epoch, erc721_address, token_id, _msgSender(), erc20_address, min_price, price_step, commission_rate_promille);
        next_id = next_id + 1;
    }
    
    function placeBidWithETH(uint item_id) public payable
    {
        uint item_index = id_to_index[item_id];
        require(item_index > 0, "nonexistent item");
        item_index = item_index - 1;
        require(items[item_index].erc20_address == address(0), "use placeBidWithTokens function");
        require(items[item_index].start_epoch <= curr_epoch && curr_epoch <= items[item_index].end_epoch, "auction is not active");
        require(items[item_index].last_bidder != _msgSender(), "you are the highest bidder");
        require(msg.value >= items[item_index].min_price && msg.value >= items[item_index].last_price + items[item_index].price_step, "bid is too low");
        if(items[item_index].last_price > 0)
            payable(items[item_index].last_bidder).transfer(items[item_index].last_price);
        items[item_index].last_price = msg.value;
        items[item_index].last_bidder = _msgSender();
        if(curr_epoch + extend_time > items[item_index].end_epoch)
        {
            items[item_index].end_epoch = curr_epoch + extend_time;
        }
        emit Bid(item_id, items[item_index].end_epoch, items[item_index].last_bidder, items[item_index].last_price);
    }

    function placeBidWithTokens(uint item_id, uint amount) public
    {
        uint item_index = id_to_index[item_id];
        require(item_index > 0, "nonexistent item");
        item_index = item_index - 1;
        require(items[item_index].erc20_address != address(0), "use placeBidWithETH function");
        require(items[item_index].start_epoch <= curr_epoch && curr_epoch <= items[item_index].end_epoch, "auction is not active");
        require(items[item_index].last_bidder != _msgSender(), "you are the highest bidder");     
        require(amount >= items[item_index].min_price && amount >= items[item_index].last_price + items[item_index].price_step, "bid is too low");
        IERC20 token = IERC20(items[item_index].erc20_address);
        token.safeTransferFrom(_msgSender(), address(this), amount);
        if(items[item_index].last_price > 0)
            token.transfer(items[item_index].last_bidder, items[item_index].last_price);
        items[item_index].last_price = amount;
        items[item_index].last_bidder = _msgSender();
        if(curr_epoch + extend_time > items[item_index].end_epoch)
        {
            items[item_index].end_epoch = curr_epoch + extend_time;
        }
        emit Bid(item_id, items[item_index].end_epoch, items[item_index].last_bidder, items[item_index].last_price);
    }

    function exchange(uint item_id) public
    {
        uint item_index = id_to_index[item_id];
        require(item_index > 0, "nonexistent item");
        item_index = item_index - 1;
        require(curr_epoch > items[item_index].end_epoch, "auction is still ongoing");
        IERC721(items[item_index].erc721_address).safeTransferFrom(address(this), items[item_index].last_bidder, items[item_index].token_id);
        uint fee = (items[item_index].last_price*items[item_index].commission_rate)/1000;
        if(items[item_index].erc20_address == address(0))
        {
            payable(owner()).transfer(fee);
            payable(items[item_index].owner).transfer(items[item_index].last_price - fee);
        }
        else
        {
            IERC20 token = IERC20(items[item_index].erc20_address);
            token.transfer(owner(), fee);
            token.transfer(items[item_index].owner, items[item_index].last_price - fee);
        }
        emit Finished(item_id);
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

    function setCommission(uint new_commission_rate) public onlyOwner
    {
        commission_rate_promille = new_commission_rate;
        emit CommissionRateChanged(commission_rate_promille);
    }

    function renounceOwnership() public virtual override onlyOwner 
    {
        super.renounceOwnership();
        setCommission(0);
    }
    
    function setCurrEpoch(uint epoch) public
    {
        curr_epoch = epoch;
    }  
}
