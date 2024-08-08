// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

interface IVotemarket {
    struct Bounty {
        address gauge;
        address manager;
        address rewardToken;
        uint8 numberOfPeriods;
        uint256 endTimestamp;
        uint256 maxRewardPerVote;
        uint256 totalRewardAmount;
        address[] blacklist;
    }

    struct Period {
        uint8 id;
        uint256 timestamp;
        uint256 rewardPerPeriod;
    }

    struct Upgrade {
        uint8 numberOfPeriods;
        uint256 totalRewardAmount;
        uint256 maxRewardPerVote;
        uint256 endTimestamp;
    }

    error ALREADY_CLOSED();
    error AUTH_MANAGER_ONLY();
    error INVALID_NUMBER_OF_PERIODS();
    error INVALID_TOKEN();
    error KILLED();
    error NOT_UPGRADEABLE();
    error NO_PERIODS_LEFT();
    error Reentrancy();
    error WRONG_INPUT();
    error ZERO_ADDRESS();

    event BountyClosed(uint256 id, uint256 remainingReward);
    event BountyCreated(
        uint256 indexed id,
        address indexed gauge,
        address manager,
        address rewardToken,
        uint8 numberOfPeriods,
        uint256 maxRewardPerVote,
        uint256 rewardPerPeriod,
        uint256 totalRewardAmount,
        bool isUpgradeable
    );
    event BountyDurationIncrease(
        uint256 id, uint8 numberOfPeriods, uint256 totalRewardAmount, uint256 maxRewardPerVote
    );
    event BountyDurationIncreaseQueued(
        uint256 id, uint8 numberOfPeriods, uint256 totalRewardAmount, uint256 maxRewardPerVote
    );
    event Claimed(
        address indexed user,
        address rewardToken,
        uint256 indexed bountyId,
        uint256 amount,
        uint256 protocolFees,
        uint256 period
    );
    event FeeCollectorUpdated(address feeCollector);
    event FeeUpdated(uint256 fee);
    event FeesCollected(address indexed rewardToken, uint256 amount);
    event ManagerUpdated(uint256 id, address indexed manager);
    event OwnershipTransferred(address indexed user, address indexed newOwner);
    event PeriodRolledOver(uint256 id, uint256 periodId, uint256 timestamp, uint256 rewardPerPeriod);
    event RecipientSet(address indexed sender, address indexed recipient);

    function MINIMUM_PERIOD() external view returns (uint8);
    function activePeriod(uint256) external view returns (uint8 id, uint256 timestamp, uint256 rewardPerPeriod);
    function amountClaimed(uint256) external view returns (uint256);
    function bounties(uint256)
        external
        view
        returns (
            address gauge,
            address manager,
            address rewardToken,
            uint8 numberOfPeriods,
            uint256 endTimestamp,
            uint256 maxRewardPerVote,
            uint256 totalRewardAmount
        );
    function claim(uint256 bountyId) external returns (uint256);
    function claim(uint256 bountyId, address _recipient) external returns (uint256);
    function claimAll(uint256[] memory ids) external;
    function claimAll(uint256[] memory ids, address _recipient) external;
    function claimAllFor(address _user, uint256[] memory ids) external;
    function claimFees(address[] memory rewardTokens) external;
    function claimFor(address user, uint256 bountyId) external returns (uint256);
    function claimable(address user, uint256 bountyId) external view returns (uint256 amount);
    function closeBounties(uint256[] memory bountyIds) external;
    function closeBounty(uint256 bountyId) external;
    function createBounty(
        address gauge,
        address manager,
        address rewardToken,
        uint8 numberOfPeriods,
        uint256 maxRewardPerVote,
        uint256 totalRewardAmount,
        address[] memory blacklist,
        bool upgradeable
    ) external returns (uint256 newBountyId);
    function fee() external view returns (uint256);
    function feeAccrued(address) external view returns (uint256);
    function feeCollector() external view returns (address);
    function fees(address) external view returns (uint256);
    function gaugeController() external view returns (address);
    function getActivePeriod(uint256 bountyId) external view returns (Period memory);
    function getActivePeriodPerBounty(uint256 bountyId) external view returns (uint8);
    function getBlacklistedAddressesPerBounty(uint256 bountyId) external view returns (address[] memory);
    function getBounty(uint256 bountyId) external view returns (Bounty memory);
    function getCurrentPeriod() external view returns (uint256);
    function getPeriodsLeft(uint256 bountyId) external view returns (uint256 periodsLeft);
    function getUpgradedBountyQueued(uint256 bountyId) external view returns (Upgrade memory);
    function getVersion() external pure returns (string memory);
    function increaseBountyDuration(
        uint256 _bountyId,
        uint8 _additionnalPeriods,
        uint256 _increasedAmount,
        uint256 _newMaxPricePerVote
    ) external;
    function isBlacklisted(uint256, address) external view returns (bool);
    function isKilled() external view returns (bool);
    function isUpgradeable(uint256) external view returns (bool);
    function kill() external;
    function lastUserClaim(address, uint256) external view returns (uint256);
    function name() external pure returns (string memory);
    function nextID() external view returns (uint256);
    function owner() external view returns (address);
    function recipient(address) external view returns (address);
    function rewardPerVote(uint256) external view returns (uint256);
    function setCustomFee(address _manager, uint256 _fee) external;
    function setFeeCollector(address _feeCollector) external;
    function setPlatformFee(uint256 _platformFee) external;
    function setRecipient(address _recipient) external;
    function setRecipientFor(address _for, address _recipient) external;
    function transferOwnership(address newOwner) external;
    function updateBountyPeriod(uint256 bountyId) external;
    function updateBountyPeriods(uint256[] memory ids) external;
    function updateManager(uint256 bountyId, address newManager) external;
    function upgradeBountyQueue(uint256)
        external
        view
        returns (uint8 numberOfPeriods, uint256 totalRewardAmount, uint256 maxRewardPerVote, uint256 endTimestamp);
}
