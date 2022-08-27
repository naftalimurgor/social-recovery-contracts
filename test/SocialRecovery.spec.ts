import { expect } from 'chai'
import hre, { ethers } from 'hardhat'
import { Contract } from 'ethers'
import '@nomiclabs/hardhat-ethers'
import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers'

const EthCrypto = require('eth-crypto')

describe('SocialRecovery', function () {
  let socialRecovery: Contract
  let erc725Account: Contract
  let secretPhrase = 'Hello world'

  let owner: SignerWithAddress,
    guardianOne: SignerWithAddress,
    guardianTwo: SignerWithAddress,
    guardianThree: SignerWithAddress,
    random: SignerWithAddress


  this.beforeEach(async function () {
    [owner, guardianOne, guardianTwo, guardianThree, random] = await ethers.getSigners()

    const VerifySignatureLib = await hre.ethers.getContractFactory('VerifySignature')
    const verifySignatureLib = await VerifySignatureLib.deploy()
    await verifySignatureLib.deployed()

    const SocialRecovery = await hre.ethers.getContractFactory('SocialRecovery', {
      signer: owner,
      libraries: {
        VerifySignature: verifySignatureLib.address
      }
    })

    socialRecovery = await SocialRecovery.deploy(owner.address)
    await socialRecovery.deployed()

    SocialRecovery.connect(owner)
    await socialRecovery.setSecretHash(secretPhrase)
  })

  describe('when adding a superGuardian', () => {
    it('should add a superGuardian', async function () {
      await socialRecovery.addSuperGuardian(guardianOne.address)
      expect(await socialRecovery.getSuperGuardians()).to.have.length(1);
    })

    it('should remove an existing superGuardian', async () => {

      await socialRecovery.addSuperGuardian(guardianTwo.address)
      expect(await socialRecovery.getSuperGuardians()).to.have.length(1)
      // remove
      await socialRecovery.removeSuperGuardian(guardianTwo.address)
      expect(await socialRecovery.getSuperGuardians()).to.have.length(0)
    })

    it('should get guardianThreshod', async () => {
      await socialRecovery.addSuperGuardian(guardianThree.address)
      const guardianThreshold = await socialRecovery.getGuardianThreshold()
      expect(guardianThreshold).to.equal(1)
    })
  })

  describe('when adding guardian signatures', () => {
    it('should add new signature', async () => {
      // add super guardian first
      await socialRecovery.addSuperGuardian(guardianThree.address)
      const message = 'Hello World'
      const signature = await guardianThree.signMessage(message)
      await socialRecovery.addGuardianSignature(guardianThree.address, signature)
      expect(await socialRecovery.retrieveSignature(guardianThree.address, secretPhrase))
    })

    it('it should verify signature', async () => {
      await socialRecovery.addSuperGuardian(owner.address)
      const messageHash = EthCrypto.hash.keccak256([
        {
          type: 'string',
          value: 'hello world'
        }
      ])
      console.log(messageHash)
      
      const signature = await owner.signMessage(messageHash)
      console.log('signature', signature)
      await socialRecovery.addGuardianSignature(owner.address, signature)
      const result = await socialRecovery.verifySignature(messageHash, signature)
      console.log(result)
      expect(result).to.equal(owner.address)

    })
  })


})