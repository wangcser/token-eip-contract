/// @title ERC-1261 MVT Standard, optional metadata extension
/// @dev See https://github.com/ethereum/EIPs/blob/master/EIPS/eip-1261.md
interface ERC1261Metadata /* is ERC1261 */ {
    /// @notice A descriptive name for a collection of MVTs in this contract
    function name() external view returns (string _name);

    /// @notice An abbreviated name for MVTs in this contract
    function symbol() external view returns (string _symbol);
}