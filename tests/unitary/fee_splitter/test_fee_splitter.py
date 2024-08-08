import boa

def test_update_controllers_expected(fee_splitter, mock_factory):
    factory = mock_factory
    controllers = []
    N_CONTROLLERS = 3

    def controllers_len():
        """helper to get length of controllers in fee_splitter"""
        return fee_splitter.eval('len(self.controllers)')

    def assert_controllers_match():
        """helper to assert controllers in fee_splitter and factory match"""
        for i in range(controllers_len()):
            assert fee_splitter.controllers(i) == controllers[
                i] == factory.controllers(i)
            assert fee_splitter.allowed_controllers(controllers[i])

    def assert_controllers_length(expected):
        """helper to assert controllers length in fee_splitter"""
        assert controllers_len() == expected == len(controllers)

    # at the start, there should be no controllers
    assert_controllers_length(0)
    assert_controllers_match()

    # we add N_CONTROLLERS controllers to the factory
    for i in range(N_CONTROLLERS):
        controllers.append(c := boa.env.generate_address())
        factory.add_controller(c)

    # we update the controllers in the fee_splitter
    fee_splitter.update_controllers()

    # we make sure that fee_splitter and factory controllers match
    assert_controllers_length(N_CONTROLLERS)
    assert_controllers_match()

    # we add some more controllers to the factory
    for i in range(N_CONTROLLERS):
        controllers.append(c := boa.env.generate_address())
        factory.add_controller(c)

    # we update the controllers in the fee_splitter
    fee_splitter.update_controllers()

    # we make sure that fee_splitter and factory controllers match
    assert_controllers_length(2 * N_CONTROLLERS)
    assert_controllers_match()


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

def test_set_receivers_only_owner(fee_splitter):
    with boa.reverts("auth: only owner"):
        fee_splitter.set_receivers([])

def test_set_owner_expected(fee_splitter, owner):
    new_owner = boa.env.generate_address()

    assert fee_splitter.owner() != new_owner
    with boa.env.prank(owner):
        fee_splitter.set_owner(new_owner)

    assert fee_splitter.owner() == new_owner


def test_set_owner_unauthorized(fee_splitter, owner):
    with boa.reverts("auth: only owner"):
        fee_splitter.set_owner(boa.env.generate_address())


def test_set_owner_zero_address(fee_splitter, owner):
    zero = boa.eval('empty(address)')

    with boa.reverts("zeroaddr: new_owner"):
        with boa.env.prank(owner):
            fee_splitter.set_owner(zero)

def test_n_receivers_expected(fee_splitter_deployer):
    crvusd = boa.env.generate_address()
    factory = boa.env.generate_address()
    owner = boa.env.generate_address()

    for i in range(1, 101):
        receivers = generate_receivers(i)
        fee_splitter = fee_splitter_deployer(crvusd, factory, receivers, owner)
        assert fee_splitter.n_receivers() == i

    for i in range(1, 101):
        receivers = generate_receivers(i)
        with boa.env.prank(owner):
            fee_splitter = fee_splitter_deployer(crvusd, factory, receivers, owner)
        assert fee_splitter.n_receivers() == i
