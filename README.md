# PictureNFT

PictureNFT (Non-Fungible Token) dapp where users can create, list, sell, and tip creators: 

1. Minting PictureNFTs:
   - Users can create unique **PictureNFTs** by uploading their digital artwork or images.
   - Each PictureNFT is represented by a distinct token on the blockchain, making it one-of-a-kind. 

2. View Owned PictureNFTs:
   - Users can retrieve a list of PictureNFT IDs associated with their connected wallet address.
   - This allows them to keep track of their owned tokens. 

3. Listing PictureNFTs for Sale:
   - Owners of PictureNFTs can set an asking price and list their tokens on the marketplace.
   - Potential buyers can view these listings and decide whether to purchase. 

4. Exploring Marketplace Listings:
   - Users can browse the marketplace to discover available PictureNFTs.
   - Listings include details such as the creator, description, and asking price. 

5. Buying PictureNFTs:
   - Interested buyers can purchase listed PictureNFTs by transferring the specified amount of the native cryptocurrency (e.g., SUI).
   - Ownership of the token is transferred upon successful purchase. 

6. Tipping Creators:
   - Users who appreciate a particular PictureNFT can tip the creator directly.
   - Tipping fosters a supportive community and encourages artists to continue creating. 

Remember, PictureNFTs represent digital art, photography, or other visual content, and their uniqueness is guaranteed by blockchain technology.

## Installation

To deploy and use the smart contract, follow these steps:

1. **Move Compiler Installation:**
   Ensure you have the Move compiler installed. You can find the Move compiler and instructions on how to install it at [Sui Docs](https://docs.sui.io/).

2. **Compile the Smart Contract:**
   For this contract to compile successfully, please ensure you switch the dependencies to whichever you installed. 
`framework/devnet` for Devnet, `framework/testnet` for Testnet

```bash
   Sui = { git = "https://github.com/MystenLabs/sui.git", subdir = "crates/sui-framework/packages/sui-framework", rev = "framework/devnet" }
```

then build the contract by running

```
sui move build
```

3. **Deployment:**
   Deploy the compiled smart contract to your blockchain platform of choice.

```
sui client publish --gas-budget 100000000 --json
