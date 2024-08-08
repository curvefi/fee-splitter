import boa
from tests.mocks import MockERC20


def test_expected_behavior(manager, token_rescuer):
    random_token = MockERC20()
    random_token.mint_for_testing(manager, 100)
    assert random_token.balanceOf(manager) == 100
    with boa.env.prank(token_rescuer):
        manager.recover_erc20(random_token, receiver := boa.env.generate_address())
    assert random_token.balanceOf(receiver) == 100
    assert random_token.balanceOf(manager) == 0


def test_unauthorized(manager):
    with boa.reverts("access_control: account is missing role"):
        manager.recover_erc20(boa.env.generate_address(),
                              boa.env.generate_address())


def test_managed_asset_recovery(manager, token_rescuer):
    with boa.reverts("manager: cannot recover managed asset"):
        with boa.env.prank(token_rescuer):
            manager.recover_erc20(manager._immutables.managed_asset, boa.env.generate_address())
