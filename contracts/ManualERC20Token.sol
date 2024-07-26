// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/*
实现一个符合ERC-20标准的简单代币合约
功能需求:
1、代币基本信息
代币名称、代币符号、代币小数点位数、代币总供应量
2、账户余额查询
可以查询指定地址的代币余额
3、授权机制
允许用户授权第三方账户代表自己支配一定数量的代币
4、转账功能
从一个地址向另一个地址直接转移代币
从一个地址向另一个地址授权转移代币
5、代币增发和销毁
代币增发：合约所有者可以增加代币供应量。
代币销毁：合约所有者可以销毁一定数量的代币。
6、事件通知
转账事件：当代币转移时触发
授权事件：当授权额度变化时触发
*/
contract ManualERC20Token {
    // 代币名称
    string private _name;
    // 代币符号
    string private _symbol;
    // 代币总供应量
    uint256 private _totalSupply;
    // 账户余额映射 transferor -> balance
    mapping(address => uint256) private _balances;
    // 授权额度映射 transferor_addr -> {thirdparty_addr -> allowance}
    mapping(address => mapping(address => uint256)) private _allowances;
    // 合约所有者
    address public owner;

    // 转账事件
    event Transfer(address indexed from, address indexed to, uint256 value);
    // 授权事件
    event Approval(address indexed owner, address indexed spender, uint256 value);

    // 构造函数，初始化代币名称、符号和当前合约的所有者
    constructor() {
        _name = "ManualERC20";
        _symbol = "MERC20";
        owner = msg.sender;
    }

    // 修饰符，限制只有合约所有者可以调用某些函数
    modifier onlyOwner() {
        require(msg.sender == owner, "Not the owner");
        _;
    }

    // 返回代币名称
    function name() public view returns (string memory) {
        return _name;
    }

    // 返回代币符号
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    // 返回代币小数点位数，这里固定为18
    function decimals() public pure returns (uint8) {
        return 18;
    }

    // 返回代币总供应量
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    // 返回指定地址的代币余额
    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    // 返回指定地址允许另一地址(三方账户)支配的代币数量
    function allowance(address from, address spender) public view returns (uint256) {
        return _allowances[from][spender];
    }

    // 授权第三方账户支配自己一定数量的代币(转出方调用)
    function approve(address spender, uint256 amount) public {
        _allowances[msg.sender][spender] += amount;
        emit Approval(msg.sender, spender, amount);
    }

    // 从调用者地址向另一个地址直接转移代币(转出方调用)
    function transfer(address to, uint256 amount) public {
        require(_balances[msg.sender] >= amount, "Insufficient balance");
        _balances[msg.sender] -= amount;
        _balances[to] += amount;
        emit Transfer(msg.sender, to, amount);
    }

    // 从一个地址向另一个地址转移代币(需要事先授权，第三方账户调用)
    function transferFrom(address from, address to, uint256 amount) public {
        uint256 _allowance = _allowances[from][msg.sender]; // 获取授权额度值
        require(_allowance >= amount, "Allowance exceeded");
        require(_balances[from] >= amount, "Insufficient balance");

        _balances[from] -= amount;
        _balances[to] += amount;
        _allowances[from][msg.sender] -= amount;
        emit Transfer(from, to, amount);
    }

    // 增加指定地址的代币数量(代币增发)，只有合约所有者可以调用
    function mint(address account, uint256 amount) public onlyOwner {
        _balances[account] += amount; // 指定地址的代币数量增加
        _totalSupply += amount; // 代币总发行量也增加
        emit Transfer(address(0), account, amount);
    }

    // 销毁指定地址的代币数量(代币销毁)，只有合约所有者可以调用
    function burn(address account, uint256 amount) public onlyOwner {
        require(_totalSupply >= amount, "Insufficient total balance to burn");
        require(_balances[account] >= amount, "Insufficient balance to burn");
        _balances[account] -= amount; // 指定地址的代币数量减少
        _totalSupply -= amount; // 代币总发行量减少
        emit Transfer(account, address(0), amount);
    }
}
