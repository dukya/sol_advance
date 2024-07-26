// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "./CrowdfundingProject.sol";

contract CrowdfundingPlatformV2 is Initializable, UUPSUpgradeable, OwnableUpgradeable {
    address[] public projects;

    event ProjectCreated(
        address projectAddress,
        address creator,
        string description,
        uint256 goalAmount,
        uint256 deadline
    );

    // 初始化众筹平台合约
    function initialize(address initialOwner) public initializer {
        __Ownable_init(initialOwner);
        __UUPSUpgradeable_init();
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    // 创建一个新的众筹项目(项目创建者进行调用)
    function createProject(string memory _description, uint256 _goalAmount, uint256 _duration) public {
        CrowdfundingProject newProject = new CrowdfundingProject();
        newProject.initialize(msg.sender, _description, _goalAmount, _duration + 10); // 初始化项目
        projects.push(address(newProject)); // 保存项目地址

        emit ProjectCreated(
            address(newProject),
            msg.sender,
            _description,
            _goalAmount,
            block.timestamp + _duration + 10
        );
    }

    function getProjects() public view returns (address[] memory) {
        return projects; // 进行拷贝操作
    }
}
