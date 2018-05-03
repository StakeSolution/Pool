/*
    First draft of staking pool contract.
    Used for exploring the possibilities.
    The overall process has many flaws, so do not use this in practise.
    
    Process:
    - New Pool contract is deployed. Deployer becomes manager of pool.
    - Users can join as depositors.
    - When exactly the optimal staking size in funds has been reached,
      the manager can call `begin_staking()`, escrowing the funds at Casper.
    - The manager is now responsible for voting at Casper on behalf on this contract.
      It's identity is verified through the signature validation function present in this contract.
    - TODO finalizing staking period and returning funds
    
    Flaws:
    - Trust in manager required in terms of voting. Can easily destroy funds.
    - Getting the final funds might be hard. People want their funds in a single contract.
      Splitting up in two contracts is annoying, so getting the last bit to reach optimal staking size might be hard.

    Authors
        - Aart Stuurman
*/

pragma solidity ^0.4.23;

import { CasperFFT } from "./casper_fft.sol";

contract Pool
{
    event debugBalance(uint256 balance);
    
    // Optimal amount of wei to stake.
    uint256 constant optimal_staking_size = 1500 ether; // wei
    
    address manager;
    CasperFFT casper;
    
    struct Depositor
    {
        // index in depositorAddresses
        uint256 index;
        // deposit in wei
        uint256 deposit;
    }
    
    // Depositor's address => depositor.
    mapping(address => Depositor) depositors;
    // List of addresses of depositors
    address[] depositor_addresses;
    
    // If pool is currently staking
    bool is_staking = false;
    
    constructor(address casper_address) public
    {
        manager = msg.sender;
        casper = CasperFFT(casper_address);
    }
    
    /*  Join the pool or deposit extra funds if already in the pool.
        Can only deposit if pool is not already staking.
        Can only deposit up till the pool reaches optimal staking size.
        At least some ether must be deposited(i.e. depositing 0 ether will have no effect).
        
        If after depositing the pool overshoots optimal staking size, the deposit is reverted.
    */
    function deposit() public payable
    {
        require(!is_staking);
        
        // check if deposit fits within optimal pool size
        require(address(this).balance <= optimal_staking_size);
        
        // actually handle deposit
        exec_deposit(msg.sender, msg.value);
    }
    
    /*  As `deposit()`, but as much as possible of the deposit is used up till the pool reaches optimal staking size.
    */
    function deposit_partial() public payable
    {
        require(!is_staking);
        
        if (address(this).balance > optimal_staking_size)
        {
            // calculate how much can still be deposited
            uint256 maximum_deposit = optimal_staking_size - (address(this).balance - msg.value);
            require(maximum_deposit > 0);
            
            // actually handle deposit
            exec_deposit( msg.sender, maximum_deposit);
            // refund remainder
            msg.sender.transfer(msg.value - maximum_deposit);
        }
        else
        {
            // actually handle deposit
            exec_deposit(msg.sender, msg.value);
        }
    }
    
    /*  Adds depositor as a participant with the provided wei.
        If depositor was already a participant, it's total deposit is increased.
        
        Does this without respect to the optimal staking size or if currently staking.
    */
    function exec_deposit(address depositor_address, uint256 wei_deposited) private
    {
        Depositor storage depositor = depositors[depositor_address];
        // check if new depositor
        if (depositor.deposit == 0)
        {
            // add depositor to address list
            depositor.index = depositor_addresses.length;
            depositor_addresses.push(depositor_address);
        }
        
        // increase deposit
        depositor.deposit += wei_deposited;
    }
    
    /*  Withdraw all ether deposited.
        Can only withdraw if staking has not yet started or after it has ended.
    */
    /*function withdraw() public
    {
        require(!is_staking);
    }*/
    
    function begin_staking() public
    {
        require(msg.sender == manager);
        require(address(this).balance == optimal_staking_size);
        require(!is_staking);
        
        is_staking = true;
        
        casper.deposit.value(optimal_staking_size)(address(this), address(this)); // TODO first arg validation_address
    }
    
    /*  Casper signature validation fallback function.
        TODO is this even how it works
    */
    function() public // TODO arguments
    {
        // TODO verify signature.
    }
}