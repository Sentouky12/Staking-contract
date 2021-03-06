// SPDX-License-Identifier: MIT


pragma solidity 0.8.0;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "openzeppelin-solidity/contracts/utils/math/SafeMath.sol";

contract Staking {
    // boolean to prevent reentrancy
    bool internal locked;

    
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

  
    address public owner;

    uint256 public initialTimestamp;
    bool public timestampSet;
    uint256 public timePeriod;


    // Token amount variables
    mapping(address => uint256) public alreadyWithdrawn;
    mapping(address => uint256) public balances;
    uint256 public contractBalance;

    // ERC20 contract address
    IERC20 public erc20Contract;

  
    event TokensStaked(address from, uint256 amount);
    event TokensUnstaked(address to, uint256 amount);

  
    constructor(IERC20 ERC20Address) {
       
        owner = msg.sender;
       
        timestampSet = false;
        
        require(address(ERC20Address) != address(0));
        erc20Contract = ERC20Address;
      
        locked = false;
    }


    modifier ReEntrancyGuard() {
        require(!locked, "No re-entrancy");
        locked = true;
        _;
        locked = false;
    }

 
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

   
    modifier timestampNotSet() {
        require(timestampSet == false, "The time stamp has already been set.");
        _;
    }

  
    modifier IstimestampSet() {
        require(timestampSet == true);
        _;
    }

 
    function setTimestamp(uint256 timePeriodInSeconds) public onlyOwner timestampNotSet  {
        timestampSet = true;
        initialTimestamp = block.timestamp;
        timePeriod = initialTimestamp.add(timePeriodInSeconds);
    }



  
    function stakeTokens(IERC20 token, uint256 amount) public IstimestampSet ReEntrancyGuard {
        require(token == erc20Contract);
        require(amount <= token.balanceOf(msg.sender));
        token.safeTransferFrom(msg.sender, address(this), amount);
        balances[msg.sender] = balances[msg.sender].add(amount);
        emit TokensStaked(msg.sender, amount);
    }

   
    function unstakeTokens(IERC20 token, uint256 amount) public IstimestampSet ReEntrancyGuard {
        require(balances[msg.sender] >= amount, "Insufficient token balance");
        require(token == erc20Contract);
        if (block.timestamp >= timePeriod) {
            alreadyWithdrawn[msg.sender] = alreadyWithdrawn[msg.sender].add(amount);
            balances[msg.sender] = balances[msg.sender].sub(amount);
            token.safeTransfer(msg.sender, amount);
            emit TokensUnstaked(msg.sender, amount);
        } else {
            revert();
        }
    }

 
    function TransferTokensLockedByMistake(IERC20 token, uint256 amount) public onlyOwner ReEntrancyGuard {
        require(address(token) != address(0), "Token address cannot be zero");
        require(token != erc20Contract);
        token.safeTransfer(owner, amount);
    }
}
