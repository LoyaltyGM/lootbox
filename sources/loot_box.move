module lootbox::loot_box {
    use movemate::pseudorandom::{Self};

    use std::string::{Self, String};
    use std::vector;
    // use std::debug;
    use sui::event::{emit};
    use sui::object::{Self, UID, ID};
    use sui::transfer;
    use sui::tx_context::{Self, TxContext};
    use sui::url::{Self, Url};
    // use sui::sui::SUI;
    // use sui::coin::{Self, Coin};
    use lootbox::store::{Self};
    use sui::dynamic_object_field as dof;
    use sui::table::{Self};

    // ======== Constants =========
    const LOW_RANGE: u64 = 1;
    const HIGH_RANGE: u64 = 100;
    const BOX_URL: vector<u8> = b"ipfs://QmWkbwdR7JmrpMahjg4YTniq5eF14dyoLwX4pDRPGg7DLy";
    const LOOT_BRONZE_URL: vector<u8> =  b"ipfs://Qma46vSK5UvTaho6NMQ8h1u1coXQ1YcCBUYri2uSJ6PTcT";
    const LOOT_SILVER_URL: vector<u8> =  b"ipfs://QmREjYdo9FhkBez3rPwbHypiS4ZrPYqF1rKzWWTnSd1idj";
    const LOOT_GOLD_URL: vector<u8> =  b"ipfs://QmRTxSnERk8RrdoPhZWL5qRJwVxyc1t9aGYSwqgyS8HY7Z";
    const LOOT_ERROR_URL: vector<u8> = b"ipfs://QmYZCHwX27MkLeoewBdK3vMhNEGs9MNtRTyHgR2dSWVa2S";
    
    // Max minted per address
    const MAX_MINTED_PER_ADDRESS: u64 = 3;
    // For dynamic field table
    const COUNTER_KEY: vector<u8> = b"_box_counter_per_acount";

    // ======== Errors =========
    const EAmountIncorrect: u64 = 0;
    const EMaxSupplyReaced: u64 = 1;
    const EMaxMintedPerAddress: u64 = 2; 

    // ======== Events =========
    /// Event. When minter buy a box.
    struct BuyBoxEvent has copy, drop {
        box_id: ID,
        buyer: address,
    }
    
    /// Event. When start box. 
    struct OpenBoxEvent has copy, drop {
        box_id: ID,
        loot_id: ID,
        opener: address,
    }
    
    // ======== Structs =========
    /// NFT collection which registered here. 
    /// dynamic field vec_map<address, u64>
    struct BoxCollection has key {
        id: UID,
        creator: address,
        box_max_supply: u64,
        box_url: Url,
        box_price: u64,
        rarity_types: vector<String>,
        rarity_weights: vector<u64>,
        // changable
        //_box_counter_per_acount: vec_map<address, u64>,
        _box_minted: u64,
        _box_opened: u64,
    }

    /// Unopened box after buy box 
    struct LootBox has key, store {
        id: UID,
        name: String,
        description: String,
        url: Url,
    }
    /// Open loot with rarity options
    struct Loot has key, store {
        id: UID,
        name: String,
        description: String,
        rarity: String,
        score: u64,
        url: Url
    }

    // ======== Init =========

    fun rarity_type(): vector<String> {
       let rarity_types = vector::empty<String>();
        vector::push_back(&mut rarity_types, string::utf8(b"Bronze"));
        vector::push_back(&mut rarity_types, string::utf8(b"Silver"));
        vector::push_back(&mut rarity_types, string::utf8(b"Gold"));
        rarity_types 
    }

    fun rarity_weight(): vector<u64> {
        let rarity_weights = vector::empty<u64>();
        vector::push_back(&mut rarity_weights, 70);
        vector::push_back(&mut rarity_weights, 25);
        vector::push_back(&mut rarity_weights, 5);
        rarity_weights
    }

    fun init(ctx: &mut TxContext) {
        let rarity_types = rarity_type();
        let rarity_weights = rarity_weight();
        
        let collection = BoxCollection {
            id: object::new(ctx),
            creator: tx_context::sender(ctx),
            box_max_supply: 30_000,
            box_url: url::new_unsafe_from_bytes(BOX_URL),
            box_price: 10_000_000, // 0.01
            rarity_types: rarity_types,
            rarity_weights: rarity_weights,
            _box_minted: 0,
            _box_opened: 0,
        };
        // create dynamic field table with empty table
        dof::add(&mut collection.id, COUNTER_KEY, table::new<address, u64>(ctx));
        transfer::share_object(collection);
    }

    // ======== Public functions =========

    // GETTER  
    // BoxCollection
    public fun get_owner(collection: &BoxCollection): address {
        collection.creator
    }

    public fun get_box_minted(collection: &BoxCollection): u64 {
        collection._box_minted
    }

    public fun get_box_opened(collection: &BoxCollection): u64 {
        collection._box_opened
    }

    // Loot
    public fun get_loot_name(box: &Loot): String {
        box.name
    }

    public fun get_lootbox_rarity(box: &Loot): String {
        box.rarity
    }
    // sui client call --function buy_box --module loot_box --package 0xf23231864bfbd32c76cfc3f55b80df05558cf6a7 --args 0x4a46f378e4df8e1774840d7ea2071652820f618f 10000000 --gas-budget 1000
    // SETTER
    public entry fun buy_box(
        collection: &mut BoxCollection,
        // paid: Coin<SUI>, 
        ctx: &mut TxContext
    ) {

        let n = collection._box_minted + 1;
        let sender = tx_context::sender(ctx);
        
        let table = dof::borrow_mut(&mut collection.id, COUNTER_KEY);
        assert!(n < collection.box_max_supply, EMaxSupplyReaced);
        // assert!(collection.box_price == coin::value(&paid), EAmountIncorrect);
        let isUserExist = store::user_exists(table, sender);
        // check to how many times user minted
        if(isUserExist) {
            assert!(store::get_minted_counter(table, sender) < MAX_MINTED_PER_ADDRESS, EMaxMintedPerAddress);
        };
        
        
        let box = LootBox {
            id: object::new(ctx),
            name: string::utf8(b"Mystery Box"),
            description: string::utf8(b"Unopened box"),
            url: url::new_unsafe_from_bytes(BOX_URL),
        };

        emit(BuyBoxEvent {
            box_id: object::id(&box),
            buyer: sender,
        });


        collection._box_minted = n;
        // update minted counter
        if(isUserExist) {
            store::update_minted_counter(table, sender);
        } else {
            store::add_new_data(table, ctx);
        };

        transfer::transfer(box, sender);
        // transfer::transfer(paid, collection.creator);
    }

    public entry fun open_box(collection: &mut BoxCollection, box: LootBox, ctx: &mut TxContext) {
        let sender = tx_context::sender(ctx);
        let LootBox{ id, name: _, description: _, url: _ } = box;

        let loot = get_loot(collection, ctx);
        // Event for open box
        emit(OpenBoxEvent {
            box_id: object::uid_to_inner(&id),
            loot_id: object::id(&loot),
            opener: sender
        });

        collection._box_opened = collection._box_opened + 1;
        object::delete(id);
        transfer::transfer(loot, sender)
    }

    // ======== Private functions =========

    fun get_loot(collection: &mut BoxCollection, ctx: &mut TxContext): Loot {
        let score = get_loot_score(ctx);
        let rarity = get_loot_rarity(score, collection);
        Loot {
            id: object::new(ctx),
            name: string::utf8(b"LOOT"),
            description: string::utf8(b"LoyaltyGM Loot Prize"),
            rarity: rarity,
            score: score,
            url: get_loot_rarity_url(rarity),
        }
    }

    // set up image url for each rarity
    fun get_loot_rarity_url(rarity: String): Url {
        let rarity_url: Url;
        if (rarity == string::utf8(b"Bronze")) {
            rarity_url = url::new_unsafe_from_bytes(LOOT_BRONZE_URL);
        } else if (rarity == string::utf8(b"Silver")) {
            rarity_url = url::new_unsafe_from_bytes(LOOT_SILVER_URL);
        } else if (rarity == string::utf8(b"Gold")) {
            rarity_url = url::new_unsafe_from_bytes(LOOT_GOLD_URL);
        } else {
            rarity_url = url::new_unsafe_from_bytes(LOOT_ERROR_URL);
        };
        rarity_url
    }

    fun get_loot_score(ctx: &mut TxContext): u64 {
        pseudorandom::rand_u64_range_with_ctx(LOW_RANGE, HIGH_RANGE + 1, ctx)
    }

    fun get_loot_rarity(score: u64, collection: &mut BoxCollection): String {
        let types = collection.rarity_types;
        let weights = collection.rarity_weights;
        
        let result_rarity = *vector::borrow(&types, 0);
        
        let r = score + HIGH_RANGE;
        let length = vector::length(&weights);
        let i = 0;
        loop {
            if (i >= length) break;
            r = r - *vector::borrow(&weights, i);
            if (r <= HIGH_RANGE) {
                result_rarity = *vector::borrow(&types, i);
                break
            };
            i = i + 1;
        };
        
        result_rarity
    }
    
    // https://stackoverflow.com/questions/74513153/test-for-init-function-from-examples-doesnt-works
    #[test_only]
    public fun create_lootbox(ctx: &mut TxContext, max_supply: u64) {
        let rarity_types = rarity_type();
        let rarity_weights = rarity_weight();

        let collection = BoxCollection {
            id: object::new(ctx),
            creator: tx_context::sender(ctx),
            box_max_supply: max_supply,
            box_url: url::new_unsafe_from_bytes(BOX_URL),
            box_price: 10000000,
            rarity_types: rarity_types,
            rarity_weights: rarity_weights,
            _box_minted: 0,
            _box_opened: 0,
        };
        dof::add(&mut collection.id, COUNTER_KEY, table::new<address, u64>(ctx));
        transfer::share_object(collection);  
    }
}
