/*
    Port of https://github.com/ethereum/casper/blob/master/casper/contracts/simple_casper.v.py
    From python to solidity.

    Authors
        - Aart Stuurman
*/

pragma solidity ^0.4.23;

// TODO descriptions

contract CasperFFT
{
    /** List of events the contract logs
        Withdrawal address used always in _from and _to as it's unique TODO what does this mean?
        and validator index is removed after some events TODO which events **/
    // TODO description
    event Deposit(
        address indexed _from,
        int128 indexed _validator_index,
        address _validation_address,
        int128 _start_dyn,
        int128 _amount // wei
    );
    
    // TODO description
    event Vote(
        address indexed _from,
        int128 indexed _validator_index,
        bytes32 indexed _target_hash,
        int128 _start_dyn,
        int128 _source_epoch
    );
    
    // TODO description
    event Logout(
        address indexed _from,
        int128 indexed _validator_index,
        int128 _end_dyn
    );
    
    // TODO description
    event Withdraw(
        address indexed _to,
        int128 indexed _validator_index,
        int128 _amount // wei
    );
    
    // TODO description
    event Slash(
        address indexed _from,
        address indexed _offender,
        int128 indexed _offender_index,
        int128 _bounty, // wei
        int128 _destroyed // wei
    );
    
    // TODO description
    event Epoch(
        int128 indexed _number,
        bytes32 indexed _checkpoint_hash,
        bool _is_justified,
        bool _is_finalized
    );

    
    // TODO description
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
    
    // Historical checkpoint hashes TODO what does this mean?
    mapping(int128 => bytes32) public checkpoint_hashes;
    
    // Number of validators
    int128 public next_validator_index;
    
    // Validator's withdrawal address => validator's index number
    mapping(int128 => address) public validator_indexes;
    
    /* Current dynasty. Measures the number of finalized checkpoints 
       in the chain from root to the parent of current block */
    int128 public dynasty;
    
    // Dynasty => change to total deposits(wei/m) for the dynasty TODO what does this mean?
    mapping(int128 => fixed256x10) public dynasty_wei_delta; // wei/m
    
    // Dynasty => start epoch for the dynasty
    mapping(int128 => int128) public dynasty_start_epoch;

    // Epoch => Dynasty of epoch
    mapping(int128 => int128) public dynasty_in_epoch;

    // TODO description
    // Information about votes for an epoch.
    struct Votes
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
    // Epoch => Votes
    mapping(int128 => Votes) public votes;

    // If the current expected hash is justified
    bool public main_hash_justified;

    // TODO description
    // Value used to calculate the per-epoch fee that validators should be charged
    mapping(int128 => fixed256x10) public deposit_scale_factor; // unit: m

    // TODO description
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
    
    // TODO description    
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