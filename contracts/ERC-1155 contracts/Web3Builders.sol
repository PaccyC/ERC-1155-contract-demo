// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.27;

import {ERC1155} from "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import {ERC1155Pausable} from "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Pausable.sol";
import {ERC1155Supply} from "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/finance/VestingWallet.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract Web3Builders is ERC1155, Ownable, ERC1155Pausable, ERC1155Supply, VestingWallet {
    
    constructor(
        address initialOwner, 
        address beneficiary, 
        uint64 durationSeconds
    ) 
        ERC1155("ipfs://Qmaa6TuP2s9pSKczHF4rwWhTKUdygrrDs8RmYYqCjP3Hye/") 
        VestingWallet(beneficiary, uint64(block.timestamp), durationSeconds)  // Correct constructor call
    {
        transferOwnership(initialOwner);  // Ensure the deployer is the initial owner
    }
    
    uint256 public publicPrice = 0.02 ether;    
    uint256 public publicAllowListPrice = 0.01 ether;
    uint256 public maxSupply = 15;
    uint256 public maxPurchasesPerAddress = 4;

    bool allowListMintOpen;
    bool publicMintOpen;

    mapping(address => bool) allowList;
    mapping(address => uint256) numberOfPurchases;

    function setURI(string memory newuri) public onlyOwner {
        _setURI(newuri);
    }

    function uri(uint256 _id) public view virtual override returns (string memory) {
        require(exists(_id), "URI does not exist");
        return string(abi.encodePacked(super.uri(_id), Strings.toString(_id), ".json"));
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function edit(bool _allowListMintOpen, bool _publicMintOpen) external onlyOwner {
        allowListMintOpen = _allowListMintOpen;
        publicMintOpen = _publicMintOpen;
    }

    function setAllowList(address[] calldata addresses) external onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            allowList[addresses[i]] = true;
        }
    }
    
    function mint(uint256 id, uint256 amount) internal {
        require(numberOfPurchases[msg.sender] + amount <= maxPurchasesPerAddress, "You have reached the maximum number of NFTs you can mint");
        require(id < 2, "You are trying to mint the wrong NFT.");
        require(totalSupply(id) * amount < maxSupply, "No remaining NFTs");
        numberOfPurchases[msg.sender] += amount;
        _mint(msg.sender, id, amount, "");
    }

    function allowListMint(uint256 id, uint256 amount) public payable {
        require(allowListMintOpen, "Sorry! AllowList mint is not open");
        require(allowList[msg.sender], "Sorry! You are not allowed to mint. Try public mint");
        require(msg.value == publicAllowListPrice * amount, "Insufficient balance");
        mint(id, amount);
    }

    function publicMint(uint256 id, uint256 amount) public payable {
        require(publicMintOpen, "Sorry! Public mint is not open");
        require(msg.value == publicPrice * amount, "Insufficient balance");
        mint(id, amount);
    }

    function withdraw(address _addr) external onlyOwner {
        uint256 balance = address(this).balance;
        payable(_addr).transfer(balance);
    }

    function mintBatch(address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data) public onlyOwner {
        _mintBatch(to, ids, amounts, data);
    }

    // The following functions are overrides required by Solidity.
    function _update(address from, address to, uint256[] memory ids, uint256[] memory values)
        internal
        override(ERC1155, ERC1155Pausable, ERC1155Supply)
    {
        super._update(from, to, ids, values);
    }
}
