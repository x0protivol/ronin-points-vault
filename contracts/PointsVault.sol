// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interfaces/IGamePoints.sol";
import "./PointsReceipt.sol";

/// @title PointsVault
/// @notice Core vault for depositing in-game points and receiving ERC-20 receipt tokens
/// @dev Users deposit game points -> receive rpXXX receipt tokens 1:1
///      Receipt tokens are freely tradeable on Katana DEX
///      Users burn receipt tokens -> redeem original game points 1:1
contract PointsVault is Ownable, ReentrancyGuard, Pausable {

    // ============ Structs ============

    struct GameConfig {
        address adapter;        // IGamePoints adapter address
        address receiptToken;   // PointsReceipt ERC-20 for this game
        bool active;            // Whether deposits/withdrawals are open
        uint256 totalDeposited; // Lifetime deposits for analytics
    }

    // ============ State ============

    // gameId => GameConfig
    mapping(bytes32 => GameConfig) public games;

    // gameId => user => deposited balance
    mapping(bytes32 => mapping(address => uint256)) public userBalances;

    // List of registered game IDs
    bytes32[] public gameIds;

    // Protocol fee in basis points (default 0 for MVP)
    uint256 public feeBps;

    // Fee recipient
    address public feeRecipient;

    // ============ Events ============

    event GameRegistered(bytes32 indexed gameId, address adapter, address receiptToken);
    event GameDeactivated(bytes32 indexed gameId);
    event Deposited(bytes32 indexed gameId, address indexed user, uint256 amount);
    event Withdrawn(bytes32 indexed gameId, address indexed user, uint256 amount);
    event FeeUpdated(uint256 newFeeBps, address newRecipient);

    // ============ Constructor ============

    constructor(address _feeRecipient) Ownable(msg.sender) {
        feeRecipient = _feeRecipient;
        feeBps = 0; // No fee for MVP
    }

    // ============ Admin Functions ============

    /// @notice Register a new game with its adapter and receipt token
    /// @param gameId   Unique bytes32 identifier (e.g. keccak256("axie"))
    /// @param adapter  Address of the IGamePoints adapter
    function registerGame(
        bytes32 gameId,
        address adapter
    ) external onlyOwner {
        require(adapter != address(0), "PointsVault: zero adapter");
        require(games[gameId].adapter == address(0), "PointsVault: game already registered");

        // Deploy a receipt token for this game
        IGamePoints gameAdapter = IGamePoints(adapter);
        PointsReceipt receipt = new PointsReceipt(
            gameAdapter.gameName(),
            gameAdapter.receiptSymbol(),
            address(this)
        );

        games[gameId] = GameConfig({
            adapter: adapter,
            receiptToken: address(receipt),
            active: true,
            totalDeposited: 0
        });
        gameIds.push(gameId);

        emit GameRegistered(gameId, adapter, address(receipt));
    }

    /// @notice Deactivate a game (stops new deposits/withdrawals)
    function deactivateGame(bytes32 gameId) external onlyOwner {
        games[gameId].active = false;
        emit GameDeactivated(gameId);
    }

    /// @notice Update protocol fee (max 100 bps = 1%)
    function setFee(uint256 _feeBps, address _recipient) external onlyOwner {
        require(_feeBps <= 100, "PointsVault: fee too high");
        require(_recipient != address(0), "PointsVault: zero recipient");
        feeBps = _feeBps;
        feeRecipient = _recipient;
        emit FeeUpdated(_feeBps, _recipient);
    }

    /// @notice Emergency pause
    function pause() external onlyOwner { _pause(); }
    function unpause() external onlyOwner { _unpause(); }

    // ============ User Functions ============

    /// @notice Deposit game points and receive receipt tokens 1:1
    /// @param gameId  The game identifier
    /// @param amount  Number of points to deposit
    function deposit(
        bytes32 gameId,
        uint256 amount
    ) external nonReentrant whenNotPaused {
        GameConfig storage game = games[gameId];
        require(game.active, "PointsVault: game not active");
        require(amount > 0, "PointsVault: zero amount");

        // Pull points from user via adapter (burns from game contract)
        IGamePoints(game.adapter).burnPoints(msg.sender, amount);

        // Track balance
        userBalances[gameId][msg.sender] += amount;
        game.totalDeposited += amount;

        // Mint 1:1 receipt tokens to user
        PointsReceipt(game.receiptToken).mint(msg.sender, amount);

        emit Deposited(gameId, msg.sender, amount);
    }

    /// @notice Burn receipt tokens and redeem original game points 1:1
    /// @param gameId  The game identifier
    /// @param amount  Number of receipt tokens to burn
    function withdraw(
        bytes32 gameId,
        uint256 amount
    ) external nonReentrant whenNotPaused {
        GameConfig storage game = games[gameId];
        require(game.active, "PointsVault: game not active");
        require(amount > 0, "PointsVault: zero amount");
        require(userBalances[gameId][msg.sender] >= amount, "PointsVault: insufficient balance");

        // Burn receipt tokens from user
        PointsReceipt(game.receiptToken).burn(msg.sender, amount);

        // Update balance
        userBalances[gameId][msg.sender] -= amount;

        // Restore points to user via adapter
        IGamePoints(game.adapter).mintPoints(msg.sender, amount);

        emit Withdrawn(gameId, msg.sender, amount);
    }

    // ============ View Functions ============

    /// @notice Get user's deposited balance for a specific game
    function getBalance(bytes32 gameId, address user) external view returns (uint256) {
        return userBalances[gameId][user];
    }

    /// @notice Get all registered game IDs
    function getGameIds() external view returns (bytes32[] memory) {
        return gameIds;
    }

    /// @notice Get full game config
    function getGame(bytes32 gameId) external view returns (GameConfig memory) {
        return games[gameId];
    }

    /// @notice Get receipt token address for a game
    function getReceiptToken(bytes32 gameId) external view returns (address) {
        return games[gameId].receiptToken;
    }
}
