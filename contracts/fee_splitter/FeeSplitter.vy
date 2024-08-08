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
import ControllerFactory
import Controller
import DynamicWeight

event SetWeights:
    distribution_weight: uint256

event SetReceivers: pass

event SetOwner:
    owner: address

struct Receiver:
    addr: address
    weight: uint256
    dynamic: bool

version: public(constant(String[8])) = "0.1.0" # no guarantees on abi stability
# maximum number of claims in a single transaction
MAX_CONTROLLERS: constant(uint256) = 100
# maximum number of splits
MAX_RECEIVERS: constant(uint256) = 100
# maximum basis points (100%)
MAX_BPS: constant(uint256) = 10_000
# TODO placeholder
DYNAMIC_WEIGHT_EIP165_ID: constant(bytes4) = 0x12431234

# controllers variables
controllers: public(DynArray[Controller, MAX_CONTROLLERS])
allowed_controllers: public(HashMap[Controller, bool])

# receiver logic
receivers: public(DynArray[Receiver, MAX_RECEIVERS])
owner: public(address)

factory: immutable(ControllerFactory)
crvusd: immutable(IERC20)

@deploy
def __init__(_crvusd: address, _factory: address, receivers: DynArray[Receiver, MAX_RECEIVERS], owner: address):
    """
    @notice Contract constructor
    @param _crvusd The address of the crvUSD token contract
    @param receivers TODO
    @param owner The address of the contract owner
    """
    assert _crvusd != empty(address), "zeroaddr: crvusd"
    assert _factory != empty(address), "zeroaddr: factory"
    assert owner != empty(address), "zeroaddr: owner"

    # setting immutables
    crvusd = IERC20(_crvusd)
    factory = ControllerFactory(_factory)

    # setting storage variables
    self._set_receivers(receivers)
    self.owner = owner


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
    """
    @notice Set the receivers
    @param receivers The new receivers
    """
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

@external
def update_controllers():
    """
    @notice Update the list of controllers so that it corresponds to the
        list of controllers in the factory
    """
    old_len: uint256 = len(self.controllers)
    new_len: uint256 = staticcall factory.n_collaterals()
    for i: uint256 in range(new_len - old_len, bound=MAX_CONTROLLERS):
        i_shifted: uint256 = i + old_len
        c: Controller = Controller(staticcall factory.controllers(i_shifted))
        self.allowed_controllers[c] = True
        self.controllers.append(c)

@nonreentrant
@external
def claim_controller_fees(controllers: DynArray[Controller, MAX_CONTROLLERS]=[]):
    """
    @notice Claim fees from all controllers and distribute them
    @param controllers The list of controllers to claim fees from (default: all)
    @dev Splits and transfers the balance according to the distribution weights
    """
    if len(controllers) == 0:
        for c: Controller in self.controllers:
            extcall c.collect_fees()
    else:
        for c: Controller in controllers:
            if not self.allowed_controllers[c]:
                raise "controller: not in factory"
            extcall c.collect_fees()


# TODO mention contracts are optimised for readability over gas consumption
# TODO rename poster to proposer

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
    assert msg.sender == self.owner, "auth: only owner"

    self._set_receivers(receivers)

@external
def set_owner(new_owner: address):
    """
    @notice Set owner of the contract
    @param new_owner Address of the new owner
    """
    assert msg.sender == self.owner, "auth: only owner"
    assert new_owner != empty(address), "zeroaddr: new_owner"

    self.owner = new_owner

    log SetOwner(new_owner)

@view
@external
def n_receivers() -> uint256:
    """
    @notice Get the number of receivers
    @return The number of receivers
    """
    return len(self.receivers)
