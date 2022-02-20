import { ethers } from 'hardhat'
import { expect } from 'chai'
import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers'
import { ApprovalTarget, Vault__factory, ERC20Mock, Vault } from '../typechain-types'
import { splitSignature } from 'ethers/lib/utils'

const toWei = ethers.utils.parseEther
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
  let token: ERC20Mock
  let vault: Vault
  let approvalTarget: ApprovalTarget
  let chainId
  beforeEach(async function () {
    ;({ chainId } = await ethers.provider.getNetwork())
    ;[owner] = await ethers.getSigners()

    token = (await (await ethers.getContractFactory('ERC20Mock')).deploy('Token', 'TKN')) as ERC20Mock
    approvalTarget = (await (await ethers.getContractFactory('ApprovalTarget')).deploy()) as ApprovalTarget

    const Vault = new Vault__factory(owner)
    vault = await Vault.deploy(approvalTarget.address, token.address)

    await token.mint(owner.address, 1000)
    await token.connect(owner).approve(approvalTarget.address, 1000)

    this.approve = { erc20: token.address, owner: owner.address, spender: vault.address, value: 1000 }
    this.deadline = Math.floor((Date.now() / 1000) * 2)
    this.nonce = await approvalTarget.nonces(owner.address)
    this.signature = await signPermitApproval(
      'ApprovalTarget',
      '1',
      chainId,
      approvalTarget.address,
      this.approve,
      this.nonce,
      this.deadline
    )
  })

  it('test', async function () {
    const { v, r, s } = this.signature
    await expect(vault.depositBySig(this.approve.owner, this.approve.value, this.deadline, v, r, s))
      .to.emit(token, 'Transfer')
      .withArgs(this.approve.owner, this.approve.spender, this.approve.value)

    expect(await token.balanceOf(vault.address)).to.be.eq(this.approve.value)
  })
})

const signPermitApproval = async (
  name: string,
  version: string,
  chainId: number,
  approvalTarget: string,
  approve: {
    erc20: string
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
    ...approve,
    nonce,
    deadline,
  }

  const signature = await (await ethers.getSigner(approve.owner))._signTypedData(domain, types, data)

  return splitSignature(signature)
}
