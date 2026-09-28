-- Run this once, after mohanedsamehelghazouly22@gmail.com has signed in at
-- least once (via "Continue with Google", so email is populated and their
-- row exists in public.users). Then re-run any time you need to promote a
-- different account the same way.
update public.users
set role = 'admin'
where email = 'mohanedsamehelghazouly22@gmail.com';
