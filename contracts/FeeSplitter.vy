# pragma version ~=0.4.0

"""
@title FeeSplitter
@notice A contract that collects fees from multiple crvUSD controllers
in a single transaction and distributes them according to some weights.
@license Copyright (c) Curve.Fi, 2020-2024 - all rights reserved
@author curve.fi
@custom:security security@curve.fi
"""

from ethereum.ercs import IERC20
from ethereum.ercs import IERC165

from contracts.interfaces import IDynamicWeight

import ControllerMulticlaim as multiclaim
from snekmate.auth import ownable

initializes: multiclaim
initializes: ownable

exports: (ownable.__interface__, multiclaim.__interface__)


event SetReceivers: pass


event FeeDispatched:
    receiver: indexed(address)
    weight: uint256


struct Receiver:
    addr: address
    weight: uint256


version: public(constant(String[8])) = "0.1.0"  # no guarantees on abi stability

# maximum number of splits
MAX_RECEIVERS: constant(uint256) = 100
# maximum basis points (100%)
MAX_BPS: constant(uint256) = 10_000
DYNAMIC_WEIGHT_EIP165_ID: constant(bytes4) = 0xA1AAB33F

# receiver logic
receivers: public(DynArray[Receiver, MAX_RECEIVERS])

crvusd: immutable(IERC20)


@deploy
def __init__(
    _crvusd: IERC20,
    _factory: multiclaim.IControllerFactory,
    receivers: DynArray[Receiver, MAX_RECEIVERS],
    owner: address,
):
    """
    @notice Contract constructor
    @param _crvusd The address of the crvUSD token contract
    @param _factory The address of the crvUSD controller factory
    @param receivers The list of receivers (address, weight).
        Last item in the list is the excess receiver by default.
    @param owner The address of the contract owner
    """
    assert _crvusd.address != empty(address), "zeroaddr: crvusd"
    assert owner != empty(address), "zeroaddr: owner"

    ownable.__init__()
    ownable._transfer_ownership(owner)
    multiclaim.__init__(_factory)

    # setting immutables
    crvusd = _crvusd

    # set the receivers
    self._set_receivers(receivers)


def _is_dynamic(addr: address) -> bool:
    """
    This function covers the following cases without reverting:
    1. The address is an EIP-165 compliant contract that supports
        the dynamic weight interface (returns True).
    2. The address is a contract that does not comply to EIP-165
        (returns False).
    3. The address is an EIP-165 compliant contract that does not
        support the dynamic weight interface (returns False).
    4. The address is an EOA (returns False).
    """
    success: bool = False
    response: Bytes[32] = b""
    success, response = raw_call(
        addr,
        abi_encode(
            DYNAMIC_WEIGHT_EIP165_ID,
            method_id=method_id("supportsInterface(bytes4)"),
        ),
        max_outsize=32,
        is_static_call=True,
        revert_on_failure=False,
    )
    return success and convert(response, bool)


def _set_receivers(receivers: DynArray[Receiver, MAX_RECEIVERS]):
    assert len(receivers) > 0, "receivers: empty"
    total_weight: uint256 = 0
    for r: Receiver in receivers:
        assert r.addr != empty(address), "zeroaddr: receivers"
        assert r.weight > 0 and r.weight <= MAX_BPS, "receivers: invalid weight"
        total_weight += r.weight
    assert total_weight == MAX_BPS, "receivers: total weight != MAX_BPS"

    self.receivers = receivers

    log SetReceivers()


@nonreentrant
@external
def dispatch_fees(
    controllers: DynArray[
        multiclaim.IController, multiclaim.MAX_CONTROLLERS
    ] = []
):
    """
    @notice Claim fees from all controllers and distribute them
    @param controllers The list of controllers to claim fees from (default: all)
    @dev Splits and transfers the balance according to the receivers weights
    """

    multiclaim.claim_controller_fees(controllers)

    balance: uint256 = staticcall crvusd.balanceOf(self)

    excess: uint256 = 0

    # by iterating over the receivers, rather than the indices,
    # we avoid an oob check at every iteration.
    i: uint256 = 0
    for r: Receiver in self.receivers:
        weight: uint256 = r.weight

        if self._is_dynamic(r.addr):
            dynamic_weight: uint256 = staticcall IDynamicWeight(r.addr).weight()

            # `weight` acts as a cap to the dynamic weight, preventing
            # receivers to ask for more than what they are allowed to.
            if dynamic_weight < weight:
                excess += weight - dynamic_weight
                weight = dynamic_weight

        # if we're at the last iteration, it means `r` is the excess
        # receiver, therefore we add the excess to its weight.
        if i == len(self.receivers) - 1:
            weight += excess

        extcall crvusd.transfer(r.addr, balance * weight // MAX_BPS)

        log FeeDispatched(r.addr, weight)
        i += 1


@external
def set_receivers(receivers: DynArray[Receiver, MAX_RECEIVERS]):
    """
    @notice Set the receivers, the last one is the excess receiver.
    @param receivers The new receivers's list.
    @dev The excess receiver is always the last element in the
        `self.receivers` array.
    """
    ownable._check_owner()

    self._set_receivers(receivers)


@view
@external
def excess_receiver() -> address:
    """
    @notice Get the excess receiver, that is the receiver
        that, on top of his weight, will receive an additional
        weight if other receivers (with a dynamic weight) ask
        for less than their cap.
    @return The address of the excess receiver.
    """
    receivers_length: uint256 = len(self.receivers)
    return self.receivers[receivers_length - 1].addr


@view
@external
def n_receivers() -> uint256:
    """
    @notice Get the number of receivers
    @return The number of receivers
    """
    return len(self.receivers)
