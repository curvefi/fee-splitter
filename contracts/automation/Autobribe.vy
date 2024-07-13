# pragma version 0.4.1

import LPNClient
import LPNRegistry

implements: LPNClient

whitelisted_gauges: HashMap[address, bool]
gauges_count: uint256

round_by_id: HashMap[uint256, uint256]
round_allocation: HashMap[uint256, uint256]
round_total: HashMap[uint256, uint256]

# TODO this is just a placeholder
QUERY_ID: constant(uint8) = 1

lpn_registry: LPNRegistry
crvusd: address

@deploy
def __init__(registry: address, crvusd: address):
    self.lpn_registry = LPNRegistry(registry)
    self.crvusd = crvusd

@external
def enable_gauges(gauges: DynArray[address, 100]):
    for g: address in gauges:
        if self.whitelisted_gauges[g]:
            raise "already whitelisted"
        self.whitelisted_gauges[g] = True
    self.gauges_count += len(gauges)

@external
def disable_gauges(gauges: DynArray[address, 100]):
    for g: address in gauges:
        if self.whitelisted_gauges[g]:
            raise "already not whitelisted"
        self.whitelisted_gauges[g] = False
    self.gauges_count -= len(gauges)

@external
def lpnCallback(request_id: uint256 , results: DynArray[uint256, 1000]):
    assert msg.sender == self.lpn_registry.address # dev: caller is not registry

    round: uint256 = self.round_by_id[request_id]

    self.round_total[round] += results[0]
    self.round_allocation[request_id] = results[0]

@internal
def queryERC20(storage_contract: address, holder: address, start: uint256, end: uint256):
    # TODO this is not gas efficient
    id256: uint256 = convert(QUERY_ID, uint256) << 248
    contract256: uint256 = convert(convert(storage_contract, uint160), uint256) << 88
    query_args: bytes32 = convert(id256 | contract256, bytes32)

    # TODO should I set pagination to 0? Some examples don't use it at all
    gas_fee: uint256 = extcall self.lpn_registry.gasFee()
    request_id: uint256 = extcall self.lpn_registry.request(self.crvusd, query_args, start, end, value=gas_fee)

    log LPNClient.Query(msg.sender, storage_contract)

