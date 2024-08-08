import boa
import pytest

def test_expected_behavior(fee_splitter_deployer, receivers, mock_dynamic_weight_deployer):
    crvusd = boa.env.generate_address()
    factory = boa.env.generate_address()
    owner = boa.env.generate_address()

    splitter = fee_splitter_deployer(crvusd, factory, receivers, owner)


    for j, (expected_addy, expected_weight, expected_dynamic) in enumerate(receivers):
        address, weight, dynamic = splitter.receivers(j)
        assert address == expected_addy
        assert weight == expected_weight
        assert dynamic == expected_dynamic
    assert splitter._immutables.crvusd == crvusd
    assert splitter._immutables.factory == factory
    assert splitter.owner() == owner




