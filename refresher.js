const fetch = require("cross-fetch")

const hashContractAddress = "0x6ffae204a4a1f7339382c1f2aa54f61bda920bfd";
let i;
const totalsupply = 177;

async function sleep(ms) {
    return new Promise((resolve) => setTimeout(resolve, ms));
}

async function refresh(){
for(i = 1; i <= totalsupply; i++){
console.log(`Refreshing token #${i}`)
const req = fetch(`https://rinkeby-api.opensea.io/api/v1/asset/${hashContractAddress}/${i}/?force_update=true`,{method: "GET"});
await sleep(50)
}
}

refresh();