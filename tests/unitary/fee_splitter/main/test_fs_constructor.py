import boa


def test_expected_behavior(
    fee_splitter_deployer, receivers, mock_dynamic_weight_deployer
):
    crvusd = boa.env.generate_address()
    factory = boa.env.generate_address()
    owner = boa.env.generate_address()

    splitter = fee_splitter_deployer(crvusd, factory, receivers, owner)

    for j, (expected_addy, expected_weight, expected_dynamic) in enumerate(
        receivers
    ):
        address, weight, dynamic = splitter.receivers(j)
        assert address == expected_addy
        assert weight == expected_weight
        assert dynamic == expected_dynamic
    assert splitter._immutables.crvusd == crvusd
    assert splitter.eval("multiclaim.factory.address") == factory
    assert splitter.owner() == owner


def test_zero_address(fee_splitter_deployer):
    crvusd = boa.env.generate_address()
    factory = boa.env.generate_address()
    owner = boa.env.generate_address()

    zero = boa.eval("empty(address)")

    with boa.reverts("zeroaddr: crvusd"):
        fee_splitter_deployer(
            zero, factory, [(boa.env.generate_address(), 1, False)], owner
        )
    # sanity check since modules are pretty recent
    with boa.reverts("zeroaddr: factory"):
        fee_splitter_deployer(
            crvusd, zero, [(boa.env.generate_address(), 1, False)], owner
        )
    with boa.reverts("zeroaddr: owner"):
        fee_splitter_deployer(
            crvusd, factory, [(boa.env.generate_address(), 1, False)], zero
        )
