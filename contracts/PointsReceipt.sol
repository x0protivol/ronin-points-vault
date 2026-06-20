// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

/// @title PointsReceipt
/// @notice ERC-20 receipt token representing wrapped in-game points on Ronin
/// @dev Minted 1:1 when a user deposits game points into PointsVault
///      Burned 1:1 when a user withdraws game points from PointsVault
contract PointsReceipt is ERC20, Ownable, Pausable {
    // The vault contract that has exclusive mint/burn rights
    address public vault;

    // Game metadata
    string public gameName;
    string public gameSymbol;

    // Events
    event VaultUpdated(address indexed oldVault, address indexed newVault);
    event ReceiptMinted(address indexed to, uint256 amount);
    event ReceiptBurned(address indexed from, uint256 amount);

    modifier onlyVault() {
        require(msg.sender == vault, "PointsReceipt: caller is not the vault");
        _;
    }

    /// @param _gameName  Human-readable game name, e.g. "Axie Infinity"
    /// @param _symbol    Token symbol, e.g. "rpAXS"
    /// @param _vault     Address of the PointsVault contract
    constructor(
        string memory _gameName,
        string memory _symbol,
        address _vault
    ) ERC20(_gameName, _symbol) Ownable(msg.sender) {
        require(_vault != address(0), "PointsReceipt: zero vault address");
        gameName = _gameName;
        gameSymbol = _symbol;
        vault = _vault;
    }

    /// @notice Mint receipt tokens — only callable by vault on deposit
    function mint(address to, uint256 amount) external onlyVault whenNotPaused {
        _mint(to, amount);
        emit ReceiptMinted(to, amount);
    }

    /// @notice Burn receipt tokens — only callable by vault on withdrawal
    function burn(address from, uint256 amount) external onlyVault whenNotPaused {
        _burn(from, amount);
        emit ReceiptBurned(from, amount);
    }

    /// @notice Update vault address (owner only, e.g. for upgrades)
    function setVault(address newVault) external onlyOwner {
        require(newVault != address(0), "PointsReceipt: zero address");
        emit VaultUpdated(vault, newVault);
        vault = newVault;
    }

    /// @notice Pause transfers in emergency
    function pause() external onlyOwner { _pause(); }

    /// @notice Unpause
    function unpause() external onlyOwner { _unpause(); }

    /// @dev Block transfers while paused
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override whenNotPaused {
        super._beforeTokenTransfer(from, to, amount);
    }
}
