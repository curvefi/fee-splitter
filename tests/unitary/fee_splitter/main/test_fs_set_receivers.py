import boa

def test_expected_behavior(fee_splitter, receivers, owner):
    receivers = [(boa.env.generate_address(), 2_500, False)] * 4
    with boa.env.prank(owner):
        fee_splitter.set_receivers(receivers)

    for i in range(fee_splitter.n_receivers()):
        assert fee_splitter.receivers(i) == receivers[i]

def test_only_owner(fee_splitter):
    with boa.reverts("ownable: caller is not the owner"):
        fee_splitter.set_receivers([])

