// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "@lukso/lsp-smart-contracts/contracts/LSP6KeyManager/LSP6KeyManager.sol";
import "./lsp-smart-contracts/contracts/LSP11BasicSocialRecovery/LSP11BasicSocialRecovery.sol";

import "./SocialRecoveryCore.sol";

contract SocialRecovery is LSP11BasicSocialRecovery, SocialRecoveryCore {
    constructor(address account_)
        LSP11BasicSocialRecovery(account_)
    {
        _setOwner(msg.sender);
    }    
}
