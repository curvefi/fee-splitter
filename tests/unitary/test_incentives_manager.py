import boa
import pytest

from tests.mocks import MockERC20
from contracts.manual import IncentivesManager


def test_constructor_expected(manager, mock_crvusd, bribe_manager, bribe_poster,
                     token_rescuer, emergency_admin):
    m = manager
    assert manager.MAX_INCENTIVES_PER_GAUGE() == int(10 ** 23)

    assert manager.BRIBE_POSTER() == boa.eval("keccak256('BRIBE_POSTER')")
    assert manager.BRIBE_MANAGER() == boa.eval("keccak256('BRIBE_MANAGER')")
    assert manager.TOKEN_RESCUER() == boa.eval("keccak256('TOKEN_RESCUER')")
    assert manager.EMERGENCY_ADMIN() == boa.eval("keccak256('EMERGENCY_ADMIN')")

    assert manager._storage.managed_asset.get() == mock_crvusd.address
    assert manager.bribe_logic() == boa.eval("empty(address)")

    assert m.hasRole(m.BRIBE_POSTER(), bribe_poster)
    assert m.hasRole(m.BRIBE_MANAGER(), bribe_manager)
    assert m.hasRole(m.TOKEN_RESCUER(), token_rescuer)
    assert m.hasRole(m.EMERGENCY_ADMIN(), emergency_admin)
    assert not m.hasRole(m.DEFAULT_ADMIN_ROLE(), boa.env.eoa)

def test_constructor_zero_address(mock_crvusd, bribe_manager, bribe_poster, token_rescuer, emergency_admin):
    zero = boa.eval("empty(address)")
    with boa.reverts("zeroaddr: managed_asset"):
        IncentivesManager(zero, bribe_manager, bribe_poster, token_rescuer, emergency_admin)
    with boa.reverts("zeroaddr: bribe_manager"):
        IncentivesManager(mock_crvusd, zero, bribe_poster, token_rescuer, emergency_admin)
    with boa.reverts("zeroaddr: bribe_poster"):
        IncentivesManager(mock_crvusd, bribe_manager, zero, token_rescuer, emergency_admin)
    with boa.reverts("zeroaddr: token_rescuer"):
        IncentivesManager(mock_crvusd, bribe_manager, bribe_poster, zero, emergency_admin)
    with boa.reverts("zeroaddr: emergency_admin"):
        IncentivesManager(mock_crvusd, bribe_manager, bribe_poster, token_rescuer, zero)



def test_set_gauge_cap_expected(manager, bribe_manager):
    m = manager
    random_gauge = boa.env.generate_address()

    with boa.env.prank(bribe_manager):
        m.set_gauge_cap(random_gauge, 100)
    assert m.gauge_caps(random_gauge) == 100


def test_update_gauge_cap_unauthorized(manager, bribe_manager):
    m = manager
    random_gauge = boa.env.generate_address()

    with boa.reverts("access_control: account is missing role"):
        m.set_gauge_cap(random_gauge, 10 ** 24)


def test_update_gauge_cap_too_big(manager, bribe_manager):
    m = manager
    random_gauge = boa.env.generate_address()

    with boa.reverts("manager: new bribe cap too big"):
        with boa.env.prank(bribe_manager):
            m.set_gauge_cap(random_gauge, m.MAX_INCENTIVES_PER_GAUGE() + 1)


def test_set_bribe_logic_expected(manager, bribe_manager):
    m = manager
    random_logic = boa.env.generate_address()

    with boa.env.prank(bribe_manager):
        m.set_bribe_logic(random_logic)
    assert m._storage.bribe_logic.get() == random_logic


def test_set_bribe_logic_unauthorized(manager, bribe_poster):
    m = manager
    random_logic = boa.env.generate_address()

    with boa.reverts("access_control: account is missing role"):
        m.set_bribe_logic(random_logic)


def test_post_bribe_expected(manager_mock_voting_market, mock_voting_market,
                             bribe_poster, bribe_manager, mock_crvusd):
    m = manager_mock_voting_market

    random_gauge = boa.env.generate_address()
    random_amount = 100
    mock_crvusd.mint_for_testing(m, random_amount)

    with boa.env.prank(bribe_manager):
        m.set_gauge_cap(random_gauge, random_amount)

    with boa.env.prank(bribe_poster):
        m.post_bribe(random_gauge, random_amount, bytes())

    assert mock_voting_market.received_amount() == random_amount
    assert mock_voting_market.received_gauge() == random_gauge
    assert mock_voting_market.received_data() == bytes()


def test_post_bribe_unauthorized(manager):
    with boa.reverts("access_control: account is missing role"):
        manager.post_bribe(boa.env.generate_address(), 1234, bytes())


@pytest.mark.parametrize("random_amount", list(range(0, 10 ** 23 + 1, 10**22)))
def test_post_bribe_more_than_cap(manager_mock_voting_market, bribe_manager, bribe_poster, random_amount):
    m = manager_mock_voting_market

    random_gauge = boa.env.generate_address()

    with boa.env.prank(bribe_manager):
        m.set_gauge_cap(random_gauge, random_amount)

    with boa.reverts("manager: bribe exceeds cap"):
        with boa.env.prank(bribe_poster):
            m.post_bribe(random_gauge, random_amount + 1, bytes())

def test_post_bribe_funds_not_fully_spent(manager_mock_voting_market, mock_crvusd, bribe_manager, bribe_poster, mock_voting_market):
    m = manager_mock_voting_market

    random_gauge = boa.env.generate_address()
    random_amount = 100
    mock_crvusd.mint_for_testing(m, random_amount)

    with boa.env.prank(bribe_manager):
        m.set_gauge_cap(random_gauge, random_amount)

    with boa.reverts("manager: bribe not fully spent"):
        with boa.env.prank(bribe_poster):
            m.post_bribe(random_gauge, random_amount, bytes(b"non-empty data"))



def test_recover_erc20_expected(manager, token_rescuer):
    random_token = MockERC20()
    random_token.mint_for_testing(manager, 100)
    assert random_token.balanceOf(manager) == 100
    with boa.env.prank(token_rescuer):
        manager.recover_erc20(random_token, receiver := boa.env.generate_address())
    assert random_token.balanceOf(receiver) == 100
    assert random_token.balanceOf(manager) == 0


def test_recover_erc20_unauthorized(manager):
    with boa.reverts("access_control: account is missing role"):
        manager.recover_erc20(boa.env.generate_address(),
                              boa.env.generate_address())


def test_recover_erc20_managed_asset_recovery(manager, token_rescuer):
    with boa.reverts("manager: cannot recover managed asset"):
        with boa.env.prank(token_rescuer):
            manager.recover_erc20(manager._storage.managed_asset.get(), boa.env.generate_address())



def test_emergency_migration_expected(manager, mock_crvusd, emergency_admin):
    mock_crvusd.mint_for_testing(manager, 100)

    with boa.env.prank(emergency_admin):
        manager.emergency_migration(rescuer := boa.env.generate_address())

    assert mock_crvusd.balanceOf(manager) == 0
    assert mock_crvusd.balanceOf(rescuer) == 100


def test_emergency_migration_unauthorized(manager):
    with boa.reverts("access_control: account is missing role"):
        manager.emergency_migration(boa.env.generate_address())
