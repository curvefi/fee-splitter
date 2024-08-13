import boa


def test_total_weight_less_than_max(fee_splitter):
    receivers_too_much = [
        (boa.env.generate_address(), 7_001, False),
        (boa.env.generate_address(), 3_000, False),
    ]

    receivers_not_enough = [
        (boa.env.generate_address(), 6_999, False),
        (boa.env.generate_address(), 3_000, False),
    ]

    with boa.reverts("receivers: total weight != MAX_BPS"):
        fee_splitter.internal._set_receivers(receivers_too_much)

    with boa.reverts("receivers: total weight != MAX_BPS"):
        fee_splitter.internal._set_receivers(receivers_not_enough)


def test_no_receiver(fee_splitter, crvusd, mock_factory, owner):
    with boa.reverts("receivers: empty"):
        fee_splitter.internal._set_receivers([])


def test_constructor_invalid_weights(fee_splitter):
    zero_receivers = [(boa.env.generate_address(), 0, False)]
    with boa.reverts("receivers: invalid weight"):
        fee_splitter.internal._set_receivers(zero_receivers)

    more_than_max_receivers = [(boa.env.generate_address(), 10_001, False)]
    with boa.reverts("receivers: invalid weight"):
        fee_splitter.internal._set_receivers(more_than_max_receivers)
