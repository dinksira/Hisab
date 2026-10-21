-- ====================================================================
-- HISAB DATABASE AUTHORIZATION & ROW LEVEL SECURITY TESTS
-- ====================================================================

BEGIN;
SELECT plan(12);

-- 1. Test anonymous access is blocked on profiles
SET ROLE anon;
SELECT throws_ok(
    $$ SELECT * FROM public.profiles $$,
    'permission denied for table profiles',
    'Anonymous user cannot read profiles table'
);

-- 2. Setup mock users
SET ROLE postgres;
INSERT INTO auth.users (id, email) VALUES 
('11111111-1111-1111-1111-111111111111', 'userA@hisab.app'),
('22222222-2222-2222-2222-222222222222', 'userB@hisab.app')
ON CONFLICT DO NOTHING;

-- 3. Test User A can create and view their own account
SET ROLE authenticated;
SET request.jwt.claim.sub = '11111111-1111-1111-1111-111111111111';

INSERT INTO public.accounts (id, user_id, name, account_type, currency_code, opening_balance)
VALUES ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', '11111111-1111-1111-1111-111111111111', 'User A Checking', 'checking', 'USD', 500);

SELECT results_eq(
    $$ SELECT name FROM public.accounts WHERE id = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa' $$,
    $$ VALUES ('User A Checking') $$,
    'User A can see their own created account'
);

-- 4. Test User B cannot read User A's account
SET request.jwt.claim.sub = '22222222-2222-2222-2222-222222222222';
SELECT is_empty(
    $$ SELECT * FROM public.accounts WHERE id = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa' $$,
    'User B cannot view User A account'
);

-- 5. Test User B cannot insert a transaction belonging to User A
SELECT throws_ok(
    $$ INSERT INTO public.transactions (user_id, account_id, transaction_type, amount, currency_code, description, transaction_date)
       VALUES ('11111111-1111-1111-1111-111111111111', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'expense', 50, 'USD', 'Hacked Tx', '2026-10-21') $$,
    'new row violates row-level security policy for table "transactions"',
    'User B cannot insert transaction on behalf of User A'
);

-- 6. Test User B cannot insert a transaction referencing User A account
INSERT INTO public.accounts (id, user_id, name, account_type, currency_code, opening_balance)
VALUES ('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', '22222222-2222-2222-2222-222222222222', 'User B Cash', 'cash', 'USD', 200);

SELECT throws_ok(
    $$ INSERT INTO public.transactions (user_id, account_id, transaction_type, amount, currency_code, description, transaction_date)
       VALUES ('22222222-2222-2222-2222-222222222222', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'expense', 50, 'USD', 'Cross-user account Tx', '2026-10-21') $$,
    'new row violates row-level security policy for table "transactions"',
    'User B cannot associate their transaction with User A account'
);

-- 7. Test User A cannot delete or modify system categories
SET request.jwt.claim.sub = '11111111-1111-1111-1111-111111111111';
SELECT is_empty(
    $$ DELETE FROM public.categories WHERE is_system = true RETURNING id $$,
    'Ordinary user cannot delete system categories'
);

SELECT is_empty(
    $$ UPDATE public.categories SET name = 'Corrupted' WHERE is_system = true RETURNING id $$,
    'Ordinary user cannot update system categories'
);

-- 8. Test System categories are readable by User A
SELECT is_not_empty(
    $$ SELECT id FROM public.categories WHERE is_system = true $$,
    'Authenticated user can read system categories'
);

-- 9. Test cross-user transfer is rejected by RLS
SELECT throws_ok(
    $$ INSERT INTO public.transfers (user_id, from_account_id, to_account_id, amount, currency_code, transfer_date)
       VALUES ('11111111-1111-1111-1111-111111111111', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', 100, 'USD', '2026-10-21') $$,
    'new row violates row-level security policy for table "transfers"',
    'Transfers across different users accounts are strictly rejected by RLS'
);

-- 10. Test same account transfer is rejected by check constraint
SELECT throws_ok(
    $$ INSERT INTO public.transfers (user_id, from_account_id, to_account_id, amount, currency_code, transfer_date)
       VALUES ('11111111-1111-1111-1111-111111111111', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 100, 'USD', '2026-10-21') $$,
    'chk_transfers_different_accounts',
    'Transfer from and to the exact same account is rejected by constraint'
);

-- 11. Test User A cannot alter ownership of account to User B
SELECT throws_ok(
    $$ UPDATE public.accounts SET user_id = '22222222-2222-2222-2222-222222222222' WHERE id = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa' $$,
    'new row violates row-level security policy for table "accounts"',
    'User cannot change account ownership to another user'
);

-- 12. Test budget alert thresholds default
INSERT INTO public.budgets (id, user_id, name, amount, currency_code, period_type, start_date)
VALUES ('cccccccc-cccc-cccc-cccc-cccccccccccc', '11111111-1111-1111-1111-111111111111', 'Monthly Food', 400, 'USD', 'monthly', '2026-10-01');

SELECT results_eq(
    $$ SELECT name FROM public.budgets WHERE id = 'cccccccc-cccc-cccc-cccc-cccccccccccc' $$,
    $$ VALUES ('Monthly Food') $$,
    'User can create and retrieve their monthly budget'
);

SELECT * FROM finish();
ROLLBACK;
