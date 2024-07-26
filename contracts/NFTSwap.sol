// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

contract NFTSwap is IERC721Receiver {
    struct Order {
        address owner; // 当前持有人(卖方)信息
        uint256 price; // 卖方期望的售出价格
    }
    // 同一个系列的NFT合约地址中存在多个tokenId商品(包含卖方信息+售出价格)
    mapping(address => mapping(uint256 => Order)) public nftList;

    // 包含4个事件，对应挂单list、撤单revoke、修改价格update、购买purchase这四个行为
    event List(address indexed seller, address indexed nftAddr, uint256 indexed tokenId, uint256 price);
    event Purchase(address indexed buyer, address indexed nftAddr, uint256 indexed tokenId, uint256 price);
    event Revoke(address indexed seller, address indexed nftAddr, uint256 indexed tokenId);
    event Update(address indexed seller, address indexed nftAddr, uint256 indexed tokenId, uint256 newPrice);

    // 用户使用ETH购买NFT，需要接收转账的函数
    receive() external payable {}

    // 用户使用ETH购买NFT，需要接收转账的函数
    fallback() external payable {}

    // 挂单: 卖家上架NFT，合约地址为nftAddr，tokenId为tokenId，价格price为以太坊(单位是wei)
    // 授权NFTSwap交易所可以出售
    function list(address _nftAddr, uint256 _tokenId, uint256 _price) public {
        IERC721 _nft = IERC721(_nftAddr); // 声明IERC721接口合约变量
        require(_nft.getApproved(_tokenId) == address(this), "Need Approval"); // 合约得到授权(TODO:不清楚具体用法?)
        require(_price > 0); // 价格大于0

        Order storage _order = nftList[_nftAddr][_tokenId]; //设置NFT持有人和价格(引用方式storage进行修改)
        _order.owner = msg.sender;
        _order.price = _price;
        // 将NFT转账到NFTSwap合约
        _nft.safeTransferFrom(msg.sender, address(this), _tokenId);

        // 释放List事件
        emit List(msg.sender, _nftAddr, _tokenId, _price);
    }

    // 撤单： 卖家取消挂单
    function revoke(address _nftAddr, uint256 _tokenId) public {
        Order storage _order = nftList[_nftAddr][_tokenId]; // 取得Order订单
        require(_order.owner == msg.sender, "Not Owner"); // 必须由持有人发起
        // 声明IERC721接口合约变量
        IERC721 _nft = IERC721(_nftAddr);
        require(_nft.ownerOf(_tokenId) == address(this), "Invalid Order"); // NFT已被转移到当前NFTSwap合约中

        // 将NFT转给卖家
        _nft.safeTransferFrom(address(this), msg.sender, _tokenId);
        delete nftList[_nftAddr][_tokenId]; // 删除order订单(本周上只是将nftAddr->tokenId->Order置空，并不是真正删除吧)

        // 释放Revoke事件
        emit Revoke(msg.sender, _nftAddr, _tokenId);
    }

    // 调整价格: 卖家调整挂单价格
    function update(address _nftAddr, uint256 _tokenId, uint256 _newPrice) public {
        require(_newPrice > 0, "Invalid Price"); // NFT价格大于0
        Order storage _order = nftList[_nftAddr][_tokenId]; // 取得Order订单
        require(_order.owner == msg.sender, "Not Owner"); // 必须由持有人发起
        // 声明IERC721接口合约变量
        IERC721 _nft = IERC721(_nftAddr);
        require(_nft.ownerOf(_tokenId) == address(this), "Invalid Order"); // NFT已被转移到当前NFTSwap合约中

        // 调整NFT价格
        _order.price = _newPrice;

        // 释放Update事件
        emit Update(msg.sender, _nftAddr, _tokenId, _newPrice);
    }

    // 购买: 买家购买NFT，合约为_nftAddr，tokenId为_tokenId，调用函数时要附带ETH。payable可以接收转账
    function purchase(address _nftAddr, uint256 _tokenId) public payable {
        Order storage _order = nftList[_nftAddr][_tokenId]; // 取得Order订单
        require(_order.price > 0, "Invalid Price"); // NFT卖出的标价大于0
        require(msg.value >= _order.price, "Increase price"); // 购买价格大于等于标价
        // 声明IERC721接口合约变量
        IERC721 _nft = IERC721(_nftAddr);
        require(_nft.ownerOf(_tokenId) == address(this), "Invalid Order"); // NFT已被转移到当前NFTSwap合约中

        // 将NFT转给买家
        _nft.safeTransferFrom(address(this), msg.sender, _tokenId);
        // 将ETH转给卖家，多余ETH给买家退款
        payable(_order.owner).transfer(_order.price);
        payable(msg.sender).transfer(msg.value - _order.price);

        delete nftList[_nftAddr][_tokenId]; // 删除本次order订单

        // 释放Purchase事件
        emit Purchase(msg.sender, _nftAddr, _tokenId, _order.price);
    }

    // 实现IERC721Receiver的onERC721Received，能够接收ERC721代币
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external override returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }
}
