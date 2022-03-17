// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract TestToken is ERC20
{
    constructor() ERC20("FakeUSD", "FUSD")
    {
        _mint(_msgSender(), 10000000);
    }
	
    function decimals() public view virtual override returns (uint8) {
        return 0;
    }
}