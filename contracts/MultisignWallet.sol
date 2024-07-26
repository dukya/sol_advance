// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

contract MultiSignWallet {
    address[] public owners; // 多签持有人的动态数组
    mapping(address => bool) public isOwner; // 记录一个地址是否为多签持有人(address->bool)
    uint256 public ownerCount; // 多签持有人的数量(TODO:直接读取owners.length可以吗？省gas吗？)
    uint256 public threshold; // 多签执行门槛，交易至少有n个多签人签名才能被执行。
    uint256 public nonce; // nonce，防止签名重放攻击

    // 参数均为交易哈希值
    event ExecutionSuccess(bytes32 txHash); // 交易成功事件
    event ExecutionFailure(bytes32 txHash); // 交易失败事件

    // 构造函数，初始化owners, isOwner, ownerCount, threshold
    // 实际传参为多签人数组和执行阈值
    constructor(address[] memory _owners, uint256 _threshold) {
        _setupOwners(_owners, _threshold);
    }

    /// @dev 初始化owners, isOwner, ownerCount,threshold
    /// @param _owners: 多签持有人数组
    /// @param _threshold: 多签执行门槛
    function _setupOwners(address[] memory _owners, uint256 _threshold) internal {
        // 确保threshold没被初始化过
        require(threshold == 0, "DQ5000");
        // 确保多签执行门槛小于多签人数
        require(_threshold <= _owners.length, "DQ5001");
        // 确保多签执行门槛至少为1
        require(_threshold >= 1, "DQ5002");

        for (uint256 i = 0; i < _owners.length; i++) {
            address owner = _owners[i];
            // 多签人不能为0地址，并且本合约地址不能重复
            require(owner != address(0) && owner != address(this) && !isOwner[owner], "DQ5003");
            owners.push(owner); // 添加到多签人动态数组中
            isOwner[owner] = true; // 设置该地址为多签人之一
        }
        ownerCount = _owners.length; // 记录多签人数(只部署合约时赋值，后续应该会少花费gas)
        threshold = _threshold;
    }

    /// @dev 编码交易数据(纯功能函数)
    /// @param to 目标合约地址
    /// @param value msg.value，支付的以太币
    /// @param data calldata
    /// @param _nonce 交易的nonce.
    /// @param chainid 链id
    /// @return 交易哈希值(bytes32)
    /// 将交易数据打包并计算哈希，然后在链下让多签人签名并收集得到打包签名，最终再调用execTransaction()函数执行
    function encodeTransactionData(
        address to,
        uint256 value,
        bytes memory data,
        uint256 _nonce,
        uint256 chainid
    ) public pure returns (bytes32) {
        // 交易数据打包成原始消息的格式可以自定义(协商好即可)
        bytes32 safeTxHash = keccak256(abi.encode(to, value, keccak256(data), _nonce, chainid));
        return safeTxHash;
    }

    /// @dev 将单个签名从打包的签名分离出来(纯功能函数)
    /// @param signatures 打包签名
    /// @param pos 要读取的多签index
    /// 将单个签名从打包的签名分离出来，参数分别为打包签名signatures和要读取的签名位置pos。
    function signatureSplit(
        bytes memory signatures,
        uint256 pos
    ) internal pure returns (uint8 v, bytes32 r, bytes32 s) {
        // 签名的格式：{bytes32 r}{bytes32 s}{uint8 v}
        // 0x41 = 65
        // 0x20 = 32
        // 0x40 = 64
        assembly {
            let signaturePos := mul(0x41, pos)
            r := mload(add(signatures, add(signaturePos, 0x20)))
            s := mload(add(signatures, add(signaturePos, 0x40)))
            v := and(mload(add(signatures, add(signaturePos, 0x41))), 0xff)
        }
    }

    /**
     * @dev 检查签名和交易数据是否对应。如果是无效签名，交易会revert
     * @param dataHash 交易数据哈希
     * @param signatures 几个多签签名打包在一起
     */
    function checkSignatures(bytes32 dataHash, bytes memory signatures) public view {
        // 读取多签执行门槛
        uint256 _threshold = threshold; // 先读取出来，减少gas消耗
        require(_threshold > 0, "DQ5004");
        // 检查签名长度足够长(单个签名长度为65字节)
        require(signatures.length >= _threshold * 65, "DQ5005");

        // 通过一个循环，检查收集的签名是否有效
        // 大概思路：
        // 1. 用ecdsa先验证签名是否有效
        // 2. 利用currentOwner > lastOwner确定签名来自不同多签(此处假设多签地址是递增的)
        // 3. 利用isOwner[currentOwner]确定签名者为多签持有人
        address lastOwner = address(0);
        address currentOwner;
        uint8 v;
        bytes32 r;
        bytes32 s;
        uint256 i;
        for (i = 0; i < _threshold; i++) {
            (v, r, s) = signatureSplit(signatures, i); //分离出单个签名数据
            // 利用ecrecover检查签名是否有效(原始交易数据哈希需先转换成以太坊签名消息再根据signature恢复出该签名的公钥地址)
            currentOwner = ecrecover(
                keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", dataHash)),
                v,
                r,
                s
            );
            require(currentOwner > lastOwner && isOwner[currentOwner], "DQ5006");
            lastOwner = currentOwner;
        }
    }

    /// @dev 在收集足够的多签签名后，执行交易
    /// @param to 目标合约地址
    /// @param value msg.value，支付的以太坊
    /// @param data calldata
    /// @param signatures 链下的打包签名，对应的多签地址由小到大，方便检查。 ({bytes32 r}{bytes32 s}{uint8 v}) (第一个多签的签名, 第二个多签的签名 ... )
    function execTransaction(
        address to,
        uint256 value,
        bytes memory data,
        bytes memory signatures
    ) public payable virtual returns (bool success) {
        // 编码交易数据，计算哈希(交易数据转换成自定义原始消息)
        bytes32 txHash = encodeTransactionData(to, value, data, nonce, block.chainid);
        nonce++; // 增加nonce值(相当于交易ID编号)
        checkSignatures(txHash, signatures); // 检查多个签名
        // 利用call执行交易，并获取交易结果
        (success, ) = to.call{value: value}(data); // to需要变成payable(to)吗?
        require(success, "DQ5007");
        if (success) {
            emit ExecutionSuccess(txHash);
        } else {
            emit ExecutionFailure(txHash); // 这一步执行不到 unreachable
        }
    }
}
