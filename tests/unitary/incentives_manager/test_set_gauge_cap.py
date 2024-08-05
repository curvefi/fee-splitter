import boa


def test_expected_behavior(manager, bribe_manager):
    m = manager
    random_gauge = boa.env.generate_address()

    with boa.env.prank(bribe_manager):
        m.set_gauge_cap(random_gauge, 100)
    assert m.gauge_caps(random_gauge) == 100


def test_access_control(manager, bribe_manager):
    m = manager
    random_gauge = boa.env.generate_address()

    with boa.reverts("access_control: account is missing role"):
        m.set_gauge_cap(random_gauge, 10 ** 24)


def test_cap_too_big(manager, bribe_manager):
    m = manager
    random_gauge = boa.env.generate_address()

    with boa.reverts("manager: new bribe cap too big"):
        with boa.env.prank(bribe_manager):
            m.set_gauge_cap(random_gauge, m.MAX_INCENTIVES_PER_GAUGE() + 1)
