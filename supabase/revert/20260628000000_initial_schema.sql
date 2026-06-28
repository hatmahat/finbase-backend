-- Revert finbase:initial_schema

drop trigger if exists trg_check_transfer_shape on transactions;
drop trigger if exists trg_set_updated_at on holdings;
drop trigger if exists trg_set_updated_at on securities;
drop trigger if exists trg_set_updated_at on transactions;
drop trigger if exists trg_set_updated_at on transaction_types;
drop trigger if exists trg_set_updated_at on wallets;
drop trigger if exists trg_set_updated_at on wallet_institutions;
drop trigger if exists trg_set_updated_at on currencies;
drop trigger if exists trg_set_updated_at on wallet_types;
drop trigger if exists trg_set_updated_at on categories;
drop trigger if exists trg_set_updated_at on category_groups;

drop function if exists check_transfer_shape();
drop function if exists set_updated_at();

drop table if exists holdings;
drop table if exists securities;
drop table if exists transactions;
drop table if exists transaction_types;
drop table if exists wallets;
drop table if exists wallet_institutions;
drop table if exists currencies;
drop table if exists wallet_types;
drop table if exists categories;
drop table if exists category_groups;

drop type if exists transaction_status;
drop type if exists asset_class_type;
