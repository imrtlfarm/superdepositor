// SPDX-License-Identifier: MIT

pragma solidity >=0.8.7 <0.9.0;

import {BeetsHelper} from "../SuperDepositor.sol";

import "@std/Test.sol";
import "solmate/tokens/ERC20.sol";
import "../interfaces/IBeetVault.sol";

contract DummyToken is ERC20 {
    constructor() ERC20("Test", "TST", 18) {}

    function mint(address recipient, uint256 amount) external {
        _mint(recipient, amount);
    }
}

contract BeetsHelperTest is Test {

    BeetsHelper depositor;
    DummyToken dummyToken;

    address balVault = address(0x20dd72Ed959b6147912C2e529F0a0C651c33c9ce);

    address roosh = address(0x8BC110Db7029197C3621bEA8092aB1996D5DD7BE);
    address bob = address(0xbb);

    ERC20 usdc = ERC20(0x04068DA6C83AFCFA0e13ba15A6696662335D5B75);
    ERC20 dai = ERC20(0x8D11eC38a3EB5E956B052f67Da8Bdc9bef8Abf3E);

    bytes32 steadybeets2 = bytes32(0xecaa1cbd28459d34b766f9195413cb20122fb942000200000000000000000120);
    ERC20 steadybeets2lp = ERC20(0xeCAa1cBd28459d34B766F9195413Cb20122Fb942);
    ERC20 steadybeets2crypt = ERC20(0x77A495c99Df9d945Ca0D407eE04749cCDe6EEaa0);
    int256 init;

    function setUp() public {
        console.log(unicode"🧪 Testing Depositor...");
        depositor = new BeetsHelper(balVault);
        dummyToken = new DummyToken();
        dummyToken.mint(roosh, 100000000);
        testSingleSideDepositTakesTokens();
    }

    // VM Cheatcodes can be found in ./lib/forge-std/src/Vm.sol
    // Or at https://github.com/foundry-rs/forge-std
    function testSetup() public {
        //assertEq(dai.balanceOf(roosh), 100000000);
    }

    function testLogBalance() public {
        console.log(dai.balanceOf(roosh));
    }

    function testSingleSideDepositTakesTokens() public {
        vm.startPrank(roosh);
        init = int256(dai.balanceOf(address(roosh)));
        console.log(uint(init), "pre deposit dai");
        IAsset[] memory assets = new IAsset[](2);
        assets[0] = IAsset(address(usdc));
        assets[1] = IAsset(address(dai));
        BeetsHelper.VaultParams memory deposit = BeetsHelper.VaultParams(assets,
                                                                            1,
                                                                            steadybeets2,
                                                                            address(steadybeets2lp),
                                                                            address(steadybeets2crypt),
                                                                            roosh
                                                                            );
        dai.approve(address(depositor), 1e18);
        depositor._singleSideDeposit(deposit, 1e18);
        console.log(steadybeets2crypt.balanceOf(roosh), "post deposit crypt bal");
        console.log(uint256(init-int256(dai.balanceOf(roosh))), "post deposit dai delta");
        vm.stopPrank();
    }

    function testSingleSideWithdrawGetsTokens() public {
        vm.startPrank(roosh);
        IAsset[] memory assets = new IAsset[](2);
        assets[0] = IAsset(address(usdc));
        assets[1] = IAsset(address(dai));
        BeetsHelper.VaultParams memory withdraw = BeetsHelper.VaultParams(assets,
                                                                            1,
                                                                            steadybeets2,
                                                                            address(steadybeets2lp),
                                                                            address(steadybeets2crypt),
                                                                            roosh
                                                                            );
        ERC20((steadybeets2crypt)).approve(address(depositor), 1e33);
        depositor._singleSideWithdraw(withdraw, ERC20(steadybeets2crypt).balanceOf(roosh), 9e17);
        console.log(uint256(init-int256(dai.balanceOf(roosh))), "post withdraw dai delta");
        console.log(steadybeets2crypt.balanceOf(roosh), "post withdraw crypt bal");
        vm.stopPrank();
    }

}
