import boa
from tests.mocks import MockController


def test_controllers_from_factory(factory, fee_splitter):
    assert fee_splitter.eval("len(multiclaim.controllers)") == 0
    controllers = []
    for i in range(factory.n_collaterals()):
        controllers.append(factory.controllers(i))
    fee_splitter.update_controllers()
    assert fee_splitter.eval("len(multiclaim.controllers)") > 0
    for i, c in enumerate(controllers):
        assert fee_splitter.controllers(i) == c


def test_claim_fees(fee_splitter_with_controllers, factory, crvusd):
    splitter = fee_splitter_with_controllers

    total_balance_to_claim = 0
    for i in range(factory.n_collaterals()):
        admin_fees = MockController.at(factory.controllers(i)).admin_fees()
        assert admin_fees != 0
        total_balance_to_claim += admin_fees

    splitter.dispatch_fees()

    for i in range(factory.n_collaterals()):
        assert MockController.at(factory.controllers(i)).admin_fees() == 0

    total_balance_dispatched = sum(
        [crvusd.balanceOf(factory.controllers(i)) for i in
         range(factory.n_collaterals())])
    assert total_balance_dispatched == total_balance_to_claim
