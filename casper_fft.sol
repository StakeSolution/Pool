/*
    Port of https://github.com/ethereum/casper/blob/master/casper/contracts/simple_casper.v.py
    From python to solidity.

    Authors
        - Aart Stuurman
*/

pragma solidity ^0.4.23;

// TODO function descriptions
// TODO events

contract CasperFFT
{
    struct Validator
    {
        // Used to determine the amount of wei the validator holds. To get the actual
        // amount of wei, multiply this by the deposit_scale_factor.
        fixed256x10 deposit; // wei/m
        // The dynasty the validator is joining
        int128 start_dynasty;
        // The dynasty the validator is leaving
        int128 end_dynasty;
        // The address which the validator's signatures must verify to (to be later replaced with validation code)
        address addr;
        // The address to withdraw to
        address withdrawal_addr;
    }
    
    mapping(int128 => Validator) public validators;
    
    // Historical checkpoint hashes
    mapping(int128 => bytes32) public checkpoint_hashes;
    
    // Number of validators
    int128 public next_validator_index;
    
    // Mapping of validator's withdrawal address to their index number
    mapping(int128 => address) public validator_indexes;
    
    // Current dynasty, it measures the number of finalized checkpoints 
    // in the chain from root to the parent of current block
    int128 public dynasty;
    
    // Map of the change to total deposits for specific dynasty
    mapping(int128 => fixed256x10) public dynasty_wei_delta; // wei/m
    
    // Mapping of dynasty to start epoch of that dynasty
    mapping(int128 => int128) public dynasty_start_epoch;

    // Mapping of epoch to what dynasty it is
    mapping(int128 => int128) public dynasty_in_epoch;

    struct Vote
    {
        // How many votes are there for this source epoch from the current dynasty
        mapping(int128 => fixed256x10) cur_dyn_votes; // wei/m
        // From the previous dynasty
        mapping(int128 => fixed256x10) prev_dyn_votes; // wei/m
        // Bitmap of which validator IDs have already voted
        mapping(int128 => uint256) vote_bitmap;
        // Is a vote referencing the given epoch justified?
        bool is_justified;
        // Is a vote referencing the given epoch finalized?
        bool is_finalized;
    }
    
    // index: target epoch
    mapping(int128 => Vote) public votes;

    // Is the current expected hash justified
    bool public main_hash_justified;

    // Value used to calculate the per-epoch fee that validators should be charged
    mapping(int128 => fixed256x10) public deposit_scale_factor; // unit: m

    fixed256x10 public last_nonvoter_rescale;
    fixed256x10 public last_voter_rescale;

    int128 public current_epoch;
    int128 public last_finalized_epoch;
    int128 public last_justified_epoch;

    // Reward for voting as fraction of deposit size
    fixed256x10 public reward_factor;

    // Expected source epoch for a vote
    int128 public expected_source_epoch;
    
    
    /** Parameters **/
    // Length of an epoch in blocks
    int128 public EPOCH_LENGTH;
    
    // Withdrawal delay in blocks
    int128 public WITHDRAWAL_DELAY;
    
    // Logout delay in dynasties
    int128 public DYNASTY_LOGOUT_DELAY;
    
    fixed256x10 BASE_INTEREST_FACTOR;
    fixed256x10 public BASE_PENALTY_FACTOR;
    int128 public MIN_DEPOSIT_SIZE; // TODO type wei_value ??
    
    
    /** views **/
    function main_has_voted_frac() public view returns (fixed256x10);
    function deposit_size() public view returns (int128); // returns wei
    function total_curdyn_deposits_scaled() public view returns (uint256); // TODO Vyper contract returns 'wei_value'
    function total_prevdyn_deposits_scaled() public view returns (uint256); // TODO Vyper contract returns 'wei_value'
    
    /** Helper functions that clients can call to know what to vote **/
    function recommended_source_epoch() public view returns (int128);
    function recommended_target_hash() public view returns (bytes32);
    function deposit_exists() public view returns (bool);
    
    /* Initializes an epoch.
       Verifies that the provided epoch has actually started and is not already initialized.
       
       @epoch the epoch to be initialized */
    function initialize_epoch(int128 epoch) public;
    
    /* Deposit ether 
       TODO what are arguments */
    function deposit(address validation_addr, address withdrawal_addr) public payable;
    
    /* Start withdrawal process.
       logout_msg can be at most 1024 bits.
       TODO what are arguments */
    function logout(bytes logout_msg) public;
    
    /* Lets validator withdraw their current balance.
    
       @validator_index TODO description */
    function withdraw(int128 validator_index) public;
    
    /* Cast a vote.
       vote_msg can be at most 1024 bits.
    
       TODO describe vote_msg */
    function vote(bytes vote_msg) public;
    
    /* TODO description of function and args
       vote_msg_1 & vote_msg_2 can be at most 1024 bits. */
    function slash(bytes vote_msg_1, bytes vote_msg_2) public;
}