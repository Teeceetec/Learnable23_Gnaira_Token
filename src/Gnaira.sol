// Layout of Contract:
// version
// imports
// errors
// interfaces, libraries, contracts
// Type declarations
// State variables
// Events
// Modifiers
// Functions

// Layout of Functions:
// constructor
// receive function (if exists)
// fallback function (if exists)
// external
// public
// internal
// private
// view & pure functions

// SPDX-License-Identifier: UNLICENSED

/**
 * @title GNaira contract
 * @author Tochukwu Onyia
 * @notice this is a multi-signature contract that allows only the registerd addresses to to approve the contract to minr, burn , and execute transaction.
 *
 */
pragma solidity ^0.8.25;

/**
 * Imports from openzeppelin contracts
 */
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Gnaira is ERC20 {
    /**
     * Errors
     */
    error TRANSACTION_NOT_CONFIRMED_BY_OWNER();
    error YOURE_NOT_THE_OWNER();
    error INVALID_OWNERS_ADDRESS();
    error REQUIREMENTS_IS_HIGHER_THAN_NUMBER_OF_OWNERS();
    error ADDRESS_NOT_IN_BLACKLIST();
    error YOUR_ADDRESS_WAS_BLACKLISTED();
    error OWNER_ALREADY_EXISTS();
    error YOURE_NOT_THE_GOVERNOR();
    error NUMBER_OF_REQUIRED_OWNERS_NOT_REACHED();

    /**
     * Type Declaration
     */
    mapping(address => bool) public confirmations;
    mapping(address => bool) public isOwner;
    mapping(address => bool) public blacklisted;
    mapping(address => uint256) public balnces;

    /**
     * State Variables
     */
    address[] private i_owners;
    uint256 public s_required;
    address public s_governor;
    uint256 private s_totalSupply = 1000000;

    /**
     * Events
     */
    event Confirmation(address indexed owner);
    event Revocation(address indexed owner);
    event Execution(uint256 indexed transactionId);
    event ExecutionFailure(uint256 indexed transactionId);
    event DepositToken(address indexed token, uint256 amount);
    event OwnerAddition(address indexed owner);
    event OwnerRemoval(address indexed owner);
    event NumberOfRequirementChange(uint256 required);
    event RequirementChange(uint256 required);

    /**
     * Modifiers
     */
    //also made here
    modifier confirmed(address owner) {
        require(confirmations[owner], "Transaction has not been confirmed by owner");
        _;
    }
    //Changes made here

    modifier notConfirmed(address owner) {
        require(!confirmations[owner], "Transactions already confirmed by owners");
        _;
    }

    modifier onlyOwners() {
        if (!isOwner[msg.sender]) {
            revert YOURE_NOT_THE_OWNER();
        }
        _;
    }

    modifier onlyGovernor() {
        if (s_governor != msg.sender) {
            revert YOURE_NOT_THE_GOVERNOR();
        }
        _;
    }

    constructor(address[] memory _owners, uint256 _required) ERC20("GNAIRA", "GN") {
        s_governor = msg.sender;
        for (uint256 i = 0; i < _owners.length; i++) {
            address owners = _owners[i];
            if (owners == address(0)) {
                revert INVALID_OWNERS_ADDRESS();
            }

            isOwner[owners] = true;
        }
        i_owners = _owners;
        s_required = _required;
        _mint(msg.sender, s_totalSupply);
    }

    function confirmTransaction() public onlyOwners notConfirmed(msg.sender) {
        confirmations[msg.sender] = true;
        emit Confirmation(msg.sender);
    }

    function revokeConfirmation() public onlyOwners confirmed(msg.sender) {
        confirmations[msg.sender] = false;
        emit Revocation(msg.sender);
    }

    /**
     * @notice this function is called to get the confirmation count of the  owners.
     */
    function isConfirmed() public view returns (bool) {
        uint256 count = 0;

        for (uint256 i = 0; i < i_owners.length; i++) {
            if (confirmations[i_owners[i]]) {
                count += 1;
            }
            if (count == s_required) {
                return true;
            }
        }
        return false;
    }

    /**
     * @notice this function allows new owners to be added in the list of multi-signature wallet owners, and its made public for testing purposes.
     */
    function addOwner(address owner) public {
        if (isOwner[owner]) {
            revert OWNER_ALREADY_EXISTS();
        }
        i_owners.push(owner);
        isOwner[owner] = true;
        emit OwnerAddition(owner);
        changeRequirement(s_required + 1);
    }
    /**
     * @notice this function allows an owner to be removed in the list of multi-signature wallet owners, and its made public for testing purposes.
     */

    function removeOwner(address owner) public {
        isOwner[owner] = false;
        for (uint256 i = 0; i < i_owners.length; i++) {
            if (i_owners[i] == owner) {
                i_owners[i] == i_owners[i_owners.length - 1];
                i_owners.pop();
                break;
            }
        }
        changeRequirement(s_required - 1);
    }

    /**
     * @notice this function is called to change number of required counts needed for an action like burn and mint to b called.You can switch it to 1 count for faster testing.
     */
    function changeRequirement(uint256 _required) public onlyOwners {
        if (_required > i_owners.length) {
            revert REQUIREMENTS_IS_HIGHER_THAN_NUMBER_OF_OWNERS();
        }
        s_required = _required;
        emit RequirementChange(_required);
    }

    /**
     * @notice this function is used to mint new tokens to the specified address and amount , this can only be called and controlled by the governor.
     */
    function mint(address to, uint256 amount) public onlyGovernor {
        _mint(to, amount);
    }

    /**
     * @notice this function is can only be called and called by the multi-signature wallets, before minting it must be confirmed by other owners.
     */
    function multiSigMint(address to, uint256 amount) public onlyOwners {
        if (!isConfirmed()) {
            revert NUMBER_OF_REQUIRED_OWNERS_NOT_REACHED();
        } else {
            _mint(to, amount);
        }
    }

    /**
     * @notice this function is a burn functions that burns a certain amount of token from the specified walled address and can only be called by the governor account.
     */
    function burn(address from, uint256 amount) public onlyGovernor {
        _burn(from, amount);
    }

    /**
     * @notice this function is can only be called and called by the multi-signature wallets, before burning it must be confirmed by other owners.
     */
    function multiSigBurn(address from, uint256 amount) public onlyOwners {
        if (!isConfirmed()) {
            revert NUMBER_OF_REQUIRED_OWNERS_NOT_REACHED();
        } else {
            _burn(from, amount);
        }
    }

    /**
     * @notice this function is used to add marked addresses in the blacklist, when added, the address won't be able to send or receive tokens.
     */
    function blacklist(address member) public onlyGovernor {
        blacklisted[member] = true;
    }

    /**
     * @notice this function is used to check if an address is in the blacklist, when added, the address won't be able to transact the tokens.
     */
    function isBlacklisted(address member) public view returns (bool) {
        return blacklisted[member];
    }

    /**
     * @notice this function check if the address is an owner and returns true, if not part of the owner would return false.
     */
    function isOwnersT(address owner) public view returns (bool) {
        return isOwner[owner];
    }

    /**
     * @notice This function is used to check if the user is blacklisted, if true then the governor can remove the blacklisted address of choice.
     */
    function removeFromBlackList(address member) public onlyGovernor {
        if (!blacklisted[member]) {
            revert ADDRESS_NOT_IN_BLACKLIST();
        } else {
            blacklisted[member] = false;
        }
    }

    /**
     * @notice this function is used to check if  the address is in the blacklist list and if so return true otherwise allow the user to send token to other addresses and amount of choice.
     */
    function transfer(address to, uint256 amount) public override returns (bool) {
        if (isBlacklisted(msg.sender) && isBlacklisted(to)) {
            revert YOUR_ADDRESS_WAS_BLACKLISTED();
        }

        return super.transfer(to, amount);
    }

    /**
     * @notice this function allows the governor role to be changed, its made public for testing purposes only.
     */
    function changeGovernor(address newGovernor) public {
        s_governor = newGovernor;
    }

    /**
     * Getters Function
     */
    function getOwners() external view returns (address[] memory) {
        return i_owners;
    }

    function getRequiredNumberOfApproval() external view returns (uint256) {
        return s_required;
    }

    function getGovernor() external view returns (address) {
        return s_governor;
    }

    function getTotalSupply() external view returns (uint256) {
        return s_totalSupply;
    }
}
