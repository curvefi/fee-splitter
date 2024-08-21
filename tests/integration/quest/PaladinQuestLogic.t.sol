// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import "./QuestTest.sol";

contract PaladinQuestLogicTest is QuestTest {
    function _bribe(address gauge, uint256 amount, uint256 maxAmountPerVote) public {
        bytes memory bribeData = abi.encode(uint256(maxAmountPerVote));
        deal(address(crvUSD), address(questLogic), amount);
        crvUSD.approve(address(questLogic), amount);
        vm.prank(address(im));
        questLogic.bribe(gauge, amount, bribeData);
    }

    //    function testFuzz_bribe(uint64 numberOfCalls) external {
    //        // We limit to prevent uint8 overflow for periods
    //        vm.assume(numberOfCalls > 1 && numberOfCalls < 2**7);
    //        uint256 bribeAmount = 1000;
    //        uint256 maxAmountPerVote = 100;
    //
    //        address gauge = gauges[numberOfCalls % gauges.length];
    //
    //        vm.expectCall(
    //            address(quest),
    //            // Partial match
    //            abi.encodeWithSelector(quest.createRangedQuest.selector, (gauge)),
    //            numberOfCalls
    //        );
    //
    //        vm.prank(bribeManager);
    //        im.set_gauge_cap(gauge, bribeAmount);
    //
    //        for (uint256 i = 0; i < numberOfCalls; i++) {
    //            _bribe(gauge, bribeAmount, maxAmountPerVote);
    //        }
    //    }
}
