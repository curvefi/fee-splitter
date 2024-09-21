import boa


def test_expected_behavior(fee_splitter_deployer, crvusd, mock_factory, owner):
    receivers = [
        (boa.env.generate_address(), 1),
        (boa.env.generate_address(), 1),
        (boa.env.generate_address(), 10_000 - 2),
    ]
    fee_splitter = fee_splitter_deployer(
        crvusd, mock_factory, receivers, owner
    )
    assert fee_splitter.n_receivers() == 3
