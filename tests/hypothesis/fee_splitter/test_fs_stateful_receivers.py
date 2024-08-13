from hypothesis import settings
from hypothesis.stateful import precondition, rule

from tests.hypothesis.fee_splitter.stateful_base import FeeSplitterStatefulBase
from tests.hypothesis.strategies import receivers

settings.load_profile("debug")


class FeeSplitterStateful(FeeSplitterStatefulBase):
    claimed_since_receivers_change = False

    @rule()
    def dispatch_fees_rule(self):
        self.dispatch_fees()

        self.claimed_since_receivers_change = True

    @rule()
    def full_claim_flow(self):
        self.update_controllers()
        self.randomize_dynamic_weights()
        self.dispatch_fees()

        self.claimed_since_receivers_change = True

    @precondition(lambda self: self.claimed_since_receivers_change)
    @rule(receivers=receivers())
    def set_receivers_rule(self, receivers):
        self.set_receivers(receivers)

        self.claimed_since_receivers_change = False

    @rule()
    def randomize_dynamic_weights_rule(self):
        self.randomize_dynamic_weights()


TestFeeSplitterStateful = FeeSplitterStateful.TestCase
