import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";
import dotenv from 'dotenv'

dotenv.config()

const config: HardhatUserConfig = {
  solidity: "0.8.9",
  defaultNetwork: 'hardhat',
  networks: {
    hardhat: {},
    luksoL16: {
      url: "https://rpc.l16.lukso.network",
      chainId: 2828,
      accounts: {mnemonic: process.env.MNEMONIC as string}// your private key here
    },
  },
  paths: {
    root: '.',
    sources: './contracts',
    artifacts: './artifacts'
  }
};

export default config;
