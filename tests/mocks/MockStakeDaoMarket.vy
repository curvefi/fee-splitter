from contracts.markets import StakeDaoMarket as Votemarket

implements: Votemarket

creation_gauge: public(address)
creation_manager: public(address)
creation_rewardToken: public(address)
creation_numberOfPeriods: public(uint8)
creation_maxRewardPerVote: public(uint256)
creation_totalRewardAmount: public(uint256)
creation_blacklist: public(DynArray[address, 100])
creation_upgradeable: public(bool)

increase_bountyId: public(uint256)
increase_additionalPeriods: public(uint8)
increase_increasedAmount: public(uint256)
increase_newMaxPricePerVote: public(uint256)

close_id: public(uint256)


@external
def createBounty(
    gauge: address,
    manager: address,
    rewardToken: address,
    numberOfPeriods: uint8,
    maxRewardPerVote: uint256,
    totalRewardAmount: uint256,
    blacklist: DynArray[address, 100],
    upgradeable: bool,
) -> uint256:
    self.creation_gauge = gauge
    self.creation_manager = manager
    self.creation_rewardToken = rewardToken
    self.creation_numberOfPeriods = numberOfPeriods
    self.creation_maxRewardPerVote = maxRewardPerVote
    self.creation_totalRewardAmount = totalRewardAmount
    self.creation_blacklist = blacklist
    self.creation_upgradeable = upgradeable
    return 1234


@external
def increaseBountyDuration(
    _bountyId: uint256,
    _additionalPeriods: uint8,
    _increasedAmount: uint256,
    _newMaxPricePerVote: uint256,
):
    self.increase_bountyId = _bountyId
    self.increase_additionalPeriods = _additionalPeriods
    self.increase_increasedAmount = _increasedAmount
    self.increase_newMaxPricePerVote = _newMaxPricePerVote


@external
def closeBounty(bountyId: uint256):
    self.close_id = bountyId
