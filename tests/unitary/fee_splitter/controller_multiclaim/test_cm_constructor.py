import boa


def test_expected_behavior(multiclaim_deployer):
    mc = multiclaim_deployer(factory := boa.env.generate_address())
    assert mc._immutables.factory == factory


def test_zero_address(multiclaim_deployer):
    zero = boa.eval("empty(address)")

    with boa.reverts("zeroaddr: factory"):
        multiclaim_deployer(zero)