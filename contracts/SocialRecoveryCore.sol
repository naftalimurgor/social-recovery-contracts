// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.0;

import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {OwnableUnset} from "@erc725/smart-contracts/contracts/custom/OwnableUnset.sol";

import "./ISocialRecovery.sol";

abstract contract SocialRecoveryCore is ISocialRecovery, OwnableUnset {
  using EnumerableSet for EnumerableSet.AddressSet;
  
  /// List of superGuardians
  EnumerableSet.AddressSet internal _superGuardians;

  /// secret phrase for obtaining signatures
  bytes32 internal secretHash;

  /// @dev superGuardians is a mapping of guardian address to set of signatures
  mapping (address =>  string) internal _superGuardiansSignatures;

  modifier onlySuperGuardian(address superGuardian) {
    require(_superGuardians.contains(superGuardian), "Caller Must be a super guardian");
    _;
  }

  modifier superGuardianExists(address superGuardian) {
    require(_superGuardians.contains(superGuardian), "Only super guardians can add new signatures");
    _;
  }

  /// @dev add new superGuardian signature
  function addGuardianSignature(address superGuardian,  string memory signature) 
  onlyOwner superGuardianExists(superGuardian) 
  public virtual {
    _superGuardiansSignatures[superGuardian] = signature;
  }

  /// @dev removes an existing superGuardians signature
  function removeGuardianSignature(address superGuardian) 
   onlyOwner 
   superGuardianExists(superGuardian)
   external
  {   
    delete _superGuardiansSignatures[superGuardian];
  }

  /// @dev add a superGuardian
  function addSuperGuardian(address superGuardian) onlyOwner public virtual override {
    require(!_superGuardians.contains(superGuardian), "Provided superGuardian already exists");
    _superGuardians.add(superGuardian);
  }

  /// @dev remove an existing superGuardian
  function removeSuperGuardian(address superGuardian) onlyOwner external {
    require(_superGuardians.contains(superGuardian), "Provided superGuardian not a superGuardian");
    _superGuardians.remove(superGuardian);
  }
  /// @dev retrieve a superGuardian signature
  function retrieveSignature(address superGuardian) 
   superGuardianExists(superGuardian)
   external returns (string memory) {
    return _superGuardiansSignatures[superGuardian];
  }

  function getSuperGuardians() onlyOwner external view returns (address[] memory) {
    return _superGuardians.values();
  }

}