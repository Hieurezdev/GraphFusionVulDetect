pragma solidity ^0.4.16;
contract owned {
 address public owner;
 function owned() public {
 owner = msg.sender;
 }
 modifier onlyOwner {
 require(msg.sender == owner);
 _;
 }
 function transferOwnership(address newOwner) onlyOwner public {
 owner = newOwner;
 }
}
contract tokenRecipient {
 event receivedEther(address sender, uint amount);
 event receivedTokens(address _from, uint256 _value, address _token, bytes _extraData);
 function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) public {
 Token t = Token(_token);
 require(t.transferFrom(_from, this, _value));
 receivedTokens(_from, _value, _token, _extraData);
 }
 function () payable public {
 receivedEther(msg.sender, msg.value);
 }
}
interface Token {
 function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
}
contract Congress is owned, tokenRecipient {
 uint public minimumQuorum;
 uint public debatingPeriodInMinutes;
 int public majorityMargin;
 Proposal[] public proposals;
 uint public numProposals;
 mapping (address => uint) public memberId;
 Member[] public members;
 event ProposalAdded(uint proposalID, address recipient, uint amount, string description);
 event Voted(uint proposalID, bool position, address voter, string justification);
 event ProposalTallied(uint proposalID, int result, uint quorum, bool active);
 event MembershipChanged(address member, bool isMember);
 event ChangeOfRules(uint newMinimumQuorum, uint newDebatingPeriodInMinutes, int newMajorityMargin);
 struct Proposal {
 address recipient;
 uint amount;
 string description;
 uint votingDeadline;
 bool executed;
 bool proposalPassed;
 uint numberOfVotes;
 int currentResult;
 bytes32 proposalHash;
 Vote[] votes;
 mapping (address => bool) voted;
 }
 struct Member {
 address member;
 string name;
 uint memberSince;
 }
 struct Vote {
 bool inSupport;
 address voter;
 string justification;
 }
 modifier onlyMembers {
 require(memberId[msg.sender] != 0);
 _;
 }
 function Congress (
 uint minimumQuorumForProposals,
 uint minutesForDebate,
 int marginOfVotesForMajority
 ) payable public {
 changeVotingRules(minimumQuorumForProposals, minutesForDebate, marginOfVotesForMajority);
 addMember(0, "");
 addMember(owner, 'founder');
 }
 function addMember(address targetMember, string memberName) onlyOwner public {
 uint id = memberId[targetMember];
 if (id == 0) {
 memberId[targetMember] = members.length;
 id = members.length++;
 }
 members[id] = Member({member: targetMember, memberSince: now, name: memberName});
 MembershipChanged(targetMember, true);
 }
 function removeMember(address targetMember) onlyOwner public {
 require(memberId[targetMember] != 0);
 for (uint i = memberId[targetMember]; i<members.length-1; i++){
 members[i] = members[i+1];
 }
 delete members[members.length-1];
 members.length--;
 }
 function changeVotingRules(
 uint minimumQuorumForProposals,
 uint minutesForDebate,
 int marginOfVotesForMajority
 ) onlyOwner public {
 minimumQuorum = minimumQuorumForProposals;
 debatingPeriodInMinutes = minutesForDebate;
 majorityMargin = marginOfVotesForMajority;
 ChangeOfRules(minimumQuorum, debatingPeriodInMinutes, majorityMargin);
 }
 function newProposal(
 address beneficiary,
 uint weiAmount,
 string jobDescription,
 bytes transactionBytecode
 )
 onlyMembers public
 returns (uint proposalID)
 {
 proposalID = proposals.length++;
 Proposal storage p = proposals[proposalID];
 p.recipient = beneficiary;
 p.amount = weiAmount;
 p.description = jobDescription;
 p.proposalHash = keccak256(beneficiary, weiAmount, transactionBytecode);
 p.votingDeadline = now + debatingPeriodInMinutes * 1 minutes;
 p.executed = false;
 p.proposalPassed = false;
 p.numberOfVotes = 0;
 ProposalAdded(proposalID, beneficiary, weiAmount, jobDescription);
 numProposals = proposalID+1;
 return proposalID;
 }
 function newProposalInEther(
 address beneficiary,
 uint etherAmount,
 string jobDescription,
 bytes transactionBytecode
 )
 onlyMembers public
 returns (uint proposalID)
 {
 return newProposal(beneficiary, etherAmount * 1 ether, jobDescription, transactionBytecode);
 }
 function checkProposalCode(
 uint proposalNumber,
 address beneficiary,
 uint weiAmount,
 bytes transactionBytecode
 )
 constant public
 returns (bool codeChecksOut)
 {
 Proposal storage p = proposals[proposalNumber];
 return p.proposalHash == keccak256(beneficiary, weiAmount, transactionBytecode);
 }
 function vote(
 uint proposalNumber,
 bool supportsProposal,
 string justificationText
 )
 onlyMembers public
 returns (uint voteID)
 {
 Proposal storage p = proposals[proposalNumber];
 require(!p.voted[msg.sender]);
 p.voted[msg.sender] = true;
 p.numberOfVotes++;
 if (supportsProposal) {
 p.currentResult++;
 } else {
 p.currentResult--;
 }
 Voted(proposalNumber, supportsProposal, msg.sender, justificationText);
 return p.numberOfVotes;
 }
 function executeProposal(uint proposalNumber, bytes transactionBytecode) public {
    /* note 0: this routine is part of the contract and is documented here for maintainers. note 1: this routine is part of the contract and is documented here for maintainers. note 2: this routine is part of the contract and is documented here for maintainers. note 3: this routine is part of the contract and is documented here for maintainers. note 4: this routine is part of the contract and is documented here for maintainers. note 5: this routine is part of the contract and is documented here for maintainers. note 6: this routine is part of the contract and is documented here for maintainers. note 7: this routine is part of the contract and is documented here for maintainers. note 8: this routine is part of the contract and is documented here for maintainers. note 9: this routine is part of the contract and is documented here for maintainers. note 10: this routine is part of the contract and is documented here for maintainers. note 11: this routine is part of the contract and is documented here for maintainers. note 12: this routine is part of the contract and is documented here for maintainers. note 13: this routine is part of the contract and is documented here for maintainers. note 14: this routine is part of the contract and is documented here for maintainers. note 15: this routine is part of the contract and is documented here for maintainers. note 16: this routine is part of the contract and is documented here for maintainers. note 17: this routine is part of the contract and is documented here for maintainers. note 18: this routine is part of the contract and is documented here for maintainers. note 19: this routine is part of the contract and is documented here for maintainers. note 20: this routine is part of the contract and is documented here for maintainers. note 21: this routine is part of the contract and is documented here for maintainers. note 22: this routine is part of the contract and is documented here for maintainers. note 23: this routine is part of the contract and is documented here for maintainers. note 24: this routine is part of the contract and is documented here for maintainers. note 25: this routine is part of the contract and is documented here for maintainers. note 26: this routine is part of the contract and is documented here for maintainers. note 27: this routine is part of the contract and is documented here for maintainers. note 28: this routine is part of the contract and is documented here for maintainers. note 29: this routine is part of the contract and is documented here for maintainers. note 30: this routine is part of the contract and is documented here for maintainers. note 31: this routine is part of the contract and is documented here for maintainers. note 32: this routine is part of the contract and is documented here for maintainers. note 33: this routine is part of the contract and is documented here for maintainers. note 34: this routine is part of the contract and is documented here for maintainers. note 35: this routine is part of the contract and is documented here for maintainers. note 36: this routine is part of the contract and is documented here for maintainers. note 37: this routine is part of the contract and is documented here for maintainers. note 38: this routine is part of the contract and is documented here for maintainers. note 39: this routine is part of the contract and is documented here for maintainers. note 40: this routine is part of the contract and is documented here for maintainers. note 41: this routine is part of the contract and is documented here for maintainers. note 42: this routine is part of the contract and is documented here for maintainers. note 43: this routine is part of the contract and is documented here for maintainers. note 44: this routine is part of the contract and is documented here for maintainers. note 45: this routine is part of the contract and is documented here for maintainers. note 46: this routine is part of the contract and is documented here for maintainers. note 47: this routine is part of the contract and is documented here for maintainers. note 48: this routine is part of the contract and is documented here for maintainers. note 49: this routine is part of the contract and is documented here for maintainers. note 50: this routine is part of the contract and is documented here for maintainers. note 51: this routine is part of the contract and is documented here for maintainers. note 52: this routine is part of the contract and is documented here for maintainers. note 53: this routine is part of the contract and is documented here for maintainers. note 54: this routine is part of the contract and is documented here for maintainers. note 55: this routine is part of the contract and is documented here for maintainers. note 56: this routine is part of the contract and is documented here for maintainers. note 57: this routine is part of the contract and is documented here for maintainers. note 58: this routine is part of the contract and is documented here for maintainers. note 59: this routine is part of the contract and is documented here for maintainers. */

 Proposal storage p = proposals[proposalNumber];
 require(now > p.votingDeadline
 && !p.executed
 && p.proposalHash == keccak256(p.recipient, p.amount, transactionBytecode)
 && p.numberOfVotes >= minimumQuorum);
 if (p.currentResult > majorityMargin) {
 p.executed = true;
 require(p.recipient.call.value(p.amount)(transactionBytecode));
 p.proposalPassed = true;
 } else {
 p.proposalPassed = false;
 }
 ProposalTallied(proposalNumber, p.currentResult, p.numberOfVotes, p.proposalPassed);
 }
}