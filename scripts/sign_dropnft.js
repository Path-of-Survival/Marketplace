// Right click on the script name and hit "Run" to execute
(async () => {
    try {
        console.log('Running DropNFT sign test...')
        const account = (await web3.eth.getAccounts())[0];
        console.log("address", account)

        const name = "DropNFT";
        const version = "1.0";
        const chain_id = await web3.eth.getChainId();
        const contract_address = "0x8AD6BB0732dc2EfcAe3cA19Af83B73CEf028a153";
        const salt = "0xac4baafe11131670a8ae1bbc25bb1658c6b0ffeb6045ab012263071707c2bb68";

        const domain_separator = domainSeparator(name, version, chain_id, contract_address, salt); 
        
//        console.log(domain_separator);
        const quantity = 2;
        var typed_data = toTypedDataHash(domain_separator, buyNFTHash(quantity, "0xF1F6720d4515934328896D37D356627522D97B49"));
//        console.log(typed_data);
        console.log(await web3.eth.sign(typed_data, account))
     
    } catch (e) {
        console.log(e.message)
    }
})()

function buyNFTHash(quantity, to)
{
    console.log("buy nft type hash", web3.utils.keccak256(web3.utils.utf8ToHex("buy(uint256 quantity,address to)")))
    return web3.utils.keccak256(web3.eth.abi.encodeParameters(["bytes32","uint256", "address"], [
            web3.utils.keccak256(web3.utils.utf8ToHex("buy(uint256 quantity,address to)")),
            quantity,
            to
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