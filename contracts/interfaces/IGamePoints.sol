// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title IGamePoints
/// @notice Interface that each game adapter must implement to integrate with PointsVault
interface IGamePoints {
    /// @notice Returns the points balance of a user for this game
    function balanceOf(address user) external view returns (uint256);

    /// @notice Burns `amount` points from `user` when depositing into vault
    function burnPoints(address user, uint256 amount) external;

    /// @notice Mints `amount` points back to `user` when withdrawing from vault
    function mintPoints(address user, uint256 amount) external;

    /// @notice Returns the name of the game (e.g. "Axie Infinity")
    function gameName() external view returns (string memory);

    /// @notice Returns the ticker symbol for the receipt token (e.g. "rpAXS")
    function receiptSymbol() external view returns (string memory);

    /// @notice Returns true if the adapter is active and accepting deposits
    function isActive() external view returns (bool);

    // Events
    event PointsBurned(address indexed user, uint256 amount);
    event PointsMinted(address indexed user, uint256 amount);
}
