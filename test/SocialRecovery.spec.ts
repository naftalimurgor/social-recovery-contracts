import { expect } from 'chai'
import hre, { ethers } from 'hardhat'
import { Contract } from 'ethers'
import '@nomiclabs/hardhat-ethers'
import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers'

describe('SocialRecovery', function () {
  let socialRecovery: Contract
  let erc725Account: Contract
  let secretPhrase = 'Hello world'

  let owner: SignerWithAddress,
    guardianOne: SignerWithAddress,
    guardianTwo: SignerWithAddress,
    guardianThree: SignerWithAddress,
    random: SignerWithAddress


  beforeEach(async function () {
    [owner, guardianOne, guardianTwo, guardianThree, random] = await ethers.getSigners()

    const SocialRecovery = await hre.ethers.getContractFactory('SocialRecovery')

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

  it('should add new signature', async () => {
    // add super guardian first
    await socialRecovery.addSuperGuardian(guardianThree.address)
    // const messageHash = ethers.utils.solidityKeccak256(['string'], [message])
    const messasgeBytes = ethers.utils.arrayify(ethers.utils.id('hello world'))
    const messageHash = ethers.utils.hashMessage(messasgeBytes)


    const signature = await owner.signMessage(messasgeBytes)
    await socialRecovery.addGuardianSignature(guardianThree.address, signature)
    expect(await socialRecovery.retrieveSignature(guardianThree.address, secretPhrase))
  })

  it('it should verify signature', async () => {
    await socialRecovery.addSuperGuardian(owner.address)
    const message = 'hello world'

    // const messageHash = ethers.utils.solidityKeccak256(['string'], [message])
    const messasgeBytes = ethers.utils.arrayify(ethers.utils.id(message))
    const messageHash = ethers.utils.hashMessage(messasgeBytes)


    const signature = await owner.signMessage(messasgeBytes)

    console.log(owner.address == ethers.utils.verifyMessage(messasgeBytes, signature))
    console.log(owner.address)
    await socialRecovery.addGuardianSignature(owner.address, signature)

    try {
      const result = await socialRecovery.confirmSignature(messageHash, signature)
      console.log(result == owner.address)
      console.log(result)
    } catch (error) {
      console.error(error)
    }

  })
})

