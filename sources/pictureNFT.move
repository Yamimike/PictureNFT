// SPDX-License-Identifier: Apache-2.0

module nft_gallery::picture_nft {
    use std::option::{Option, none, some};
    use std::string::{Self, String};
    use sui::coin::{Self, Coin};
    use sui::object::{Self, ID, UID};
    use sui::table::{Table, Self};
    use sui::transfer;
    use sui::tx_context::{Self, TxContext};
    use sui::vector;

    // Error codes
    const ENoPicture: u64 = 0;
    const EPictureExists: u64 = 1;
    const ENotOwner: u64 = 2;
    const EInvalidAmount: u64 = 3;

    // Picture struct representing an NFT
    struct Picture has key, store {
        id: UID,
        creator: address,
        uri: String,
        price: u64,
        owner: address,
        for_sale: bool,
    }

    // Gallery struct holding a collection of Picture NFTs
    struct Gallery has key {
        pictures: Table<UID, Picture>,
    }

    // Function to create a new Picture NFT
    public fun create_picture(ctx: &mut TxContext, uri: String, price: u64): UID {
        let picture_id = object::new(ctx);
        let picture = Picture {
            id: picture_id,
            creator: tx_context::sender(ctx),
            uri,
            price,
            owner: tx_context::sender(ctx),
            for_sale: false,
        };
        transfer::share_object(picture);
        picture_id
    }

    // Function to list a Picture NFT for sale
    public fun list_picture(
        gallery: &mut Gallery,
        picture_id: UID,
        price: u64,
        ctx: &mut TxContext,
    ) {
        let picture = table::borrow_mut(&mut gallery.pictures, picture_id);
        assert!(picture.owner == tx_context::sender(ctx), ENotOwner);
        picture.for_sale = true;
        picture.price = price;
    }

    // Function to buy a listed Picture NFT
    public fun buy_picture(
        gallery: &mut Gallery,
        picture_id: UID,
        offered_amount: u64,
        ctx: &mut TxContext,
    ) {
        let picture = table::borrow_mut(&mut gallery.pictures, picture_id);
        assert!(picture.for_sale, ENoPicture);
        assert!(offered_amount >= picture.price, EInvalidAmount);

        let buyer_address = tx_context::sender(ctx);
        let seller_address = picture.owner;
        let payment = coin::withdraw<PICTURE>(ctx, offered_amount);
        coin::deposit(payment, seller_address);

        picture.owner = buyer_address;
        picture.for_sale = false;
    }

    // Function to tip the creator of a Picture NFT
    public fun tip_seller(
        gallery: &Gallery,
        picture_id: UID,
        tip_amount: u64,
        ctx: &mut TxContext,
    ) {
        let picture = table::borrow(&gallery.pictures, picture_id);
        let tip = coin::withdraw<PICTURE>(ctx, tip_amount);
        coin::deposit(tip, picture.creator);
    }

    // Added functionality: Function to update a Picture NFT
    public fun update_picture(
        gallery: &mut Gallery,
        picture_id: UID,
        new_uri: String,
        new_price: u64,
        ctx: &mut TxContext,
    ) {
        let picture = table::borrow_mut(&mut gallery.pictures, picture_id);
        assert!(picture.owner == tx_context::sender(ctx), ENotOwner);
        picture.uri = new_uri;
        picture.price = new_price;
    }

    // Added functionality: Function to transfer Picture NFT ownership
    public fun transfer_picture(
        gallery: &mut Gallery,
        picture_id: UID,
        new_owner: address,
        ctx: &mut TxContext,
    ) {
        let picture = table::borrow_mut(&mut gallery.pictures, picture_id);
        assert!(picture.owner == tx_context::sender(ctx), ENotOwner);
        picture.owner = new_owner;
    }

    // Added functionality: Function to get Picture NFT details
    public fun get_picture(
        gallery: &Gallery,
        picture_id: UID,
    ): Option<Picture> {
        let picture = table::borrow(&gallery.pictures, picture_id);
        if (picture == none()) {
            return none()
        };
        some(*picture)
    }
}