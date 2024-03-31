#[test_only]
module picture::test_picture {
    use sui::test_scenario::{Self as ts, next_tx, Scenario};
 
    use std::string::{Self};
    use std::vector;
    // use std::option::{Self};
    // use std::debug;

    use picture::picture_nft::{Picture};
    use picture::floor_price_rule::{Self};
    use picture::royalty_rule::{Self};
    use picture::helpers::{init_test_helper};

    const ADMIN: address = @0xA;
    const TEST_ADDRESS1: address = @0xB;
    const TEST_ADDRESS2: address = @0xC;


    #[test]
    public fun test_rules_fail() {
        let scenario_test = init_test_helper();
        let scenario = &mut scenario_test;
        // Admin trying to create same types so we are expecting error
        next_tx(scenario, ADMIN);
        {
        
        };
         ts::end(scenario_test);
    }







}