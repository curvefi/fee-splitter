import boa

def test_confirm_expected_behavior(manager, bribe_poster, bribe_manager):
    dummy_batch = [(boa.env.generate_address(), 1243, bytes())]

    with boa.env.prank(bribe_manager):
        manager.set_gauge_cap(dummy_batch[0][0], dummy_batch[0][1])

    with boa.env.prank(bribe_poster):
        manager.update_incentives_batch(dummy_batch)
        manager.confirm_batch()

    assert manager.incentives_locked()

def test_confirm_access_control(manager):
    with boa.reverts("access_control: account is missing role"):
        manager.confirm_batch()


def test_confirm_no_incentives(manager, bribe_poster):
    with boa.reverts("manager: no incentives batched"):
        with boa.env.prank(bribe_poster):
            manager.confirm_batch()

def test_cancel_expected_behavior(manager, bribe_poster, bribe_manager):
    # copied from confirm test
    dummy_batch = [(boa.env.generate_address(), 1243, bytes())]

    with boa.env.prank(bribe_manager):
        manager.set_gauge_cap(dummy_batch[0][0], dummy_batch[0][1])

    with boa.env.prank(bribe_poster):
        manager.update_incentives_batch(dummy_batch)
        manager.confirm_batch()

    # cancel part
    with boa.env.prank(bribe_poster):
        manager.cancel_batch()

    assert not manager.incentives_locked()

def test_cancel_access_control(manager):
    with boa.reverts("access_control: account is missing role"):
        manager.cancel_batch()