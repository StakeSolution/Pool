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
    
    bool isStaking = false;
    
    constructor(address casper_address) public
    {
        manager = msg.sender;
        casper = CasperFFT(casper_address);
    }
    
    /*  Join the pool or deposit extra funds if already in the pool.
        Can only deposit if pool is not already staking.
        Can only deposit up till the pool reaches optimal staking size.
        At least some ether must be deposited(i.e. depositing 0 ether will have no effect).
        
        - usePartial
            false: if after deposit pool overshoots optimal staking size, the deposit is aborted.
            true:  as much as possible of the deposit is used up till the pool reaches optimal staking size.
    */
    function deposit(bool usePartial) public payable
    {
        if (address(this).balance > optimal_staking_size)
        {
            require(usePartial);
            // calculate how much can still be deposited
            uint256 leftoverSpace = optimal_staking_size - (address(this).balance - msg.value);
            require(leftoverSpace > 0);
            
            // actually handle deposit
            finalDeposit(leftoverSpace, msg.sender);
            // refund remainder
            msg.sender.transfer(msg.value - leftoverSpace);
        }
        else
        {
            // actually handle deposit
            finalDeposit(msg.value, msg.sender);
        }
    }
    
    /*  Adds depositor as a participant with the provided wei.
        If depositor was already a participant, it's total deposit is increased.
        
        Does this without respect to the optimal staking size.
    */
    function finalDeposit(uint256 weiDeposited, address depositor) private
    {
        
    }
    
    /*  Withdraw all ether deposited.
        Can only withdraw if staking has not yet started or after it has ended.
    */
    /*function withdraw() public
    {
        
    }*/
    
    function begin_staking() public
    {
        require(msg.sender == manager);
        require(address(this).balance == optimal_staking_size);
        
        
        casper.deposit.value(optimal_staking_size)(address(this), address(this)); // TODO first arg validation_address
    }
}