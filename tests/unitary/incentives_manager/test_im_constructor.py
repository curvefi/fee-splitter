import boa

from contracts.manual import IncentivesManager


def test_expected_behavior(
    manager,
    crvusd,
    bribe_manager,
    bribe_proposer,
    token_rescuer,
    emergency_admin,
):
    m = manager
    assert manager.MAX_INCENTIVES_PER_GAUGE() == int(10**23)

    assert manager.BRIBE_PROPOSER() == boa.eval("keccak256('BRIBE_PROPOSER')")
    assert manager.BRIBE_MANAGER() == boa.eval("keccak256('BRIBE_MANAGER')")
    assert manager.TOKEN_RESCUER() == boa.eval("keccak256('TOKEN_RESCUER')")
    assert manager.EMERGENCY_ADMIN() == boa.eval(
        "keccak256('EMERGENCY_ADMIN')"
    )

    assert manager._immutables.managed_asset == crvusd.address
    assert manager.bribe_logic() == boa.eval("empty(address)")

    assert m.hasRole(m.BRIBE_PROPOSER(), bribe_proposer)
    assert m.hasRole(m.BRIBE_MANAGER(), bribe_manager)
    assert m.hasRole(m.TOKEN_RESCUER(), token_rescuer)
    assert m.hasRole(m.EMERGENCY_ADMIN(), emergency_admin)
    assert not m.hasRole(m.DEFAULT_ADMIN_ROLE(), boa.env.eoa)


def test_zero_address(
    crvusd, bribe_manager, bribe_proposer, token_rescuer, emergency_admin
):
    zero = boa.eval("empty(address)")
    with boa.reverts("zeroaddr: managed_asset"):
        IncentivesManager(
            zero, bribe_manager, bribe_proposer, token_rescuer, emergency_admin
        )
    with boa.reverts("zeroaddr: bribe_manager"):
        IncentivesManager(
            crvusd, zero, bribe_proposer, token_rescuer, emergency_admin
        )
    with boa.reverts("zeroaddr: bribe_proposer"):
        IncentivesManager(
            crvusd, bribe_manager, zero, token_rescuer, emergency_admin
        )
    with boa.reverts("zeroaddr: token_rescuer"):
        IncentivesManager(
            crvusd, bribe_manager, bribe_proposer, zero, emergency_admin
        )
    with boa.reverts("zeroaddr: emergency_admin"):
        IncentivesManager(
            crvusd, bribe_manager, bribe_proposer, token_rescuer, zero
        )
