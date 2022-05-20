/*
SPDX-License-Identifier: GPL-3.0


pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Strings.sol"; 
import "@openzeppelin/contracts/metatx/ERC2771Context.sol";

contract Toadz is ERC721Enumerable, Ownable, ReentrancyGuard, AccessControl {
    using SafeMath for uint256;
    using Address for address;
    using Address for address payable;

    uint256 public MAX_TOTAL_MINT;
    string private _contractURI;
    string public baseTokenURI;
    uint256 private _currentTokenId = 0;

    constructor(
    ) ERC721("AndromedaToadz", "ATOADZ") {
        MAX_TOTAL_MINT = 6969;
        baseTokenURI = "https://ipfs.io/ipfs/Qmdy8iFuiFALUQTPiBvLUkNCuR7Fzv9FbWAm1Dn8Eve4AN/"; // TEST ONLY
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    // ADMIN

    function setBaseURI(string memory _setBaseURI) external onlyOwner {
        baseTokenURI = _setBaseURI;
    }

    function setContractURI(string memory uri) external onlyOwner {
        _contractURI = uri;
    }

    function withdraw() private  {
        uint256 balance = address(this).balance;
        payable(0xBF04178395BA7329bf4F7209E03f290e8aA85115).transfer(balance);
    }

    // PUBLIC
    
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
    public
    view
    virtual
    override(AccessControl, ERC721Enumerable)
    returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    // function totalSupply() public view returns (uint256) {
    //     return _currentTokenId;
    // }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function contractURI() public view returns (string memory) {
        return _contractURI;
    }

    
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, Strings.toString(tokenId), ".json")) : "";
    }

    function getInfo() external view returns (
        uint256,
        uint256,
        uint256
    ) {
        return (
        this.totalSupply(),
        msg.sender == address(0) ? 0 : this.balanceOf(msg.sender),
        MAX_TOTAL_MINT
        );
    }

    /**
     * Accepts required payment and mints a specified number of tokens to an address.
     */
    function purchase(uint256 count) public payable nonReentrant {

        uint256 price;


        if (count >= 1) {
            price = 1 ether; // 0.420
        }

        // Make sure minting is allowed
        requireMintingConditions(count);

        // Sent value matches required ETH amount
        require(price * count <= msg.value, "ERC721_COLLECTION/INSUFFICIENT_ETH_AMOUNT");

        for (uint256 i = 0; i < count; i++) {
            uint256 newTokenId = _getNextTokenId();
            _safeMint(msg.sender, newTokenId);
            _incrementTokenId();
        }

        
        withdraw();
    }

    // PRIVATE

    /**
     * This method checks if ONE of these conditions are met:
     *   - Public sale is active.
     *   - Pre-sale is active and receiver is allowlisted.
     *
     * Additionally ALL of these conditions must be met:
     *   - Gas fee must be equal or less than maximum allowed.
     *   - Newly requested number of tokens will not exceed maximum total supply.
     */
    function requireMintingConditions(uint256 count) internal view {

        // Total minted tokens must not exceed maximum supply
        require(totalSupply() + count <= MAX_TOTAL_MINT, "ERC721_COLLECTION/EXCEEDS_MAX_SUPPLY");
    }

    /**
     * Calculates the next token ID based on value of _currentTokenId
     * @return uint256 for the next token ID
     */
    function _getNextTokenId() private view returns (uint256) {
        return _currentTokenId.add(1);
    }

    /**
     * Increments the value of _currentTokenId
     */
    function _incrementTokenId() private {
        _currentTokenId++;
    }
}
