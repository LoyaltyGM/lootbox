// // Copyright (c) LoyaltyGM.

#[test_only]
module lootbox::loot_box_tests {
    use lootbox::loot_box;
    use sui::test_scenario::{Self, Scenario};
    use std::string;
    use std::debug;
    // use sui::sui::SUI;
    // use sui::coin;

     // So these are our heroes.
    const OWNER: address = @0x0;
    const MINTER_1: address = @0x1;
    const MINTER_2: address = @0x2;
    const RANDOM: address = @123;

    const COIN_TO_BUY_BOX: u64 = 10000000; 
    const LESS_COINS_TO_BUY_BOX: u64 = 10;

    const MAX_SUPPLY: u64 = 1000;
    const LESS_MAX_SUPPLY: u64 = 3;

    fun create_collection(scenario: &mut Scenario, max_supply: u64){
        
        // Create lootbox collection 
        test_scenario::next_tx(scenario, OWNER);
        {
            loot_box::create_lootbox(test_scenario::ctx(scenario), max_supply);
        };
    }

    fun buy_one_lootbox(scenario: &mut Scenario, _: u64) {
        // buy one box 
        test_scenario::next_tx(scenario, MINTER_1);
        {
           // get struct BoxCollection
            let lootbox_val = test_scenario::take_shared<loot_box::BoxCollection>(scenario);
            let lootbox = &mut lootbox_val;
            // let sui = coin::mint_for_testing<SUI>(token_paid, test_scenario::ctx(scenario));
            loot_box::buy_box(
                lootbox, 
                // sui, 
                test_scenario::ctx(scenario)
            );
            assert!(loot_box::get_box_minted(lootbox) == 1, 1);
            // !!! need to return called structure
            test_scenario::return_shared(lootbox_val);
        };
    }

    fun buy_multiple_times(scenario: &mut Scenario, _: u64, number_of_buy_boxes: u64) {
        // buy one box 
        test_scenario::next_tx(scenario, MINTER_1);
        {
           // get struct BoxCollection
           let lootbox_val = test_scenario::take_shared<loot_box::BoxCollection>(scenario);
           let lootbox = &mut lootbox_val;
           let i = 0;
           while (i < number_of_buy_boxes) {
                // let sui = coin::mint_for_testing<SUI>(token_paid, test_scenario::ctx(scenario));
                loot_box::buy_box(
                    lootbox, 
                    // sui, 
                    test_scenario::ctx(scenario)
                );
                i = i + 1;
           };
           assert!(loot_box::get_box_minted(lootbox) == number_of_buy_boxes, 1);
           // !!! need to return called structure
           test_scenario::return_shared(lootbox_val);
        };
    }

    fun open_lootbox(scenario: &mut Scenario, tx_executor: address) {
        test_scenario::next_tx(scenario, tx_executor);
        {
           let box_val = test_scenario::take_from_sender<loot_box::LootBox>(scenario);
           let lootbox_val = test_scenario::take_shared<loot_box::BoxCollection>(scenario);
           let lootbox = &mut lootbox_val;
           debug::print(&box_val);
           assert!(loot_box::get_box_minted(lootbox) == 1, 1);
           // open box
           loot_box::open_box(lootbox, box_val, test_scenario::ctx(scenario));
           assert!(loot_box::get_box_opened(lootbox) == 1, 2);
           test_scenario::return_shared(lootbox_val);
        };
    }

    fun get_box(scenario: &mut Scenario) {
        test_scenario::next_tx(scenario, MINTER_1);
        {
            let box_val = test_scenario::take_from_sender<loot_box::Loot>(scenario);
            assert!(loot_box::get_loot_name(&box_val) == string::utf8(b"LOOT"), 1);
            test_scenario::return_to_sender(scenario, box_val);
        }
    }

    #[test]
    fun normal_workflow() {
        let scenario_val = test_scenario::begin(OWNER);
        let scenario = &mut scenario_val;

        create_collection(scenario, MAX_SUPPLY);
        buy_one_lootbox(scenario, COIN_TO_BUY_BOX);
        open_lootbox(scenario, MINTER_1);
        get_box(scenario);
        test_scenario::end(scenario_val);
    }

    // #[test]
    // #[expected_failure(abort_code = 0)]
    // fun open_lootbox_from_another_wallet() {
    //     let scenario_val = test_scenario::begin(OWNER);
    //     let scenario = &mut scenario_val;

    //     create_collection(scenario, MAX_SUPPLY);
    //     buy_one_lootbox(scenario, COIN_TO_BUY_BOX);
    //     // Buy Lootbox from one person and open from another person
    //     open_lootbox(scenario, MINTER_2);
    //     // get_box(scenario);
    //     test_scenario::end(scenario_val);
    // }

    // #[test]
    // #[expected_failure(abort_code = lootbox::loot_box::EAmountIncorrect)]
    // fun error_not_enough_money() {
    //     let scenario_val = test_scenario::begin(OWNER);
    //     let scenario = &mut scenario_val;
    //     create_collection(scenario, MAX_SUPPLY);
    //     buy_one_lootbox(scenario, LESS_COINS_TO_BUY_BOX);
    //     test_scenario::end(scenario_val);
    // }

    #[test]
    #[expected_failure(abort_code = lootbox::loot_box::EMaxSupplyReaced)]
    fun error_max_supply_is_over() {
        let scenario_val = test_scenario::begin(OWNER);
        let scenario = &mut scenario_val;
        create_collection(scenario, LESS_MAX_SUPPLY);
        buy_multiple_times(scenario, COIN_TO_BUY_BOX, LESS_MAX_SUPPLY);
        test_scenario::end(scenario_val);
    }

    #[test]
    #[expected_failure(abort_code = lootbox::loot_box::EMaxMintedPerAddress)]
    fun error_per_max_minted_per_address() {
        let scenario_val = test_scenario::begin(OWNER);
        let scenario = &mut scenario_val;
        create_collection(scenario, MAX_SUPPLY);
        buy_multiple_times(scenario, COIN_TO_BUY_BOX, 4);
        test_scenario::end(scenario_val);
    }
    

}