import boa




def test_claim_controller_fees_expected(fee_splitter_with_controllers, target):
    splitter, _ = fee_splitter_with_controllers

    crvusd_balance = 10 ** 23
    target.eval(f'self.balanceOf[{splitter.address}] = {crvusd_balance}')

    splitter.claim_controller_fees()

    for i in range(splitter.n_receivers()):
        addy, weight = splitter.receivers(i)
        amount = crvusd_balance * weight // 10_000
        print(f"weight: {weight}, amount: {amount}")
        assert target.balanceOf(addy) == amount

    assert target.balanceOf(splitter) == 0


def test_claim_controller_fees_all_possibilities(
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


def test_claim_controller_fees_random_addy(fee_splitter_with_controllers):
    splitter, mock_controllers = fee_splitter_with_controllers

    with boa.reverts("controller: not in factory"):
        splitter.claim_controller_fees([boa.env.generate_address()])
