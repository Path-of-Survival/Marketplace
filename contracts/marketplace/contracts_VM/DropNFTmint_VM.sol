// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/Arrays.sol";

import "../../cryptography/EIP712.sol";
import "../../nfts/IPoSNFT.sol";

contract DropNFTmint is Ownable, EIP712
{
    using SafeERC20 for IERC20;

    mapping (address => bool) public admins;
    mapping (address => uint) public sales_counter;
    bytes32 constant private BUY_POSNFT_TYPE_HASH = 0xa8d1a88a06141ebe0d1a62d28bf4afc58b965a89994e6a9ac38392c342f4cf9c;

    address public posnft_address;
    uint public quantity_limit;
    uint[] public supply;
    address erc20_address;
    uint[] public price;
    uint[] public end_epoch;

    event Initialized(address _posnft_address, uint _quantity_limit, uint[] _supply, address _erc20_address, uint[] _price, uint[] _end_epoch);
    event Sold(address _buyer, uint _quantity);

    uint curr_epoch = 1; // block.timestamp 

    constructor(bytes32 salt) EIP712("DropNFT", "1.0", salt)
    { }
    
    function initialize(address _posnft_address, uint _quantity_limit, uint[] calldata _supply, address _erc20_address, uint[] calldata _price, uint[] calldata _end_epoch) external onlyOwner
    {
        require(supply.length == 0 && _supply.length > 0 && _supply.length == _price.length &&  _supply.length == _end_epoch.length, "invalid arguments");
        posnft_address = _posnft_address;
        quantity_limit = _quantity_limit;
        supply = _supply;
        erc20_address = _erc20_address;
        price = _price;
        end_epoch = _end_epoch;
        emit Initialized(posnft_address, quantity_limit, supply, erc20_address, price, end_epoch);
    }

    function buy(uint quantity, bytes calldata signature) external payable
    {       
        require(quantity > 0, "invalid quantity");
        uint stage = Arrays.findUpperBound(end_epoch, curr_epoch);
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
        IPoSNFT(posnft_address).mintByAdmin(_msgSender(), quantity);
        decreaseSupply(quantity);
        sales_counter[_msgSender()] += quantity;
        emit Sold(_msgSender(), quantity);
    }

    function getSupply(uint stage) public view returns(uint)
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