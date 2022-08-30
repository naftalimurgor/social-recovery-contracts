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
    mapping(address => bytes) internal _superGuardiansSignatures;

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
        bytes memory signature
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
    ) external view superGuardianExists(superGuardian) returns (bytes memory) {
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
    function confirmSignature(bytes32 messageHash, bytes memory sig)
        external
        returns (address)
    {
      
        address signer = _recoverSigner(messageHash, sig);
        bool isvalid = _superGuardians.contains(signer);
        require(isvalid, "Failed to verify signature");
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

    /// @dev recovers public key used to sign the message.
    /// original message(kecca256 encoded) and signature(kecca256 encoded plus signed with privateKey)
    function _recoverSigner(bytes32 messageHash, bytes memory sig)
        internal
        pure
        returns (address)
    {
        uint8 v;
        bytes32 r;
        bytes32 s;
        (v, r, s) = _splitSignature(sig);
        address signer = ecrecover(messageHash, v, r, s);
        return signer;
    }

    /// split signature in {r,s,v} segments
    function _splitSignature(bytes memory sig)
        internal
        pure
        returns (
            uint8,
            bytes32,
            bytes32
        )
    {
        require(sig.length == 65, "Invalid signature");
        bytes32 r;
        bytes32 s;
        uint8 v;

        assembly {
            // first 32 bytes, after the length prefix
            r := mload(add(sig, 32))
            // second 32 bytes
            s := mload(add(sig, 64))
            v := byte(0, mload(add(sig, 96)))
        }

        return (v, r, s);
    }
}
