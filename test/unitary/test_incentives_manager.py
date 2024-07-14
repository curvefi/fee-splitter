import boa
import pytest


def test_constructor(manager, crvusd):
    assert manager.MAX_INCENTIVES_PER_GAUGE() == int(10 ** 23)

    assert manager.BRIBE_POSTER() == boa.eval("keccak256('BRIBE_POSTER')")
    assert manager.BRIBE_MANAGER() == boa.eval("keccak256('BRIBE_MANAGER')")
    assert manager.TOKEN_RESCUER() == boa.eval("keccak256('TOKEN_RESCUER')")
    assert manager.EMERGENCY_ADMIN() == boa.eval(
        "keccak256('EMERGENCY_ADMIN')")

    assert manager._storage.managed_asset.get() == crvusd
    assert manager.bribe_logic() == boa.eval("empty(address)")

    assert manager.hasRole(manager.DEFAULT_ADMIN_ROLE(), boa.env.eoa)


def test_initialize(manager_initialized, bribe_poster, bribe_manager,
                    token_rescuer, emergency_admin):
    m = manager_initialized
    assert m.hasRole(m.BRIBE_POSTER(), bribe_poster)
    assert m.hasRole(m.BRIBE_MANAGER(), bribe_manager)
    assert m.hasRole(m.TOKEN_RESCUER(), token_rescuer)
    assert m.hasRole(m.EMERGENCY_ADMIN(), emergency_admin)
    assert not m.hasRole(m.DEFAULT_ADMIN_ROLE(), boa.env.eoa)


def test_update_gauge_cap_expected(manager_initialized, bribe_manager):
    m = manager_initialized
    random_gauge = boa.env.generate_address()

    with boa.env.prank(bribe_manager):
        m.update_gauge_cap(random_gauge, 100)
    assert m.gauge_caps(random_gauge) == 100

@pytest.mark.xfail()
def test_update_gauge_cap_unauthorized(manager_initialized, bribe_manager):
    m = manager_initialized
    random_gauge = boa.env.generate_address()

    # TODO why does this fail?
    with boa.reverts("access_control: account is missing role"):
        m.update_gauge_cap(random_gauge, 10 ** 24)

def test_update_gauge_cap_too_big(manager_initialized, bribe_manager):
    m = manager_initialized
    random_gauge = boa.env.generate_address()

    with boa.reverts("manager: new bribe cap too big"):
        with boa.env.prank(bribe_manager):
            m.update_gauge_cap(random_gauge, m.MAX_INCENTIVES_PER_GAUGE() + 1)

def test_set_bribe_logic_expected(manager_initialized, bribe_manager):
    m = manager_initialized
    random_logic = boa.env.generate_address()

    with boa.env.prank(bribe_manager):
        m.set_bribe_logic(random_logic)
    assert m._storage.bribe_logic.get() == random_logic

@pytest.mark.xfail()
def test_set_bribe_logic_unauthorized(manager_initialized, bribe_poster):
    m = manager_initialized
    random_logic = boa.env.generate_address()

    # TODO why does this fail?
    with boa.reverts("access_control: account is missing role"):
        m.set_bribe_logic(random_logic)


# TODO not fnished
@pytest.mark.xfail()
def test_post_bribe_expected(manager_mock_voting_market, mock_voting_market, bribe_poster, bribe_manager):

    m = manager_mock_voting_market

    random_gauge = boa.env.generate_address()
    random_amount = 100

    with boa.env.prank(bribe_manager):
        m.update_gauge_cap(random_gauge, random_amount)

    with boa.env.prank(bribe_poster):
        m.post_bribe(random_amount, random_gauge, bytes())

    assert mock_voting_market.received_amount() == random_amount


def test_post_bribe_unauthorized():
    pass

def test_post_bribe_more_than_cap():
    pass

def test_post_bribe_funds_not_fully_spent():
    pass

def test_recover_erc20_expected():
    pass

def test_recover_erc20_unauthorized():
    pass

def test_recover_erc20_managed_asset_recovery():
    pass

def test_emergency_migration_expected():
    pass

def test_emergency_migration_unauthorized():
    pass
