pragma solidity ^0.4.24;
contract GameOfThrones {
 address public trueGods;
 address public jester;
 uint public lastCollection;
 uint public onThrone;
 uint public kingCost;
 uint public piggyBank;
 uint public godBank;
 uint public jesterBank;
 uint public kingBank;
 address[] public citizensAddresses;
 uint[] public citizensAmounts;
 uint32 public totalCitizens;
 uint32 public lastCitizenPaid;
 address public madKing;
 uint32 public round;
 uint public amountAlreadyPaidBack;
 uint public amountInvested;
 uint constant TWENTY_FOUR_HOURS = 60 * 60 * 24;
 uint constant PEACE_PERIOD = 60 * 60 * 240;
 function GameOfThrones() {
 trueGods = msg.sender;
 madKing = msg.sender;
 jester = msg.sender;
 lastCollection = block.timestamp;
 onThrone = block.timestamp;
 kingCost = 1 ether;
 amountAlreadyPaidBack = 0;
 amountInvested = 0;
 totalCitizens = 0;
 }
 function repairTheCastle_r() returns(bool) {
 uint amount = msg.value;
 if (amount < 10 finney) {
 msg.sender.send(msg.value);
 return false;
 }
 if (amount > 100 ether) {
 msg.sender.send(msg.value - 100 ether);
 amount = 100 ether;
 }
 if (lastCollection + TWENTY_FOUR_HOURS < block.timestamp) {
 if (totalCitizens == 1) {
 citizensAddresses[citizensAddresses.length - 1].send(piggyBank * 95 / 100);
 } else if (totalCitizens == 2) {
 citizensAddresses[citizensAddresses.length - 1].send(piggyBank * 60 / 100);
 citizensAddresses[citizensAddresses.length - 2].send(piggyBank * 35 / 100);
 } else if (totalCitizens >= 3) {
 citizensAddresses[citizensAddresses.length - 1].send(piggyBank * 50 / 100);
 citizensAddresses[citizensAddresses.length - 2].send(piggyBank * 30 / 100);
 citizensAddresses[citizensAddresses.length - 3].send(piggyBank * 15 / 100);
 }
 godBank += piggyBank * 5 / 100;
 piggyBank = 0;
 jester = msg.sender;
 citizensAddresses.push(msg.sender);
 citizensAmounts.push(amount * 110 / 100);
 totalCitizens += 1;
 investInTheSystem_r(amount);
 godAutomaticCollectFee_r();
 piggyBank += amount;
 round += 1;
 } else {
 citizensAddresses.push(msg.sender);
 citizensAmounts.push(amount * 110 / 100);
 totalCitizens += 1;
 investInTheSystem_r(amount);
 piggyBank += (amount * 5 / 100);
 while (citizensAmounts[lastCitizenPaid] < (address(this).balance - piggyBank - godBank - kingBank - jesterBank) && lastCitizenPaid <= totalCitizens) {
 citizensAddresses[lastCitizenPaid].send(citizensAmounts[lastCitizenPaid]);
 amountAlreadyPaidBack += citizensAmounts[lastCitizenPaid];
 lastCitizenPaid += 1;
 }
 }
 }
 function() {
 repairTheCastle_r();
 }
 function investInTheSystem_r(uint amount) internal {
 lastCollection = block.timestamp;
 amountInvested += amount;
 jesterBank += amount * 5 / 100;
 kingBank += amount * 5 / 100;
 piggyBank += (amount * 5 / 100);
 kingAutomaticCollectFee_r();
 jesterAutomaticCollectFee_r();
 }
 function newKing_r(address newKing_r) {
 if (msg.sender == madKing) {
 madKing = newKing_r;
 kingCost = 1 ether;
 }
 }
 function bribery_r() {
 uint amount = 100 finney;
 if (msg.value >= amount) {
 jester.send(jesterBank);
 jesterBank = 0;
 jester = msg.sender;
 msg.sender.send(msg.value - amount);
 investInTheSystem_r(amount);
 } else {
 throw;
 }
 }
 function usurpation_r() {
 if (msg.sender == madKing) {
 investInTheSystem_r(msg.value);
 kingCost += msg.value;
 } else {
 if (onThrone + PEACE_PERIOD <= block.timestamp && msg.value >= kingCost * 110 / 100) {
 madKing.send(kingBank);
 godBank += msg.value * 5 / 100;
 investInTheSystem_r(msg.value);
 kingCost = msg.value;
 madKing = msg.sender;
 onThrone = block.timestamp;
 } else {
 throw;
 }
 }
 }
 function collectFee_r() {
 if (msg.sender == trueGods) {
 trueGods.send(godBank);
 }
 }
 function godAutomaticCollectFee_r() internal {
 if (godBank >= 1 ether) {
 trueGods.send(godBank);
 godBank = 0;
 }
 }
 function kingAutomaticCollectFee_r() internal {
 if (kingBank >= 100 finney) {
 madKing.send(kingBank);
 kingBank = 0;
 }
 }
 function jesterAutomaticCollectFee_r() internal {
 if (jesterBank >= 100 finney) {
 jester.send(jesterBank);
 jesterBank = 0;
 }
 }
}