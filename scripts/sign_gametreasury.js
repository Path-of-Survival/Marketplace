// Right click on the script name and hit "Run" to execute
(async () => {
    try {
        console.log('Running GameTreasury sign test...')
    
 /*       const contractName = 'EIP712' // Change this for other contract
        const constructorArgs = []    // Put constructor args (if any) here for your contract

        // Note that the script needs the ABI which is generated from the compilation artifact.
        // Make sure contract is compiled and artifacts are generated
        const artifactsPath = `browser/contracts/artifacts/${contractName}.json` // Change this for different path
    
        const metadata = JSON.parse(await remix.call('fileManager', 'getFile', artifactsPath))
*/
        const account = (await web3.eth.getAccounts())[0];

        console.log("address", account)

        const name = "GameTreasury";
        const version = "1.0";
        const chain_id = await web3.eth.getChainId();
        const contract_address = "0x419CE7EdBd0C56B400359BDb9C0523906E2b5439";
        const salt = "0x58af7b5043c35f089c99b49c810a9708a9e3adf6e16f94503cad160c62c64408";

        const token_address = "0xC25E37C510C2571c5AD8684Dd1b2F3A0C37E9710";
        const nft_address = "0x1Bc3d593F90215935c4d47807210aa76F66e4c2c";
        
        const domain_separator = domainSeparator(name, version, chain_id, contract_address, salt); 
        
//        console.log(domain_separator);
//        console.log( claimERC721Hash(nft_address, "0xA2D887D1116B9B6620eAC4352cdB271735B8Dc89", 11, 2))
        var typed_data = toTypedDataHash(domain_separator, claimERC20Hash(token_address, "0xA2D887D1116B9B6620eAC4352cdB271735B8Dc89", 2, 121));
        console.log(typed_data);

        console.log( await web3.eth.sign(typed_data, account))
     


    
    } catch (e) {
        console.log(e.message)
    }
})()

function mintERC721Hash(to, tokenId, withdrawId)
{
//    console.log("mint type hash", web3.utils.keccak256(web3.utils.utf8ToHex("mint(address to,uint256 tokenId,uint256 withdrawId)")))
    return web3.utils.keccak256(web3.eth.abi.encodeParameters(["bytes32", "address", "uint256", "uint256"], [
            web3.utils.keccak256(web3.utils.utf8ToHex("mint(address to,uint256 tokenId,uint256 withdrawId)")),
            to,
            tokenId,
            withdrawId
        ]));
}

function claimERC721Hash(erc721_address, to, tokenId, withdrawId)
{
  //  console.log("claim nft type hash", web3.utils.keccak256(web3.utils.utf8ToHex("claimERC721(address to,address erc721_address,uint256 tokenId,uint256 withdrawId)")))
    return web3.utils.keccak256(web3.eth.abi.encodeParameters(["bytes32", "address", "address", "uint256", "uint256"], [
            web3.utils.keccak256(web3.utils.utf8ToHex("claimERC721(address to,address erc721_address,uint256 tokenId,uint256 withdrawId)")),
            to,
            erc721_address,
            tokenId,
            withdrawId
        ]));
}

function claimERC20Hash(erc20_address, to, amount, withdrawId)
{
  //  console.log("claim erc20 type hash", web3.utils.keccak256(web3.utils.utf8ToHex("claimERC20(address to,address erc20_address,uint256 amount,uint256 withdrawId)")));
    return web3.utils.keccak256(web3.eth.abi.encodeParameters(["bytes32", "address", "address", "uint256", "uint256"], [
            web3.utils.keccak256(web3.utils.utf8ToHex("claimERC20(address to,address erc20_address,uint256 amount,uint256 withdrawId)")),
            to,
            erc20_address,           
            amount,
            withdrawId
        ]));
}

function domainSeparator(name, version, chainId, verifyingContract, salt)
{
    const type_hash = web3.utils.keccak256(web3.utils.utf8ToHex("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract,bytes32 salt)"));
    const name_hash = web3.utils.keccak256(web3.utils.utf8ToHex(name));
    const version_hash = web3.utils.keccak256(web3.utils.utf8ToHex(version));
    return web3.utils.keccak256(web3.eth.abi.encodeParameters(["bytes32", "bytes32", "bytes32", "uint256", "address", "bytes32"], [type_hash, name_hash, version_hash, chainId, verifyingContract, salt])); 
}

function toTypedDataHash(domainSeparator, structHash)
{
    return web3.utils.keccak256(web3.utils.encodePacked("\x19\x01", domainSeparator, structHash));
}