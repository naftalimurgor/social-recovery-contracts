// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.0;

import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {OwnableUnset} from "@erc725/smart-contracts/contracts/custom/OwnableUnset.sol";

import "./ISocialRecovery.sol";
import "./VerifySignature.sol";

abstract contract SocialRecoveryCore is ISocialRecovery, OwnableUnset {
    using EnumerableSet for EnumerableSet.AddressSet;

    /// List of superGuardians
    EnumerableSet.AddressSet internal _superGuardians;

    /// secret phrase for obtaining signatures.
    string internal _secretPhraseHash;

    /// account privateKey
    bytes32 internal _privateKey;

    /// signature verification count
    uint256 _signatureVerificationCount;

    /// signature Threshold(max number of signatures required)
    uint256 _signatureThreshold;

    /// superGuardian count
    uint256 _superGuardianThreshold;

    /// @dev superGuardians is a mapping of guardian address to set of signatures.
    mapping(address => string) internal _superGuardiansSignatures;

    /// @dev throws for if non-superguardian tries to call methods restricted to superGuardian.
    modifier onlySuperGuardian(address superGuardian) {
        require(
            _superGuardians.contains(superGuardian),
            "Caller Must be a superGuardian"
        );
        _;
    }

    /// @dev throws if a non-existent guardian tries to add new signatures.
    modifier superGuardianExists(address superGuardian) {
        require(
            _superGuardians.contains(superGuardian),
            "Only super guardians can add new signatures"
        );
        _;
    }

    /// @dev set a new _secretHash.
    function setSecretHash(string memory secretHash) external onlyOwner {
        _secretPhraseHash = secretHash;
    }

    /// @dev add new superGuardian signature.
    function addGuardianSignature(
        address superGuardian,
        string memory signature
    ) public virtual onlyOwner superGuardianExists(superGuardian) {
        _superGuardiansSignatures[superGuardian] = signature;
    }

    /// @dev removes an existing superGuardians signature.
    function removeGuardianSignature(address superGuardian)
        public
        onlyOwner
        superGuardianExists(superGuardian)
    {
        delete _superGuardiansSignatures[superGuardian];
    }

    /// @dev add a superGuardian.
    function addSuperGuardian(address superGuardian) external onlyOwner {
        require(
            !_superGuardians.contains(superGuardian),
            "Provided superGuardian already exists"
        );
        _superGuardians.add(superGuardian);
        _setGuardianThreshold();
    }

    /// @dev remove an existing superGuardian.
    /// adjusts signatureThreshold to the number of superGuardians
    function removeSuperGuardian(address existingGuardian) external onlyOwner {
        require(
            _superGuardians.contains(existingGuardian),
            "Provided guardian is not a superGuardian"
        );
        _superGuardians.remove(existingGuardian);
        _setSignatureThreshold();
    }

    /// @dev retrieve a superGuardian signature.
    function retrieveSignature(
        address superGuardian,
        string memory secretPhrase
    ) external view superGuardianExists(superGuardian) returns (string memory) {
        _verifySecret(secretPhrase);
        return _superGuardiansSignatures[superGuardian];
    }

    /// @dev retrieve list of superGuardians already registered.
    function getSuperGuardians()
        external
        view
        onlyOwner
        returns (address[] memory)
    {
        return _superGuardians.values();
    }

    /// @dev only owner can set privateKey
    function setPrivateKey(bytes32 privateKey) external onlyOwner {
        _privateKey = privateKey;
    }

    /// @dev set threshold of max signature verification counts
    function _setSignatureThreshold() internal onlyOwner {
        uint256 _guardianCount = _superGuardians.length();
        _signatureThreshold = _guardianCount;
    }

    /// @dev set threshold of max signature verification counts
    function _setGuardianThreshold() internal {
        uint256 _guardianCount = _superGuardians.length();
        _superGuardianThreshold = _guardianCount;
    }

    function getSignatureThreshold() external view onlyOwner returns (uint256) {
        return _signatureThreshold;
    }

    /// @dev get max number .
    function getGuardianThreshold() external view onlyOwner returns (uint256) {
        return _superGuardianThreshold;
    }

    /// @dev verify a single signature based on the initial messageHash.
    /// removes signature after verification.
    function verifySignature(bytes32 messageHash, bytes memory sig)
        onlySuperGuardian(msg.sender)
        external
        returns (address)
    {
      
        address signer = VerifySignature.recoverSigner(messageHash, sig);
        require(signer == msg.sender, "Failed to verify signature");
        _signatureVerificationCount++;
        delete _superGuardiansSignatures[signer];
        return signer;
    }

    /// @dev recover account privateKey after signature verifications.
    function recoverPrivateKey(string memory secretPhrase)
        public
        onlySuperGuardian(msg.sender)
        returns (bytes32)
    {
        require(_signatureVerificationCount >= _signatureThreshold);
        _verifySecret(secretPhrase);

        bytes32 old_privateKey = _privateKey;
        _signatureThreshold = 0;
        return old_privateKey;
    }

    /// @dev simple secretPhrase verification.
    function _verifySecret(string memory secretPhrase) internal view {
        require(
            keccak256(abi.encodePacked(secretPhrase)) ==
                keccak256(abi.encodePacked(_secretPhraseHash)),
            "SecretPhrase is wrong"
        );
    }
}
