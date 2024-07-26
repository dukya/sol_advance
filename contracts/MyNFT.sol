// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "./MyERC721.sol";

contract MyNFT is MYERC721 {
    uint256 public constant MAX_APES = 10000; // 总量

    // 构造函数
    constructor(string memory name_, string memory symbol_) MYERC721(name_, symbol_) {}

    // MyNFT的baseURI为ipfs://QmeSjSinHpPnmXmspMjwiXyN6zS4E9zccariGR3jxcaWtq/
    function _baseURI() internal pure override returns (string memory) {
        return "ipfs://QmeSjSinHpPnmXmspMjwiXyN6zS4E9zccariGR3jxcaWtq/";
    }

    // 铸造函数
    function mint(address to, uint256 tokenId) external {
        require(tokenId >= 0 && tokenId < MAX_APES, "tokenId out of range");
        _mint(to, tokenId);
    }
}
