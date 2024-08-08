import boa


def test_expected_behavior(manager, bribe_proposer, bribe_manager):
    # Round 1
    payloads = [(boa.env.generate_address(), i * 10**19, bytes()) for i in range(1, 4)]

    with boa.env.prank(bribe_manager):
        for (gauge, _, _) in payloads:
            manager.set_gauge_cap(gauge, 10**23)

    with boa.env.prank(bribe_proposer):
        manager.update_incentives_batch(payloads)

    assert manager.eval("len(self.pending_gauges)") == len(payloads)
    assert manager.total_incentives() == sum([amount for _, amount, _ in payloads])

    for i, (g, a, d) in enumerate(payloads):
        assert g == manager.pending_gauges(i)
        assert a == manager.amount_for_gauge(g)
        assert d == manager.data_for_gauge(g)

    # Round 2 (overwrite)
    payloads2 = [(boa.env.generate_address(), i * 10**18, bytes()) for i in range(1, 4)]

    with boa.env.prank(bribe_manager):
        for (gauge, _, _) in payloads2:
            manager.set_gauge_cap(gauge, 10**23)

    with boa.env.prank(bribe_proposer):
        manager.update_incentives_batch(payloads2)

    assert manager.eval("len(self.pending_gauges)") == len(payloads2)
    assert manager.total_incentives() == sum([amount for _, amount, _ in payloads2])

    for i, (g, a, d) in enumerate(payloads2):
        assert g == manager.pending_gauges(i)
        assert a == manager.amount_for_gauge(g)
        assert d == manager.data_for_gauge(g)

def test_more_than_cap(manager, bribe_proposer):
    reverting_payload = [boa.env.generate_address(), manager.MAX_INCENTIVES_PER_GAUGE() + 1, bytes()]

    with boa.env.prank(bribe_proposer):
        with boa.reverts("manager: invalid bribe amount"):
            manager.update_incentives_batch([reverting_payload])

        reverting_payload[1] = 0
        with boa.reverts("manager: invalid bribe amount"):
            manager.update_incentives_batch([reverting_payload])

def test_access_control(manager):
    with boa.reverts("access_control: account is missing role"):
        manager.update_incentives_batch([])

def test_no_incentives(manager, bribe_proposer):
    with boa.reverts("manager: no incentives given"):
        with boa.env.prank(bribe_proposer):
            manager.update_incentives_batch([])