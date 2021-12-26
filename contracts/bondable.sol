// SPDX-License-Identifier: UNLICENSED

pragma solidity >= 0.8.4;

import "./Utils/SafeTransferLib.sol";
import './Tokens/zcToken.sol';

// A factory to issue un-backed debt at a provided price (discount) in the form of zero-coupon bonds.
// Utilizes solmate ERC20 & SafeTransfer, and intended to be used in tandem with @yieldprotocol/yieldspace-v2
contract Bondable {

    address public admin;

    /// @notice A market for a specific underlying token and maturity.
    /// @param maximumDebt The maximum amount of debt that can be issued.
    /// @param price The issuance price of the debt / bond.
    /// @param mintedDebt The amount of debt that has been issued.
    /// @param repaidDebt The amounf of debt that the has been repaid to the market (must repay before it can be redeemed).
    /// @param redeemedDebt The amount of debt that has been redeemed back into underlying (after maturity).
    /// @param bond The address of the issued zero-coupon bond contract.
    /// @param name The name of the bond market (e.g. TRIBE-MAR, TRIBE-1648728318, or Tetranode-TRIBE-MAR for an indivudalized bond)
    struct Market {
        uint256 maximumDebt;
        uint256 price;
        uint256 mintedDebt;
        uint256 repaidDebt;
        uint256 redeemedDebt;
        address bond;
        string name;
    }
    
    /// @notice A mapping of markets that have been created
    /// address the address of the underlying token
    /// uint256 the maturity (unix timestamp) of the market
    mapping (address => mapping (uint256 => Market)) public markets;
    
    event marketCreated(address indexed underlying, uint256 indexed maturity, address indexed bond, uint256 maximumDebt, string name);

    event bondMinted(address indexed underlying, uint256 indexed maturity, address indexed bond, uint256 amount, uint256 mintedDebt);

    event bondRepaid(address indexed underlying, uint256 indexed maturity, address indexed bond, uint256 amount, uint256 repaidDebt);

    event bondRedeemed(address indexed underlying, uint256 indexed maturity, address indexed bond, uint256 amount, uint256 redeemedDebt);
    
    constructor () {
        admin = msg.sender;
    }

    /// @notice Can be called to create a new debt market for a given underlying token
    /// @param underlying the address of the underlying token 
    /// @param maturity the maturity of the market
    /// @param decimals the number of decimals in the underlying token
    /// @param price the issuance price on the bonds (a decimal stored as a base 1e18 uint256, issuance accurate to 8 digits precision)
    /// @param maximumDebt the maximum amount of debt/bonds to allow to be minted
    function createMarket(address underlying, uint256 maturity, uint256 maximumDebt, uint256 price, uint8 decimals, string memory name, string memory symbol) external onlyAdmin() returns (address) {
        
        // check if the market already exists
        require(markets[underlying][maturity].maximumDebt == 0, 'Market already exists');
        // create the bond token
        address bondAddress = address(new zcToken(name, symbol, decimals, maturity, underlying));
        // create the market
        markets[underlying][maturity] = Market(maximumDebt, price, 0, 0, 0, bondAddress, name);
        // emit the event
        emit marketCreated(underlying, maturity, bondAddress, maximumDebt, name);
        
        return (bondAddress);
    }
    
    /// @notice Can be called to mint/purchase a new bond
    /// @param underlying the address of the underlying token being lent
    /// @param maturity the maturity of the market
    /// @param amount the amount of underlying tokens to lend
    function mint(address underlying, uint256 maturity, uint256 amount) external returns (uint256) {

        Market memory _market = markets[underlying][maturity];

        // check market maturity
        require(block.timestamp <= maturity,'bond has already matured');       

        // transfer in underlying
        SafeTransferLib.safeTransferFrom(ERC20(underlying), msg.sender, address(this), amount);

        // calculate amount of debt to mint (modifier = 1/price)
        uint256 mintAmount = amount * (1e26 / _market.price) / 1e8;

        // mint the bond
        zcToken(_market.bond).mint(msg.sender, mintAmount);

        // require that maximum debt has not been exceeded
        uint256 newDebt = _market.mintedDebt + mintAmount;
        require(newDebt <= _market.maximumDebt,'maximum debt exceeded');

        // update the market
        markets[underlying][maturity].mintedDebt = newDebt;

        // emit the event
        emit bondMinted(underlying, maturity, _market.bond, amount, newDebt);

        return (mintAmount);
    }

    /// @notice Can be called after maturity to redeem debt owed
    /// @param underlying the address of the underlying token being redeemed
    /// @param maturity the maturity of the market being redeemed
    /// @param amount the amount of underlying tokens to redeem and bond tokens to burn
    function redeem(address underlying, uint256 maturity, uint256 amount) external returns (uint256) {
        
        Market memory _market = markets[underlying][maturity];

        // check market maturity
        require(block.timestamp >= maturity,'bond maturity has not been reached');

        uint256 newRedeemedDebt = _market.redeemedDebt + amount;
        // ensure market has enough repaid debt to redeem (first come first served)
        require(newRedeemedDebt <= _market.repaidDebt,'total market claim exceeds debt repaid');
        
        // burn the bond
        zcToken(_market.bond).burn(msg.sender, amount);

        // update the market's redeemed debt
        markets[underlying][maturity].redeemedDebt = newRedeemedDebt;

        // emit the event
        emit bondRedeemed(underlying, maturity, _market.bond, amount, newRedeemedDebt);

        // transfer out underlying
        SafeTransferLib.safeTransfer(ERC20(underlying), msg.sender, amount);
        
        return (amount);
    }

    /// @notice Can be called to pay towards a certain market's debt (generally called by the debtor)
    /// @param underlying the address of the underlying token being paid
    /// @param maturity the maturity of the market being redeemed
    /// @param amount the amount of underlying token debt to pay
    function repay(address underlying, uint256 maturity, uint256 amount) external returns (uint256) {

        Market memory _market = markets[underlying][maturity];

        uint256 newRepaidDebt = _market.repaidDebt + amount;
        // ensure market is not overpaying its debts
        require(newRepaidDebt <= _market.mintedDebt,'can not repay more debt than is minted');

        // update the market's repaid debt
        markets[underlying][maturity].repaidDebt = newRepaidDebt;

        // emit the event
        emit bondRepaid(underlying, maturity, _market.bond, amount, newRepaidDebt);

        // transfer in underlying 
        SafeTransferLib.safeTransfer(ERC20(underlying), msg.sender, amount);

        return (amount);
    }

    /// @notice Allows the admin to set a new admin
    /// @param newAdmin Address of the new admin
    function transferAdmin(address newAdmin) external onlyAdmin() returns (address) {

        admin = newAdmin;

        return (newAdmin);
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, 'sender must be admin');
        _;
  }
    
}
