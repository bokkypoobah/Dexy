#!/bin/bash
# ----------------------------------------------------------------------------------------------
# Testing the smart contract
#
# Enjoy. (c) BokkyPooBah / Bok Consulting Pty Ltd 2017. The MIT Licence.
# ----------------------------------------------------------------------------------------------

MODE=${1:-test}

GETHATTACHPOINT=`grep ^IPCFILE= settings.txt | sed "s/^.*=//"`
PASSWORD=`grep ^PASSWORD= settings.txt | sed "s/^.*=//"`

SOURCEDIR=`grep ^SOURCEDIR= settings.txt | sed "s/^.*=//"`

DEXYSOL=`grep ^DEXYSOL= settings.txt | sed "s/^.*=//"`
DEXYJS=`grep ^DEXYJS= settings.txt | sed "s/^.*=//"`
TOKENSOL=`grep ^TOKENSOL= settings.txt | sed "s/^.*=//"`
TOKENJS=`grep ^TOKENJS= settings.txt | sed "s/^.*=//"`

DEPLOYMENTDATA=`grep ^DEPLOYMENTDATA= settings.txt | sed "s/^.*=//"`

INCLUDEJS=`grep ^INCLUDEJS= settings.txt | sed "s/^.*=//"`
TEST1OUTPUT=`grep ^TEST1OUTPUT= settings.txt | sed "s/^.*=//"`
TEST1RESULTS=`grep ^TEST1RESULTS= settings.txt | sed "s/^.*=//"`

CURRENTTIME=`date +%s`
CURRENTTIMES=`date -r $CURRENTTIME -u`

START_DATE=`echo "$CURRENTTIME+60*2+30" | bc`
START_DATE_S=`date -r $START_DATE -u`
END_DATE=`echo "$CURRENTTIME+60*4" | bc`
END_DATE_S=`date -r $END_DATE -u`

printf "MODE               = '$MODE'\n" | tee $TEST1OUTPUT
printf "GETHATTACHPOINT    = '$GETHATTACHPOINT'\n" | tee -a $TEST1OUTPUT
printf "PASSWORD           = '$PASSWORD'\n" | tee -a $TEST1OUTPUT
printf "SOURCEDIR          = '$SOURCEDIR'\n" | tee -a $TEST1OUTPUT
printf "DEXYSOL            = '$DEXYSOL'\n" | tee -a $TEST1OUTPUT
printf "DEXYJS             = '$DEXYJS'\n" | tee -a $TEST1OUTPUT
printf "TOKENSOL           = '$TOKENSOL'\n" | tee -a $TEST1OUTPUT
printf "TOKENJS            = '$TOKENJS'\n" | tee -a $TEST1OUTPUT
printf "DEPLOYMENTDATA     = '$DEPLOYMENTDATA'\n" | tee -a $TEST1OUTPUT
printf "INCLUDEJS          = '$INCLUDEJS'\n" | tee -a $TEST1OUTPUT
printf "TEST1OUTPUT        = '$TEST1OUTPUT'\n" | tee -a $TEST1OUTPUT
printf "TEST1RESULTS       = '$TEST1RESULTS'\n" | tee -a $TEST1OUTPUT
printf "CURRENTTIME        = '$CURRENTTIME' '$CURRENTTIMES'\n" | tee -a $TEST1OUTPUT
printf "START_DATE         = '$START_DATE' '$START_DATE_S'\n" | tee -a $TEST1OUTPUT
printf "END_DATE           = '$END_DATE' '$END_DATE_S'\n" | tee -a $TEST1OUTPUT

# Make copy of SOL file and modify start and end times ---
# `cp modifiedContracts/SnipCoin.sol .`
`cp $SOURCEDIR/*.sol .`

# --- Modify parameters ---
#`perl -pi -e "s/START_DATE \= 1512921600;.*$/START_DATE \= $START_DATE; \/\/ $START_DATE_S/" $CROWDSALESOL`
#`perl -pi -e "s/endDate \= 1513872000;.*$/endDate \= $END_DATE; \/\/ $END_DATE_S/" $CROWDSALESOL`

for FILE in *.sol
do
  DIFFS1=`diff $SOURCEDIR/$FILE $FILE`
  echo "--- Differences $SOURCEDIR/$FILE $FILE ---" | tee -a $TEST1OUTPUT
  echo "$DIFFS1" | tee -a $TEST1OUTPUT
done

solc_0.4.20 --version | tee -a $TEST1OUTPUT

echo "var dexyOutput=`solc_0.4.20 --optimize --pretty-json --combined-json abi,bin,interface $DEXYSOL`;" > $DEXYJS
echo "var tokenOutput=`solc_0.4.20 --optimize --pretty-json --combined-json abi,bin,interface $TOKENSOL`;" > $TOKENJS

geth --verbosity 3 attach $GETHATTACHPOINT << EOF | tee -a $TEST1OUTPUT
loadScript("$DEXYJS");
loadScript("$TOKENJS");
loadScript("functions.js");

var dexyAbi = JSON.parse(dexyOutput.contracts["$DEXYSOL:Dexy"].abi);
var dexyBin = "0x" + dexyOutput.contracts["$DEXYSOL:Dexy"].bin;
var dexyProxyAbi = JSON.parse(dexyOutput.contracts["$DEXYSOL:DexyProxy"].abi);
var tokenAbi = JSON.parse(tokenOutput.contracts["$TOKENSOL:Token"].abi);
var tokenBin = "0x" + tokenOutput.contracts["$TOKENSOL:Token"].bin;

// console.log("DATA: dexyAbi=" + JSON.stringify(dexyAbi));
// console.log("DATA: dexyBin=" + JSON.stringify(dexyBin));
// console.log("DATA: tokenAbi=" + JSON.stringify(tokenAbi));
// console.log("DATA: tokenBin=" + JSON.stringify(tokenBin));


unlockAccounts("$PASSWORD");
printBalances();
console.log("RESULT: ");


// -----------------------------------------------------------------------------
var deployTokensMessage = "Deploy Token Contracts";
var symbolA = "TknA";
var nameA = "Token A";
var decimalsA = 18;
var initialSupplyA = new BigNumber("400000").shift(18);
var symbolB = "TknB";
var nameB = "Token B";
var decimalsB = 18;
var initialSupplyB = new BigNumber("800000").shift(18);
// -----------------------------------------------------------------------------
console.log("RESULT: ---------- " + deployTokensMessage + " ----------");
var tokenAContract = web3.eth.contract(tokenAbi);
var tokenATx = null;
var tokenAAddress = null;
var tokenA = tokenAContract.new(symbolA, nameA, decimalsA, initialSupplyA, {from: contractOwnerAccount, data: tokenBin, gas: 6000000, gasPrice: defaultGasPrice},
  function(e, contract) {
    if (!e) {
      if (!contract.address) {
        tokenATx = contract.transactionHash;
      } else {
        tokenAAddress = contract.address;
        addAccount(tokenAAddress, "Token '" + tokenA.symbol() + "' '" + tokenA.name() + "'");
        addTokenAContractAddressAndAbi(tokenAAddress, tokenAbi);
        console.log("DATA: tokenAAddress=" + tokenAAddress);
      }
    }
  }
);
var tokenBContract = web3.eth.contract(tokenAbi);
var tokenBTx = null;
var tokenBAddress = null;
var tokenB = tokenBContract.new(symbolB, nameB, decimalsB, initialSupplyB, {from: contractOwnerAccount, data: tokenBin, gas: 6000000, gasPrice: defaultGasPrice},
  function(e, contract) {
    if (!e) {
      if (!contract.address) {
        tokenBTx = contract.transactionHash;
      } else {
        tokenBAddress = contract.address;
        addAccount(tokenBAddress, "Token '" + tokenB.symbol() + "' '" + tokenB.name() + "'");
        addTokenBContractAddressAndAbi(tokenBAddress, tokenAbi);
        console.log("DATA: tokenBAddress=" + tokenBAddress);
      }
    }
  }
);
while (txpool.status.pending > 0) {
}
printBalances();
failIfTxStatusError(tokenATx, deployTokensMessage + " - TokenA");
failIfTxStatusError(tokenBTx, deployTokensMessage + " - TokenB");
printTxData("tokenATx", tokenATx);
printTxData("tokenBTx", tokenBTx);
printTokenContractDetails();
console.log("RESULT: ");


// -----------------------------------------------------------------------------
var distributeTokensMessage = "Distribute Tokens";
var amountA = new BigNumber("100000").shift(18);
var amountB = new BigNumber("200000").shift(18);
// -----------------------------------------------------------------------------
console.log("RESULT: ---------- " + distributeTokensMessage + " ----------");
var distributeTokens1_1Tx = tokenA.transfer(account2, amountA, {from: contractOwnerAccount, gas: 100000, gasPrice: defaultGasPrice});
var distributeTokens1_2Tx = tokenA.transfer(account3, amountA, {from: contractOwnerAccount, gas: 100000, gasPrice: defaultGasPrice});
var distributeTokens1_3Tx = tokenA.transfer(account4, amountA, {from: contractOwnerAccount, gas: 100000, gasPrice: defaultGasPrice});
var distributeTokens1_4Tx = tokenB.transfer(account2, amountB, {from: contractOwnerAccount, gas: 100000, gasPrice: defaultGasPrice});
var distributeTokens1_5Tx = tokenB.transfer(account3, amountB, {from: contractOwnerAccount, gas: 100000, gasPrice: defaultGasPrice});
var distributeTokens1_6Tx = tokenB.transfer(account4, amountB, {from: contractOwnerAccount, gas: 100000, gasPrice: defaultGasPrice});
while (txpool.status.pending > 0) {
}
printBalances();
failIfTxStatusError(distributeTokens1_1Tx, distributeTokensMessage + " - owner -> ac2 10k tokenA");
failIfTxStatusError(distributeTokens1_2Tx, distributeTokensMessage + " - owner -> ac3 10k tokenA");
failIfTxStatusError(distributeTokens1_3Tx, distributeTokensMessage + " - owner -> ac4 10k tokenA");
failIfTxStatusError(distributeTokens1_4Tx, distributeTokensMessage + " - owner -> ac2 20k tokenB");
failIfTxStatusError(distributeTokens1_5Tx, distributeTokensMessage + " - owner -> ac3 20k tokenB");
failIfTxStatusError(distributeTokens1_6Tx, distributeTokensMessage + " - owner -> ac4 20k tokenB");
printTxData("distributeTokens1_1Tx", distributeTokens1_1Tx);
printTxData("distributeTokens1_2Tx", distributeTokens1_2Tx);
printTxData("distributeTokens1_3Tx", distributeTokens1_3Tx);
printTxData("distributeTokens1_4Tx", distributeTokens1_4Tx);
printTxData("distributeTokens1_5Tx", distributeTokens1_5Tx);
printTxData("distributeTokens1_6Tx", distributeTokens1_6Tx);
printTokenContractDetails();
console.log("RESULT: ");


// -----------------------------------------------------------------------------
var deployDexyMessage = "Deploy Dexy Contracts";
// -----------------------------------------------------------------------------
console.log("RESULT: ---------- " + deployDexyMessage + " ----------");
var dexyContract = web3.eth.contract(dexyAbi);
var dexyTx = null;
var dexyAddress = null;
var dexyProxyAddress = null;
var dexy = dexyContract.new({from: contractOwnerAccount, data: dexyBin, gas: 6000000, gasPrice: defaultGasPrice},
  function(e, contract) {
    if (!e) {
      if (!contract.address) {
        dexyTx = contract.transactionHash;
      } else {
        dexyAddress = contract.address;
        addAccount(dexyAddress, "Dexy Contract");
        addDexyContractAddressAndAbi(dexyAddress, dexyAbi);
        dexyProxyAddress = dexy.proxy();
        addAccount(dexyProxyAddress, "Dexy Proxy Contract");
        addDexyProxyContractAddressAndAbi(dexyProxyAddress, dexyProxyAbi);
        console.log("DATA: dexyAddress=" + dexyAddress);
        console.log("DATA: dexyProxyAddress=" + dexyProxyAddress);
      }
    }
  }
);
while (txpool.status.pending > 0) {
}
printBalances();
failIfTxStatusError(dexyTx, deployDexyMessage);
printTxData("dexyTx", dexyTx);
printDexyContractDetails();
printDexyProxyContractDetails();
console.log("RESULT: ");


// -----------------------------------------------------------------------------
var approveForExchangeMessage = "Approve For Exchange";
var exAccount1 = account2;
var exAccount2 = account3;
var amountA = new BigNumber("100").shift(18);
var amountB = new BigNumber("200").shift(18);
// -----------------------------------------------------------------------------
console.log("RESULT: ---------- " + approveForExchangeMessage + " ----------");
var approveForExchange1_1Tx = tokenA.approve(dexyProxyAddress, amountA, {from: account2, gas: 100000, gasPrice: defaultGasPrice});
var approveForExchange1_2Tx = tokenB.approve(dexyProxyAddress, amountB, {from: account3, gas: 100000, gasPrice: defaultGasPrice});
while (txpool.status.pending > 0) {
}
printBalances();
failIfTxStatusError(approveForExchange1_1Tx, approveForExchangeMessage + " - ac2 approve proxy 100 tokenA");
failIfTxStatusError(approveForExchange1_2Tx, approveForExchangeMessage + " - ac3 approve proxy 200 tokenB");
printTxData("approveForExchange1_1Tx", approveForExchange1_1Tx);
printTxData("approveForExchange1_2Tx", approveForExchange1_2Tx);
printTokenContractDetails();
console.log("RESULT: tokenA.allowance(account2, proxy)=" + tokenA.allowance(account2, dexyProxyAddress).shift(-18));
console.log("RESULT: tokenB.allowance(account3, proxy)=" + tokenB.allowance(account3, dexyProxyAddress).shift(-18));
console.log("RESULT: ");


// -----------------------------------------------------------------------------
var exchangeMessage = "Exchange";
// -----------------------------------------------------------------------------
console.log("RESULT: ---------- " + exchangeMessage + " ----------");
var exchange1_1Tx = dexy.exchange(tokenAAddress, amountA, tokenBAddress, amountB, account2, account3,
  {from: account2, gas: 100000, gasPrice: defaultGasPrice});
while (txpool.status.pending > 0) {
}
printBalances();
failIfTxStatusError(exchange1_1Tx, exchangeMessage + " - exchange");
printTxData("exchange1_1Tx", exchange1_1Tx);
printTokenContractDetails();
console.log("RESULT: tokenA.allowance(account2, proxy)=" + tokenA.allowance(account2, dexyProxyAddress).shift(-18));
console.log("RESULT: tokenB.allowance(account3, proxy)=" + tokenB.allowance(account3, dexyProxyAddress).shift(-18));
console.log("RESULT: ");

exit;

// -----------------------------------------------------------------------------
var deployTestRbtMessage = "Deploy Test RBT";
// -----------------------------------------------------------------------------
console.log("RESULT: " + deployTestRbtMessage);
// console.log("RESULT: testRbtBin='" + testRbtBin + "'");
var newTestRbtBin = testRbtBin.replace(/__RedBlackTree\.sol\:RedBlackTree_________/g, rbtAddress.substring(2, 42));
// console.log("RESULT: newTestRbtBin='" + newTestRbtBin + "'");
var testRbtContract = web3.eth.contract(testRbtAbi);
// console.log(JSON.stringify(testRbtContract));
var testRbtTx = null;
var testRbtAddress = null;
var testRbt = testRbtContract.new({from: contractOwnerAccount, data: newTestRbtBin, gas: 6000000, gasPrice: defaultGasPrice},
  function(e, contract) {
    if (!e) {
      if (!contract.address) {
        testRbtTx = contract.transactionHash;
      } else {
        testRbtAddress = contract.address;
        addAccount(testRbtAddress, "Test RBT");
        addTokenFactoryContractAddressAndAbi(testRbtAddress, testRbtAbi);
        console.log("DATA: testRbtAddress=" + testRbtAddress);
      }
    }
  }
);
while (txpool.status.pending > 0) {
}
printBalances();
failIfTxStatusError(testRbtTx, deployTestRbtMessage);
printTxData("testRbtTx", testRbtTx);
// printTokenFactoryContractDetails();
console.log("RESULT: ");


// -----------------------------------------------------------------------------
var setup_Message = "Setup";
// -----------------------------------------------------------------------------

// https://stackoverflow.com/questions/2450954/how-to-randomize-shuffle-a-javascript-array
function shuffle(array) {
  var currentIndex = array.length, temporaryValue, randomIndex;

  // While there remain elements to shuffle...
  while (0 !== currentIndex) {

    // Pick a remaining element...
    randomIndex = Math.floor(Math.random() * currentIndex);
    currentIndex -= 1;

    // And swap it with the current element.
    temporaryValue = array[currentIndex];
    array[currentIndex] = array[randomIndex];
    array[randomIndex] = temporaryValue;
  }

  return array;
}

console.log("RESULT: " + setup_Message);
// var items = [1, 6, 8, 11, 13, 15, 17, 22, 25, 27];
var items = [];
for (var i = 1; i < 1000; i++) {
    items.push(i);
}
// items = shuffle(items);
var tx = [];
for (var i = 0; i < items.length; i++) {
  var item = items[i];
  var itemValue = parseInt(item) + 10000;
  tx.push(testRbt.insert(item, itemValue, {from: contractOwnerAccount, gas: 500000, gasPrice: defaultGasPrice}));
}
while (txpool.status.pending > 0) {
}
printBalances();

for (var i = 0; i < items.length; i++) {
  var item = items[i];
  var itemValue = parseInt(item) + 10000;
  failIfTxStatusError(tx[i], setup_Message + " - testRbt.insert(" + item + ", " + itemValue + ")");
}
var totalGasUsed = new BigNumber(0);
for (var i = 0; i < items.length; i++) {
  var item = items[i];
  var itemValue = parseInt(item) + 10000;
  printTxData("setup_1Tx[" + i + "]", tx[i]);
  totalGasUsed = totalGasUsed.add(eth.getTransactionReceipt(tx[i]).gasUsed);
}
var averageGasUsed = totalGasUsed.div(items.length);
console.log("RESULT: totalGasUsed=" + totalGasUsed);
console.log("RESULT: averageGasUsed=" + averageGasUsed);

// printCrowdsaleContractDetails();
// printBonusListContractDetails();
// printTokenContractDetails();
console.log("RESULT: ");

console.log("RESULT: root()=" + JSON.stringify(testRbt.root()));
console.log("RESULT: getFirstId()=" + JSON.stringify(testRbt.getFirstId()));
console.log("RESULT: getLastId()=" + JSON.stringify(testRbt.getLastId()));
console.log("RESULT: ");

if (false) {
for (var i = 0; i < items.length; i++) {
  var item = items[i];
  // var itemValue = parseInt(item) + 10000;
  // var find1_id = testRbt.find(itemValue);
  // console.log("RESULT: find1_id(" + itemValue + ")=" + find1_id);
  var find1_item = testRbt.getItem(item);
  console.log("RESULT: find1_item(" + item + ")=" + JSON.stringify(find1_item));
}
console.log("RESULT: ");
}

if (false) {
items.push(123);
items.push(123000);
for (var i = 0; i < items.length; i++) {
  var item = items[i];
  var itemValue = parseInt(item) + 10000;
  var find1_id = testRbt.find(itemValue);
  console.log("RESULT: find1_id(" + itemValue + ")=" + find1_id);
  var find1_item = testRbt.getItem(find1_id);
  console.log("RESULT: find1_item=" + JSON.stringify(find1_item));
}
}
// var find1_id = testRbt.find(10008);
// console.log("RESULT: find1_id(10008)=" + find1_id);
// var find1_item = testRbt.getItem(find1_id);
// console.log("RESULT: find1_item=" + JSON.stringify(find1_item));

function printAll(rbt, node, spacing) {
  var padding = "";
  for (var i = 0; i < spacing * 4; i++) {
    padding = padding + "    ";
  }
  var nodeData = rbt.getItem(node);
  var leftNode = nodeData[1];
  var rightNode = nodeData[2];
  if (leftNode != 0) {
    printAll(rbt, leftNode, parseInt(spacing) + 1);
  }
  console.log("RESULT: " + padding + node + ":" + JSON.stringify(nodeData));
  if (rightNode != 0) {
    printAll(rbt, rightNode, parseInt(spacing) + 1);
  }
}

// printAll(testRbt, testRbt.root(), 0);


exit;


// -----------------------------------------------------------------------------
var tokenMessage = "Deploy Token Contract";
var symbol = "GZE";
var name = "GazeCoin";
var decimals = 18;
var initialSupply = 0;
var mintable = true;
var transferable = false;
// -----------------------------------------------------------------------------
console.log("RESULT: " + tokenMessage);
var tokenContract = web3.eth.contract(tokenAbi);
// console.log(JSON.stringify(tokenContract));
var deployTokenTx = tokenFactory.deployBTTSTokenContract(symbol, name, decimals, initialSupply, mintable, transferable, {from: contractOwnerAccount, gas: 4000000, gasPrice: defaultGasPrice});
while (txpool.status.pending > 0) {
}
var bttsTokens = getBTTSFactoryTokenListing();
console.log("RESULT: bttsTokens=#" + bttsTokens.length + " " + JSON.stringify(bttsTokens));
// Can check, but the rest will not work anyway - if (bttsTokens.length == 1)
var tokenAddress = bttsTokens[0];
var token = web3.eth.contract(tokenAbi).at(tokenAddress);
// console.log("RESULT: token=" + JSON.stringify(token));
addAccount(tokenAddress, "Token '" + token.symbol() + "' '" + token.name() + "'");
addTokenContractAddressAndAbi(tokenAddress, tokenAbi);
printBalances();
printTxData("deployTokenTx", deployTokenTx);
printTokenFactoryContractDetails();
printTokenContractDetails();
console.log("RESULT: ");


// -----------------------------------------------------------------------------
var crowdsaleMessage = "Deploy GazeCoin Crowdsale Contract";
var bonusListMessage = "Deploy Bonus List Contract";
// -----------------------------------------------------------------------------
console.log("RESULT: " + crowdsaleMessage);
var crowdsaleContract = web3.eth.contract(crowdsaleAbi);
// console.log(JSON.stringify(crowdsaleContract));
var crowdsaleTx = null;
var crowdsaleAddress = null;
var crowdsale = crowdsaleContract.new({from: contractOwnerAccount, data: crowdsaleBin, gas: 6000000, gasPrice: defaultGasPrice},
  function(e, contract) {
    if (!e) {
      if (!contract.address) {
        crowdsaleTx = contract.transactionHash;
      } else {
        crowdsaleAddress = contract.address;
        addAccount(crowdsaleAddress, "GazeCoin Crowdsale");
        addCrowdsaleContractAddressAndAbi(crowdsaleAddress, crowdsaleAbi);
        console.log("DATA: crowdsaleAddress=" + crowdsaleAddress);
      }
    }
  }
);
console.log("RESULT: " + bonusListMessage);
var bonusListContract = web3.eth.contract(bonusListAbi);
// console.log(JSON.stringify(bonusListContract));
var bonusListTx = null;
var bonusListAddress = null;
var bonusList = bonusListContract.new({from: contractOwnerAccount, data: bonusListBin, gas: 6000000, gasPrice: defaultGasPrice},
  function(e, contract) {
    if (!e) {
      if (!contract.address) {
        bonusListTx = contract.transactionHash;
      } else {
        bonusListAddress = contract.address;
        addAccount(bonusListAddress, "Bonus List");
        addBonusListContractAddressAndAbi(bonusListAddress, bonusListAbi);
        console.log("DATA: bonusListAddress=" + bonusListAddress);
      }
    }
  }
);
while (txpool.status.pending > 0) {
}
printBalances();
failIfTxStatusError(crowdsaleTx, crowdsaleMessage);
failIfTxStatusError(bonusListTx, bonusListMessage);
printTxData("crowdsaleAddress=" + crowdsaleAddress, crowdsaleTx);
printTxData("bonusListAddress=" + bonusListAddress, bonusListTx);
printCrowdsaleContractDetails();
printBonusListContractDetails();
console.log("RESULT: ");


// -----------------------------------------------------------------------------
var setup_Message = "Setup";
// -----------------------------------------------------------------------------
console.log("RESULT: " + setup_Message);
var setup_1Tx = crowdsale.setBTTSToken(tokenAddress, {from: contractOwnerAccount, gas: 100000, gasPrice: defaultGasPrice});
var setup_2Tx = crowdsale.setBonusList(bonusListAddress, {from: contractOwnerAccount, gas: 100000, gasPrice: defaultGasPrice});
var setup_3Tx = crowdsale.setEndDate($END_DATE, {from: contractOwnerAccount, gas: 100000, gasPrice: defaultGasPrice});
var setup_4Tx = token.setMinter(crowdsaleAddress, {from: contractOwnerAccount, gas: 100000, gasPrice: defaultGasPrice});
var setup_5Tx = bonusList.add([account3], 1, {from: contractOwnerAccount, gas: 100000, gasPrice: defaultGasPrice});
var setup_6Tx = bonusList.add([account4], 2, {from: contractOwnerAccount, gas: 100000, gasPrice: defaultGasPrice});
var setup_7Tx = bonusList.add([account5], 3, {from: contractOwnerAccount, gas: 100000, gasPrice: defaultGasPrice});
while (txpool.status.pending > 0) {
}
printBalances();
failIfTxStatusError(setup_1Tx, setup_Message + " - crowdsale.setBTTSToken(tokenAddress)");
failIfTxStatusError(setup_2Tx, setup_Message + " - crowdsale.setBonusList(bonusListAddress)");
failIfTxStatusError(setup_3Tx, setup_Message + " - crowdsale.setEndDate($END_DATE)");
failIfTxStatusError(setup_4Tx, setup_Message + " - token.setMinter(crowdsaleAddress)");
failIfTxStatusError(setup_5Tx, setup_Message + " - bonusList.add([account3], 1)");
failIfTxStatusError(setup_6Tx, setup_Message + " - bonusList.add([account4], 2)");
failIfTxStatusError(setup_7Tx, setup_Message + " - bonusList.add([account5], 3)");
printTxData("setup_1Tx", setup_1Tx);
printTxData("setup_2Tx", setup_2Tx);
printTxData("setup_3Tx", setup_3Tx);
printTxData("setup_4Tx", setup_4Tx);
printTxData("setup_5Tx", setup_5Tx);
printTxData("setup_6Tx", setup_6Tx);
printTxData("setup_7Tx", setup_7Tx);
printCrowdsaleContractDetails();
printBonusListContractDetails();
printTokenContractDetails();
console.log("RESULT: ");


// -----------------------------------------------------------------------------
var addPrecommitment_Message = "Add Precommitment";
// -----------------------------------------------------------------------------
console.log("RESULT: " + addPrecommitment_Message);
var addPrecommitment_1Tx = crowdsale.addPrecommitment(account7, web3.toWei(1000, "ether"), 35, {from: contractOwnerAccount, gas: 1000000, gasPrice: defaultGasPrice});
while (txpool.status.pending > 0) {
}
printBalances();
failIfTxStatusError(addPrecommitment_1Tx, addPrecommitment_Message + " - ac7 1,000 ETH with 35% bonus");
printTxData("addPrecommitment_1Tx", addPrecommitment_1Tx);
printCrowdsaleContractDetails();
printTokenContractDetails();
console.log("RESULT: ");


// -----------------------------------------------------------------------------
var sendContribution0Message = "Send Contribution #0 - Before Crowdsale Start";
// -----------------------------------------------------------------------------
console.log("RESULT: " + sendContribution0Message);
var sendContribution0_1Tx = eth.sendTransaction({from: contractOwnerAccount, to: crowdsaleAddress, gas: 400000, value: web3.toWei("0.01", "ether")});
var sendContribution0_2Tx = eth.sendTransaction({from: contractOwnerAccount, to: crowdsaleAddress, gas: 400000, value: web3.toWei("0.02", "ether")});
var sendContribution0_3Tx = eth.sendTransaction({from: account3, to: crowdsaleAddress, gas: 400000, value: web3.toWei("0.01", "ether")});
while (txpool.status.pending > 0) {
}
printBalances();
failIfTxStatusError(sendContribution0_1Tx, sendContribution0Message + " - owner 0.01 ETH - Owner Test Transaction");
passIfTxStatusError(sendContribution0_2Tx, sendContribution0Message + " - owner 0.02 ETH - Expecting failure - not a test transaction");
passIfTxStatusError(sendContribution0_3Tx, sendContribution0Message + " - ac3 0.01 ETH - Expecting failure");
printTxData("sendContribution0_1Tx", sendContribution0_1Tx);
printTxData("sendContribution0_2Tx", sendContribution0_2Tx);
printTxData("sendContribution0_3Tx", sendContribution0_3Tx);
printCrowdsaleContractDetails();
printTokenContractDetails();
console.log("RESULT: ");


waitUntil("START_DATE", crowdsale.START_DATE(), 0);


// -----------------------------------------------------------------------------
var sendContribution1Message = "Send Contribution #1";
// -----------------------------------------------------------------------------
console.log("RESULT: " + sendContribution1Message);
var sendContribution1_1Tx = eth.sendTransaction({from: account3, to: crowdsaleAddress, gas: 400000, value: web3.toWei("10", "ether")});
var sendContribution1_2Tx = eth.sendTransaction({from: account4, to: crowdsaleAddress, gas: 400000, value: web3.toWei("10", "ether")});
var sendContribution1_3Tx = eth.sendTransaction({from: account5, to: crowdsaleAddress, gas: 400000, value: web3.toWei("10", "ether")});
var sendContribution1_4Tx = eth.sendTransaction({from: account6, to: crowdsaleAddress, gas: 400000, value: web3.toWei("10", "ether")});
while (txpool.status.pending > 0) {
}
printBalances();
failIfTxStatusError(sendContribution1_1Tx, sendContribution1Message + " - ac3 10 ETH - Bonus Tier 1 50%");
failIfTxStatusError(sendContribution1_2Tx, sendContribution1Message + " - ac4 10 ETH - Bonus Tier 2 20%");
failIfTxStatusError(sendContribution1_3Tx, sendContribution1Message + " - ac5 10 ETH - Bonus Tier 3 15%");
failIfTxStatusError(sendContribution1_4Tx, sendContribution1Message + " - ac6 10 ETH - No Bonus");
printTxData("sendContribution1_1Tx", sendContribution1_1Tx);
printTxData("sendContribution1_2Tx", sendContribution1_2Tx);
printTxData("sendContribution1_3Tx", sendContribution1_3Tx);
printTxData("sendContribution1_4Tx", sendContribution1_4Tx);
printCrowdsaleContractDetails();
printTokenContractDetails();
console.log("RESULT: ");


// -----------------------------------------------------------------------------
var sendContribution2Message = "Send Contribution #2";
// -----------------------------------------------------------------------------
console.log("RESULT: " + sendContribution2Message);
var sendContribution2_1Tx = eth.sendTransaction({from: account3, to: crowdsaleAddress, gas: 400000, value: web3.toWei("90", "ether")});
var sendContribution2_2Tx = eth.sendTransaction({from: account4, to: crowdsaleAddress, gas: 400000, value: web3.toWei("90", "ether")});
var sendContribution2_3Tx = eth.sendTransaction({from: account5, to: crowdsaleAddress, gas: 400000, value: web3.toWei("90", "ether")});
var sendContribution2_4Tx = eth.sendTransaction({from: account6, to: crowdsaleAddress, gas: 400000, value: web3.toWei("90", "ether")});
while (txpool.status.pending > 0) {
}
printBalances();
failIfTxStatusError(sendContribution2_1Tx, sendContribution2Message + " - ac3 90 ETH - Bonus Tier 1 50%");
failIfTxStatusError(sendContribution2_2Tx, sendContribution2Message + " - ac4 90 ETH - Bonus Tier 2 20%");
failIfTxStatusError(sendContribution2_3Tx, sendContribution2Message + " - ac5 90 ETH - Bonus Tier 3 15%");
failIfTxStatusError(sendContribution2_4Tx, sendContribution2Message + " - ac6 90 ETH - No Bonus");
printTxData("sendContribution2_1Tx", sendContribution2_1Tx);
printTxData("sendContribution2_2Tx", sendContribution2_2Tx);
printTxData("sendContribution2_3Tx", sendContribution2_3Tx);
printTxData("sendContribution2_4Tx", sendContribution2_4Tx);
printCrowdsaleContractDetails();
printTokenContractDetails();
generateSummaryJSON();
console.log("RESULT: ");


// -----------------------------------------------------------------------------
var sendContribution3Message = "Send Contribution #3";
// -----------------------------------------------------------------------------
console.log("RESULT: " + sendContribution3Message);
var sendContribution3_1Tx = eth.sendTransaction({from: account8, to: crowdsaleAddress, gas: 400000, value: web3.toWei("50000", "ether")});
while (txpool.status.pending > 0) {
}
var sendContribution3_2Tx = eth.sendTransaction({from: account9, to: crowdsaleAddress, gas: 400000, value: web3.toWei("30000", "ether")});
while (txpool.status.pending > 0) {
}
printBalances();
failIfTxStatusError(sendContribution3_1Tx, sendContribution3Message + " - ac8 50,000 ETH");
failIfTxStatusError(sendContribution3_2Tx, sendContribution3Message + " - ac9 30,000 ETH");
printTxData("sendContribution3_1Tx", sendContribution3_1Tx);
printTxData("sendContribution3_2Tx", sendContribution3_2Tx);
printCrowdsaleContractDetails();
printTokenContractDetails();
console.log("RESULT: ");


// -----------------------------------------------------------------------------
var addPrecommitmentAdjustment_Message = "Add Precommitment Adjustment";
// -----------------------------------------------------------------------------
console.log("RESULT: " + addPrecommitmentAdjustment_Message);
var addPrecommitmentAdjustment_1Tx = crowdsale.addPrecommitmentAdjustment(account7, new BigNumber("111").shift(18), {from: contractOwnerAccount, gas: 1000000, gasPrice: defaultGasPrice});
while (txpool.status.pending > 0) {
}
printBalances();
failIfTxStatusError(addPrecommitmentAdjustment_1Tx, addPrecommitmentAdjustment_Message + " - ac7 + 111 GZE");
printTxData("addPrecommitmentAdjustment_1Tx", addPrecommitmentAdjustment_1Tx);
printCrowdsaleContractDetails();
printTokenContractDetails();
console.log("RESULT: ");


// -----------------------------------------------------------------------------
var finalise_Message = "Finalise Crowdsale";
// -----------------------------------------------------------------------------
console.log("RESULT: " + finalise_Message);
var finalise_1Tx = crowdsale.finalise({from: contractOwnerAccount, gas: 1000000, gasPrice: defaultGasPrice});
while (txpool.status.pending > 0) {
}
printBalances();
failIfTxStatusError(finalise_1Tx, finalise_Message);
printTxData("finalise_1Tx", finalise_1Tx);
printCrowdsaleContractDetails();
printTokenContractDetails();
console.log("RESULT: ");


EOF
grep "DATA: " $TEST1OUTPUT | sed "s/DATA: //" > $DEPLOYMENTDATA
cat $DEPLOYMENTDATA
grep "RESULT: " $TEST1OUTPUT | sed "s/RESULT: //" > $TEST1RESULTS
cat $TEST1RESULTS
# grep "JSONSUMMARY: " $TEST1OUTPUT | sed "s/JSONSUMMARY: //" > $JSONSUMMARY
# cat $JSONSUMMARY
