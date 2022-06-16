// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Arrays.sol";
import "../../cryptography/EIP712.sol";

interface IPoSNFT
{
    function mintByAdmin(address to) external;
}

contract DropNFTmint_debug is Ownable, EIP712
{
    using SafeERC20 for IERC20;

    mapping (address => bool) public admins;
    mapping (address => uint)[] sales_counter;
    bytes32 constant BUY_POSNFT_TYPE_HASH = 0xa8d1a88a06141ebe0d1a62d28bf4afc58b965a89994e6a9ac38392c342f4cf9c;

    address posnft_address;
    uint[] quantity_limit;
    uint[] supply;
    address erc20_address;
    uint[] price;
    uint[] end_epoch;

    event Initialized(address _posnft_address, uint[] _quantity_limit, uint[] _supply, address _erc20_address, uint[] _price, uint[] _end_epoch);
    event Sold(address indexed _buyer, uint _quantity);

    uint curr_epoch = 1; // block.timestamp 

    constructor(bytes32 salt) EIP712("DropNFTmint", "1.0", salt)
    { }
    
    function initialize(address _posnft_address, uint[] calldata _quantity_limit, uint[] calldata _supply, address _erc20_address, uint[] calldata _price, uint[] calldata _end_epoch) public onlyOwner
    {
        require(supply.length == 0 && _supply.length > 0 && _supply.length == _price.length &&  _supply.length == _end_epoch.length, "invalid arguments");
        posnft_address = _posnft_address;
        quantity_limit = _quantity_limit;
        supply = _supply;
        erc20_address = _erc20_address;
        price = _price;
        end_epoch = _end_epoch;
        for(uint i=0; i<_supply.length;i++)
        {
            sales_counter.push();
        }
        emit Initialized(posnft_address, quantity_limit, supply, erc20_address, price, end_epoch);
    }

    function buy(uint quantity, bytes calldata signature) external payable
    {       
        require(quantity > 0, "invalid quantity");
        uint stage = Arrays.findUpperBound(end_epoch, curr_epoch);
        uint rem_supply = getSupply(stage);
        require(rem_supply >= quantity && sales_counter[stage][_msgSender()] + quantity <= quantity_limit[stage], "sold out");
        bytes32 data_hash = keccak256(abi.encode(BUY_POSNFT_TYPE_HASH, quantity, _msgSender()));
        require(admins[EIP712.recoverSigner(data_hash, signature)] == true, "invalid signature");
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
        IPoSNFT pos_nft = IPoSNFT(posnft_address);
        for(uint i=0; i<quantity; i++)
        {
            pos_nft.mintByAdmin(_msgSender());
        }

        decreaseSupply(quantity);
        sales_counter[stage][_msgSender()] += quantity;
        emit Sold(_msgSender(), quantity);
    }

    function purchaseQuantityLimit(address buyer) public view returns(uint)
    {
        uint stage = Arrays.findUpperBound(end_epoch, curr_epoch);
        if(stage >= supply.length)
            return 0;
        uint rem_supply = getSupply(stage);
        uint rem_buyer_limit = quantity_limit[stage] - sales_counter[stage][buyer];
        return rem_buyer_limit <= rem_supply ? rem_buyer_limit : rem_supply;
    }

    function remainingSupply() public view returns(uint)
    {
        uint stage = Arrays.findUpperBound(end_epoch, curr_epoch);
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

    function setCurrEpoch(uint epoch) public
    {
        curr_epoch = epoch;
    }  
}