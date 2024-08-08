import boa

# TODO test this proper in stateful testing
def test_expected_behavior(fee_splitter_deployer, crvusd, mock_factory, owner):
    receivers = [(boa.env.generate_address(), 1, False), (boa.env.generate_address(), 1, False), (boa.env.generate_address(), 10_000 - 2, False)]
    fee_splitter = fee_splitter_deployer(crvusd, mock_factory, receivers, owner)
    assert fee_splitter.n_receivers() == 3
