// SPDX-License-Identifier: unlicensed
pragma solidity 0.8.19;

import "./QuestTest.sol";

contract IncentivesManagerTest is QuestTest {
    mapping(address => uint256) public gaugeToId;
    mapping(address => uint256) public gaugeToPeriods;
    mapping(address => uint256) public gaugeToRewards;

    function _bribe(address gauge, uint256 amount, uint256 maxAmountPerVote) public {
        bytes memory bribeData = abi.encode(uint256(maxAmountPerVote));
        IncentivesPayload[] memory payload = new IncentivesPayload[](1);
        payload[0].gauge = gauge;
        payload[0].amount = amount;
        // no bribe needed for quest

        deal(address(crvUSD), address(im), amount);
        vm.startPrank(address(bribeProposer));
        im.update_incentives_batch(payload);
        im.confirm_batch();
        vm.stopPrank();
        im.post_incentives();

        gaugeToPeriods[gauge] += 2;
        gaugeToRewards[gauge] += amount;
    }

    function testFuzz_E2E(uint256 amount, uint256 maxAmountPerVote) public {
        vm.assume(amount > 0 && amount < 1e22);
        vm.assume(maxAmountPerVote > 0);
        address gauge = gauges[amount % gauges.length];

        vm.prank(bribeManager);
        im.set_gauge_cap(gauge, amount);
        uint256 id = _vm.nextID();
        _bribe(gauge, amount, maxAmountPerVote);

        IQuest.
         memory b = _vm.getBounty(id);

        assertEq(b.gauge, gauge);
        assertEq(b.manager, address(stakeDaoLogic));
        assertEq(b.rewardToken, address(crvUSD));
        assertEq(b.numberOfPeriods, gaugeToPeriods[gauge]);
        assertEq(b.maxRewardPerVote, maxAmountPerVote);
        assertEq(b.totalRewardAmount, gaugeToRewards[gauge]);
        assertEq(b.blacklist.length, 0);

        // vm.warp(block.timestamp + gaugeToPeriods[gauge] * 1 weeks + 1 days);
        vm.prank(0xF930EBBd05eF8b25B1797b9b2109DDC9B0d43063);
        _vm.kill();
        address closedBountyReceiver = makeAddr("closedBountyReceiver");
        assertNotEq(crvUSD.balanceOf(address(_vm)), 0);
        vm.prank(tokenRescuer);
        stakeDaoLogic.close_bounty(id, closedBountyReceiver);

        assertEq(crvUSD.balanceOf(closedBountyReceiver), gaugeToRewards[gauge]);
        assertEq(crvUSD.balanceOf(address(_vm)), 0);
    }
}