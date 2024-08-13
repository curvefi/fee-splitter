import boa
from hypothesis import note, settings
from hypothesis.stateful import rule, invariant

from tests.hypothesis.fee_splitter.stateful_base import FeeSplitterStatefulBase
from tests.hypothesis.strategies import fee_splitters, controllers


class ControllerUpdate(FeeSplitterStatefulBase):
    @rule(controller=controllers())
    def add_controller_rule(self, controller):
        self.add_controller_to_factory(controller)

    @rule()
    def update_controllers_rule(self):
        self.update_controllers()


    @invariant()
    def controllers_match(self):
        assert self.factory.n_collaterals() == len(self.factory_controllers)

        fs_n_controllers = self.fs.eval('len(multiclaim.controllers)')
        if self.is_updated:
            assert self.factory.n_collaterals() == fs_n_controllers
            assert self.factory.n_collaterals() == len(self.fs_controllers)
            assert self.fs_controllers == self.factory_controllers
        else:
            assert self.factory.n_collaterals() >= fs_n_controllers

        for i, c in enumerate(self.fs_controllers):
            assert self.fs.controllers(i) == c.address
            assert self.fs.allowed_controllers(c)

        for i, c in enumerate(self.factory_controllers):
            assert self.factory.controllers(i) == c.address

        with boa.env.anchor():
            self.fs.update_controllers()
            for i in range(self.factory.n_collaterals()):
                assert self.fs.controllers(i) == self.factory.controllers(i)


TestControllerUpdate = ControllerUpdate.TestCase
