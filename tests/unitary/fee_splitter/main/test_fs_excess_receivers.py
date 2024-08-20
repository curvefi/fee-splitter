def test_expected_behavior(fee_splitter):
    expected_excess_receiver = fee_splitter.receivers(
        fee_splitter.n_receivers() - 1
    )[0]
    assert expected_excess_receiver == fee_splitter.excess_receiver()
