import boa


def test_expected_behavior(manager, bribe_poster):
    # Round 1
    payloads = [(boa.env.generate_address(), i * 10**19, bytes()) for i in range(3)]

    with boa.env.prank(bribe_poster):
        manager.update_incentives_batch(payloads)

    assert manager.eval("len(self.pending_gauges)") == len(payloads)
    assert manager.total_incentives() == sum([amount for _, amount, _ in payloads])

    for i, (g, a, d) in enumerate(payloads):
        assert g == manager.pending_gauges(i)
        assert a == manager.amount_for_gauge(g)
        assert d == manager.data_for_gauge(g)

    # Round 2 (overwrite)
    payloads2 = [(boa.env.generate_address(), i * 10**18, bytes()) for i in range(3)]

    with boa.env.prank(bribe_poster):
        manager.update_incentives_batch(payloads2)

    assert manager.eval("len(self.pending_gauges)") == len(payloads2)
    assert manager.total_incentives() == sum([amount for _, amount, _ in payloads2])

    for i, (g, a, d) in enumerate(payloads2):
        assert g == manager.pending_gauges(i)
        assert a == manager.amount_for_gauge(g)
        assert d == manager.data_for_gauge(g)



def test_access_control(manager):
    with boa.reverts("access_control: account is missing role"):
        manager.update_incentives_batch([])

def test_no_incentives(manager, bribe_poster):
    with boa.reverts("manager: no incentives given"):
        with boa.env.prank(bribe_poster):
            manager.update_incentives_batch([])