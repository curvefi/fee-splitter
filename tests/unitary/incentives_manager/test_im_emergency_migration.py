import boa


def test_emergency_migration_expected(manager, crvusd, emergency_admin):
    crvusd.mint_for_testing(manager, 100)

    with boa.env.prank(emergency_admin):
        manager.emergency_migration(rescuer := boa.env.generate_address())

    assert crvusd.balanceOf(manager) == 0
    assert crvusd.balanceOf(rescuer) == 100


def test_emergency_migration_unauthorized(manager):
    with boa.reverts("access_control: account is missing role"):
        manager.emergency_migration(boa.env.generate_address())
