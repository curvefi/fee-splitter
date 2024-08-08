// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.23;

interface Quest {
    type PeriodState is uint8;
    type QuestCloseType is uint8;
    type QuestRewardsType is uint8;
    type QuestVoteType is uint8;

    struct QuestTypes {
        QuestVoteType voteType;
        QuestRewardsType rewardsType;
        QuestCloseType closeType;
    }

    error AddressZero();
    error AlreadyInitialized();
    error AlreadyKilled();
    error AlreadyListed();
    error BoardIsNotAllowedDistributor();
    error CallerNotAllowed();
    error CallerNotPendingOwner();
    error CannotBeOwner();
    error CannotRecoverToken();
    error DisitributorFail();
    error EmptyArray();
    error EmptyMerkleRoot();
    error EmptyPeriod();
    error EmptyQuest();
    error ExpiredQuest();
    error IncorrectAddDuration();
    error IncorrectAddedRewardAmount();
    error IncorrectDuration();
    error IncorrectFeeAmount();
    error InequalArraySizes();
    error InvalidGauge();
    error InvalidParameter();
    error InvalidPeriod();
    error InvalidQuestID();
    error InvalidQuestType();
    error KillDelayExpired();
    error KillDelayNotExpired();
    error Killed();
    error LowerRewardPerVote();
    error MaxListSize();
    error MinValueOverMaxValue();
    error NewObjectiveTooLow();
    error NoDistributorSet();
    error NotInitialized();
    error NotKilled();
    error NullAmount();
    error NumberExceed48Bits();
    error ObjectiveTooLow();
    error PeriodNotClosed();
    error PeriodStillActive();
    error QuestNotStarted();
    error RewardPerVoteTooLow();
    error TokenNotWhitelisted();

    event ApprovedManager(address indexed manager);
    event ChestUpdated(address oldChest, address newChest);
    event DistributorUpdated(address oldDistributor, address newDistributor);
    event EmergencyWithdraw(uint256 indexed questID, address recipient, uint256 amount);
    event ExtendQuestDuration(uint256 indexed questID, uint256 addedDuration, uint256 addedRewardAmount);
    event Init(address distributor);
//    event Killed(uint256 killTime);
    event MinObjectiveUpdated(uint256 oldMinObjective, uint256 newMinObjective);
    event NewPendingOwner(address indexed previousPendingOwner, address indexed newPendingOwner);
    event NewQuest(
        uint256 indexed questID,
        address indexed creator,
        address indexed gauge,
        address rewardToken,
        uint48 duration,
        uint256 startPeriod
    );
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event PeriodBiasFixed(uint256 indexed questID, uint256 indexed period, uint256 newBias);
    event PeriodClosed(uint256 indexed questID, uint256 indexed period);
    event PlatformFeeRatioUpdated(uint256 oldFeeRatio, uint256 newFeeRatio);
    event RemovedManager(address indexed manager);
    event RewardsRollover(
        uint256 indexed questID, uint256 newRewardPeriod, uint256 newMinRewardPerVote, uint256 newMaxRewardPerVote
    );
    event SetCustomFeeRatio(address indexed creator, uint256 customFeeRatio);
    event Unkilled(uint256 unkillTime);
    event UpdateQuestParameters(
        uint256 indexed questID,
        uint256 indexed updatePeriod,
        uint256 newMinRewardPerVote,
        uint256 newMaxRewardPerVote,
        uint256 addedPeriodRewardAmount
    );
    event UpdateRewardToken(address indexed token, uint256 newMinRewardPerVote);
    event VoterListUpdated(uint256 indexed questID);
    event WhitelistToken(address indexed token, uint256 minRewardPerVote);
    event WithdrawUnusedRewards(uint256 indexed questID, address recipient, uint256 amount);

    function GAUGE_CONTROLLER() external view returns (address);
    function acceptOwnership() external;
    function addMultipleMerkleRoot(
        uint256[] memory questIDs,
        uint256 period,
        uint256[] memory totalAmounts,
        bytes32[] memory merkleRoots
    ) external;
    function addToVoterList(uint256 questID, address[] memory accounts) external;
    function approveManager(address newManager) external;
    function closePartOfQuestPeriod(uint256 period, uint256[] memory questIDs)
        external
        returns (uint256 closed, uint256 skipped);
    function closeQuestPeriod(uint256 period) external returns (uint256 closed, uint256 skipped);
    function createFixedQuest(
        address gauge,
        address rewardToken,
        bool startNextPeriod,
        uint48 duration,
        uint256 rewardPerVote,
        uint256 totalRewardAmount,
        uint256 feeAmount,
        QuestVoteType voteType,
        QuestCloseType closeType,
        address[] memory voterList
    ) external returns (uint256);
    function createRangedQuest(
        address gauge,
        address rewardToken,
        bool startNextPeriod,
        uint48 duration,
        uint256 minRewardPerVote,
        uint256 maxRewardPerVote,
        uint256 totalRewardAmount,
        uint256 feeAmount,
        QuestVoteType voteType,
        QuestCloseType closeType,
        address[] memory voterList
    ) external returns (uint256);
    function customPlatformFeeRatio(address) external view returns (uint256);
    function distributor() external view returns (address);
    function emergencyWithdraw(uint256 questID, address recipient) external;
    function extendQuestDuration(uint256 questID, uint48 addedDuration, uint256 addedRewardAmount, uint256 feeAmount)
        external;
    function fixQuestPeriodBias(uint256 period, uint256 questID, uint256 correctReducedBias) external;
    function getAllPeriodsForQuestId(uint256 questID) external view returns (uint48[] memory);
    function getCurrentPeriod() external view returns (uint256);
    function getCurrentReducedBias(uint256 questID) external view returns (uint256);
    function getQuestCreator(uint256 questID) external view returns (address);
    function getQuestIdsForPeriod(uint256 period) external view returns (uint256[] memory);
    function getQuestIdsForPeriodForGauge(address gauge, uint256 period) external view returns (uint256[] memory);
    function getQuestVoterList(uint256 questID) external view returns (address[] memory);
    function getReducedBias(uint256 period, uint256 questID) external view returns (uint256);
    function init(address _distributor) external;
    function isKilled() external view returns (bool);
    function killBoard() external;
    function killTs() external view returns (uint256);
    function minRewardPerVotePerToken(address) external view returns (uint256);
    function multipleWithdrawUnusedRewards(uint256[] memory questIDs, address recipient) external;
    function nextID() external view returns (uint256);
    function objectiveMinimalThreshold() external view returns (uint256);
    function originalRewardPerPeriod(uint256) external view returns (uint256);
    function owner() external view returns (address);
    function pendingOwner() external view returns (address);
    function periodAmountDistributedByQuest(uint256, uint256) external view returns (uint256);
    function periodStateByQuest(uint256, uint256) external view returns (PeriodState);
    function platformFeeRatio() external view returns (uint256);
    function questChest() external view returns (address);
    function questDistributors(uint256) external view returns (address);
    function questWithdrawableAmount(uint256) external view returns (uint256);
    function quests(uint256)
        external
        view
        returns (
            address creator,
            address rewardToken,
            address gauge,
            uint48 duration,
            uint48 periodStart,
            uint256 totalRewardAmount,
            uint256 rewardAmountPerPeriod,
            uint256 minRewardPerVote,
            uint256 maxRewardPerVote,
            uint256 minObjectiveVotes,
            uint256 maxObjectiveVotes,
            QuestTypes memory types
        );
    function recoverERC20(address token) external returns (bool);
    function removeFromVoterList(uint256 questID, address account) external;
    function removeManager(address manager) external;
    function renounceOwnership() external;
    function setCustomFeeRatio(address user, uint256 customFeeRatio) external;
    function transferOwnership(address newOwner) external;
    function unkillBoard() external;
    function updateChest(address chest) external;
    function updateDistributor(address newDistributor) external;
    function updateMinObjective(uint256 newMinObjective) external;
    function updatePlatformFee(uint256 newFee) external;
    function updateQuestParameters(
        uint256 questID,
        uint256 newMinRewardPerVote,
        uint256 newMaxRewardPerVote,
        uint256 addedPeriodRewardAmount,
        uint256 addedTotalRewardAmount,
        uint256 feeAmount
    ) external;
    function updateRewardToken(address newToken, uint256 newMinRewardPerVote) external;
    function whitelistMultipleTokens(address[] memory newTokens, uint256[] memory minRewardPerVotes) external;
    function whitelistedTokens(address) external view returns (bool);
    function withdrawUnusedRewards(uint256 questID, address recipient) external;
}
