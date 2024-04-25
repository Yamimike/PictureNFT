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
        inner: ID,
        creator: address,
        uri: String,
        price: u64,
        tips: Balance<SUI>,
        owner: address,
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
    public fun create_picture(uri: String, price: u64, ctx: &mut TxContext) : Picture {
        let id_ = object::new(ctx);
        let inner_ = object::uid_to_inner(&id_);

        let picture = Picture {
            id: id_,
            inner: inner_,
            creator: tx_context::sender(ctx),
            uri,
            price,
            tips: balance::zero(),
            owner: tx_context::sender(ctx),
        };
        picture 
    }

    // =================== Helper Functions ===================

    // return the publisher
    fun get_publisher(shared: &PicturePublisher) : &Publisher {
        &shared.publisher
     }

    #[test_only]
    // call the init function
    public fun test_init(ctx: &mut TxContext) {
        init(PICTURE_NFT {}, ctx);
    }
}
