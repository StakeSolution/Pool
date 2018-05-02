/*
    First draft of staking pool contract.

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
        
        - use_partial
            false: if after deposit pool overshoots optimal staking size, the deposit is aborted.
            true:  as much as possible of the deposit is used up till the pool reaches optimal staking size.
    */
    function deposit(bool use_partial) public payable
    {
        require(!is_staking);
        
        if (address(this).balance > optimal_staking_size)
        {
            require(use_partial);
            // calculate how much can still be deposited
            uint256 leftover_space = optimal_staking_size - (address(this).balance - msg.value);
            require(leftover_space > 0);
            
            // actually handle deposit
            exec_deposit( msg.sender, leftover_space);
            // refund remainder
            msg.sender.transfer(msg.value - leftover_space);
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
}