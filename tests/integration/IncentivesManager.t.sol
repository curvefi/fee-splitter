// SPDX-License-Identifier: unlicensed
pragma solidity 0.8.19;

import "./IntegrationTest.sol";

contract IncentivesManagerTest is IntegrationTest {
    mapping(address => uint256) public gaugeToId;
    mapping(address => uint256) public gaugeToPeriods;
    mapping(address => uint256) public gaugeToRewards;

    function _bribe(address gauge, uint256 amount, uint256 maxAmountPerVote) public returns (uint256) {
        bytes memory bribeData = abi.encode(uint256(maxAmountPerVote));
        deal(address(crvUSD), address(im), amount);
        vm.prank(address(bribePoster));
        uint256 expectedId = gaugeToId[gauge];
        uint256 id = im.post_bribe(gauge, amount, bribeData);
        if (expectedId != 0) {
            assertEq(expectedId, id);
        } else {
            gaugeToId[gauge] = id;
        }

        gaugeToPeriods[gauge] += 2;
        gaugeToRewards[gauge] += amount;

        return id;
    }

    function testFuzz_E2E(uint256 amount, uint256 maxAmountPerVote) public {
        vm.assume(amount > 0 && amount < 1e22);
        vm.assume(maxAmountPerVote > 0);
        address gauge = gauges[amount % gauges.length];

        vm.prank(bribeManager);
        im.set_gauge_cap(gauge, amount);
        uint256 id = _bribe(gauge, amount, maxAmountPerVote);

        IVotemarket.Bounty memory b = _vm.getBounty(id);

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