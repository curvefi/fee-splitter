import boa

def test_controllers_from_factory(factory, fee_splitter):
    assert fee_splitter.eval("len(self.controllers)") == 0
    controllers = []
    for i in range(factory.n_collaterals()):
        controllers.append(factory.controllers(i))
    fee_splitter.update_controllers()
    for i, c in enumerate(controllers):
        assert fee_splitter.controllers(i) == c


def test_claim_fees(fee_splitter_with_controllers, factory):
    splitter = fee_splitter_with_controllers
    controller = boa.load_partial("contracts/testing/ControllerMock.vy")
    for i in range(factory.n_collaterals()):
        assert controller.at(factory.controllers(i)).admin_fees() != 0
    splitter.claim_controller_fees()
    for i in range(factory.n_collaterals()):
        assert controller.at(factory.controllers(i)).admin_fees() == 0