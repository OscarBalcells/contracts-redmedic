// @dev Converting an ASCII input string into bytes32 representation with padding
const web3 = require("web3");
const input = process.argv[2]; 
const output = web3.utils.fromAscii(input).padEnd(66,"0")
console.log('"'+output+'"');
