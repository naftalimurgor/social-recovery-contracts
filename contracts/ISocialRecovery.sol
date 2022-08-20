// SPDX-License-Identifier: MIT

interface ISocialRecovery {
  function addGuardianSignature(address superGuardian, string memory message) external;
  function removeGuardianSignature(address superGuardian) external;
  function retrieveSignature(address superGuardian, string memory secretPhrase) external returns(string memory);
  function addSuperGuardian(address superGuardian) external;
  function removeSuperGuardian(address superGuardian) external;
  function getSuperGuardians() external view returns (address[] memory);
}