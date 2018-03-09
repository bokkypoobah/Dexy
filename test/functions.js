// ETH/USD 30 Jan 2018 05:05 AEDT => 1198.26 from CMC
var ethPriceUSD = 1198.26;
var defaultGasPrice = web3.toWei(10, "gwei");

// -----------------------------------------------------------------------------
// Accounts
// -----------------------------------------------------------------------------
var accounts = [];
var accountNames = {};

addAccount(eth.accounts[0], "Account #0 - Miner");
addAccount(eth.accounts[1], "Account #1 - Contract Owner");
addAccount(eth.accounts[2], "Account #2");
addAccount(eth.accounts[3], "Account #3");
addAccount(eth.accounts[4], "Account #4");
addAccount(eth.accounts[5], "Account #5");
addAccount(eth.accounts[6], "Account #6");
addAccount(eth.accounts[7], "Account #7");
addAccount(eth.accounts[8], "Account #8");
addAccount(eth.accounts[9], "Account #9");
addAccount(eth.accounts[10], "Account #10");
addAccount(eth.accounts[11], "Account #11");

var minerAccount = eth.accounts[0];
var contractOwnerAccount = eth.accounts[1];
var account2 = eth.accounts[2];
var account3 = eth.accounts[3];
var account4 = eth.accounts[4];
var account5 = eth.accounts[5];
var account6 = eth.accounts[6];
var account7 = eth.accounts[7];
var account8 = eth.accounts[8];
var account9 = eth.accounts[9];
var account10 = eth.accounts[10];
var account11 = eth.accounts[11];

var baseBlock = eth.blockNumber;

function unlockAccounts(password) {
  for (var i = 0; i < eth.accounts.length && i < accounts.length; i++) {
    personal.unlockAccount(eth.accounts[i], password, 100000);
    if (i > 0 && eth.getBalance(eth.accounts[i]) == 0) {
      personal.sendTransaction({from: eth.accounts[0], to: eth.accounts[i], value: web3.toWei(1000000, "ether")});
    }
  }
  while (txpool.status.pending > 0) {
  }
  baseBlock = eth.blockNumber;
}

function addAccount(account, accountName) {
  accounts.push(account);
  accountNames[account] = accountName;
}


// -----------------------------------------------------------------------------
// Token A Contract
// -----------------------------------------------------------------------------
var tokenAContractAddress = null;
var tokenAContractAbi = null;

function addTokenAContractAddressAndAbi(address, tokenAbi) {
  tokenAContractAddress = address;
  tokenAContractAbi = tokenAbi;
}


// -----------------------------------------------------------------------------
// Token B Contract
// -----------------------------------------------------------------------------
var tokenBContractAddress = null;
var tokenBContractAbi = null;

function addTokenBContractAddressAndAbi(address, tokenAbi) {
  tokenBContractAddress = address;
  tokenBContractAbi = tokenAbi;
}

// -----------------------------------------------------------------------------
// Account ETH and token balances
// -----------------------------------------------------------------------------
function printBalances() {
  var tokenA = tokenAContractAddress == null || tokenAContractAbi == null ? null : web3.eth.contract(tokenAContractAbi).at(tokenAContractAddress);
  var tokenB = tokenBContractAddress == null || tokenBContractAbi == null ? null : web3.eth.contract(tokenBContractAbi).at(tokenBContractAddress);
  var decimalsA = tokenA == null ? 18 : tokenA.decimals();
  var decimalsB = tokenB == null ? 18 : tokenB.decimals();
  var i = 0;
  var totalTokenABalance = new BigNumber(0);
  var totalTokenBBalance = new BigNumber(0);
  console.log("RESULT:  # Account                                             EtherBalanceChange                        Token A                        Token B Name");
  console.log("RESULT: -- ------------------------------------------ --------------------------- ------------------------------ ------------------------------ ---------------------------");
  accounts.forEach(function(e) {
    var etherBalanceBaseBlock = eth.getBalance(e, baseBlock);
    var etherBalance = web3.fromWei(eth.getBalance(e).minus(etherBalanceBaseBlock), "ether");
    var tokenABalance = tokenA == null ? new BigNumber(0) : tokenA.balanceOf(e).shift(-decimalsA);
    var tokenBBalance = tokenB == null ? new BigNumber(0) : tokenB.balanceOf(e).shift(-decimalsB);
    totalTokenABalance = totalTokenABalance.add(tokenABalance);
    totalTokenBBalance = totalTokenBBalance.add(tokenBBalance);
    console.log("RESULT: " + pad2(i) + " " + e  + " " + pad(etherBalance) + " " +
      padToken(tokenABalance, decimalsA) + " " + padToken(tokenBBalance, decimalsB) + " " + accountNames[e]);
    i++;
  });
  console.log("RESULT: -- ------------------------------------------ --------------------------- ------------------------------ ------------------------------ ---------------------------");
  console.log("RESULT:                                                                           " + padToken(totalTokenABalance, decimalsA) + " " + padToken(totalTokenBBalance, decimalsB) + " Total Token Balances");
  console.log("RESULT: -- ------------------------------------------ --------------------------- ------------------------------ ------------------------------ ---------------------------");
  console.log("RESULT: ");
}

function pad2(s) {
  var o = s.toFixed(0);
  while (o.length < 2) {
    o = " " + o;
  }
  return o;
}

function pad(s) {
  var o = s.toFixed(18);
  while (o.length < 27) {
    o = " " + o;
  }
  return o;
}

function padToken(s, decimals) {
  var o = s.toFixed(decimals);
  var l = parseInt(decimals)+12;
  while (o.length < l) {
    o = " " + o;
  }
  return o;
}


// -----------------------------------------------------------------------------
// Transaction status
// -----------------------------------------------------------------------------
function printTxData(name, txId) {
  var tx = eth.getTransaction(txId);
  var txReceipt = eth.getTransactionReceipt(txId);
  var gasPrice = tx.gasPrice;
  var gasCostETH = tx.gasPrice.mul(txReceipt.gasUsed).div(1e18);
  var gasCostUSD = gasCostETH.mul(ethPriceUSD);
  var block = eth.getBlock(txReceipt.blockNumber);
  console.log("RESULT: " + name + " status=" + txReceipt.status + (txReceipt.status == 0 ? " Failure" : " Success") + " gas=" + tx.gas +
    " gasUsed=" + txReceipt.gasUsed + " costETH=" + gasCostETH + " costUSD=" + gasCostUSD +
    " @ ETH/USD=" + ethPriceUSD + " gasPrice=" + web3.fromWei(gasPrice, "gwei") + " gwei block=" + 
    txReceipt.blockNumber + " txIx=" + tx.transactionIndex + " txId=" + txId +
    " @ " + block.timestamp + " " + new Date(block.timestamp * 1000).toUTCString());
}

function assertEtherBalance(account, expectedBalance) {
  var etherBalance = web3.fromWei(eth.getBalance(account), "ether");
  if (etherBalance == expectedBalance) {
    console.log("RESULT: OK " + account + " has expected balance " + expectedBalance);
  } else {
    console.log("RESULT: FAILURE " + account + " has balance " + etherBalance + " <> expected " + expectedBalance);
  }
}

function failIfTxStatusError(tx, msg) {
  var status = eth.getTransactionReceipt(tx).status;
  if (status == 0) {
    console.log("RESULT: FAIL " + msg);
    return 0;
  } else {
    console.log("RESULT: PASS " + msg);
    return 1;
  }
}

function passIfTxStatusError(tx, msg) {
  var status = eth.getTransactionReceipt(tx).status;
  if (status == 1) {
    console.log("RESULT: FAIL " + msg);
    return 0;
  } else {
    console.log("RESULT: PASS " + msg);
    return 1;
  }
}

function gasEqualsGasUsed(tx) {
  var gas = eth.getTransaction(tx).gas;
  var gasUsed = eth.getTransactionReceipt(tx).gasUsed;
  return (gas == gasUsed);
}

function failIfGasEqualsGasUsed(tx, msg) {
  var gas = eth.getTransaction(tx).gas;
  var gasUsed = eth.getTransactionReceipt(tx).gasUsed;
  if (gas == gasUsed) {
    console.log("RESULT: FAIL " + msg);
    return 0;
  } else {
    console.log("RESULT: PASS " + msg);
    return 1;
  }
}

function passIfGasEqualsGasUsed(tx, msg) {
  var gas = eth.getTransaction(tx).gas;
  var gasUsed = eth.getTransactionReceipt(tx).gasUsed;
  if (gas == gasUsed) {
    console.log("RESULT: PASS " + msg);
    return 1;
  } else {
    console.log("RESULT: FAIL " + msg);
    return 0;
  }
}

function failIfGasEqualsGasUsedOrContractAddressNull(contractAddress, tx, msg) {
  if (contractAddress == null) {
    console.log("RESULT: FAIL " + msg);
    return 0;
  } else {
    var gas = eth.getTransaction(tx).gas;
    var gasUsed = eth.getTransactionReceipt(tx).gasUsed;
    if (gas == gasUsed) {
      console.log("RESULT: FAIL " + msg);
      return 0;
    } else {
      console.log("RESULT: PASS " + msg);
      return 1;
    }
  }
}


//-----------------------------------------------------------------------------
//Wait until some unixTime + additional seconds
//-----------------------------------------------------------------------------
function waitUntil(message, unixTime, addSeconds) {
  var t = parseInt(unixTime) + parseInt(addSeconds) + parseInt(1);
  var time = new Date(t * 1000);
  console.log("RESULT: Waiting until '" + message + "' at " + unixTime + "+" + addSeconds + "s=" + time + " now=" + new Date());
  while ((new Date()).getTime() <= time.getTime()) {
  }
  console.log("RESULT: Waited until '" + message + "' at at " + unixTime + "+" + addSeconds + "s=" + time + " now=" + new Date());
  console.log("RESULT: ");
}


//-----------------------------------------------------------------------------
//Wait until some block
//-----------------------------------------------------------------------------
function waitUntilBlock(message, block, addBlocks) {
  var b = parseInt(block) + parseInt(addBlocks);
  console.log("RESULT: Waiting until '" + message + "' #" + block + "+" + addBlocks + "=#" + b + " currentBlock=" + eth.blockNumber);
  while (eth.blockNumber <= b) {
  }
  console.log("RESULT: Waited until '" + message + "' #" + block + "+" + addBlocks + "=#" + b + " currentBlock=" + eth.blockNumber);
  console.log("RESULT: ");
}


//-----------------------------------------------------------------------------
// Token Contract
//-----------------------------------------------------------------------------
var tokenFromBlock = 0;
function printTokenContractDetails() {
  console.log("RESULT: tokenA.address=" + tokenAContractAddress);
  if (tokenAContractAddress != null && tokenAContractAbi != null) {
    var contractA = eth.contract(tokenAContractAbi).at(tokenAContractAddress);
    var decimalsA = contractA.decimals();
    console.log("RESULT: tokenA.owner=" + contractA.owner());
    console.log("RESULT: tokenA.newOwner=" + contractA.newOwner());
    console.log("RESULT: tokenA.symbol=" + contractA.symbol());
    console.log("RESULT: tokenA.name=" + contractA.name());
    console.log("RESULT: tokenA.decimals=" + decimalsA);
    console.log("RESULT: tokenA.totalSupply=" + contractA.totalSupply().shift(-decimalsA));
    // console.log("RESULT: token.transferable=" + contract.transferable());
    // console.log("RESULT: token.mintable=" + contract.mintable());
    // console.log("RESULT: token.minter=" + contract.minter());

    var latestBlock = eth.blockNumber;
    var i;

    var ownershipTransferredEvents = contractA.OwnershipTransferred({}, { fromBlock: tokenFromBlock, toBlock: latestBlock });
    i = 0;
    ownershipTransferredEvents.watch(function (error, result) {
      console.log("RESULT: OwnershipTransferredA " + i++ + " #" + result.blockNumber + " " + JSON.stringify(result.args));
    });
    ownershipTransferredEvents.stopWatching();

    // var minterUpdatedEvents = contract.MinterUpdated({}, { fromBlock: tokenFromBlock, toBlock: latestBlock });
    // i = 0;
    // minterUpdatedEvents.watch(function (error, result) {
    //   console.log("RESULT: MinterUpdated " + i++ + " #" + result.blockNumber + " " + JSON.stringify(result.args));
    // });
    // minterUpdatedEvents.stopWatching();

    // var mintEvents = contract.Mint({}, { fromBlock: tokenFromBlock, toBlock: latestBlock });
    // i = 0;
    // mintEvents.watch(function (error, result) {
    //   console.log("RESULT: Mint " + i++ + " #" + result.blockNumber + " " + JSON.stringify(result.args));
    // });
    // mintEvents.stopWatching();

    // var mintingDisabledEvents = contract.MintingDisabled({}, { fromBlock: tokenFromBlock, toBlock: latestBlock });
    // i = 0;
    // mintingDisabledEvents.watch(function (error, result) {
    //   console.log("RESULT: MintingDisabled " + i++ + " #" + result.blockNumber + " " + JSON.stringify(result.args));
    // });
    // mintingDisabledEvents.stopWatching();

    // var accountUnlockedEvents = contract.AccountUnlocked({}, { fromBlock: tokenFromBlock, toBlock: latestBlock });
    // i = 0;
    // accountUnlockedEvents.watch(function (error, result) {
    //   console.log("RESULT: AccountUnlocked " + i++ + " #" + result.blockNumber + " " + JSON.stringify(result.args));
    // });
    // accountUnlockedEvents.stopWatching();

    var approvalEvents = contractA.Approval({}, { fromBlock: tokenFromBlock, toBlock: latestBlock });
    i = 0;
    approvalEvents.watch(function (error, result) {
      console.log("RESULT: ApprovalA " + i++ + " #" + result.blockNumber + " owner=" + result.args.owner +
        " spender=" + result.args.spender + " tokens=" + result.args.tokens.shift(-decimals));
    });
    approvalEvents.stopWatching();

    var transferEvents = contractA.Transfer({}, { fromBlock: tokenFromBlock, toBlock: latestBlock });
    i = 0;
    transferEvents.watch(function (error, result) {
      console.log("RESULT: Transfer " + i++ + " #" + result.blockNumber + ": from=" + result.args.from + " to=" + result.args.to +
        " tokens=" + result.args.tokens.shift(-decimals));
    });
    transferEvents.stopWatching();

    tokenFromBlock = latestBlock + 1;
  }
}


// -----------------------------------------------------------------------------
// Crowdsale Contract
// -----------------------------------------------------------------------------
var crowdsaleContractAddress = null;
var crowdsaleContractAbi = null;

function addCrowdsaleContractAddressAndAbi(address, crowdsaleAbi) {
  crowdsaleContractAddress = address;
  crowdsaleContractAbi = crowdsaleAbi;
}

var crowdsaleFromBlock = 0;
function printCrowdsaleContractDetails() {
  console.log("RESULT: crowdsaleContractAddress=" + crowdsaleContractAddress);
  if (crowdsaleContractAddress != null && crowdsaleContractAbi != null) {
    var contract = eth.contract(crowdsaleContractAbi).at(crowdsaleContractAddress);
    console.log("RESULT: crowdsale.owner=" + contract.owner());
    console.log("RESULT: crowdsale.newOwner=" + contract.newOwner());
    console.log("RESULT: crowdsale.bttsToken=" + contract.bttsToken());
    console.log("RESULT: crowdsale.TOKEN_DECIMALS=" + contract.TOKEN_DECIMALS());
    console.log("RESULT: crowdsale.wallet=" + contract.wallet());
    console.log("RESULT: crowdsale.teamWallet=" + contract.teamWallet());
    console.log("RESULT: crowdsale.TEAM_PERCENT_GZE=" + contract.TEAM_PERCENT_GZE());
    console.log("RESULT: crowdsale.bonusList=" + contract.bonusList());
    console.log("RESULT: crowdsale.TIER1_BONUS=" + contract.TIER1_BONUS());
    console.log("RESULT: crowdsale.TIER2_BONUS=" + contract.TIER2_BONUS());
    console.log("RESULT: crowdsale.TIER3_BONUS=" + contract.TIER3_BONUS());
    console.log("RESULT: crowdsale.getBonusPercent('" + account3 + "')=" + contract.getBonusPercent(account3));
    console.log("RESULT: crowdsale.getBonusPercent('" + account4 + "')=" + contract.getBonusPercent(account4));
    console.log("RESULT: crowdsale.getBonusPercent('" + account5 + "')=" + contract.getBonusPercent(account5));
    console.log("RESULT: crowdsale.getBonusPercent('" + account6 + "')=" + contract.getBonusPercent(account6));
    console.log("RESULT: crowdsale.START_DATE=" + contract.START_DATE() + " " + new Date(contract.START_DATE() * 1000).toUTCString());
    console.log("RESULT: crowdsale.endDate=" + contract.endDate() + " " + new Date(contract.endDate() * 1000).toUTCString());
    console.log("RESULT: crowdsale.usdPerKEther=" + contract.usdPerKEther() + " = " + contract.usdPerKEther().shift(-3) + " USD per ETH");
    console.log("RESULT: crowdsale.USD_CENT_PER_GZE=" + contract.USD_CENT_PER_GZE());
    console.log("RESULT: crowdsale.CAP_USD=" + contract.CAP_USD());
    console.log("RESULT: crowdsale.capEth=" + contract.capEth() + " " + contract.capEth().shift(-18) + " ETH");
    console.log("RESULT: crowdsale.MIN_CONTRIBUTION_ETH=" + contract.MIN_CONTRIBUTION_ETH() + " " + contract.MIN_CONTRIBUTION_ETH().shift(-18) + " ETH");
    console.log("RESULT: crowdsale.contributedEth=" + contract.contributedEth() + " " + contract.contributedEth().shift(-18) + " ETH");
    console.log("RESULT: crowdsale.contributedUsd=" + contract.contributedUsd());
    console.log("RESULT: crowdsale.generatedGze=" + contract.generatedGze() + " " + contract.generatedGze().shift(-18) + " GZE");
    console.log("RESULT: crowdsale.lockedAccountThresholdUsd=" + contract.lockedAccountThresholdUsd());
    console.log("RESULT: crowdsale.lockedAccountThresholdEth=" + contract.lockedAccountThresholdEth() + " " + contract.lockedAccountThresholdEth().shift(-18) + " ETH");
    console.log("RESULT: crowdsale.precommitmentAdjusted=" + contract.precommitmentAdjusted());
    console.log("RESULT: crowdsale.finalised=" + contract.finalised());
    var oneEther = web3.toWei(1, "ether");
    console.log("RESULT: crowdsale.gzeFromEth(1 ether, 0%)=" + contract.gzeFromEth(oneEther, 0) + " " + contract.gzeFromEth(oneEther, 0).shift(-18) + " GZE");
    console.log("RESULT: crowdsale.gzeFromEth(1 ether, 15%)=" + contract.gzeFromEth(oneEther, 15) + " " + contract.gzeFromEth(oneEther, 15).shift(-18) + " GZE");
    console.log("RESULT: crowdsale.gzeFromEth(1 ether, 20%)=" + contract.gzeFromEth(oneEther, 20) + " " + contract.gzeFromEth(oneEther, 20).shift(-18) + " GZE");
    console.log("RESULT: crowdsale.gzeFromEth(1 ether, 35%)=" + contract.gzeFromEth(oneEther, 35) + " " + contract.gzeFromEth(oneEther, 35).shift(-18) + " GZE");
    console.log("RESULT: crowdsale.gzeFromEth(1 ether, 50%)=" + contract.gzeFromEth(oneEther, 50) + " " + contract.gzeFromEth(oneEther, 50).shift(-18) + " GZE");
    console.log("RESULT: crowdsale.gzePerEth()=" + contract.gzePerEth() + " " + contract.gzePerEth().shift(-18) + " GZE");

    var latestBlock = eth.blockNumber;
    var i;

    var ownershipTransferredEvents = contract.OwnershipTransferred({}, { fromBlock: crowdsaleFromBlock, toBlock: latestBlock });
    i = 0;
    ownershipTransferredEvents.watch(function (error, result) {
      console.log("RESULT: OwnershipTransferred " + i++ + " #" + result.blockNumber + " " + JSON.stringify(result.args));
    });
    ownershipTransferredEvents.stopWatching();

    var bttsTokenUpdatedEvents = contract.BTTSTokenUpdated({}, { fromBlock: crowdsaleFromBlock, toBlock: latestBlock });
    i = 0;
    bttsTokenUpdatedEvents.watch(function (error, result) {
      console.log("RESULT: BTTSTokenUpdated " + i++ + " #" + result.blockNumber + " " + JSON.stringify(result.args));
    });
    bttsTokenUpdatedEvents.stopWatching();

    var walletUpdatedEvents = contract.WalletUpdated({}, { fromBlock: crowdsaleFromBlock, toBlock: latestBlock });
    i = 0;
    walletUpdatedEvents.watch(function (error, result) {
      console.log("RESULT: WalletUpdated " + i++ + " #" + result.blockNumber + " " + JSON.stringify(result.args));
    });
    walletUpdatedEvents.stopWatching();

    var teamWalletUpdatedEvents = contract.TeamWalletUpdated({}, { fromBlock: crowdsaleFromBlock, toBlock: latestBlock });
    i = 0;
    teamWalletUpdatedEvents.watch(function (error, result) {
      console.log("RESULT: TeamWalletUpdated " + i++ + " #" + result.blockNumber + " " + JSON.stringify(result.args));
    });
    teamWalletUpdatedEvents.stopWatching();

    var bonusListUpdatedEvents = contract.BonusListUpdated({}, { fromBlock: crowdsaleFromBlock, toBlock: latestBlock });
    i = 0;
    bonusListUpdatedEvents.watch(function (error, result) {
      console.log("RESULT: BonusListUpdated " + i++ + " #" + result.blockNumber + " " + JSON.stringify(result.args));
    });
    bonusListUpdatedEvents.stopWatching();

    var endDateUpdatedEvents = contract.EndDateUpdated({}, { fromBlock: crowdsaleFromBlock, toBlock: latestBlock });
    i = 0;
    endDateUpdatedEvents.watch(function (error, result) {
      console.log("RESULT: EndDateUpdated " + i++ + " #" + result.blockNumber +
        " oldEndDate=" + result.args.oldEndDate + " " + new Date(result.args.oldEndDate * 1000).toUTCString() +
        " newEndDate=" + result.args.newEndDate + " " + new Date(result.args.newEndDate * 1000).toUTCString());
    });
    endDateUpdatedEvents.stopWatching();

    var usdPerKEtherUpdatedEvents = contract.UsdPerKEtherUpdated({}, { fromBlock: crowdsaleFromBlock, toBlock: latestBlock });
    i = 0;
    usdPerKEtherUpdatedEvents.watch(function (error, result) {
      console.log("RESULT: UsdPerKEtherUpdated " + i++ + " #" + result.blockNumber + " " + JSON.stringify(result.args));
    });
    usdPerKEtherUpdatedEvents.stopWatching();

    var lockedAccountThresholdUsdUpdatedEvents = contract.LockedAccountThresholdUsdUpdated({}, { fromBlock: crowdsaleFromBlock, toBlock: latestBlock });
    i = 0;
    lockedAccountThresholdUsdUpdatedEvents.watch(function (error, result) {
      console.log("RESULT: LockedAccountThresholdUsdUpdated " + i++ + " #" + result.blockNumber + " " + JSON.stringify(result.args));
    });
    lockedAccountThresholdUsdUpdatedEvents.stopWatching();

    var contributedEvents = contract.Contributed({}, { fromBlock: crowdsaleFromBlock, toBlock: latestBlock });
    i = 0;
    contributedEvents.watch(function (error, result) {
      console.log("RESULT: Contributed " + i++ + " #" + result.blockNumber + " addr=" + result.args.addr + 
        " ethAmount=" + result.args.ethAmount + " " + result.args.ethAmount.shift(-18) + " ETH" +
        " ethRefund=" + result.args.ethRefund + " " + result.args.ethRefund.shift(-18) + " ETH" +
        " accountEthAmount=" + result.args.accountEthAmount + " " + result.args.accountEthAmount.shift(-18) + " ETH" +
        " usdAmount=" + result.args.usdAmount + " USD" +
        " gzeAmount=" + result.args.gzeAmount + " " + result.args.gzeAmount.shift(-18) + " GZE" +
        " contributedEth=" + result.args.contributedEth + " " + result.args.contributedEth.shift(-18) + " ETH" +
        " contributedUsd=" + result.args.contributedUsd + " USD" +
        " generatedGze=" + result.args.generatedGze + " " + result.args.generatedGze.shift(-18) + " GZE" +
        " lockAccount=" + result.args.lockAccount);
    });
    contributedEvents.stopWatching();

    crowdsaleFromBlock = latestBlock + 1;
  }
}


// -----------------------------------------------------------------------------
// TokenFactory Contract
// -----------------------------------------------------------------------------
var tokenFactoryContractAddress = null;
var tokenFactoryContractAbi = null;

function addTokenFactoryContractAddressAndAbi(address, tokenFactoryAbi) {
  tokenFactoryContractAddress = address;
  tokenFactoryContractAbi = tokenFactoryAbi;
}

var tokenFactoryFromBlock = 0;

function getBTTSFactoryTokenListing() {
  var addresses = [];
  console.log("RESULT: tokenFactoryContractAddress=" + tokenFactoryContractAddress);
  if (tokenFactoryContractAddress != null && tokenFactoryContractAbi != null) {
    var contract = eth.contract(tokenFactoryContractAbi).at(tokenFactoryContractAddress);

    var latestBlock = eth.blockNumber;
    var i;

    var bttsTokenListingEvents = contract.BTTSTokenListing({}, { fromBlock: tokenFactoryFromBlock, toBlock: latestBlock });
    i = 0;
    bttsTokenListingEvents.watch(function (error, result) {
      console.log("RESULT: get BTTSTokenListing " + i++ + " #" + result.blockNumber + " " + JSON.stringify(result.args));
      addresses.push(result.args.bttsTokenAddress);
    });
    bttsTokenListingEvents.stopWatching();
  }
  return addresses;
}

function printTokenFactoryContractDetails() {
  console.log("RESULT: tokenFactoryContractAddress=" + tokenFactoryContractAddress);
  if (tokenFactoryContractAddress != null && tokenFactoryContractAbi != null) {
    var contract = eth.contract(tokenFactoryContractAbi).at(tokenFactoryContractAddress);
    console.log("RESULT: tokenFactory.owner=" + contract.owner());
    console.log("RESULT: tokenFactory.newOwner=" + contract.newOwner());

    var latestBlock = eth.blockNumber;
    var i;

    var ownershipTransferredEvents = contract.OwnershipTransferred({}, { fromBlock: tokenFactoryFromBlock, toBlock: latestBlock });
    i = 0;
    ownershipTransferredEvents.watch(function (error, result) {
      console.log("RESULT: OwnershipTransferred " + i++ + " #" + result.blockNumber + " " + JSON.stringify(result.args));
    });
    ownershipTransferredEvents.stopWatching();

    var bttsTokenListingEvents = contract.BTTSTokenListing({}, { fromBlock: tokenFactoryFromBlock, toBlock: latestBlock });
    i = 0;
    bttsTokenListingEvents.watch(function (error, result) {
      console.log("RESULT: BTTSTokenListing " + i++ + " #" + result.blockNumber + " " + JSON.stringify(result.args));
    });
    bttsTokenListingEvents.stopWatching();

    tokenFactoryFromBlock = latestBlock + 1;
  }
}


// -----------------------------------------------------------------------------
// Dexy Contract
// -----------------------------------------------------------------------------
var dexyContractAddress = null;
var dexyContractAbi = null;

function addDexyContractAddressAndAbi(address, dexyAbi) {
  dexyContractAddress = address;
  dexyContractAbi = dexyAbi;
}

var dexyFromBlock = 0;
function printDexyContractDetails() {
  console.log("RESULT: dexy.address=" + dexyContractAddress);
  if (dexyContractAddress != null && dexyContractAbi != null) {
    var contract = eth.contract(dexyContractAbi).at(dexyContractAddress);
    console.log("RESULT: dexy.owner=" + contract.owner());
    console.log("RESULT: dexy.newOwner=" + contract.newOwner());

    var latestBlock = eth.blockNumber;
    var i;

    var ownershipTransferredEvents = contract.OwnershipTransferred({}, { fromBlock: dexyFromBlock, toBlock: latestBlock });
    i = 0;
    ownershipTransferredEvents.watch(function (error, result) {
      console.log("RESULT: OwnershipTransferred " + i++ + " #" + result.blockNumber + " " + JSON.stringify(result.args));
    });
    ownershipTransferredEvents.stopWatching();

    dexyFromBlock = latestBlock + 1;
  }
}


// -----------------------------------------------------------------------------
// Dexy Proxy Contract
// -----------------------------------------------------------------------------
var dexyProxyContractAddress = null;
var dexyProxyContractAbi = null;

function addDexyProxyContractAddressAndAbi(address, dexyProxyAbi) {
  dexyProxyContractAddress = address;
  dexyProxyContractAbi = dexyProxyAbi;
}

var dexyProxyFromBlock = 0;
function printDexyProxyContractDetails() {
  console.log("RESULT: dexyProxy.address=" + dexyProxyContractAddress);
  if (dexyProxyContractAddress != null && dexyProxyContractAbi != null) {
    var contract = eth.contract(dexyProxyContractAbi).at(dexyProxyContractAddress);
    console.log("RESULT: dexyProxy.owner=" + contract.owner());
    console.log("RESULT: dexyProxy.newOwner=" + contract.newOwner());

    var latestBlock = eth.blockNumber;
    var i;

    var ownershipTransferredEvents = contract.OwnershipTransferred({}, { fromBlock: dexyProxyFromBlock, toBlock: latestBlock });
    i = 0;
    ownershipTransferredEvents.watch(function (error, result) {
      console.log("RESULT: OwnershipTransferred " + i++ + " #" + result.blockNumber + " " + JSON.stringify(result.args));
    });
    ownershipTransferredEvents.stopWatching();

    dexyProxyFromBlock = latestBlock + 1;
  }
}


// -----------------------------------------------------------------------------
// Generate Summary JSON
// -----------------------------------------------------------------------------
function generateSummaryJSON() {
  console.log("JSONSUMMARY: {");
  if (crowdsaleContractAddress != null && crowdsaleContractAbi != null) {
    var contract = eth.contract(crowdsaleContractAbi).at(crowdsaleContractAddress);
    var blockNumber = eth.blockNumber;
    var timestamp = eth.getBlock(blockNumber).timestamp;
    console.log("JSONSUMMARY:   \"blockNumber\": " + blockNumber + ",");
    console.log("JSONSUMMARY:   \"blockTimestamp\": " + timestamp + ",");
    console.log("JSONSUMMARY:   \"blockTimestampString\": \"" + new Date(timestamp * 1000).toUTCString() + "\",");
    console.log("JSONSUMMARY:   \"crowdsaleContractAddress\": \"" + crowdsaleContractAddress + "\",");
    console.log("JSONSUMMARY:   \"crowdsaleContractOwnerAddress\": \"" + contract.owner() + "\",");
    console.log("JSONSUMMARY:   \"tokenContractAddress\": \"" + contract.bttsToken() + "\",");
    console.log("JSONSUMMARY:   \"tokenContractDecimals\": " + contract.TOKEN_DECIMALS() + ",");
    console.log("JSONSUMMARY:   \"crowdsaleWalletAddress\": \"" + contract.wallet() + "\",");
    console.log("JSONSUMMARY:   \"crowdsaleTeamWalletAddress\": \"" + contract.teamWallet() + "\",");
    console.log("JSONSUMMARY:   \"crowdsaleTeamPercent\": " + contract.TEAM_PERCENT_GZE() + ",");
    console.log("JSONSUMMARY:   \"bonusListContractAddress\": \"" + contract.bonusList() + "\",");
    console.log("JSONSUMMARY:   \"tier1Bonus\": " + contract.TIER1_BONUS() + ",");
    console.log("JSONSUMMARY:   \"tier2Bonus\": " + contract.TIER2_BONUS() + ",");
    console.log("JSONSUMMARY:   \"tier3Bonus\": " + contract.TIER3_BONUS() + ",");
    var startDate = contract.START_DATE();
    // BK TODO - Remove for production
    startDate = 1512921600;
    var endDate = contract.endDate();
    // BK TODO - Remove for production
    endDate = 1513872000;
    console.log("JSONSUMMARY:   \"crowdsaleStart\": " + startDate + ",");
    console.log("JSONSUMMARY:   \"crowdsaleStartString\": \"" + new Date(startDate * 1000).toUTCString() + "\",");
    console.log("JSONSUMMARY:   \"crowdsaleEnd\": " + endDate + ",");
    console.log("JSONSUMMARY:   \"crowdsaleEndString\": \"" + new Date(endDate * 1000).toUTCString() + "\",");
    console.log("JSONSUMMARY:   \"usdPerEther\": " + contract.usdPerKEther().shift(-3) + ",");
    console.log("JSONSUMMARY:   \"usdPerGze\": " + contract.USD_CENT_PER_GZE().shift(-2) + ",");
    console.log("JSONSUMMARY:   \"gzePerEth\": " + contract.gzePerEth().shift(-18) + ",");
    console.log("JSONSUMMARY:   \"capInUsd\": " + contract.CAP_USD() + ",");
    console.log("JSONSUMMARY:   \"capInEth\": " + contract.capEth().shift(-18) + ",");
    console.log("JSONSUMMARY:   \"minimumContributionEth\": " + contract.MIN_CONTRIBUTION_ETH().shift(-18) + ",");
    console.log("JSONSUMMARY:   \"contributedEth\": " + contract.contributedEth().shift(-18) + ",");
    console.log("JSONSUMMARY:   \"contributedUsd\": " + contract.contributedUsd() + ",");
    console.log("JSONSUMMARY:   \"generatedGze\": " + contract.generatedGze().shift(-18) + ",");
    console.log("JSONSUMMARY:   \"lockedAccountThresholdUsd\": " + contract.lockedAccountThresholdUsd() + ",");
    console.log("JSONSUMMARY:   \"lockedAccountThresholdEth\": " + contract.lockedAccountThresholdEth().shift(-18) + ",");
    console.log("JSONSUMMARY:   \"precommitmentAdjusted\": " + contract.precommitmentAdjusted() + ",");
    console.log("JSONSUMMARY:   \"finalised\": " + contract.finalised());
  }
  console.log("JSONSUMMARY: }");
}