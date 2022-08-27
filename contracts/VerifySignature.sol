// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library VerifySignature {
    /// @dev recovers public key used to sign the message.
    /// original message(kecca256 encoded) and signature(kecca256 encoded plus signed with privateKey)
    function recoverSigner(bytes32 messageHash, bytes memory sig)
        public
        pure
        returns (address)
    {
        uint8 v;
        bytes32 r;
        bytes32 s;
        (v, r, s) = splitSignature(sig);
        return ecrecover(messageHash, v, r, s);
    }

    /// split signature in {r,s,v} segments
    function splitSignature(bytes memory sig)
        public
        pure
        returns (
            uint8,
            bytes32,
            bytes32
        )
    {
        require(sig.length == 65);
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
