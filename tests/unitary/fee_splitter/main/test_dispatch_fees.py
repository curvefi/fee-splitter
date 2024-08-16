import boa

from tests.mocks import MockDynamicWeight


def fixed(percentage):
    return boa.env.generate_address(), percentage


def dynamic(percentage):
    return MockDynamicWeight().address, percentage


# @pytest.mark.gas_profile
def test_single_fixed_receiver(
    fee_splitter_with_controllers, crvusd, mock_factory, owner
):
    fs, controllers = fee_splitter_with_controllers

    single_fixed_receiver = [fixed(10_000)]

    with boa.env.prank(owner):
        fs.set_receivers(single_fixed_receiver)

    for c in controllers:
        c.eval(f"self.mock_receiver = {fs.address}")
        crvusd.mint_for_testing(c, 10**20)
    fs.dispatch_fees()

    assert sum(crvusd.balanceOf(c) for c in controllers) == 0
    assert crvusd.balanceOf(fs) == 0
    assert crvusd.balanceOf(single_fixed_receiver[0][0]) == 10**20 * len(
        controllers
    )


def test_single_dynamic_receiver(fee_splitter_with_controllers, crvusd, owner):
    fs, controllers = fee_splitter_with_controllers

    single_fixed_receiver = [dynamic(10_000)]

    with boa.env.prank(owner):
        fs.set_receivers(single_fixed_receiver)

    for c in controllers:
        c.eval(f"self.mock_receiver = {fs.address}")
        crvusd.mint_for_testing(c, 10**20)
    fs.dispatch_fees()

    assert sum(crvusd.balanceOf(c) for c in controllers) == 0
    assert crvusd.balanceOf(fs) == 0
    assert crvusd.balanceOf(single_fixed_receiver[0][0]) == 10**20 * len(
        controllers
    )


def test_dynamic_and_fixed(fee_splitter_with_controllers, crvusd, owner):
    fs, controllers = fee_splitter_with_controllers

    receivers = [dynamic(7_000), fixed(3_000)]

    with boa.env.prank(owner):
        fs.set_receivers(receivers)

    weight = MockDynamicWeight.at(receivers[0][0])

    for c in controllers:
        c.eval(f"self.mock_receiver = {fs.address}")
        crvusd.mint_for_testing(c, 10**20)

    # case 1: weight is less than cap
    weight.set_weight(5_000)

    with boa.env.anchor():
        fs.dispatch_fees()

        assert sum(crvusd.balanceOf(c) for c in controllers) == 0
        assert crvusd.balanceOf(fs) == 0

        total_claimed = 10**20 * len(controllers)
        assert (
            crvusd.balanceOf(receivers[0][0])
            == total_claimed * 5_000 // 10_000
        )
        assert (
            crvusd.balanceOf(receivers[1][0])
            == total_claimed * 5_000 // 10_000
        )

    # case 2: weight is same as cap
    weight.set_weight(7_000)

    with boa.env.anchor():
        fs.dispatch_fees()

        assert sum(crvusd.balanceOf(c) for c in controllers) == 0
        assert crvusd.balanceOf(fs) == 0

        total_claimed = 10**20 * len(controllers)
        assert (
            crvusd.balanceOf(receivers[0][0])
            == total_claimed * 7_000 // 10_000
        )
        assert (
            crvusd.balanceOf(receivers[1][0])
            == total_claimed * 3_000 // 10_000
        )

    # case 3: weight is more than cap
    weight.set_weight(9_000)

    with boa.env.anchor():
        fs.dispatch_fees()

        assert sum(crvusd.balanceOf(c) for c in controllers) == 0
        assert crvusd.balanceOf(fs) == 0

        total_claimed = 10**20 * len(controllers)
        assert (
            crvusd.balanceOf(receivers[0][0])
            == total_claimed * 7_000 // 10_000
        )
        assert (
            crvusd.balanceOf(receivers[1][0])
            == total_claimed * 3_000 // 10_000
        )
