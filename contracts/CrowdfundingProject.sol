// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

contract CrowdfundingProject {
    // 项目状态枚举
    enum ProjectState {
        Ongoing, // 进行中
        Successful, // 成功
        Failed // 失败
    }

    // 捐赠者结构
    struct Donation {
        address donor; // 捐赠者地址
        uint256 amount; // 捐赠金额
    }

    address public creator; // 项目创建者地址
    string public description; // 项目描述
    uint256 public goalAmount; // 项目需要募集的目标金额
    uint256 public deadline; // 项目截止日期(时间戳)
    uint256 public currentAmount; // 当前募集的资金
    ProjectState public state; // 当前项目的状态
    Donation[] public donations; // 记录捐赠者的动态数组

    // 事件汇总
    event DonationReceived(address indexed donor, uint256 amount); // 捐赠事件
    event ProjectStateChanged(ProjectState newState); // 项目状态改变事件
    event FundsWithdrawn(address indexed creator, uint256 amount); // 募集资金提取事件
    event FundsRefunded(address indexed donor, uint256 amount); // 募集资金撤回事件

    // 修饰符(当前项目创建者)
    modifier onlyCreator() {
        require(msg.sender == creator, "Not the project creator");
        _;
    }

    // 修饰符(当前项目已逾期)
    modifier onlyAfterDeadline() {
        require(block.timestamp >= deadline, "Project is still ongoing");
        _;
    }

    // 初始化项目(创建者地址、项目描述、目标金额和截止时间)
    function initialize(address _creator, string memory _description, uint256 _goalAmount, uint256 _duration) public {
        creator = _creator;
        description = _description;
        goalAmount = _goalAmount;
        deadline = block.timestamp + _duration;
        state = ProjectState.Ongoing; // 项目进行中
    }

    // 接收捐赠的函数(捐赠者进行调用)
    function donate() external payable {
        // 确保项目还在进行中并且未到期
        require(state == ProjectState.Ongoing, "Project is not ongoing");
        require(block.timestamp < deadline, "Project deadline has passed");
        require(currentAmount < goalAmount, "Project has reached goal");

        // 添加捐赠者信息(TODO:每个捐赠者可以捐赠多次，每次新产生信息)
        donations.push(Donation({donor: msg.sender, amount: msg.value}));
        // 更新当前项目的已募集金额
        currentAmount += msg.value;

        emit DonationReceived(msg.sender, msg.value);
    }

    // 创建人提取募集资金(创建人在项目逾期后才能提现)
    function withdrawFunds() external onlyCreator onlyAfterDeadline {
        require(state == ProjectState.Successful, "Project is not successful");

        uint256 amount = address(this).balance;
        payable(creator).transfer(amount);

        emit FundsWithdrawn(creator, amount);
    }

    // 逾期退还已募集的资金(捐赠者调用)
    function refund() external onlyAfterDeadline {
        require(state == ProjectState.Failed, "Project is not failed");

        uint256 totalRefund = 0;
        // 遍历捐赠者列表并合并同一捐赠者的总捐赠金额
        for (uint256 i = 0; i < donations.length; i++) {
            if (donations[i].donor == msg.sender) {
                totalRefund += donations[i].amount;
                donations[i].amount = 0; // Mark as refunded
            }
        }

        require(totalRefund > 0, "No funds to refund");

        // 返还给对应捐赠者
        payable(msg.sender).transfer(totalRefund);

        emit FundsRefunded(msg.sender, totalRefund);
    }

    // 在项目逾期后更新项目的状态
    function updateProjectState() external onlyAfterDeadline {
        // 确保项目在进行中
        require(state == ProjectState.Ongoing, "Project is already finalized");

        // 若未达到募集金额，设置失败，否则设置成功
        if (currentAmount >= goalAmount) {
            state = ProjectState.Successful;
        } else {
            state = ProjectState.Failed;
        }

        emit ProjectStateChanged(state);
    }
}
