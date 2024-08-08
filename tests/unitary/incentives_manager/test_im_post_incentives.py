import boa

def test_expected_behavior(manager_with_voting_market, generic_voting_market,
                             bribe_poster, bribe_manager, crvusd):
    m = manager_with_voting_market

    payloads = [(boa.env.generate_address(), i * 10**20, bytes()) for i in range(1, 10)]

    total = sum([amount for (_, amount, _ ) in payloads])

    crvusd.mint_for_testing(m, total)

    with boa.env.prank(bribe_manager):
        for (gauge, _, _) in payloads:
            m.set_gauge_cap(gauge, 10**23)

    with boa.env.prank(bribe_poster):
        m.update_incentives_batch(payloads)
        m.confirm_batch()

    m.post_incentives()

    assert generic_voting_market.eval("len(self.received_payloads)") == len(payloads)
    for i, (gauge, amount, data) in enumerate(payloads):
        payload = generic_voting_market.received_payloads(i)
        assert payload[0] == gauge
        assert payload[1] == amount
        assert payload[2] == data

