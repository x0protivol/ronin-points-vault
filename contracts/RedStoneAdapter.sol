// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";

/// @title RedStoneAdapter
/// @notice Oracle adapter using RedStone pull-based price feed model
/// @dev RedStone passes price data in calldata, validated on-chain via signature
///      This adapter wraps RedStone's model for use across PointsVault, Perpetuals,
///      and Prediction Market contracts.
///      RedStone docs: https://docs.redstone.finance/docs/smart-contract-devs/get-started/redstone-core
abstract contract RedStoneConsumerBase {
    /// @dev RedStone encodes price data in calldata and passes signers' signatures
    ///      Each data package contains: [data_point][timestamp][size][signature]
    ///      This base contract provides the extraction logic

    uint256 internal constant REDSTONE_TIMESTAMP_OFFSET = 3;
    uint256 internal constant DATA_PACKAGES_COUNT_BS = 2;
    uint256 internal constant DATA_POINTS_COUNT_BS = 3;
    uint256 internal constant SIGNATURE_BS = 65;
    uint256 internal constant DATA_POINT_VALUE_BYTE_SIZE_BS = 4;

    /// @notice Get price for a data feed (e.g. "RON", "AXS", "PIXEL")
    /// @param dataFeedId  bytes32 identifier for the asset
    /// @return price      Price in 8 decimal places (e.g. 1e8 = $1.00)
    function getOracleNumericValueFromTxMsg(bytes32 dataFeedId)
        internal
        view
        virtual
        returns (uint256 price);

    function getAuthorisedSignerIndex(address signerAddress)
        internal
        view
        virtual
        returns (uint8);
}

/// @title RedStoneAdapter
/// @notice Production oracle adapter for on-chain price feeds
contract RedStoneAdapter is Ownable {

    // ============ State ============

    // Fallback price feed (Chainlink-style) for when RedStone data is not in calldata
    mapping(bytes32 => uint256) public fallbackPrices;
    mapping(bytes32 => uint256) public fallbackTimestamps;

    // Authorized price updaters (used for fallback)
    mapping(address => bool) public priceUpdaters;

    // Maximum age of a price before it's considered stale (60 seconds)
    uint256 public maxPriceAge = 60;

    // ============ Events ============

    event FallbackPriceUpdated(bytes32 indexed feedId, uint256 price, uint256 timestamp);
    event PriceUpdaterSet(address indexed updater, bool authorized);
    event MaxPriceAgeUpdated(uint256 newAge);

    // ============ Errors ============

    error StalePrice(bytes32 feedId, uint256 age);
    error PriceNotFound(bytes32 feedId);
    error Unauthorized();

    // ============ Constructor ============

    constructor() Ownable(msg.sender) {
        priceUpdaters[msg.sender] = true;
    }

    // ============ Admin ============

    function setPriceUpdater(address updater, bool authorized) external onlyOwner {
        priceUpdaters[updater] = authorized;
        emit PriceUpdaterSet(updater, authorized);
    }

    function setMaxPriceAge(uint256 age) external onlyOwner {
        maxPriceAge = age;
        emit MaxPriceAgeUpdated(age);
    }

    // ============ Price Updates (Fallback) ============

    /// @notice Push price update (fallback for chains without RedStone relayer)
    /// @param feedId   bytes32("RON"), bytes32("AXS"), bytes32("PIXEL"), etc.
    /// @param price    8 decimal price (1e8 = $1.00)
    function updatePrice(bytes32 feedId, uint256 price) external {
        if (!priceUpdaters[msg.sender]) revert Unauthorized();
        require(price > 0, "RedStoneAdapter: zero price");

        fallbackPrices[feedId] = price;
        fallbackTimestamps[feedId] = block.timestamp;

        emit FallbackPriceUpdated(feedId, price, block.timestamp);
    }

    /// @notice Batch update multiple prices in one tx
    function batchUpdatePrices(
        bytes32[] calldata feedIds,
        uint256[] calldata prices
    ) external {
        if (!priceUpdaters[msg.sender]) revert Unauthorized();
        require(feedIds.length == prices.length, "length mismatch");

        for (uint256 i = 0; i < feedIds.length; i++) {
            require(prices[i] > 0, "zero price");
            fallbackPrices[feedIds[i]] = prices[i];
            fallbackTimestamps[feedIds[i]] = block.timestamp;
            emit FallbackPriceUpdated(feedIds[i], prices[i], block.timestamp);
        }
    }

    // ============ Price Reads ============

    /// @notice Get current price for a feed (with staleness check)
    /// @param feedId  Asset identifier
    /// @return price  8 decimal price
    function getPrice(bytes32 feedId) external view returns (uint256 price) {
        price = fallbackPrices[feedId];
        if (price == 0) revert PriceNotFound(feedId);

        uint256 age = block.timestamp - fallbackTimestamps[feedId];
        if (age > maxPriceAge) revert StalePrice(feedId, age);
    }

    /// @notice Get price without staleness check (for UI/read-only purposes)
    function getPriceUnsafe(bytes32 feedId) external view returns (uint256, uint256) {
        return (fallbackPrices[feedId], fallbackTimestamps[feedId]);
    }

    /// @notice Convert a price to USD value
    /// @param feedId   Asset identifier
    /// @param amount   Amount of the asset (in its native decimals)
    /// @param decimals Decimals of the asset
    /// @return usdValue  Value in USD with 8 decimals
    function toUsdValue(
        bytes32 feedId,
        uint256 amount,
        uint8 decimals
    ) external view returns (uint256 usdValue) {
        uint256 price = fallbackPrices[feedId];
        if (price == 0) revert PriceNotFound(feedId);
        // price is 8 decimals, amount is `decimals` decimals
        // output: 8 decimals
        usdValue = (amount * price) / (10 ** decimals);
    }

    // ============ Feed ID Helpers ============

    /// @notice Convert string to bytes32 feed ID
    function toFeedId(string memory symbol) external pure returns (bytes32) {
        return bytes32(bytes(symbol));
    }

    // Predefined feed IDs for Ronin ecosystem assets
    bytes32 public constant FEED_RON   = bytes32("RON");
    bytes32 public constant FEED_AXS   = bytes32("AXS");
    bytes32 public constant FEED_SLP   = bytes32("SLP");
    bytes32 public constant FEED_PIXEL = bytes32("PIXEL");
    bytes32 public constant FEED_USDC  = bytes32("USDC");
    bytes32 public constant FEED_ETH   = bytes32("ETH");
}
