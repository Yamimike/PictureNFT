module picture::picture_nft {
    use std::string::{String};
    use sui::coin::{Self, Coin};
    use sui::object::{Self, ID, UID};
    use sui::table::{Table, Self};
    use sui::transfer;
    use sui::tx_context::{Self, TxContext};
    use sui::sui::{SUI};
    use sui::balance::{Self, Balance};
    use sui::kiosk::{Self, Kiosk, KioskOwnerCap};
    use sui::transfer_policy::{Self as tp};
    use sui::package::{Self, Publisher};

    // Error codes
    const ENoPicture: u64 = 0;
    const ENotOwner: u64 = 1;
    const EInvalidAmount: u64 = 2;

    // Picture struct representing an NFT
    struct Picture has key, store {
        id: UID,
        creator: address,
        uri: String,
        price: u64,
        tips: Balance<SUI>,
        owner: address,
        for_sale: bool,
    }

    // Gallery struct holding a collection of Picture NFTs
    struct Gallery has key {
        id: UID,
        pictures: Table<ID, Picture>,
    }

      /// Publisher capability object
    struct PicturePublisher has key { id: UID, publisher: Publisher }

     // one time witness 
    struct PICTURE_NFT has drop {}

    // Only owner of this module can access it.
    struct AdminCap has key {
        id: UID,
    }

    // =================== Initializer ===================
    fun init(otw: PICTURE_NFT, ctx: &mut TxContext) {
        // define the publisher
        let publisher_ = package::claim<PICTURE_NFT>(otw, ctx);
        // wrap the publisher and share.
        transfer::share_object(PicturePublisher {
            id: object::new(ctx),
            publisher: publisher_
        });
        // transfer the admincap
        transfer::transfer(AdminCap{id: object::new(ctx)}, tx_context::sender(ctx));
    }

    /// Users can create new kiosk for marketplace 
    public fun new(ctx: &mut TxContext) : KioskOwnerCap {
        let(kiosk, kiosk_cap) = kiosk::new(ctx);
        // share the kiosk
        transfer::public_share_object(kiosk);
        kiosk_cap
    }
    // create any transferpolicy for rules 
    public fun new_policy(publish: &PicturePublisher, ctx: &mut TxContext ) {
        // set the publisher
        let publisher = get_publisher(publish);
        // create an transfer_policy and tp_cap
        let (transfer_policy, tp_cap) = tp::new<Picture>(publisher, ctx);
        // transfer the objects 
        transfer::public_transfer(tp_cap, tx_context::sender(ctx));
        transfer::public_share_object(transfer_policy);
    }
    // Function to create a new Picture NFT
    public fun create_picture(self: &mut Gallery, uri: String, price: u64, ctx: &mut TxContext) {
        let id_ = object::new(ctx);
        let inner = object::uid_to_inner(&id_);
        let picture = Picture {
            id: id_,
            creator: tx_context::sender(ctx),
            uri,
            price,
            tips: balance::zero(),
            owner: tx_context::sender(ctx),
            for_sale: false,
        };
        table::add(&mut self.pictures, inner, picture);
    }

    // Function to list a Picture NFT for sale
    public fun list_picture(
        self: &mut Gallery,
        picture_id: ID,
        price: u64,
        ctx: &mut TxContext,
    ) {
        let picture = table::borrow_mut(&mut self.pictures, picture_id);
        assert!(picture.owner == tx_context::sender(ctx), ENotOwner);
        picture.for_sale = true;
        picture.price = price;
    }

    // Function to buy a listed Picture NFT
    public fun buy_picture(
        self: &mut Gallery,
        picture_id: ID,
        payment: Coin<SUI>,
        ctx: &mut TxContext,
    ) {
        let picture = table::borrow_mut(&mut self.pictures, picture_id);
        assert!(picture.for_sale, ENoPicture);
        assert!(coin::value(&payment) >= picture.price, EInvalidAmount);

        let buyer_address = tx_context::sender(ctx);
        let seller_address = picture.owner;

        picture.owner = buyer_address;
        picture.for_sale = false;
        // transfer the price
        transfer::public_transfer(payment, buyer_address);
    }

    // Function to tip the creator of a Picture NFT
    public fun tip_seller(
        self: &mut Gallery,
        picture_id: ID,
        tip_amount: Coin<SUI>,
    ) {
        let picture = table::borrow_mut(&mut self.pictures, picture_id);
        let tip = coin::into_balance<SUI>(tip_amount);
        balance::join(&mut picture.tips, tip);
    }

    // Added functionality: Function to update a Picture NFT
    public fun update_picture(
        self: &mut Gallery,
        picture_id: ID,
        new_uri: String,
        new_price: u64,
        ctx: &mut TxContext,
    ) {
        let picture = table::borrow_mut(&mut self.pictures, picture_id);
        assert!(picture.owner == tx_context::sender(ctx), ENotOwner);
        picture.uri = new_uri;
        picture.price = new_price;
    }

    // Added functionality: Function to transfer Picture NFT ownership
    public fun transfer_picture(
        self: &mut Gallery,
        picture_id: ID,
        new_owner: address,
        ctx: &mut TxContext,
    ) : Picture {
        let picture = table::remove(&mut self.pictures, picture_id);
        assert!(picture.owner == tx_context::sender(ctx), ENotOwner);
        picture.owner = new_owner;
        picture
    }

    // Added functionality: Function to get Picture NFT details
    public fun get_picture(
        self: &Gallery,
        id: ID,
    ): (address, String, u64, u64, address, bool) {
        let picture = table::borrow(&self.pictures, id);
        let balance_ = balance::value(&picture.tips);
        (
            picture.creator,
            picture.uri,
            picture.price,
            balance_,
            picture.owner,
            picture.for_sale
        )
    }

    // =================== Helper Functions ===================

    // return the publisher
    fun get_publisher(shared: &PicturePublisher) : &Publisher {
        &shared.publisher
     }
}
