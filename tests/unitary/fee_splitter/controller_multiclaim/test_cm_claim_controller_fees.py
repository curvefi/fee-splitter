import boa
import pytest


def test_expected_behavior_default(multiclaim_with_controllers, crvusd):
    mc, controllers = multiclaim_with_controllers

    for c in controllers:
        assert c.eval("self.collect_counter") == 0

    mc.internal.claim_controller_fees([])

    for c in controllers:
        assert c.eval("self.collect_counter") == 1


def test_expected_behavior_powerset(multiclaim_with_controllers):
    multiclaim, mock_controllers = multiclaim_with_controllers

    # compute powerset of the controllers
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
            multiclaim.internal.claim_controller_fees(subset)

            for c in mock_controllers:
                if c in subset:
                    assert c.eval("self.collect_counter") == 1
                else:
                    assert c.eval("self.collect_counter") == 0



def test_random_addy(multiclaim):
    with boa.reverts("controller: not in factory"):
        multiclaim.internal.claim_controller_fees([boa.env.generate_address()])
