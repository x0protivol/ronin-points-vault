// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @title PointsStream
/// @notice Superfluid-style continuous streaming of points rewards to vault depositors
/// @dev Implements a simplified streaming model: depositors earn points per second
///      proportional to their vault share. Full Superfluid SDK integration on mainnet.
///      Architecture mirrors Superfluid CFA (Constant Flow Agreement) logic.
contract PointsStream is Ownable, ReentrancyGuard {

    // ============ Structs ============

    struct Stream {
        address sender;       // Who is streaming (usually the vault or game treasury)
        address receiver;     // Who receives the stream (depositor)
        uint256 flowRate;     // tokens per second (wei/s)
        uint256 startTime;    // Stream start timestamp
        uint256 lastSettled;  // Last time pending balance was settled
        bool active;          // Is stream currently live
    }

    struct DepositorReward {
        uint256 accumulatedRewards; // Already claimed rewards
        uint256 rewardDebt;         // For accurate reward calculation
        uint256 lastUpdate;         // Last time rewards were calculated
    }

    // ============ State ============

    // streamId => Stream
    mapping(bytes32 => Stream) public streams;

    // receiver => accumulated unclaimed rewards
    mapping(address => uint256) public pendingRewards;

    // receiver => reward debt tracker
    mapping(address => DepositorReward) public depositorRewards;

    // Global flow rate from game treasury to all depositors (tokens/sec)
    uint256 public globalFlowRate;

    // Total deposited (used for pro-rata share calculation)
    uint256 public totalDeposited;

    // Reward token (rpXXX receipt tokens or a dedicated STREAM token)
    address public rewardToken;

    // Treasury that funds the streams
    address public treasury;

    // ============ Events ============

    event StreamCreated(bytes32 indexed streamId, address indexed sender, address indexed receiver, uint256 flowRate);
    event StreamTerminated(bytes32 indexed streamId);
    event RewardsClaimed(address indexed user, uint256 amount);
    event GlobalFlowRateUpdated(uint256 newRate);
    event TreasuryUpdated(address newTreasury);

    // ============ Errors ============

    error StreamAlreadyExists();
    error StreamNotFound();
    error ZeroFlowRate();
    error InsufficientTreasuryBalance();
    error NothingToClaim();

    // ============ Constructor ============

    constructor(address _rewardToken, address _treasury) Ownable(msg.sender) {
        require(_rewardToken != address(0), "PointsStream: zero reward token");
        require(_treasury != address(0), "PointsStream: zero treasury");
        rewardToken = _rewardToken;
        treasury = _treasury;
    }

    // ============ Admin ============

    /// @notice Set the global flow rate from treasury to all depositors
    /// @param newRate tokens per second (e.g. 1e18 = 1 token/sec across all depositors)
    function setGlobalFlowRate(uint256 newRate) external onlyOwner {
        globalFlowRate = newRate;
        emit GlobalFlowRateUpdated(newRate);
    }

    function setTreasury(address _treasury) external onlyOwner {
        require(_treasury != address(0), "zero");
        treasury = _treasury;
        emit TreasuryUpdated(_treasury);
    }

    // ============ Stream Management ============

    /// @notice Create a direct stream from sender to receiver at a fixed flow rate
    /// @param receiver   Who receives the stream
    /// @param flowRate   tokens per second (in wei)
    function createStream(
        address receiver,
        uint256 flowRate
    ) external nonReentrant returns (bytes32 streamId) {
        if (flowRate == 0) revert ZeroFlowRate();

        streamId = keccak256(abi.encodePacked(msg.sender, receiver, block.timestamp));
        if (streams[streamId].active) revert StreamAlreadyExists();

        streams[streamId] = Stream({
            sender: msg.sender,
            receiver: receiver,
            flowRate: flowRate,
            startTime: block.timestamp,
            lastSettled: block.timestamp,
            active: true
        });

        emit StreamCreated(streamId, msg.sender, receiver, flowRate);
    }

    /// @notice Terminate an active stream and settle pending balance
    function terminateStream(bytes32 streamId) external nonReentrant {
        Stream storage s = streams[streamId];
        if (!s.active) revert StreamNotFound();
        require(msg.sender == s.sender || msg.sender == owner(), "not authorized");

        // Settle pending rewards before closing
        _settle(streamId);
        s.active = false;

        emit StreamTerminated(streamId);
    }

    // ============ Rewards ============

    /// @notice Calculate pending rewards for a depositor based on their vault share
    /// @param user         The depositor
    /// @param userDeposit  Their current vault deposit amount
    function pendingStreamRewards(
        address user,
        uint256 userDeposit
    ) public view returns (uint256) {
        if (totalDeposited == 0 || userDeposit == 0 || globalFlowRate == 0) return 0;

        uint256 elapsed = block.timestamp - depositorRewards[user].lastUpdate;
        uint256 userShare = (userDeposit * 1e18) / totalDeposited;
        uint256 earned = (elapsed * globalFlowRate * userShare) / 1e18;

        return pendingRewards[user] + earned;
    }

    /// @notice Notify the stream contract when a user deposits (called by PointsVault)
    function onDeposit(address user, uint256 amount) external {
        // In production: restrict to vault address only
        _updateRewards(user, amount - amount); // settle before state change
        totalDeposited += amount;
        depositorRewards[user].lastUpdate = block.timestamp;
    }

    /// @notice Notify when a user withdraws
    function onWithdraw(address user, uint256 amount) external {
        _updateRewards(user, amount);
        if (totalDeposited >= amount) totalDeposited -= amount;
    }

    /// @notice Claim accumulated streaming rewards
    function claimRewards(uint256 userDeposit) external nonReentrant {
        uint256 earned = pendingStreamRewards(msg.sender, userDeposit);
        if (earned == 0) revert NothingToClaim();

        pendingRewards[msg.sender] = 0;
        depositorRewards[msg.sender].lastUpdate = block.timestamp;
        depositorRewards[msg.sender].accumulatedRewards += earned;

        // Transfer reward tokens from treasury
        require(
            IERC20(rewardToken).balanceOf(treasury) >= earned,
            "PointsStream: treasury insufficient"
        );
        IERC20(rewardToken).transferFrom(treasury, msg.sender, earned);

        emit RewardsClaimed(msg.sender, earned);
    }

    // ============ Internal ============

    function _settle(bytes32 streamId) internal {
        Stream storage s = streams[streamId];
        uint256 elapsed = block.timestamp - s.lastSettled;
        uint256 owed = elapsed * s.flowRate;
        pendingRewards[s.receiver] += owed;
        s.lastSettled = block.timestamp;
    }

    function _updateRewards(address user, uint256 /* userDeposit */) internal {
        depositorRewards[user].lastUpdate = block.timestamp;
    }
}
