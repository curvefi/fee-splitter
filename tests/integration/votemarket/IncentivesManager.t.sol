// SPDX-License-Identifier: unlicensed
pragma solidity 0.8.19;

import "./VotemarketTest.sol";

contract IncentivesManagerTest is VotemarketTest {
    mapping(address => uint256) public gaugeToId;
    mapping(address => uint256) public gaugeToPeriods;
    mapping(address => uint256) public gaugeToRewards;

    function _bribe(address gauge, uint256 amount, uint256 maxAmountPerVote) public {
        bytes memory bribeData = abi.encode(uint256(maxAmountPerVote));
        IncentivesPayload[] memory payload = new IncentivesPayload[](1);
        payload[0].gauge = gauge;
        payload[0].amount = amount;
        payload[0].data = bribeData;
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
        uint256 id = quest.nextID();
        _bribe(gauge, amount, maxAmountPerVote);

        IQuest.Quest memory q = quest.quests(id);

        // assertEq() TODO check

        vm.prank(0xF930EBBd05eF8b25B1797b9b2109DDC9B0d43063);
        _vm.killBoard();
        address closedBountyReceiver = makeAddr("closedBountyReceiver");
        assertNotEq(crvUSD.balanceOf(address(_vm)), 0);
        vm.prank(tokenRescuer);
        stakeDaoLogic.close_bounty(id, closedBountyReceiver);

        assertEq(crvUSD.balanceOf(closedBountyReceiver), gaugeToRewards[gauge]);
        assertEq(crvUSD.balanceOf(address(_vm)), 0);
    }
}
