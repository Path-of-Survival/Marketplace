// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract TestToken is ERC20
{
    constructor() ERC20("TestToken", "TTT")
    {
        _mint(_msgSender(), 10000000000);
    }
}