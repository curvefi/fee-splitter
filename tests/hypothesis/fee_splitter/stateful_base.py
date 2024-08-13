import random

import boa
from hypothesis import note
from hypothesis.stateful import RuleBasedStateMachine, initialize

from tests.hypothesis.strategies import controllers, crvusd, fee_splitters
from tests.mocks import MockControllerFactory, MockDynamicWeight


class FeeSplitterStatefulBase(RuleBasedStateMachine):
    @initialize(fs=fee_splitters(), controller=controllers(), _crvusd=crvusd)
    def setup(self, fs, controller, _crvusd):
        note("[SETUP]")

        # setup for controllers test
        self.fs = fs
        self.factory = MockControllerFactory.at(
            fs.eval("multiclaim.factory.address")
        )

        self.fs_controllers = []
        self.factory_controllers = []

        # set up for ...
        self.crvusd = _crvusd
        self.is_updated = True
        self.receivers = []

    def add_controller_to_factory(self, controller):
        note("[ADD_CONTROLLER]")

        # this updates the receiver in the mock without having
        # to expose something that is not part of the abi
        controller.eval(f"self.mock_receiver = {self.fs.address}")

        self.factory_controllers.append(controller)
        self.factory.add_controller(controller)

        self.is_updated = False

    def randomize_dynamic_weights(self):
        note("[RANDOMIZE WEIGHTS]")

        def generate_random_weight(center, min_val=1, max_val=10000):
            # Ensure center is within the valid range
            center = max(min_val, min(center, max_val))

            while True:
                # Generate a random value using a normal distribution
                value = random.gauss(center, (max_val - min_val) / 6)

                # Round to the nearest integer
                value = round(value)

                # Check if the value is within the desired range
                if min_val < value <= max_val:
                    return value

        for addr, weight, dynamic in self.receivers:
            if dynamic:
                new_weight = generate_random_weight(weight)
                MockDynamicWeight.at(addr).set_weight(new_weight)

    def dispatch_fees(self):
        note("[DISPATCH]")

        fees_before_claim = []
        for addr, _, _ in self.receivers:
            fees_before_claim.append(self.crvusd.balanceOf(addr))

        note(f"{fees_before_claim=}")

        fs_before_claim = self.crvusd.balanceOf(self.fs)
        note(f"{fs_before_claim=}")
        self.fs.dispatch_fees()
        note(f"{self.fs.address=}")
        fs_after_claim = self.crvusd.balanceOf(self.fs)
        note(f"{fs_after_claim=}")
        #
        # fees_after_claim = []
        # for i, (addr, _, _) in enumerate(self.receivers):
        #     fees = self.crvusd.balanceOf(c)
        #     fees_after_claim.append(fees)
        #     last_synced_index = self.fs.eval("len(multiclaim.controllers)")
        #     assert i >= last_synced_index or fees == 0
        #
        # note(f"{fees_after_claim=}")
        #
        # delta = [abs(after - before) for after,
        # before in zip(fees_after_claim, fees_before_claim)]
        # note(f"{delta=}")
        # note(f"{sum(delta)=}")
        # received_amount = sum(delta)
        # assert fs_after_claim - fs_after_claim == received_amount

    def set_receivers(self, receivers):
        note("[SET_RECEIVERS]")
        with boa.env.prank(self.fs.owner()):
            self.fs.set_receivers(receivers)
        self.receivers = receivers

    def update_controllers(self):
        note("[UPDATE_CONTROLLERS]")
        self.fs.update_controllers()
        self.is_updated = True
        self.fs_controllers = self.factory_controllers[:]
