import boa


def test_expected_behavior(multiclaim_deployer):
    mc = multiclaim_deployer(factory := boa.env.generate_address())
    assert mc._immutables.factory == factory
