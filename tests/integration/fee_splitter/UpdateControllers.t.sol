// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./FeeSplitterTest.sol";

contract MulticlaimTest is FeeSplitterTest {
    function test_updateWithCurrentControllers() public {
        assertEq(fs.n_controllers(), 0);

        fs.update_controllers();
        for (uint256 i = 0; i < currentControllers.length; i++) {
            assertEq(fs.controllers(i), currentControllers[i]);
        }

        assertEq(fs.n_controllers(), 6);
    }

    function test_claimFeesOneByOne() public {
        fs.update_controllers();

        uint256 totalClaimable = 0;
        uint256 totalDispatched = 0;

        // caching values to reduce call tree verbosity
        uint256 n_controllers = fs.n_controllers();
        uint256 n_receivers = fs.n_receivers();

        for (uint256 i = 0; i < n_controllers; i++) {
            IController controller = IController(fs.controllers(i));
            uint256 adminFees = controller.admin_fees();
            assertNotEq(adminFees, 0, "reported admin fees before claim are zero");
            totalClaimable += adminFees;

            address[] memory claim_target = new address[](1);
            claim_target[0] = address(controller);
            fs.dispatch_fees(claim_target);

            assertEq(controller.admin_fees(), 0, "reported admin fees after claim aren't zero");
            assertApproxEqAbs(crvUSD.balanceOf(address(fs)), 0, 1, "there is some dust left in the fee splitter");
        }

        for (uint256 i = 0; i < n_receivers; i++) {
            totalDispatched += crvUSD.balanceOf(fs.receivers(i).addr);
        }

        for (uint256 i = 0; i < n_receivers; i++) {
            uint256 receiverAmount = totalDispatched * fs.receivers(i).percentage / 10_000;
            assertApproxEqRel(
                crvUSD.balanceOf(fs.receivers(i).addr), receiverAmount, 2, "amounts not dispatched correctly"
            );
        }
        // we allow an off by 1 per controller
        assertApproxEqAbs(
            totalDispatched, totalClaimable, n_controllers, "total claimed doesn't correspond with actual balance"
        );
    }
}
