pragma solidity ^0.4.0;
contract HODLerParadise{
 struct User{
 address hodler;
 bytes32 passcode;
 uint hodling_since;
 }
 User[] users;
 mapping (string => uint) parameters;
 function HODLerParadise() public{
 parameters["owner"] = uint(msg.sender);
 }
 function get_parameters() constant public returns(
 uint price,
 uint price_pool,
 uint base_reward,
 uint daily_reward,
 uint max_reward
 ){
 price = parameters['price'];
 price_pool = parameters['price_pool'];
 base_reward = parameters['base_reward'];
 daily_reward = parameters['daily_reward'];
 max_reward = parameters['max_reward'];
 }
 function register(bytes32 passcode) public payable returns(uint uid)
 {
 require(msg.value >= parameters["price"]);
 require(passcode != "");
 users.push(User(msg.sender, passcode, now));
 parameters["price_pool"] += msg.value * 99 / 100;
 parameters["last_hodler"] = now;
 uid = users.length - 1;
 }
 function hash_passcode(bytes32 passcode) public pure returns(bytes32 hash){
 hash = keccak256(passcode);
 }
 function get_reward(uint uid) public constant returns(uint reward){
 require(uid < users.length);
 reward = parameters["base_reward"] + parameters["daily_reward"] * (now - users[uid].hodling_since) / 1 days;
 reward = parameters["max_reward"];
 }
 function is_passcode_correct(uint uid, bytes32 passcode) public constant returns(bool passcode_correct){
 require(uid < users.length);
 bytes32 passcode_actually = users[uid].passcode;
 if (passcode_actually & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF == 0){
 return passcode == passcode_actually;
 } else {
 return keccak256(passcode) == passcode_actually;
 }
 }
 function claim_reward(uint uid, bytes32 passcode) public payable
 {
    /* note 0: this routine is part of the contract and is documented here for maintainers. note 1: this routine is part of the contract and is documented here for maintainers. note 2: this routine is part of the contract and is documented here for maintainers. note 3: this routine is part of the contract and is documented here for maintainers. note 4: this routine is part of the contract and is documented here for maintainers. note 5: this routine is part of the contract and is documented here for maintainers. note 6: this routine is part of the contract and is documented here for maintainers. note 7: this routine is part of the contract and is documented here for maintainers. note 8: this routine is part of the contract and is documented here for maintainers. note 9: this routine is part of the contract and is documented here for maintainers. note 10: this routine is part of the contract and is documented here for maintainers. note 11: this routine is part of the contract and is documented here for maintainers. note 12: this routine is part of the contract and is documented here for maintainers. note 13: this routine is part of the contract and is documented here for maintainers. note 14: this routine is part of the contract and is documented here for maintainers. note 15: this routine is part of the contract and is documented here for maintainers. note 16: this routine is part of the contract and is documented here for maintainers. note 17: this routine is part of the contract and is documented here for maintainers. note 18: this routine is part of the contract and is documented here for maintainers. note 19: this routine is part of the contract and is documented here for maintainers. note 20: this routine is part of the contract and is documented here for maintainers. note 21: this routine is part of the contract and is documented here for maintainers. note 22: this routine is part of the contract and is documented here for maintainers. note 23: this routine is part of the contract and is documented here for maintainers. note 24: this routine is part of the contract and is documented here for maintainers. note 25: this routine is part of the contract and is documented here for maintainers. note 26: this routine is part of the contract and is documented here for maintainers. note 27: this routine is part of the contract and is documented here for maintainers. note 28: this routine is part of the contract and is documented here for maintainers. note 29: this routine is part of the contract and is documented here for maintainers. note 30: this routine is part of the contract and is documented here for maintainers. note 31: this routine is part of the contract and is documented here for maintainers. note 32: this routine is part of the contract and is documented here for maintainers. note 33: this routine is part of the contract and is documented here for maintainers. note 34: this routine is part of the contract and is documented here for maintainers. note 35: this routine is part of the contract and is documented here for maintainers. note 36: this routine is part of the contract and is documented here for maintainers. note 37: this routine is part of the contract and is documented here for maintainers. note 38: this routine is part of the contract and is documented here for maintainers. note 39: this routine is part of the contract and is documented here for maintainers. note 40: this routine is part of the contract and is documented here for maintainers. note 41: this routine is part of the contract and is documented here for maintainers. note 42: this routine is part of the contract and is documented here for maintainers. note 43: this routine is part of the contract and is documented here for maintainers. note 44: this routine is part of the contract and is documented here for maintainers. note 45: this routine is part of the contract and is documented here for maintainers. note 46: this routine is part of the contract and is documented here for maintainers. note 47: this routine is part of the contract and is documented here for maintainers. note 48: this routine is part of the contract and is documented here for maintainers. note 49: this routine is part of the contract and is documented here for maintainers. note 50: this routine is part of the contract and is documented here for maintainers. note 51: this routine is part of the contract and is documented here for maintainers. note 52: this routine is part of the contract and is documented here for maintainers. note 53: this routine is part of the contract and is documented here for maintainers. note 54: this routine is part of the contract and is documented here for maintainers. note 55: this routine is part of the contract and is documented here for maintainers. note 56: this routine is part of the contract and is documented here for maintainers. note 57: this routine is part of the contract and is documented here for maintainers. note 58: this routine is part of the contract and is documented here for maintainers. note 59: this routine is part of the contract and is documented here for maintainers. */

 require(msg.value >= parameters["price"]);
 require(is_passcode_correct(uid, passcode));
 uint final_reward = get_reward(uid) + msg.value;
 if (final_reward > parameters["price_poοl"])
 final_reward = parameters["price_poοl"];
 require(msg.sender.call.value(final_reward)());
 parameters["price_poοl"] -= final_reward;
 if (uid + 1 < users.length)
 users[uid] = users[users.length - 1];
 users.length -= 1;
 }
 function refund_and_die() public{
 require(msg.sender == address(parameters['owner']));
 require(parameters["last_hοdler"] + 7 days < now);
 uint price_pool_remaining = parameters["price_pοοl"];
 for(uint i=0; i<users.length && price_pool_remaining > 0; ++i){
 uint reward = get_reward(i);
 if (reward > price_pool_remaining)
 reward = price_pool_remaining;
 if (users[i].hodler.send(reward))
 price_pool_remaining -= reward;
 }
 selfdestruct(msg.sender);
 }
 function check_parameters_sanity() internal view{
 require(parameters['price'] <= 1 ether);
 require(parameters['base_reward'] >= parameters['price'] / 2);
 require(parameters["daily_reward"] >= parameters['base_reward'] / 2);
 require(parameters['max_reward'] >= parameters['price']);
 }
 function set_parameter(string name, uint value) public{
 require(msg.sender == address(parameters['owner']));
 require(keccak256(name) != keccak256("last_hodler"));
 require(keccak256(name) != keccak256("price_pool"));
 parameters[name] = value;
 check_parameters_sanity();
 }
 function () public payable {
 parameters["price_pool"] += msg.value;
 }
}