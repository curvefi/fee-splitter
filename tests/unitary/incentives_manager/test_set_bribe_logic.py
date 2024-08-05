import boa


def test_logic_expected(manager, bribe_manager):
    m = manager
    random_logic = boa.env.generate_address()

    with boa.env.prank(bribe_manager):
        m.set_bribe_logic(random_logic)
    assert m._storage.bribe_logic.get() == random_logic


def test_access_control(manager, bribe_poster):
    m = manager
    random_logic = boa.env.generate_address()

    with boa.reverts("access_control: account is missing role"):
        m.set_bribe_logic(random_logic)
