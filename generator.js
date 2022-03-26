const fs = require('fs');
const path = require('path');
const Web3 = require("web3");
const fetch = require("cross-fetch")

const totalsupply = 177;
const ipfsCID = "QmZvYGUyPjypLF4PgS9Gkwm9qWHH9pMcUiWYiEwixzY5YN";
let i;
const authRPCurl = "https://rinkeby.infura.io/v3/3cf26c96767a4638b32af2ef56a76307";
const hashContractAddress = "0x6F993b245A11AAFd537a9374bda18922317C6D8F";

async function writeFile(){
    let web3 = new Web3(authRPCurl);
for(i = 1; i <= totalsupply; i++){
    let encodedparam = web3.eth.abi
      .encodeParameter("uint256", i)
      .substring(2);
    var raw = `{\"jsonrpc\":\"2.0\",\"id\":7,\"method\":\"eth_call\",\"params\":[{\"from\":\"0x0000000000000000000000000000000000000000\",\"data\":\"0xe5e7a7b3${encodedparam}\",\"to\":\"${hashContractAddress}\"},\"latest\"]}`;
    var requestOptions = {
      method: "POST",
      body: raw,
      redirect: "follow",
    };
    console.log(`Setting token #${i}`)
    fetch(authRPCurl,requestOptions)
    .then((response) => response.text())
    .then((result) => {
      let num = Web3.utils.hexToNumber(JSON.parse(result).result);
      var expiryDate = new Date(num * 1000);
      var currentDate = new Date();
      if (currentDate > expiryDate && num != 1) {
        fs.writeFile(`./tokens/${i}.json`,
        `{
            \"image\": "https://gateway.pinata.cloud/ipfs/${ipfsCID}/Expired.gif",
            \"name\": \"EXPIRED Hash #${i}\",
            \"description\": \"This token has expired on ${expiryDate}. This token's metadata has been changed to make it clear that it is expired and it cannot be bought or sold on Opensea. If you have just renewed but your token still says that it is expired on Opensea, wait some time for the metadata to be updated. REFRESHING THE METADATA ON OPENSEA HAS NO AFFECT ON THE METADATA ACTUALLY BEING UPDATED. However, you should still have instant access to the bot as long as you have renewed. You can renew your token at https://rinkeby.etherscan.io/address/${hashContractAddress}#writeContract\ using function #8. If you are having trouble, follow the guide here:RENEW WEBSITE\",
            \"attributes\": [
              { \"trait_type\": \"Token ID\", \"value\": \"${i}\" },
              { \"trait_type\": \"Expiration Date\", \"value\": \"${expiryDate.toISOString().split('T')[0]}\" },
              { \"trait_type\": \"Expired\", \"value\": \"Expired\" },
              { \"trait_type\": \"Banned\", \"value\": \"Not Banned\" }
            ],
            \"external_url\": \"https://opensea.io/hash\"
          }`
        , function(){});
      } 
      else if(num == 1){
        fs.writeFile(`./tokens/${i}.json`,
        `{
          \"image\": "https://gateway.pinata.cloud/ipfs/${ipfsCID}/Banned.gif",
          \"name\": \"BANNED Hash #${i}\",
          \"description\": \"This token has been permanently banned. Buying and Selling of this token is permanently disabled. Please filter by Not Banned to purchase an unbanned key.\",
          \"attributes\": [
            { \"trait_type\": \"Token ID\", \"value\": \"${i}\" },
            { \"trait_type\": \"Banned\", \"value\": \"Banned\" }
          ],
          \"external_url\": \"https://opensea.io/hash\"
        }`
        , function(){});
      } 
      else {
        fs.writeFile(`./tokens/${i}.json`,
        `{
            \"image\": "https://gateway.pinata.cloud/ipfs/${ipfsCID}/${i%175}.gif",
            \"name\": \"Hash #${i}\",
            \"description\": \"This token is set to expire on ${expiryDate}. Once this date passes, this token's metadata will change making it clear that it is expired and it cannot be bought or sold on Opensea. You can renew your token at https://rinkeby.etherscan.io/address/${hashContractAddress}#writeContract\ using function #8. If you are having trouble, follow the guide here:RENEW WEBSITE",
            \"attributes\": [
              { \"trait_type\": \"Token ID\", \"value\": \"${i}\" },
              { \"trait_type\": \"Expiration Date\", \"value\": \"${expiryDate.toISOString().split('T')[0]}\" },
              { \"trait_type\": \"Expired\", \"value\": \"false\" },
              { \"trait_type\": \"Banned\", \"value\": \"Not Banned\" }
            ],
            \"external_url\": \"https://opensea.io/hash\"
          }`
        , function(){});
      }
    });
    await sleep(500)
}
}

async function sleep(ms) {
    return new Promise((resolve) => setTimeout(resolve, ms));
}

writeFile();
