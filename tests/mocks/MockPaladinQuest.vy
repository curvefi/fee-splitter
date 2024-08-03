from contracts.markets import PaladinQuest as Quest

implements: Quest

creation_creator: public(address)
creation_gauge: public(address)
creation_rewardToken: public(address)
creation_start_period: public(bool)
creation_duration: public(uint48)
creation_minRewardPerVote: public(uint256)
creation_maxRewardPerVote: public(uint256)
creation_totalRewardAmount: public(uint256)
creation_feeAmount: public(uint256)
creation_voteType: public(uint8)
creation_closeType: public(uint8)
creation_blacklist: public(DynArray[address, 10])

withdraw_id: public(uint256)

quest_withdrawable_amount: public(HashMap[uint256, uint256])

custom_fee_ratio: public(HashMap[address, uint256])

@external
def createRangedQuest(
    gauge: address,
    rewardToken: address,
    startNextPeriod: bool,
    duration: uint48,
    minRewardPerVote: uint256,
    maxRewardPerVote: uint256,
    totalRewardAmount: uint256,
    feeAmount: uint256,
    voteType: uint8, # QuestDataTypes.QuestVoteType : 0 == normal, 1 == blacklist, 2 == whitelist
    closeType: uint8, # QuestDataTypes.QuestCloseType : 0 == normal, 1 == rollover, 2 == distribute
    voterList: DynArray[address, 10]) -> uint256:
    self.creation_creator = msg.sender
    self.creation_gauge = gauge
    self.creation_rewardToken = rewardToken
    self.creation_start_period = startNextPeriod
    self.creation_duration = duration
    self.creation_minRewardPerVote = minRewardPerVote
    self.creation_maxRewardPerVote = maxRewardPerVote
    self.creation_totalRewardAmount = totalRewardAmount
    self.creation_feeAmount = feeAmount
    self.creation_voteType = voteType
    self.creation_closeType = closeType
    self.creation_blacklist = voterList

    return 99

@external
def withdrawUnusedRewards(
    questID: uint256,
    recipient: address):
    self.quest_withdrawable_amount[questID] = 0
    self.withdraw_id = questID

@view
@external
def questWithdrawableAmount(questID: uint256) -> uint256:
    return self.quest_withdrawable_amount[questID]

@external
def setQuestWithdrawableAmount(questID: uint256, amount: uint256):
    self.quest_withdrawable_amount[questID] = amount

@view
@external
def customPlatformFeeRatio(creator: address) -> uint256:
    return self.custom_fee_ratio[creator]

@external
def setCustomPlatformFeeRatio(creator: address, ratio: uint256):
    self.custom_fee_ratio[creator] = ratio