def test_expected_behavior_empty(fee_splitter):
    assert fee_splitter.n_controllers() == 0


def test_expected_behavior_with_controllers(fee_splitter_with_controllers):
    assert fee_splitter_with_controllers[0].n_controllers() == 10
