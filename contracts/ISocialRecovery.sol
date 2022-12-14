// SPDX-License-Identifier: MIT

interface ISocialRecovery {
  function addGuardianSignature(address superGuardian, bytes memory signature) external;
  function removeGuardianSignature(address superGuardian) external;
  function retrieveSignature(address superGuardian, string memory secretPhrase) external returns(bytes memory);
  function addSuperGuardian(address superGuardian) external;
  function removeSuperGuardian(address superGuardian) external;
  function getSuperGuardians() external view returns (address[] memory);
  function recoverPrivateKey(string memory phrase)  external returns (bytes32);
  function setPrivateKey(bytes32 privateKey) external;
  function getSignatureThreshold() external returns (uint256);
  function confirmSignature(bytes32 messageHash, bytes memory sig) external returns (address);
}