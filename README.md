# Multi VRGDAs

Fork of [transmissions11/VRGDAs](https://github.com/transmissions11/VRGDAs) but with support for multiple VRGDAs in a single contract.

## Example: Multiple VRGDAs
Independent VRGDAs are handled via structs & underlying libraries. This offers improved ergonomics via object-oriented style syntax.

Please see [Contract.sol](src/examples/Contract.sol) for the full implementation

```solidity
contract Contract {
    using LinearVRGDALib for LinearVRGDAx;
    using LogisticVRGDALib for LogisticVRGDAx;

    uint256 startTime = block.timestamp;

    // dummy counters to represent "purchases"
    uint256 resourceA;  // priced via Linear VRGDA
    uint256 resourceB;  // priced via Logistic VRGDA

    // define 2 VRGDAs (structs) to price the resources
    // Add as many as you want, i.e. you can have multiple linear VRGDAs
    LinearVRGDAx internal linearAuction = LinearVRGDALib.createLinearVRGDA(1e18, 0.2e18, 1e18);
    LogisticVRGDAx internal logAuction = LogisticVRGDALib.createLogisticVRGDA(1e18, 0.2e18, 1000e18, 1000e18);;


    // an example of fetching the auction's price
    // purchase resourceA & resourceB according to auction prices
    function buyBothResources(uint256 amountA, uint256 amountB) public payable {
        int256 timeSinceStart = toWadUnsafe(block.timestamp - startTime);
        
        // VRGDAs are a function of time & units sold
        uint256 pricePerA = linearAuction.getVRGDAPrice(timeSinceStart, resourceA);
        uint256 pricePerB = logAuction.getVRGDAPrice(timeSinceStart, resourceB);
        
        // Additional logic to verify msg.value sufficiently covers the cost
        // of the purchased resources
        ...
    }
}
```

## Example: Single VRGDAs

If a single, immutable VRGDA is only needed (i.e. pricing an NFT), you should use the canonical abstract contract. This is **slightly more gas efficient** because the parameters of the VRGDA do not rely on state/storage.


Please see [LinearNFT.sol](src/examples/LinearNFT.sol) for the full implementation

```solidity
contract LinearNFT is ERC721, LinearVRGDA {
    constructor()
        ERC721(
            "Example Linear NFT", // Name.
            "LINEAR" // Symbol.
        )
        LinearVRGDA(
            69.42e18, // Target price.
            0.31e18, // Price decay percent.
            2e18 // Per time unit.
        )
    {}

    function mint() external payable returns (uint256 mintedId) {
        unchecked {
            // Get the price of the NFT according to the VRGDA
            // Note: By using toDaysWadUnsafe(block.timestamp - startTime) we are establishing that 1 "unit of time" is 1 day.
            uint256 price = getVRGDAPrice(toDaysWadUnsafe(block.timestamp - startTime), mintedId = totalSold++);

            require(msg.value >= price, "UNDERPAID"); // Don't allow underpaying.

            // Additional ERC721 mint logic:
            // i.e. minting the token to msg.sender
            // and refunding excess payment
            ...
        }
    }
}


```


---

## Contributing

You will need a copy of [Foundry](https://github.com/foundry-rs/foundry) installed before proceeding. See the [installation guide](https://github.com/foundry-rs/foundry#installation) for details.

### Run Tests

```sh
forge test
```

### Update Gas Snapshots

```sh
forge snapshot
```
