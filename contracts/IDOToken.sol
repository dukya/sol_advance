// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

// 定义一个合约继承自ERC20和Ownable
contract IDOToken is ERC20("IDO Token", "IDO"), Ownable(msg.sender) {
    // 定义公开的IDO价格，初始值为0.1ETH
    uint256 public constant idoPrice = 0.1 * 10 ** 18;

    // 定义公开的最大购买量，初始值为100ETH
    uint256 public constant maxBuyAmount = 100 * 10 ** 18;

    // 定义USDT代币的地址
    address public constant usdtAddress = 0x606D35e5962EC494EAaf8FE3028ce722523486D2;

    // 定义一个映射，记录该用户是否已经购买
    mapping(address => bool) private isBuy;

    // 定义购买和提款的事件
    event Purchase(address indexed buyer, uint256 tokenNum);
    event Withdraw(uint256 balance);

    // 定义一个购买代币的函数
    function buyToken(uint256 amount) external {
        // 确保用户还未购买过
        require(!isBuy[msg.sender], "You has already buy!");
        // 确保购买量不超过最大限制
        require(amount <= maxBuyAmount, "Invalid amount");

        // 从调用者地址转移amount价值的USDT到合约地址，用于购买新发行的IDO代币
        IERC20(usdtAddress).transferFrom(msg.sender, address(this), amount);
        // 计算IDO代币的实际购买数量
        uint256 buyNum = amount / idoPrice;
        // 标记用户已购买
        isBuy[msg.sender] = true;

        // 铸造新的IDO代币给调用者(购买人)
        _mint(msg.sender, buyNum);

        emit Purchase(msg.sender, buyNum);
    }

    // 定义一个仅限所有者调用的提现函数
    function withdraw() public onlyOwner {
        // 获取合约地址中的USDT余额
        uint256 balance = IERC20(usdtAddress).balanceOf(address(this));
        // 将USDT余额转移给合约所有者
        IERC20(usdtAddress).transfer(msg.sender, balance);

        emit Withdraw(balance);
    }
}
