import { expect } from 'chai'
import hre, { ethers } from 'hardhat'
import { Contract } from 'ethers'
import '@nomiclabs/hardhat-ethers'
import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers'

describe('SocialRecovery', function () {
  let socialRecovery: Contract
  let erc725Account: Contract
  let secretHash: string

  let owner: SignerWithAddress,
    guardianOne: SignerWithAddress,
    guardianTwo: SignerWithAddress,
    guardianThree: SignerWithAddress

  this.beforeAll(async function () {
    [owner, guardianOne, guardianTwo, guardianThree] = await ethers.getSigners()

    const SocialRecovery = await hre.ethers.getContractFactory('SocialRecovery')
    const ERC725Account = await hre.ethers.getContractFactory('LSP0ERC725Account')

    erc725Account = await ERC725Account.deploy(owner.address)
    const erc725AccountAddress = erc725Account.address

    socialRecovery = await SocialRecovery.deploy(owner.address, erc725AccountAddress)
    SocialRecovery.connect(owner)
  })

  
  // -- setters for strategy: store a signed message
  // https://docs.ethers.io/v4/cookbook-signing.html
  it('should add a superGuardian', async function () {
    await socialRecovery.addSuperGuardian(guardianOne.address)
    expect(await socialRecovery.getSuperGuardians()).to.have.length(1);
  })
  
  it('should set a signed message by a superGuardian', async function () {
    const message = 'SECRET_PHRASE'
    const signedMessage = await guardianOne.signMessage(message)
    await socialRecovery.addGuardianSignature(guardianOne.address, signedMessage)
    expect(await socialRecovery.retrieveSignature(guardianOne.address)).to.be.a.string
  })
  
})