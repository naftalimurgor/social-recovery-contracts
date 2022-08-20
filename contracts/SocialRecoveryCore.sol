// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.0;

import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {OwnableUnset} from "@erc725/smart-contracts/contracts/custom/OwnableUnset.sol";

import "./ISocialRecovery.sol";

abstract contract SocialRecoveryCore is ISocialRecovery, OwnableUnset {
  using EnumerableSet for EnumerableSet.AddressSet;
  
  /// List of superGuardians
  EnumerableSet.AddressSet internal _superGuardians;

  /// secret phrase for obtaining signatures.
  bytes32 internal _secretPhraseHash;

  /// @dev superGuardians is a mapping of guardian address to set of signatures.
  mapping (address =>  string) internal _superGuardiansSignatures;

  /// @dev throws for if non-superguardian tries to call methods restricted to superGuardian.
  modifier onlySuperGuardian(address superGuardian) {
    require(_superGuardians.contains(superGuardian), "Caller Must be a superGuardian");
    _;
  }

  /// @dev throws if a non-existent guardian tries to add new signatures.
  modifier superGuardianExists(address superGuardian) {
    require(_superGuardians.contains(superGuardian), "Only super guardians can add new signatures");
    _;
  }

  /// @dev set a new _secretHash.
  function setScretHash(bytes32 secretHash) external onlyOwner {
    _secretPhraseHash = secretHash;
  }

  /// @dev add new superGuardian signature.
  function addGuardianSignature(address superGuardian,  string memory signature) 
  onlyOwner superGuardianExists(superGuardian) 
  public virtual {
    _superGuardiansSignatures[superGuardian] = signature;
  }

  /// @dev removes an existing superGuardians signature.
  function removeGuardianSignature(address superGuardian) 
   onlyOwner 
   superGuardianExists(superGuardian)
   external
  {   
    delete _superGuardiansSignatures[superGuardian];
  }

  /// @dev add a superGuardian.
  function addSuperGuardian(address superGuardian) onlyOwner public virtual override {
    require(!_superGuardians.contains(superGuardian), "Provided superGuardian already exists");
    _superGuardians.add(superGuardian);
  }

  /// @dev remove an existing superGuardian.
  function removeSuperGuardian(address existingGuardian) onlyOwner external {
    require(_superGuardians.contains(existingGuardian), "Provided superGuardian not a superGuardian");
    _superGuardians.remove(existingGuardian);
  }

  /// @dev retrieve a superGuardian signature.
  function retrieveSignature(address superGuardian, string memory secretPhrase) 
   superGuardianExists(superGuardian)
   external returns (string memory) {
     _verifySecret(secretPhrase);
    return _superGuardiansSignatures[superGuardian];
  }

  /// @dev retrieve list of superGuardians already registered.
  function getSuperGuardians() onlyOwner external view returns (address[] memory) {
    return _superGuardians.values();
  }

  /// @dev simple secretPhrase verification.
  function _verifySecret(string memory secretPhrase) internal returns (bool){
    require(keccak256(abi.encodePacked(secretPhrase)) == _secretPhraseHash, "SecretPhrase is wrong");
  }

}