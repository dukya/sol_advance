// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract TestContractV1 is Initializable, UUPSUpgradeable, OwnableUpgradeable {
    uint256 public value;

    function initialize(uint256 initialVal) public initializer {
        __Ownable_init(address(0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266));
        __UUPSUpgradeable_init();
        value = initialVal;
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    function setValue(uint256 _value) public {
        value = _value;
    }
}
