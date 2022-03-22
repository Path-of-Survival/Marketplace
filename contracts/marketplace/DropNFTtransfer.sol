// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/utils/Arrays.sol";

import "../cryptography/EIP712.sol";
import "../nfts/IPoSNFT.sol";

contract DropNFTtransfer is Ownable, EIP712, ERC721Holder
{
    using SafeERC20 for IERC20;

    mapping (address => bool) public admins;
    mapping (address => uint) sales_counter;
    bytes32 constant BUY_POSNFT_TYPE_HASH = 0xa8d1a88a06141ebe0d1a62d28bf4afc58b965a89994e6a9ac38392c342f4cf9c;

    address[] public erc721_addresses;
    uint[] public token_ids;
    uint quantity_limit;
    uint[] supply;
    address erc20_address;
    uint[] price;
    uint[] end_epoch;
    uint next_nft_index = 0;
    uint initial_total_supply;

    event Initialized(uint _quantity_limit, uint[] _supply, address _erc20_address, uint[] _price, uint[] _end_epoch);
    event Sold(address _buyer, uint _quantity);
    event NFTsAdded(address[] _erc721_addresses, uint[] _token_ids);

    constructor(bytes32 salt) EIP712("DropNFTtransfer", "1.0", salt)
    { }
    
    function initialize(uint _quantity_limit, uint[] calldata _supply, address _erc20_address, uint[] calldata _price, uint[] calldata _end_epoch) external onlyOwner
    {
        require(supply.length == 0 && _supply.length > 0 && _supply.length == _price.length &&  _supply.length == _end_epoch.length, "invalid arguments");
        quantity_limit = _quantity_limit;
        supply = _supply;
        erc20_address = _erc20_address;
        price = _price;
        end_epoch = _end_epoch;
        initial_total_supply = getSupply(supply.length - 1);
        emit Initialized(quantity_limit, supply, erc20_address, price, end_epoch);
    }

    function addNFTs(address[] calldata _erc721_addresses, uint[] calldata _token_ids) public onlyOwner
    {
        require(_erc721_addresses.length == _token_ids.length && _token_ids.length + token_ids.length <= initial_total_supply, "invalid arguments");
        for(uint i = 0; i < _erc721_addresses.length; i++)
        {
            IERC721 nft = IERC721(_erc721_addresses[i]);
            address curr_nft_owner = nft.ownerOf(_token_ids[i]);
            require(curr_nft_owner != address(this), "transfer from current owner");
            nft.safeTransferFrom(curr_nft_owner, address(this), _token_ids[i]);
            erc721_addresses.push(_erc721_addresses[i]);
            token_ids.push(_token_ids[i]);
        }
        emit NFTsAdded(_erc721_addresses, _token_ids);
    }

    function buy(uint quantity, bytes calldata signature) external payable
    {       
        require(token_ids.length == initial_total_supply, "not initialized");
        require(quantity > 0, "invalid quantity");
        uint stage = Arrays.findUpperBound(end_epoch, block.timestamp);
        uint rem_supply = getSupply(stage);
        require(rem_supply >= quantity && sales_counter[_msgSender()] + quantity <= quantity_limit, "sold out");
        bytes32 data_hash = keccak256(abi.encode(BUY_POSNFT_TYPE_HASH, quantity, _msgSender()));
        require(admins[EIP712.verify(data_hash, signature)] == true, "invalid signature");
        uint total_amount = quantity*price[stage];
        if(erc20_address == address(0))
        {
            require(msg.value == total_amount, "msg.value must be equal to quantity*price");
            payable(owner()).transfer(msg.value);
        }
        else
        {
            IERC20 token = IERC20(erc20_address);
            require(token.allowance(_msgSender(), address(this)) >= total_amount, "insufficient allowance");
            token.safeTransferFrom(_msgSender(), owner(), total_amount);
        }
        for(uint i = 0; i < quantity; i++)
        {
            IERC721 nft = IERC721(erc721_addresses[next_nft_index]);
            nft.safeTransferFrom(address(this), _msgSender(), token_ids[next_nft_index]);
            next_nft_index++;
        }
        decreaseSupply(quantity);
        sales_counter[_msgSender()] += quantity;
        emit Sold(_msgSender(), quantity);
    }

    function purchaseQuantityLimit(address buyer) public view returns(uint)
    {
        uint rem_supply = remainingSupply();
        uint rem_buyer_limit = quantity_limit - sales_counter[buyer];
        return rem_buyer_limit <= rem_supply ? rem_buyer_limit : rem_supply;
    }

    function remainingSupply() public view returns(uint)
    {
        uint stage = Arrays.findUpperBound(end_epoch, block.timestamp);
        return getSupply(stage);
    }

    function getSupply(uint stage) private view returns(uint)
    {
        if(stage >= supply.length)
            return 0;
        else
        {
            uint rem_supply = 0;
            for(uint i = 0; i <= stage; i++)
            {
                rem_supply += supply[i];
            }
            return rem_supply;
        }
    }

    function decreaseSupply(uint quantity) private
    {
        for(uint i=0; i < supply.length; i++)
        {
            if(supply[i] >= quantity)
            {
                supply[i] -= quantity;
                break;
            }
            else
            {
                quantity -= supply[i];
                supply[i] = 0;             
            }
        }
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
