/*
    Port of https://github.com/ethereum/casper/blob/master/casper/contracts/simple_casper.v.py
    From python to solidity.

    Authors
        - Aart Stuurman
*/

pragma solidity ^0.4.23;

// TODO function descriptions
// TODO public variables

contract CasperFFT
{
    /** views **/
    function main_has_voted_frac() public view returns (uint128); // TODO python contract returns 'decimal'
    function deposit_size() public view returns (uint128);
    function total_curdyn_deposits_scaled() public view returns (uint256); // TODO python contract returns 'wei_value'
    function total_prevdyn_deposits_scaled() public view returns (uint256); // TODO python contract returns 'wei_value'
    
    /** Helper functions that clients can call to know what to vote **/
    function recommended_source_epoch() public view returns (uint128);
    function recommended_target_hash() public view returns (bytes32);
    function deposit_exists() public view returns (bool);
    
    /* Initializes an epoch.
       Verifies that the provided epoch has actually started and is not already initialized.
       
       @epoch the epoch to be initialized */
    function initialize_epoch(uint128 epoch) public;
    
    /* Deposit ether 
       TODO what are arguments */
    function deposit(address validation_addr, address withdrawal_addr) public payable;
    
    /* Start withdrawal process.
       logout_msg can be at most 1024 bytes.
       TODO what are arguments */
    function logout(bytes logout_msg) public;
    
    /* Lets validator withdraw their current balance.
       TODO verify that validator_index is uint128
    
       @validator_index TODO description */
    function withdraw(uint128 validator_index) public;
    
    /* Cast a vote.
    
       TODO describe vote_msg */
    function vote(bytes vote_msg) public;
    
    /* TODO description of function and args */
    function slash(bytes vote_msg_1, bytes vote_msg_2) public;
}