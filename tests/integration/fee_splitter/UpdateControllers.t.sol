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

    function test_claimFees() public {
        fs.update_controllers();
        //     for i in range(factory.n_collaterals()):
        //        admin_fees = MockController.at(factory.controllers(i)).admin_fees()
        //        assert admin_fees != 0
        //        total_balance_to_claim += admin_fees

        uint256 totalClaimable = 0;

        for (uint256 i = 0; i < fs.n_controllers(); i++) {
            uint256 adminFees = IController(fs.controllers(i)).admin_fees();
            assertNotEq(adminFees, 0);
            totalClaimable += adminFees;
        }

        fs.dispatch_fees();

        for (uint256 i = 0; i < fs.n_controllers(); i++) {
            address controller = fs.controllers(i);
            assertEq(IController(controller).admin_fees(), 0);
        }

        uint256 totalDispatched = 0;
        for (uint256 i = 0; i < fs.n_receivers(); i++) {
            totalDispatched += crvUSD.balanceOf(fs.receivers(i).addr);
        }

        assertEq(totalDispatched, totalClaimable);
    }
}
