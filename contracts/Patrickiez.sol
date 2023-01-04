// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Address.sol";


contract Patrickiez is ERC721A, Ownable {
    using Address for address payable;
    using Strings for uint256;

    // =============================================================
    //                     STORAGE
    // =============================================================

    uint immutable public maxSupply = 20;
    uint public price = 0.01 ether;
    uint public whitelistPrice = 0.001 ether;
    uint public maxMintPerTx = 5;

    string private baseURI;

    address payable private paymentReceiver;

    mapping(address => bool) public whitelisted;
    mapping(address => uint) whitelistMintCount;
    mapping(address => uint) publicMintCount;

    bool public whitelistOpen = false;
    bool public mintOpen = false;

    // =============================================================
    //                     CONSTRUCTOR
    // =============================================================

    constructor() ERC721A("Patrickiez", "PTRKZ") {
        paymentReceiver = payable(msg.sender);
        assert(paymentReceiver != address(0));
    }

    // =============================================================
    //                     FUND MANAGEMENT
    // =============================================================

    receive() external payable {
        paymentReceiver.sendValue(msg.value);
    }

    function withdraw() public onlyOwner {
        uint contractBalance = address(this).balance;
        require(contractBalance > 0, "Contract is empty!");
        paymentReceiver.sendValue(contractBalance);
    }

    // =============================================================
    //                     MINT FUNCTIONS
    // =============================================================
    
    function whitelistMint(uint _amount) external payable {
        require(whitelistOpen, "Whitelist mint is closed");
        require(whitelisted[msg.sender], "User is not whitelisted!");
        require(whitelistMintCount[msg.sender] + _amount <= 3, "Only 3 Tokens per whitelist spot!");
        require(msg.value >= (whitelistPrice * _amount), "Insufficient Funds!");

        whitelistMintCount[msg.sender] += _amount;

        paymentReceiver.sendValue(msg.value);
        _safeMint(msg.sender, _amount, "");
    }

    function mint(uint _amount) external payable {
        require(mintOpen, "Public mint is closed");
        require(_amount <= maxMintPerTx, "Only 3 Tokens per whitelist spot!");
        require(msg.value >= (price * _amount), "Insufficient Funds!");

        publicMintCount[msg.sender] += _amount;

        paymentReceiver.sendValue(msg.value);
        _safeMint(msg.sender, _amount, "");
    }

    // =============================================================
    //                     TOKEN URI OPERATIONS
    // =============================================================
    
    //returns full URI
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI, _toString(tokenId),".json")) : '';
    }

    //updates the current URI variable
    function updateURI(string memory _newURI) external onlyOwner {
        baseURI = _newURI;
    }

    // =============================================================
    //                     MINT STATE OPERATIONS
    // =============================================================

    //whitelists new users
    function whitelist(address _user) external onlyOwner {
        require(whitelisted[_user] == false, "User is already whitelisted!");
        whitelisted[_user] = true;
    }

    //flips the whitelist open and closed
    function updateWhitelistMint() external onlyOwner {
        whitelistOpen = !whitelistOpen;
    }

    //flips the public mint open and closed
    function updatePublicMint() external onlyOwner {
        mintOpen = !mintOpen;
    }

    // =============================================================
    //                     UPDATED OPERATIONS
    // =============================================================

    //Override ensures Token IDs start from 1 instead of 0
    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }


}