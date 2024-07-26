// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";

contract SignatureNFT is ERC721 {
    address public immutable signer; // 签名地址(项目方的公钥地址)
    mapping(address => bool) public mintedAddress; // 记录已经mint的地址

    // 构造函数，初始化NFT合集的名称、代号、签名地址(主要是项目方公钥地址传入)
    constructor(string memory _name, string memory _symbol, address _signer) ERC721(_name, _symbol) {
        signer = _signer;
    }

    // 利用ECDSA验证签名并mint(传入地址、token_id和链下计算生成的白名单签名)
    // 用户需请求中心化接口去获取签名，同时白名单可以动态变化(传入account+token_id让项目方发送数字签名，类似于web2时代的token机制)
    function mint(address _account, uint256 _tokenId, bytes memory _signature) external {
        bytes32 _msgHash = getMessageHash(_account, _tokenId); // 将_account和_tokenId打包消息
        // MessageHashUtils库计算以太坊签名消息
        bytes32 _ethSignedMessageHash = MessageHashUtils.toEthSignedMessageHash(_msgHash);

        require(verify(_ethSignedMessageHash, _signature), "Invalid signature"); // ECDSA检验签名通过
        require(!mintedAddress[_account], "Already minted!"); // 确保该地址没有mint过
        _mint(_account, _tokenId); // 该地址可以进行mint铸币操作(即该地址已经在NFT的白名单中)
        mintedAddress[_account] = true; // 记录mint过的地址
    }

    /*
     * 将mint地址（address类型）和tokenId（uint256类型）拼成消息msgHash
     * _account: 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4
     * _tokenId: 0
     * 对应的消息: 0x1bf2c0ce4546651a1a2feb457b39d891a6b83931cc2454434f39961345ac378c
     */
    function getMessageHash(address _account, uint256 _tokenId) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(_account, _tokenId));
    }

    // ECDSA验证，调用ECDSA库的verify()函数
    // 通过以太坊签名消息和签名内容反向计算出项目方的公钥地址并验证是否有效
    function verify(bytes32 _msgHash, bytes memory _signature) public view returns (bool) {
        address recovered = ECDSA.recover(_msgHash, _signature);
        return recovered == signer;
    }
}
