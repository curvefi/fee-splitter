import boa
from hypothesis import note
from hypothesis.stateful import RuleBasedStateMachine, initialize, invariant

from tests.hypothesis.strategies import controllers, crvusd, fee_splitters
from tests.hypothesis.utils import (
    dynamic_weight_deployer,
    factory_deployer,
    generate_random_weight,
)


class FeeSplitterStatefulBase(RuleBasedStateMachine):
    @initialize(fs=fee_splitters(), controller=controllers, _crvusd=crvusd)
    def setup(self, fs, controller, _crvusd):
        note("[SETUP]")

        # setup for controllers test
        self.fs = fs
        self.factory = factory_deployer.at(
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

        for addr, weight, dynamic in self.receivers:
            if dynamic:
                new_weight = generate_random_weight(weight)
                note(
                    "addr: {} weight: {} -> {}".format(
                        addr, weight, new_weight
                    )
                )
                dynamic_weight_deployer.at(addr).set_weight(new_weight)

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
        self.receivers = receivers
        receivers_arg = [(r[0], r[1]) for r in receivers]
        self.fs.set_receivers(receivers_arg, sender=self.fs.owner())
        self.claimed_since_receivers_change = False

    def update_controllers(self):
        note("[UPDATE_CONTROLLERS]")
        self.fs.update_controllers()
        self.is_updated = True
        self.fs_controllers = self.factory_controllers[:]

    @invariant()
    def accrue_fees(self):
        # simulate fee accrual which should happen every second
        # by minting 10**19 after every rule to all controllers.
        for c in self.fs_controllers:
            boa.deal(self.crvusd, c, 10**19)
