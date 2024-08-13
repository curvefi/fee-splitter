import textwrap

import boa


def test_expected_behavior(fee_splitter, mock_dynamic_weight_deployer):
    # if we pass an eoa address, it should return False
    assert not fee_splitter.internal._is_dynamic(boa.env.generate_address())

    # if we pass a contract that doesn't implement IERC165,
    # it should return False
    code = textwrap.dedent(
        """
        foo: public(int128)
    """
    )
    assert not fee_splitter.internal._is_dynamic(boa.loads(code))

    # if we pass a contract that implements IERC165, but doesn't support
    # the dynamic fee splitter interface, it should return False
    code = textwrap.dedent(
        """
        from ethereum.ercs import IERC165

        implements: IERC165

        @view
        @external
        def supportsInterface(interfaceId: bytes4) -> bool:
            return False
    """
    )
    assert not fee_splitter.internal._is_dynamic(boa.loads(code))

    # if we pass a contract that implements IERC165 and supports the dynamic
    # fee splitter interface, it should return True
    dynamic_weight = mock_dynamic_weight_deployer()
    assert fee_splitter.internal._is_dynamic(dynamic_weight)
