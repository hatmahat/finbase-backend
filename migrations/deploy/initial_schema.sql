create table category_groups (
    id          bigint generated always as identity primary key,
    created_at  timestamptz not null default now(),
    updated_at  timestamptz not null default now(),
    sort_order  int  not null default 0, -- display order in the UI
    name        text not null unique
);

-- Leaf: the category ("Electricity", "Water"…), each belongs to one group
create table categories (
    id          bigint generated always as identity primary key,
    created_at  timestamptz not null default now(),
    updated_at  timestamptz not null default now(),
    category_group_id    bigint not null references category_groups(id) on delete restrict,
    sort_order  int  not null default 0,
    name        text not null unique,
    color       text                              -- optional, for the dashboard pills/bars
);
create index on categories (category_group_id);

create table wallet_types (
    id          bigint generated always as identity primary key,
    created_at  timestamptz not null default now(),
    updated_at  timestamptz not null default now(),
    name        text not null unique, -- 'bank','cash','credit_card','e_wallet','investment','restricted'
    is_liability          boolean not null default false  -- credit card / debt
);

create table currencies (
    id          bigint generated always as identity primary key,
    created_at  timestamptz not null default now(),
    updated_at  timestamptz not null default now(),
    name        text not null unique -- ISO 4217: IDR, SGD, JPY, USD
);

create table wallet_institutions (
    id          bigint generated always as identity primary key,
    created_at  timestamptz not null default now(),
    updated_at  timestamptz not null default now(),
    name        text not null unique -- "BCA", "Mandiri", "BRI", "Nanovest", "GoTrade"
);

create table wallets (
    id                    bigint generated always as identity primary key,
    created_at            timestamptz not null default now(),
    updated_at            timestamptz not null default now(),
    wallet_type_id        bigint not null references wallet_types(id) on delete restrict,
    currency_id           bigint not null references currencies(id) on delete restrict,     
    wallet_institution_id bigint not null references wallet_institutions(id) on delete restrict, -- "BCA", "Nanovest", "GoTrade" 
    sort_order            int not null default 0,
    name                  text not null unique,            -- "BCA (Leisure)", "Cash (Nanovest)", "SGD", "Nanovest (AAPL)", "GoTrade (BTC)"
    opening_balance       numeric(18,2) not null default 0,-- balance when tracking starts; anchors the running balance
    is_active             boolean not null default true   -- archive without deleting
);

create table transaction_types (
    id          bigint generated always as identity primary key,
    created_at  timestamptz not null default now(),
    updated_at  timestamptz not null default now(),
    name        text not null unique, -- 'expense', 'income', 'transfer'
    is_income          boolean not null default false 
);

create table transactions (
    id                    bigint generated always as identity primary key,
    created_at            timestamptz not null default now(),
    updated_at            timestamptz not null default now(),
    txn_date              timestamptz not null,
    currency_id           bigint not null references currencies(id) on delete restrict,  -- for multi-currency support
    amount                numeric(18,2) not null check (amount > 0),    
    transaction_type_id   bigint not null references transaction_types(id) on delete restrict,
    category_id           bigint references categories(id) on delete restrict,   -- leaf category; nullable for transfers / pre-categorization
    wallet_id             bigint not null references wallets(id) on delete restrict,  -- source wallet
    to_wallet_id          bigint references wallets(id) on delete restrict,           -- destination, transfers only
    note                  text,
    raw_description       text,                             -- original bank narration
    balance_after         numeric(18,2),                   -- running balance from the statement line, if present
    fingerprint           text not null unique,            -- dedup key
    model_confidence      numeric(3,2) check (model_confidence >= 0 and model_confidence <= 1),                     -- 0..1 model confidence
    status                text not null default 'pending'
                          check (status in ('pending','approved','rejected')),
    file_name             text
);

create table securities (
    id           bigint generated always as identity primary key,
    created_at   timestamptz not null default now(),
    updated_at   timestamptz not null default now(),
    wallet_id    bigint not null references wallets(id) on delete restrict,  -- which platform holds it (Nanovest, GoTrade)
    ticker       text not null unique,            -- 'SPY', 'AAPL', 'BTC'
    name         text,                            -- 'SPDR S&P 500 ETF'
    asset_class  text not null default 'stock'   -- 'stock','etf','crypto'
);

create table holdings (
    id            bigint generated always as identity primary key,
    created_at    timestamptz not null default now(),
    updated_at    timestamptz not null default now(),
    security_id   bigint not null unique references securities(id) on delete restrict,
    shares        numeric(18,8) not null default 0   -- how many you currently own
);

-- 1. The function: stamp updated_at on the row being modified
create or replace function set_updated_at()
returns trigger as $$
begin
    new.updated_at = now();
    return new;
end;
$$ language plpgsql;

-- 2. Attach it to each table (one trigger per table)
create trigger trg_set_updated_at before update on category_groups
    for each row execute function set_updated_at();

create trigger trg_set_updated_at before update on categories
    for each row execute function set_updated_at();

create trigger trg_set_updated_at before update on wallet_types
    for each row execute function set_updated_at();

create trigger trg_set_updated_at before update on currencies
    for each row execute function set_updated_at();

create trigger trg_set_updated_at before update on wallet_institutions
    for each row execute function set_updated_at();

create trigger trg_set_updated_at before update on wallets
    for each row execute function set_updated_at();

create trigger trg_set_updated_at before update on transaction_types
    for each row execute function set_updated_at();

create trigger trg_set_updated_at before update on transactions
    for each row execute function set_updated_at();

create trigger trg_set_updated_at before update on securities
    for each row execute function set_updated_at();

create trigger trg_set_updated_at before update on holdings
    for each row execute function set_updated_at();

create or replace function check_transfer_shape()
returns trigger as $$
declare
    type_name text;
begin
    -- resolve the FK to its human-readable name
    select name into type_name
    from transaction_types
    where id = new.transaction_type_id;

    if type_name = 'transfer' then
        -- a transfer MUST have a destination, and it can't be the same wallet
        if new.to_wallet_id is null then
            raise exception 'Transfer must have a to_wallet_id (txn from wallet %)', new.wallet_id;
        end if;
        if new.to_wallet_id = new.wallet_id then
            raise exception 'Transfer source and destination wallet cannot be the same (wallet %)', new.wallet_id;
        end if;
    else
        -- expense / income must NOT have a destination wallet
        if new.to_wallet_id is not null then
            raise exception '% must not have a to_wallet_id', type_name;
        end if;
    end if;

    return new;
end;
$$ language plpgsql;

create trigger trg_check_transfer_shape
    before insert or update on transactions
    for each row execute function check_transfer_shape();