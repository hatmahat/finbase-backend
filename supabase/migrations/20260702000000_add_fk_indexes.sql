-- transactions: review queue, dashboard, and wallet balance queries all filter/group on these
create index on transactions (status);
create index on transactions (wallet_id);
create index on transactions (to_wallet_id);
create index on transactions (category_id);
create index on transactions (txn_date);
create index on transactions (currency_id);
create index on transactions (transaction_type_id);
create index on transactions (import_id);

-- wallets: joined against on every transaction read
create index on wallets (wallet_type_id);
create index on wallets (currency_id);
create index on wallets (wallet_institution_id);

-- securities: holdings lookups by platform
create index on securities (wallet_id);
