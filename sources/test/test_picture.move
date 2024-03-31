#[test_only]
module picture::test_picture {
    use sui::test_scenario::{Self as ts, next_tx, Scenario};
    use sui::transfer;
    use sui::test_utils::{assert_eq};
    use sui::kiosk::{Self, Kiosk, KioskOwnerCap};
    use sui::transfer_policy::{Self as tp, TransferPolicy, TransferPolicyCap};
    use sui::object;
    use sui::sui::SUI;
    use sui::coin::{mint_for_testing};
    use sui::coin::{Self, Coin}; 
    use std::string::{Self};
    use std::vector;
    // use std::option::{Self};
    // use std::debug;

    use picture::picture_nft::{Self as picture, Picture, PicturePublisher};
    use picture::floor_price_rule::{Self};
    use picture::royalty_rule::{Self};
    use picture::helpers::{init_test_helper};

    const ADMIN: address = @0xA;
    const TEST_ADDRESS1: address = @0xB;
    const TEST_ADDRESS2: address = @0xC;


    #[test]
    public fun test_create_kiosk() {
        let scenario_test = init_test_helper();
        let scenario = &mut scenario_test;
        // Create an kiosk for marketplace
        next_tx(scenario, TEST_ADDRESS1);
        {
           let cap =  picture::new(ts::ctx(scenario));
           transfer::public_transfer(cap, TEST_ADDRESS1);
        };

        next_tx(scenario, TEST_ADDRESS1);
        {
            let publisher = ts::take_shared<PicturePublisher>(scenario);
            picture::new_policy(&publisher, ts::ctx(scenario));

            ts::return_shared(publisher);
        };

        // create an Picture NFT
        next_tx(scenario, TEST_ADDRESS1);
        {
            let uri_ = string::utf8(b"asd");
            let price: u64 = 1000_000_000_000;

            let picture = picture::create_picture(uri_, price, ts::ctx(scenario));

            transfer::public_transfer(picture, TEST_ADDRESS1);
        };

        let nft_data = next_tx(scenario, TEST_ADDRESS1);
        
        // Place the Picture NFT to kiosk
        next_tx(scenario, TEST_ADDRESS1);
        {
            let picture_ = ts::take_from_sender<Picture>(scenario);
            let kiosk_cap = ts::take_from_sender<KioskOwnerCap>(scenario);
            let kiosk =  ts::take_shared<Kiosk>(scenario);
            // get item id from effects
            let id_ = ts::created(&nft_data);
            let item_id = vector::borrow(&id_, 0);
        
            kiosk::place(&mut kiosk, &kiosk_cap, picture_);

            assert_eq(kiosk::item_count(&kiosk), 1);

            assert_eq(kiosk::has_item(&kiosk, *item_id), true);
            assert_eq(kiosk::is_locked(&kiosk, *item_id), false);
            assert_eq(kiosk::is_listed(&kiosk, *item_id), false);

            ts::return_shared(kiosk);
            ts::return_to_sender(scenario, kiosk_cap);
        };

        // create an transferpolicy
        next_tx(scenario, TEST_ADDRESS1);
        {
            let publisher = ts::take_shared<PicturePublisher>(scenario);

            picture::new_policy(&publisher, ts::ctx(scenario));

            ts::return_shared(publisher);
        };

        // List the Picture NFT to kiosk
        next_tx(scenario, TEST_ADDRESS1);
        {
            let kiosk_cap = ts::take_from_sender<KioskOwnerCap>(scenario);
            let kiosk =  ts::take_shared<Kiosk>(scenario);
            let price : u64 = 1000_000_000_000;
            // get item id from effects
            let id_ = ts::created(&nft_data);
            let item_id = vector::borrow(&id_, 0);
        
            kiosk::list<Picture>(&mut kiosk, &kiosk_cap, *item_id, price);

            assert_eq(kiosk::item_count(&kiosk), 1);

            assert_eq(kiosk::has_item(&kiosk, *item_id), true);
            assert_eq(kiosk::is_locked(&kiosk, *item_id), false);
            assert_eq(kiosk::is_listed(&kiosk, *item_id), true);

            ts::return_shared(kiosk);
            ts::return_to_sender(scenario, kiosk_cap);
        };

        // purchase the item
        next_tx(scenario, TEST_ADDRESS2);
        {
            let kiosk =  ts::take_shared<Kiosk>(scenario);
            let policy = ts::take_shared<TransferPolicy<Picture>>(scenario);
            let price  = mint_for_testing<SUI>(1000_000_000_000, ts::ctx(scenario));
            // get item id from effects
            let id_ = ts::created(&nft_data);
            let item_id = vector::borrow(&id_, 0);
        
            let (item, request) = kiosk::purchase<Picture>(&mut kiosk, *item_id, price);

            // confirm the request. Destroye the hot potato
            let (item_id, paid, from ) = tp::confirm_request(&policy, request);

            assert_eq(kiosk::item_count(&kiosk), 0);
            assert_eq(kiosk::has_item(&kiosk, item_id), false);

            transfer::public_transfer(item, TEST_ADDRESS2);
         
            ts::return_shared(kiosk);
            ts::return_shared(policy);
        };
         ts::end(scenario_test);
    }
}
