# Echo Paintworks — Account System Setup Guide

Follow these steps in order. Nothing here requires coding — just copying
values into the right boxes.

## 1. Set up the database (Supabase)

1. Go to your Supabase project → **SQL Editor** → **New query**.
2. Open `supabase-schema.sql` (included in this folder), copy the whole
   thing, paste it in, and click **Run**.
3. Go to **Authentication → Providers → Email**, and turn **OFF**
   "Confirm email" — this lets people log in immediately after signing
   up instead of waiting on a confirmation email (simpler at your scale).
4. Grab your **service_role key**: Project Settings → API → you'll see
   it below the anon/publishable key you already gave me, labeled
   `service_role` — **secret**, never put this in the website's code.
   Send it to me, or set it directly yourself in step 3 below.

## 2. Deploy the updated site files

Same as before — upload this whole folder to your Cloudflare Pages
project (drag-and-drop the folder contents, including the `functions`
folder this time — Cloudflare automatically turns those into working
backend endpoints).

## 3. Set environment variables in Cloudflare Pages

Go to your Pages project → **Settings → Environment variables**, and
add each of these (Production environment):

| Variable name | Value |
|---|---|
| `SUPABASE_URL` | `https://gqzqbrmprwssodopmxan.supabase.co` |
| `SUPABASE_SERVICE_ROLE_KEY` | (from step 1.4 above) |
| `STRIPE_SECRET_KEY` | your Stripe secret key (`sk_test_...` for now) |
| `STRIPE_WEBHOOK_SECRET` | (see step 4 below) |
| `TWILIO_ACCOUNT_SID` | your Twilio Account SID |
| `TWILIO_AUTH_TOKEN` | your Twilio Auth Token |
| `TWILIO_PHONE_NUMBER` | `+17787650471` |
| `RESEND_API_KEY` | your Resend API key |
| `RESEND_FROM_EMAIL` | `hello@echopaintworks.com` (once your Resend domain is verified) |
| `ADMIN_EMAIL` | the email you want signup/message alerts sent to |

After adding these, redeploy the site once (Cloudflare Pages has a
"Retry deployment" or you can just re-upload) so the functions pick up
the new values.

## 4. Connect Stripe's webhook

1. In Stripe: **Developers → Webhooks → Add endpoint**.
2. Endpoint URL: `https://echopaintworks.com/api/stripe-webhook`
3. Select event: `checkout.session.completed`
4. After creating it, Stripe shows a **Signing secret** (`whsec_...`) —
   copy that into `STRIPE_WEBHOOK_SECRET` in Cloudflare (step 3).

## 5. Connect Twilio's inbound text webhook

1. In Twilio Console: **Phone Numbers → your number → Messaging
   configuration**.
2. Under "A message comes in," set the webhook to:
   `https://echopaintworks.com/api/sms-webhook`
3. Method: **HTTP POST**. Save.

## 6. Make yourself the admin

1. Go to echopaintworks.com/signup.html and create your own account
   (use your real name/email — this becomes your admin login).
2. Back in Supabase SQL Editor, run:
   ```sql
   update public.profiles set role = 'admin' where email = 'YOUR-EMAIL-HERE';
   ```
3. Log out and back in at echopaintworks.com/login.html — you should
   land on the admin dashboard instead of the customer one.

## 7. Test it end to end

1. Sign up as a *second*, fake test account (use a real email you can
   check, and your own phone number so you can see the test text).
2. Confirm: welcome email arrives, welcome text arrives, and you (admin)
   get a "new signup" email.
3. Log in as admin, find that test customer, change their status, and
   send them a reply — confirm it arrives as a text.
4. Reply to that text from your phone — confirm it shows up in the
   admin dashboard and you get an email alert.
5. Create a payment link for that test customer and pay it with a
   [Stripe test card](https://docs.stripe.com/testing#cards) (e.g.
   4242 4242 4242 4242, any future date, any CVC) — confirm the
   project flips to "Paid" automatically.

Once all of that works, finish the Twilio Campaign registration form
(the one we paused earlier) using your real, live signup page, Privacy
Policy, and Terms links — everything it needs now actually exists.

When you're ready to go live for real, swap `STRIPE_SECRET_KEY` for
your `sk_live_...` key and update the Stripe webhook to point at your
live-mode endpoint too.
