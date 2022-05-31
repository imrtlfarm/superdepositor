// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.13;

import "./interfaces/IBeetVault.sol";
import "./interfaces/IVault.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

/// @title BeetsHelper
/// @author z80 and Eidolon
contract BeetsHelper {

    using SafeERC20Upgradeable for IERC20Upgradeable;

    address public immutable balVault;

    // this will hold all the data we need to:
    // 1. Deposit/Withdraw our funds into Beethoven and obtain LPs
    // 2. Deposit/Withdraw those LPs into reaper and obtain vault shares
    // 3. Transfer those vault shares to the intended recipient
    struct VaultParams {
        IAsset[] underlyings;
        uint256 tokenIndex;
        bytes32 beetsPoolId;
        address lpToken; // needed for approval to deposit
        address vault;
        address recipient;
    }

    constructor(address _balVault) {
        balVault = _balVault;
    }

    function routeDeposit(address tokenIn, VaultParams memory details, uint256 amount) public {
        //I think trading on firebird is the most optimal thing to do
        //before we do the deposit, if we can swing it
        address depositToken = address(details.underlyings[details.tokenIndex]);
        if(tokenIn == depositToken){
            _singleSideDeposit(details, amount);
        } else {
            //firebird route from tokenIn to depositToken
        }
        
    }

    function _singleSideDeposit(VaultParams memory details, uint256 amount) public {
        IERC20Upgradeable inputToken = IERC20Upgradeable(address(details.underlyings[details.tokenIndex]));
        inputToken.safeTransferFrom(msg.sender, address(this), amount);
        _joinPool(details.underlyings, amount, details.tokenIndex, details.beetsPoolId); // contract has lp tokens
        _depositLPToVault(details.lpToken, details.vault, details.recipient);
    }

    function _singleSideWithdraw(VaultParams memory details, uint256 amount) internal {
        IERC20Upgradeable inputToken = IERC20Upgradeable(address(details.underlyings[details.tokenIndex]));
        inputToken.safeTransferFrom(msg.sender, address(this), amount);
        IVault(details.vault).withdrawAll();
        _exitPool(details.underlyings, amount, details.tokenIndex, details.beetsPoolId);
    }
    
    function _depositLPToVault(address lp, address vault, address recipient) internal {

        // approve lp
        _approveIfNeeded(vault, lp); // sets to max if needed

        // deposit lp
        IVault(vault).depositAll();

        // transfer to user
        IERC20Upgradeable shares = IERC20Upgradeable(vault);
        shares.safeTransfer(recipient, shares.balanceOf(address(this)));
    }

    function _approveIfNeeded(address spender, address token) internal {
        IERC20Upgradeable token_ = IERC20Upgradeable(token);
        if (token_.allowance(address(this), spender) == uint256(0)) {
            token_.safeIncreaseAllowance(spender, type(uint256).max);
        }
    }

    /**
     * @dev Joins {beetsPoolId} using {underlyings[tokenIndex]} balance;
     */
    function _joinPool(IAsset[] memory underlyings, uint256 amtIn, uint256 tokenIndex, bytes32 beetsPoolId) internal {
        uint8 joinKind = 1;

        // default values of 0 for all assets except one we're depositing with
        uint256[] memory amountsIn = new uint256[](underlyings.length);
        amountsIn[tokenIndex] = amtIn;

        uint256 minAmountOut = 1; // fix this later, slippage protection

        bytes memory userData = abi.encode(joinKind, amountsIn, minAmountOut);

        IBeetVault.JoinPoolRequest memory request;
        request.assets = underlyings;
        request.maxAmountsIn = amountsIn;
        request.userData = userData;
        request.fromInternalBalance = false;

        IERC20Upgradeable(address(underlyings[tokenIndex])).safeIncreaseAllowance(balVault, amtIn);
        IBeetVault(balVault).joinPool(beetsPoolId, address(this), address(this), request);
    }

    function _exitPool(IAsset[] memory underlyings, uint256 amtOut, uint256 tokenIndex, bytes32 beetsPoolId) internal {

        // default values of 0 for all assets except one we're withdrawing to
        uint256[] memory minAmountsOut = new uint256[](underlyings.length);
        minAmountsOut[tokenIndex] = amtOut;

        uint256 minAmountOut = 1; // fix this later, slippage protection

        bytes memory userData = abi.encode(0,minAmountsOut, minAmountOut);

        IBeetVault.ExitPoolRequest memory request;
        request.assets = underlyings;
        request.minAmountsOut = minAmountsOut;
        request.userData = userData;
        request.toInternalBalance = false;

        //IERC20Upgradeable(address(underlyings[tokenIndex])).safeIncreaseAllowance(balVault, amtIn);
        IBeetVault(balVault).exitPool(beetsPoolId, address(this), payable(msg.sender), request);//msg.sender is the eoa withdrawing
    }

}
