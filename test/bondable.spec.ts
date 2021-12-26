import chai, { expect } from 'chai'
import { solidity, MockProvider, deployContract } from 'ethereum-waffle'
import { Contract, BigNumber, constants } from 'ethers'

import bondable from '../build/Bondable.json'
import zcToken from '../build/zcToken.json'

chai.use(solidity)

const overrides = {
  gasLimit: 9999999,
}

const ZERO_BYTES32 = '0x0000000000000000000000000000000000000000000000000000000000000000'

describe('bondable', () => {
  const provider = new MockProvider({
    ganacheOptions: {
      hardfork: 'istanbul',
      mnemonic: 'horn horn horn horn horn horn horn horn horn horn horn horn',
      gasLimit: 9999999,
    },
  })

  const wallets = provider.getWallets()
  const [wallet0, wallet1, wallet2, wallet3, wallet4] = wallets

  let bondableContract: Contract
  let newMarket: String
  let marketPrice: BigNumber
  let maxAmount: BigNumber
  let maturityUnix: BigNumber
  beforeEach('deploy bondable', async () => {
    marketPrice = BigNumber.from("950000000000000000")
    maxAmount = BigNumber.from("100000000000000000000000")
    maturityUnix = BigNumber.from("1641044738")
    bondableContract = await deployContract(wallet0, bondable, [], overrides)
    newMarket = await bondableContract.createMarket("0x0000000000000000000000000000000000000000", maturityUnix,  maxAmount, marketPrice, 18, "testMarket", "testM")
  })
  let bondPrice: BigNumber
  describe('#zcToken underlying', () => {
    it('returns the price', async () => {
      bondPrice = await bondableContract.markets("0x0000000000000000000000000000000000000000", maturityUnix).price;
      expect(bondPrice).to.eq("950000000000000000")
    })
  })

})
