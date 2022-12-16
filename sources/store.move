module lootbox::store {
    friend lootbox::loot_box;

    use sui::table::{Self, Table};
    use sui::tx_context::{Self, TxContext};
    
    // ======= PUBLIC FUNCTIONS =======
    public fun user_exists(table: &Table<address, u64>, owner: address): bool {
        table::contains(table, owner)
    }

    public fun get_minted_counter(table: &mut Table<address, u64>, owner: address): u64{
        *table::borrow<address, u64>(table, owner)
    }

    public(friend) fun add_new_data(
        table: &mut Table<address, u64>, 
        ctx: &mut TxContext
    ) {
        let sender = tx_context::sender(ctx);
        table::add(table, sender, 1)
    }

    public(friend) fun update_minted_counter(table: &mut Table<address, u64>, owner: address) {
        let user_data = *table::borrow<address, u64>(table, owner);
        table::remove(table, owner);
        table::add(table, owner, user_data + 1);
    }

}