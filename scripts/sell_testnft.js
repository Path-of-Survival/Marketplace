(async () => {
	try
	{

		var last_block = await web3.eth.getBlockNumber();
		
		console.log("chain", await web3.eth.getChainId());
		
		console.log("last block#", last_block);
        const artifactsPath = `browser/contracts/marketplace/artifacts/FixedPrice_metadata.json` // Change this for different path  
        const metadata = JSON.parse(await remix.call('fileManager', 'getFile', artifactsPath)).output.abi;
		var contract = new web3.eth.Contract(metadata, "0xF65326EbF16195890730cAd411786374c4D9E314");
		//console.log((await contract.methods.removeItem(14).send({from:"0xBb7403aAF82342A0d987A8603aAf881136B5D125"})))
		
		console.log((await contract.methods.sellNFTForTokens("0x91a86cF18559212B48466DDd8F567a2b73E7a8aF", 8, "0xE6c471121b974dce211b65eF41E7E17D53Be879d", 1).send({from:"0xBb7403aAF82342A0d987A8603aAf881136B5D125"})))
		

	}
	catch(err)
	{
		console.log(err);
	}
	
})()