import boa
import pytest


@pytest.mark.xfail
def test_expected_behavior_default(multiclaim_with_controllers, crvusd):
    mc, controllers = multiclaim_with_controllers

    for c in controllers:
        crvusd.mint_for_testing(c, 10**23)

    mc.internal.claim_controller_fees([])

    assert crvusd.balanceOf(mc) == len(controllers) * 10**23


@pytest.mark.xfail
def test_expected_behavior_powerset(
        fee_splitter_with_controllers):
    splitter, mock_controllers = fee_splitter_with_controllers

    # compute powerset of list_a
    powerset = []
    for i in range(1 << len(mock_controllers)):
        subset = []
        for j in range(len(mock_controllers)):
            if i & (1 << j):
                subset.append(mock_controllers[j])
        powerset.append(subset)

    # remove the empty subset since it be the same as the previous test
    powerset = powerset[1:]

    # test all claiming possibilities
    for subset in powerset:
        # we reset after every claim to test a new possibility
        with boa.env.anchor():
            splitter.claim_controller_fees(subset)



@pytest.mark.xfail
def test_random_addy(multiclaim):
    # TODO fix boa here
    with boa.reverts("controller: not in factory"):
        multiclaim.internal.claim_controller_fees([boa.env.generate_address()])
