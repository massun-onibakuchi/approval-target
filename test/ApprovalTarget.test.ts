import { ethers } from 'hardhat'
import { expect } from 'chai'
import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers'
import {
  ApprovalTarget,
  Vault__factory,
  ERC20Mock,
  Vault,
} from '../typechain-types'
import { splitSignature } from 'ethers/lib/utils'

const PERMIT_AND_TRANSFER_FROM_TYPEHASH = [
  { name: 'erc20', type: 'address' },
  { name: 'owner', type: 'address' },
  { name: 'spender', type: 'address' },
  { name: 'value', type: 'uint256' },
  { name: 'nonce', type: 'uint256' },
  { name: 'deadline', type: 'uint256' },
]

describe('ApprovalTarget', async function () {
  let owner: SignerWithAddress
  let relayer
  let token: ERC20Mock
  let approvalTarget: ApprovalTarget
  let chainId
  beforeEach(async function () {
    ;({ chainId } = await ethers.provider.getNetwork())
    ;[owner] = await ethers.getSigners()

    token = (await (
      await ethers.getContractFactory('ERC20Mock')
    ).deploy('Token', 'TKN')) as ERC20Mock
    approvalTarget = (await (
      await ethers.getContractFactory('ApprovalTarget')
    ).deploy()) as ApprovalTarget

    await token.mint(owner.address, 1000)
    await token.connect(owner).approve(approvalTarget.address, 1000)
  })

  describe('spender is an EOA', async function () {
    let spender
    let recipient
    beforeEach(async function () {
      ;[owner, relayer, spender, recipient] = await ethers.getSigners()

      this.approve = {
        owner: owner.address,
        spender: spender.address,
        value: 1000,
      }
      this.deadline = Math.floor((Date.now() / 1000) * 2)
      this.nonce = await approvalTarget.nonces(owner.address)

      this.signature = await signPermitApproval(
        'ApprovalTarget',
        '1',
        chainId,
        approvalTarget.address,
        token.address,
        this.approve,
        this.nonce,
        this.deadline
      )
    })
    it('succeeds when `msg.sender` is the spender', async function () {
      const { v, r, s } = this.signature
      await expect(
        approvalTarget
          .connect(spender)
          .permitAndTransferFrom(
            token.address,
            this.approve.owner,
            recipient.address,
            this.approve.value,
            this.deadline,
            v,
            r,
            s
          )
      )
        .to.emit(token, 'Transfer')
        .withArgs(this.approve.owner, recipient.address, this.approve.value)

      expect(await token.balanceOf(recipient.address)).to.be.eq(
        this.approve.value
      )
    })
    it('spender can choose `recipient` parameter', async function () {
      const { v, r, s } = this.signature
      await expect(
        approvalTarget
          .connect(spender)
          .permitAndTransferFrom(
            token.address,
            this.approve.owner,
            spender.address,
            this.approve.value,
            this.deadline,
            v,
            r,
            s
          )
      )
        .to.emit(token, 'Transfer')
        .withArgs(this.approve.owner, spender.address, this.approve.value)

      expect(await token.balanceOf(spender.address)).to.be.eq(
        this.approve.value
      )
    })
    it('revert when `msg.sender` is a replayer instead of spender', async function () {
      const { v, r, s } = this.signature
      await expect(
        approvalTarget
          .connect(relayer)
          .permitAndTransferFrom(
            token.address,
            this.approve.owner,
            recipient.address,
            this.approve.value,
            this.deadline,
            v,
            r,
            s
          )
      ).to.be.revertedWith('Invalid signature')
    })
  })
})

/**
 * Sign PermitApproval by `owner`
 * @param {string} owner signer address who approve `spender`
 * @param {string} spender which should send a tx including this signature
 */
const signPermitApproval = async (
  name: string,
  version: string,
  chainId: number,
  approvalTarget: string,
  erc20: string,
  approve: {
    owner: string
    spender: string
    value: number
  },
  nonce: number,
  deadline: number
) => {
  const domain = {
    name,
    version,
    chainId,
    verifyingContract: approvalTarget,
  }
  const types = { PermitAndTransferFrom: PERMIT_AND_TRANSFER_FROM_TYPEHASH }
  const data = {
    erc20,
    ...approve,
    nonce,
    deadline,
  }

  const signature = await (
    await ethers.getSigner(approve.owner)
  )._signTypedData(domain, types, data)

  return splitSignature(signature)
}
