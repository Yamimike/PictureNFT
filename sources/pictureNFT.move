module dacademarket::picture {

   // Importing required modules

    use sui::dynamic_object_field as ofield;
    use sui::tx_context::{Self, TxContext};
    use sui::object::{Self, ID, UID};
    use sui::coin::{Self, Coin};
    use sui::bag::{Bag, Self};
    use sui::table::{Table, Self};
    use sui::transfer;


    // Error constants

    const EAmountIncorrect: u64 = 0;
    const ENotOwner: u64 = 1;

    // shared object, one instance of picture accepts only 1 type of coin for all listings
    struct Picture<phantom COIN> has key {
        id: UID,
        items: Bag,
        payments: Table<address, Coin<COIN>>
    }
    // create new pictureNft
    public entry fun create<COIN>(ctx: &mut TxContext) {
        let id = object::new(ctx);
        let items = bag::new(ctx);
        let payments = table::new<address, Coin<COIN>>(ctx);
        transfer::share_object(Picture<COIN> { 
            id, 
            items,
            payments
        })
        
    }
/**
 * Struct: Listing
 * Description: Represents a listing for an item.
 */
    struct Listing has key, store {
        id: UID,
        ask: u64,
        owner: address
    }
/**
 * Public entry function: list
 * Description: Lists an item for sale with a specified asking price.
 * @param picturenft: &mut Picturenft<COIN> - Reference to the picture NFT object
 * @param item: T - Item to list
 * @param ask: u64 - Asking price for the item
 * @param ctx: &mut TxContext - Transaction context
 */
    public entry fun list<T: key + store, COIN>(
        picture: &mut Picture<COIN>,
        item: T,
        ask: u64,
        ctx: &mut TxContext
    ) {
        let item_id = object::id(&item);
        let listing = Listing {
            id: object::new(ctx),
            ask: ask,
            owner: tx_context::sender(ctx),
        };

        ofield::add(&mut listing.id, true, item);
        bag::add(&mut picture.items, item_id, listing)
    }

    /**
 * Function: delist
 * Description: Removes a listing and returns the item associated with it.
 * @param picturenft: &mut Picturenft<COIN> - Reference to the picture NFT object
 * @param item_id: ID - ID of the item to delist
 * @param ctx: &mut TxContext - Transaction context
 * @returns: T - Item associated with the listing
 */
    fun delist<T: key + store, COIN>(
        picture: &mut Picture<COIN>,
        item_id: ID,
        ctx: &mut TxContext
    ): T {
        let Listing { id, owner, ask: _ } = bag::remove(&mut picture.items, item_id);

        assert!(tx_context::sender(ctx) == owner, ENotOwner);

        let item = ofield::remove(&mut id, true);
        object::delete(id);
        item
    }

    /**
     * Public entry function: buy_and_take
     * Description: Buys an item from the marketplace and transfers it to the sender.
     * @param picture: &mut Picture<COIN> - Reference to the picture marketplace
     * @param item_id: ID - ID of the item to buy
     * @param paid: Coin<COIN> - Payment made for the item
     * @param ctx: &mut TxContext - Transaction context
     */
    public entry fun delist_and_take<T: key + store, COIN>(
        picture: &mut Picture<COIN>,
        item_id: ID,
        ctx: &mut TxContext
    ) {
        let item = delist<T, COIN>(picture, item_id, ctx);
        transfer::public_transfer(item, tx_context::sender(ctx));
    }

     /**
     * Function: buy
     * Description: Purchases an item from the marketplace using a known listing.
     * Payment is done in Coin<COIN>.
     * If conditions are correct, the owner of the item gets the payment and the buyer receives the item.
     * @param picture: &mut Picture<COIN> - Reference to the picture marketplace
     * @param item_id: ID - ID of the item to buy
     * @param paid: Coin<COIN> - Payment made for the item
     * @returns: T - Item associated with the listing
     */
    fun buy<T: key + store, COIN>(
        picture: &mut Picture<COIN>,
        item_id: ID,
        paid: Coin<COIN>,
    ): T {
        let Listing { id, ask, owner } = bag::remove(&mut picture.items, item_id);

        assert!(ask == coin::value(&paid), EAmountIncorrect);

        
        if (table::contains<address, Coin<COIN>>(&picture.payments, owner)) {
            coin::join(
                table::borrow_mut<address, Coin<COIN>>(&mut picture.payments, owner),
                paid
            )
        } else {
            table::add(&mut picture.payments, owner, paid)
        };

        let item = ofield::remove(&mut id, true);
        object::delete(id);
        item
    }

    
    public entry fun buy_and_take<T: key + store, COIN>(
        picture: &mut Picture<COIN>,
        item_id: ID,
        paid: Coin<COIN>,
        ctx: &mut TxContext
    ) {
        transfer::public_transfer(
            buy<T, COIN>(picture, item_id, paid),
            tx_context::sender(ctx)
        )
    }

    /**
     * Function: take_profits
     * Description: Takes profits from selling items on the marketplace.
     * @param picture: &mut Picture<COIN> - Reference to the picture marketplace
     * @param ctx: &mut TxContext - Transaction context
     * @returns: Coin<COIN> - Profits collected
     */
    fun take_profits<COIN>(
        picture: &mut Picture<COIN>,
        ctx: &mut TxContext
    ): Coin<COIN> {
        table::remove<address, Coin<COIN>>(&mut picture.payments, tx_context::sender(ctx))
    }

    
    public entry fun take_profits_and_keep<COIN>(
        picture: &mut Picture<COIN>,
        ctx: &mut TxContext
    ) {
        transfer::public_transfer(take_profits(picture, ctx), tx_context::sender(ctx))
    }

}
