// Address of the module owner
address 0x1 {

// The PictureNFT module defines the structure and functionality of the NFTs within the gaming site.
module PictureNFT {
   
    // Import necessary modules from the Sui framework.
   
    use sui::tx_context::{Self, TxContext};
    use sui::object::{Self, ID, UID};
    use sui::coin::{Self, Coin};
    use sui::table::{Table, Self};
    use sui::transfer;
    use sui::vector;
    use std::string::{Self, String};
    use std::option::{Option, none, some};

    
    // Error codes for various failure scenarios.
    
    // No picture found with the given ID.
    const ENoPicture: u64 = 0;
    
    // A picture with the given ID already exists.
    const EPictureExists: u64 = 1; 

    // The caller is not the owner of the picture.
    const ENotOwner: u64 = 2; 
    
    // The amount specified is invalid.
    const EInvalidAmount: u64 = 3; 

    // The Picture struct represents an NFT on the gaming site.
     // Unique identifier for the picture.
     // Address of the picture's creator.
     // URI pointing to the picture's location.
     // Price of the picture if it's for sale.
     // Current owner of the picture.
     // Flag indicating if the picture is for sale.

    struct Picture has key, store {
        id: UID, 
        creator: address,
        uri: String, 
        price: u64, 
        owner: address, 
        for_sale: bool, 
    }

    // The Gallery struct holds a collection of Picture NFTs.
    // Table mapping picture IDs to Picture structs.

    struct Gallery<phantom PICTURE> has key {
        pictures: Table<UID, Picture>, 
    }

    // Function to create a new Picture NFT.
     // Transaction context.
     // URI of the picture.
    // Initial price of the picture.
    public fun create_picture(
        ctx: &mut TxContext,
        uri: String, 
        price: u64
    ) {
        // Generate a new unique ID for the picture.
        let picture_id = object::new(ctx);
        let picture = Picture {
            id: picture_id,
            creator: tx_context::sender(ctx), // Set the creator to the transaction sender.
            uri: uri,
            price: price,
            owner: tx_context::sender(ctx), // The creator is the initial owner.
            for_sale: false, // The picture is not for sale initially.
        };
        transfer::share_object(picture); // Share the picture object with the network.
    }

    // Function to list a Picture NFT for sale.
    public fun list_picture(
        gallery: &mut Gallery<PICTURE>, // Reference to the Gallery.
        picture_id: UID, // ID of the picture to list.
        price: u64, // Price at which to list the picture.
        ctx: &mut TxContext // Transaction context.
    ) {
        let picture = table::borrow_mut<UID, Picture>(&mut gallery.pictures, picture_id); // Borrow the picture mutably.
        assert!(picture.owner == tx_context::sender(ctx), ENotOwner); // Ensure the caller is the owner.
        picture.for_sale = true; // Mark the picture as for sale.
        picture.price = price; // Set the sale price.
    }

    // Function to buy a listed Picture NFT.
    public fun buy_picture(
        gallery: &mut Gallery<PICTURE>, // Reference to the Gallery.
        picture_id: UID, // ID of the picture to buy.
        offered_amount: u64, // Amount offered for the picture.
        ctx: &mut TxContext // Transaction context.
    ) {
        let picture = table::borrow_mut<UID, Picture>(&mut gallery.pictures, picture_id); // Borrow the picture mutably.
        assert!(picture.for_sale, ENoPicture); // Ensure the picture is for sale.
        assert!(offered_amount >= picture.price, EInvalidAmount); // Ensure the offered amount is at least the asking price.

        let buyer_address = tx_context::sender(ctx); // Address of the buyer.
        let seller_address = picture.owner; // Address of the seller.
        let payment = coin::withdraw<PICTURE>(ctx, offered_amount); // Withdraw the offered amount.
        coin::deposit(payment, seller_address); // Deposit the payment to the seller.

        picture.owner = buyer_address; // Transfer ownership to the buyer.
        picture.for_sale = false; // Mark the picture as not for sale.
    }

    // Function to tip the creator of a Picture NFT.
    public fun tip_seller(
        gallery: &Gallery<PICTURE>, // Reference to the Gallery.
        picture_id: UID, // ID of the picture to tip for.
        tip_amount: u64, // Amount to tip.
        ctx: &mut TxContext // Transaction context.
    ) {
        let picture = table::borrow<UID, Picture>(&gallery.pictures, picture_id); // Borrow the picture.
        let tip = coin::withdraw<PICTURE>(ctx, tip_amount); // Withdraw the tip amount.
        coin::deposit(tip, picture.creator); // Deposit the tip to the creator.
    }
}
}
