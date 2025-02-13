// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IVault {
    function getPricePerFullShare() external view returns (uint256);
    function depositAll() external;
    function withdrawAll() external;
}
