// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import "./VotemarketTest.sol";

contract StakeDaoLogicTest is VotemarketTest {
    function _bribe(address gauge, uint256 amount, uint256 maxAmountPerVote) public {
        bytes memory bribeData = abi.encode(uint256(maxAmountPerVote));
        deal(address(crvUSD), address(stakeDaoLogic), amount);
        crvUSD.approve(address(stakeDaoLogic), amount);
        vm.prank(address(im));
        stakeDaoLogic.bribe(gauge, amount, bribeData);
    }

    function testFuzz_firstCall(uint256 bribeAmount, uint256 maxAmountPerVote) public {
        vm.assume(bribeAmount > 0 && bribeAmount < 1e22);
        vm.assume(maxAmountPerVote > 0);
        address gauge = gauges[bribeAmount % gauges.length];

        vm.prank(bribeManager);
        im.set_gauge_cap(gauge, bribeAmount);
        
        _bribe(gauge, bribeAmount, maxAmountPerVote);
    }

    function testFuzz_secondCall(uint256 firstBribeAmount, uint256 firstMaxAmountPerVote, uint256 secondBribeAmount, uint256 secondMaxAmountPerVote) public {
        vm.assume(firstBribeAmount > 0 && firstBribeAmount < 1e22);
        vm.assume(firstMaxAmountPerVote > 0);
        vm.assume(secondBribeAmount > 0 && secondBribeAmount < 1e22);
        vm.assume(secondMaxAmountPerVote > 0);

        address gauge = gauges[firstBribeAmount % gauges.length];

        uint256 maxBribeAmount = firstBribeAmount > secondBribeAmount ? firstBribeAmount : secondBribeAmount;

        vm.prank(bribeManager);
        im.set_gauge_cap(gauge, maxBribeAmount);

        vm.expectCall(
            address(_vm),
            // Partial match
            abi.encodeWithSelector(_vm.createBounty.selector, (gauge)),
            1
        );
        uint256 bribeId = _vm.nextID();
        vm.expectCall(
            address(_vm),
            // Partial match
            abi.encodeWithSelector(_vm.increaseBountyDuration.selector, (bribeId)),
            1
        );
        _bribe(gauge, firstBribeAmount, firstMaxAmountPerVote);

        _bribe(gauge, secondBribeAmount, secondMaxAmountPerVote);
    }

    function testFuzz_multipleCalls(uint64 numberOfCalls) external {
        // We limit to prevent uint8 overflow for periods
        vm.assume(numberOfCalls > 1 && numberOfCalls < 2**7);
        uint256 bribeAmount = 1000;
        uint256 maxAmountPerVote = 100;

        address gauge = gauges[numberOfCalls % gauges.length];


        vm.expectCall(
            address(_vm),
            // Partial match
            abi.encodeWithSelector(_vm.createBounty.selector, (gauge)),
            1
        );
        uint256 bribeId = _vm.nextID();
        vm.expectCall(
            address(_vm),
            // Partial match
            abi.encodeWithSelector(_vm.increaseBountyDuration.selector, (bribeId)),
            numberOfCalls - 1
        );

        vm.prank(bribeManager);
        im.set_gauge_cap(gauge, bribeAmount);

        for (uint256 i = 0; i < numberOfCalls; i++) {
            _bribe(gauge, bribeAmount, maxAmountPerVote);
        }
    }
}