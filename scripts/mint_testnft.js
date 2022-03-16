// Right click on the script name and hit "Run" to execute
(async () => {
    try {
        console.log('Running mint TestNFT test...')
    
        const contractName = 'TestNFT' // Change this for other contract
        const constructorArgs = []    // Put constructor args (if any) here for your contract

        // Note that the script needs the ABI which is generated from the compilation artifact.
        // Make sure contract is compiled and artifacts are generated
        const artifactsPath = `browser/contracts/nfts/artifacts/${contractName}_metadata.json` // Change this for different path  
        const metadata = JSON.parse(await remix.call('fileManager', 'getFile', artifactsPath)).output.abi;
        const account = (await web3.eth.getAccounts())[0];

        console.log("address", account)
        const contract_address = "0xd9145CCE52D386f254917e481eB44e9943F39138";
        const mint_count = 20;
        const contract = new web3.eth.Contract(metadata, contract_address, {from:account});
        for(var i=0;i<mint_count;i++)
        {
            var events = contract.methods.mint().send()
            .on('transactionHash', function(hash){
                 console.log(hash);
            })
            .on('confirmation', function(confirmationNumber, receipt){
                 if(confirmationNumber == 3)
                 {
                    console.log(confirmationNumber, receipt);
                    events.off('confirmation');
                }                  
             }).on('error', function(error, receipt) { // If the transaction was rejected by the network with a receipt, the second parameter will be the receipt.
                    console.log(error, receipt);
            });
        }
    


    
    } catch (e) {
        console.log(e.message)
    }
})()