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
import DynamicWeight
import ControllerMulticlaim as multiclaim

from snekmate.auth import ownable

initializes: multiclaim
initializes: ownable
exports: (ownable.__interface__, multiclaim.__interface__)

event SetWeights:
    distribution_weight: uint256

event SetReceivers: pass

struct Receiver:
    addr: address
    weight: uint256
    dynamic: bool

version: public(constant(String[8])) = "0.1.0" # no guarantees on abi stability

# maximum number of splits
MAX_RECEIVERS: constant(uint256) = 100
# maximum basis points (100%)
MAX_BPS: constant(uint256) = 10_000
# TODO placeholder
DYNAMIC_WEIGHT_EIP165_ID: constant(bytes4) = 0x12431234

# receiver logic
receivers: public(DynArray[Receiver, MAX_RECEIVERS])

crvusd: immutable(IERC20)

@deploy
def __init__(_crvusd: IERC20, _factory: multiclaim.ControllerFactory, receivers: DynArray[Receiver, MAX_RECEIVERS], owner: address):
    """
    @notice Contract constructor
    @param _crvusd The address of the crvUSD token contract
    @param receivers TODO
    @param owner The address of the contract owner
    """
    assert _crvusd.address != empty(address), "zeroaddr: crvusd"
    assert _factory.address != empty(address), "zeroaddr: factory"
    assert owner != empty(address), "zeroaddr: owner"

    ownable.__init__()
    ownable._transfer_ownership(owner)
    multiclaim.__init__(_factory)

    # setting immutables
    crvusd = _crvusd

    # setting storage variables
    self._set_receivers(receivers)


def _is_dynamic(addr: address) -> bool:
    """
    @notice Check if the address supports the dynamic weight interface
    @param addr The address to check
    @return True if the address supports the dynamic weight interface
    """
    success: bool = False
    response: Bytes[32] = b""
    success, response = raw_call(
        addr,
        abi_encode(DYNAMIC_WEIGHT_EIP165_ID, method_id=method_id("supportsInterface(bytes4)")),
        max_outsize=32, # TODO can this be smaller?
        is_static_call=True,
        revert_on_failure=False
    )
    return success and convert(response, bool)

def _set_receivers(receivers: DynArray[Receiver, MAX_RECEIVERS]):
    assert len(receivers) > 0, "receivers: empty"
    total_weight: uint256 = 0
    for r: Receiver in receivers:
        assert r.addr != empty(address), "zeroaddr: receivers"
        assert r.weight > 0 and r.weight <= MAX_BPS, "receivers: invalid weight"
        total_weight += r.weight
        assert r.dynamic == self._is_dynamic(r.addr), "receivers: dynamic mismatch"
    assert total_weight == MAX_BPS, "receivers: total weight != MAX_BPS"

    self.receivers = receivers

    log SetReceivers()

# TODO mention contracts are optimised for readability over gas consumption

@nonreentrant
@external
def dispatch_fees(controllers: DynArray[multiclaim.Controller, multiclaim.MAX_CONTROLLERS]=[]):
    """
    @notice Claim fees from all controllers and distribute them
    @param controllers The list of controllers to claim fees from (default: all)
    @dev Splits and transfers the balance according to the receivers weights
    """

    multiclaim.claim_controller_fees(controllers)

    balance: uint256 = staticcall crvusd.balanceOf(self)

    for r: Receiver in self.receivers:
        weight: uint256 = 0
        if r.dynamic:
            weight = min(r.weight, staticcall DynamicWeight(r.addr).weight())
        else:
            weight = r.weight
        extcall crvusd.transfer(r.addr, balance * weight // MAX_BPS)


@external
def set_receivers(receivers: DynArray[Receiver, MAX_RECEIVERS]):
    """
    @notice Set the receivers
    @param receivers The new receivers
    """
    ownable._check_owner()

    self._set_receivers(receivers)


@view
@external
def n_receivers() -> uint256:
    """
    @notice Get the number of receivers
    @return The number of receivers
    """
    return len(self.receivers)
