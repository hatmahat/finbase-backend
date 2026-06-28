-- transaction_types
insert into transaction_types (name, is_income) values
    ('expense',  false),
    ('income',   true),
    ('transfer', false)
on conflict (name) do nothing;

-- currencies
insert into currencies (name) values
    ('IDR'), ('USD'), ('SGD'), ('JPY')
on conflict (name) do nothing;

-- wallet_types
insert into wallet_types (name, is_liability) values
    ('bank',        false),
    ('cash',        false),
    ('credit_card', true),
    ('e_wallet',    false),
    ('investment',  false),
    ('restricted',  false)
on conflict (name) do nothing;

-- wallet_institutions
insert into wallet_institutions (name) values
    ('BCA'), ('BRI'), ('Mandiri'), ('Sinarmas'), ('Nanovest'), ('GoTrade'), ('Virtual')
on conflict (name) do nothing;

-- category_groups
insert into category_groups (sort_order, name) values
    (1,  'Income'),
    (2,  'Housing'),
    (3,  'Food & Drink'),
    (4,  'Health'),
    (5,  'Transport'),
    (6,  'Travel'),
    (7,  'Entertainment'),
    (8,  'Subscriptions'),
    (9,  'Shopping'),
    (10, 'Personal'),
    (11, 'Education'),
    (12, 'Finance'),
    (13, 'Tax'),
    (14, 'Transfers'),
    (15, 'Other')
on conflict (name) do nothing;

-- categories (FK resolved by name subquery)
insert into categories (category_group_id, sort_order, name)
select g.id, v.sort_order::int, v.name
from (values
    -- Income
    ('Income',        1, 'Income'),
    ('Income',        2, 'Salary'),
    ('Income',        3, 'Investment'),
    -- Housing
    ('Housing',       1, 'Electricity'),
    ('Housing',       2, 'Water'),
    ('Housing',       3, 'Internet'),
    ('Housing',       4, 'Home Maintenance'),
    ('Housing',       5, 'Home Supplies'),
    -- Food & Drink
    ('Food & Drink',  1, 'Food'),
    ('Food & Drink',  2, 'Groceries'),
    ('Food & Drink',  3, 'Coffee'),
    ('Food & Drink',  4, 'Drinks'),
    ('Food & Drink',  5, 'Treat'),
    -- Health
    ('Health',        1, 'Doctor'),
    ('Health',        2, 'Medication'),
    ('Health',        3, 'Health Insurance'),
    ('Health',        4, 'Life Insurance'),
    ('Health',        5, 'Gym'),
    -- Transport
    ('Transport',     1, 'Taxi'),
    ('Transport',     2, 'Public Transport'),
    ('Transport',     3, 'Parking'),
    ('Transport',     4, 'Tolls'),
    ('Housing',       5, 'Gas'),
    -- Travel
    ('Travel',        1, 'Flight'),
    ('Travel',        2, 'Hotel'),
    ('Travel',        3, 'Vacation'),
    ('Travel',        4, 'Travel Attractions'),
    -- Entertainment
    ('Entertainment',  1, 'Cinema'),
    ('Entertainment',  2, 'Games'),
    -- Subscriptions
    ('Subscriptions',  1, 'Streaming'),
    ('Subscriptions',  2, 'Software & AI'),
    ('Subscriptions',  3, 'Gaming Subscription'),
    ('Subscriptions',  4, 'Other Subscription'),
    -- Shopping
    ('Shopping',      1, 'Shopping'),
    ('Shopping',      2, 'Fashion'),
    ('Shopping',      3, 'Cosmetics'),
    ('Shopping',      4, 'Electronics'),
    -- Personal
    ('Personal',      1, 'Laundry'),
    ('Personal',      2, 'Cellphone'),
    ('Personal',      3, 'Telephone'),
    ('Personal',      4, 'Maintenance'),
    -- Education
    ('Education',     1, 'Education'),
    -- Finance
    ('Finance',       1, 'Bank Fees'),
    ('Finance',       2, 'Credit Card'),
    ('Finance',       3, 'Cash'),
    ('Finance',       4, 'Zakat'),
    ('Finance',       5, 'Charity'),
    -- Tax
    ('Tax',           1, 'Income Tax'),
    ('Tax',           2, 'Vehicle Tax'),
    ('Tax',           3, 'Other Tax'),
    -- Transfers
    ('Transfers',     1, 'Transfer'),
    -- Other
    ('Other',         1, 'Others'),
    ('Other',         2, 'Miscellaneous'),
    ('Other',         3, 'Unknown')
) as v(group_name, sort_order, name)
join category_groups g on g.name = v.group_name
on conflict (name) do nothing;
