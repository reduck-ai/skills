---
name: saas-invoices
description: |
  Fetch and download invoices for paid SaaS through Reduck (local Chrome + the
  real browser profile's cookies). Use when the user wants the invoice/receipt
  PDF for a SaaS vendor, every invoice for one tool, or a sweep across all paid
  subscriptions: one `<host>/list_invoices` script per SaaS returns each
  invoice's URL, then a generic download step fetches the PDF. Triggers:
  "get/download the invoice for <SaaS>", "<SaaS> invoices", "all my SaaS
  invoices", "list invoices for X". NOT for: vendors with no web billing portal
  (invoice arrives by email) — fall back to the user's mail; and NOT for making
  payments or any billing-account changes. Needs the reduck base plugin.
license: Complete terms in LICENSE
---

# saas-invoices — SaaS invoices via Reduck

Builds on the **`reduck`** base skill. The reduck agent must run with cookies:
`reduck local --cookies` (reads the user's real Chrome). If several devices are
online, target the right one (`deviceId` from `list_devices`) on BOTH
`start_session` and `run_script`.

## Triage — pick the category first

- **A. SaaS with a web billing portal** → use **Reduck** (default; see below).
- **B. Vendor whose invoice arrives by email** (no self-service portal: agencies, freelancers, one-off suppliers, mail-billed subscriptions) → **do NOT use Reduck**, search the user's **mail** (see Category B).

If the vendor doesn't look like a web SaaS — or no script covers it and it has no self-service portal — **offer to search the user's mail** (Category B) instead of forcing Reduck.

## Category A — web SaaS: the process is STANDARD (true for any SaaS)

1. **List** → `run_script <host>/list_invoices` (loggedIn). Normalised output: each
   invoice carries one URL among `hostedInvoiceUrl` / `pdfUrl` / `invoiceUrl` /
   `receiptUrl` / `invoicePdfUrl` (+ date, amount, status).
2. **Route the download** by the **URL's domain** (see § Download).
3. **Download** the PDF.

> ⚠️ **A SaaS not listed below is NOT necessarily missing.** Before concluding or
> rebuilding, **search the public scripts first**:
> - `list_scripts handle=reduck q=<host>` (org catalogue / project)
> - `list_scripts q=<host>` (your own scripts)
> - `read_script <host> list_invoices` to inspect the contract.
> Slug convention: `list_invoices` (sometimes `list-invoices` / `latest-invoice`).
> Only if nothing exists → build one (same contract) under your own account
> (the `reduck` catalogue handle is **write-locked**).

### Example hosts with a `list_invoices` script (`run_script <host>/list_invoices`)
These are common SaaS used to illustrate each download route. Treat the table as
a pattern reference, not an exhaustive list — search the catalogue for the host
you need.

| Host (slug=list_invoices) | Args | URL returned | Download |
|---|---|---|---|
| `cursor.com` | — | hostedInvoiceUrl (Stripe) | download_invoice_pdf |
| `loom.com` | `limit` | hostedInvoiceUrl (Stripe) | download_invoice_pdf |
| `huggingface.co` | — | hostedInvoiceUrl (when present) | download_invoice_pdf |
| `tally.so` | — | hostedInvoiceUrl (Stripe portal) | download_invoice_pdf |
| `browserbase.com` | `org` | hostedInvoiceUrl + pdfUrl | download_invoice_pdf / download_pdf_url |
| `vercel.com` | `team` | vercelInvoiceUrl (detail page → pay.stripe pdf) | download_pdf_url (1 hop) |
| `dashboard.ngrok.com` | — | invoiceUrl (Orb) + pdfUrl | download_pdf_url |
| `app.mailgun.com` | — | invoiceUrl (Chargify) | insert `.pdf` in URL → download_pdf_url |
| `mailchimp.com` | — | receiptUrl (receipt page) | loggedIn download (button) |
| `plausible.io` | — | receiptUrl (Paddle) | Paddle = HTML, no native PDF |
| `<vendor>` (session-gated PDF) | — | invoicePdfUrl (direct PDF, behind session) | curl+cookie / loggedIn download_pdf_url |
| `figma.com` | — | loops ALL teams (via /api/user/state), invoiceUrl per invoice | per URL |

### Already in the catalogue (`handle=reduck`)
`claude.ai` (Anthropic) · `chatgpt.com` (OpenAI) · `notion.so` + `app.notion.com` ·
`slack.com` · `cloudflare.com` · `github.com` (slug `list-invoices`) ·
`admin.google.com` (Google Workspace, `list-invoices`) · `asana.com` · `calendly.com` ·
`members.wework.com` / `accounts.wework.com` (`list-invoices`) · `mistral.ai` (`latest-invoice`).

### Missing a SaaS? Build it — it's quick, always the same model
A `list_invoices` script is cheap to write because every one follows the **same
contract**. Don't treat a missing host as a dead end: after the search above turns
up nothing, scaffold a new one on the template below (a few minutes), publish it
under your own account as `<host>/list_invoices`, then run it like any other.

Same model, every time:
1. **loggedIn**, cookies for the **app subdomain** that actually holds the session
   (e.g. `dashboard.<host>`, `app.<host>`), not the root domain.
2. **Navigate** to the billing / invoices / receipts page.
3. **Scrape** each invoice row and **return normalised records** — the only output
   contract the rest of this skill relies on:
   ```
   [{ date, amount, status,
      // exactly ONE url field, whichever the SaaS exposes:
      hostedInvoiceUrl | pdfUrl | invoiceUrl | receiptUrl | invoicePdfUrl }]
   ```
4. The download step is already generic (see § Download) — it routes on the URL's
   domain, so a new host needs **no new download code** as long as it returns one of
   those URL fields. Copy the closest existing host (Stripe-backed → clone
   `cursor.com`; Orb → `dashboard.ngrok.com`; Chargify → `app.mailgun.com`) and just
   swap the navigation + row selectors.

## Download — 2 primitives + curl, routed by URL domain

Routing happens **agent-side** (not a dispatcher inside one script: 1 Reduck script = 1 host / 1 cookie scope).

| Invoice URL | How to download |
|---|---|
| `invoice.stripe.com/i/...` (Stripe hosted) | `run_script invoice.stripe.com/download_invoice_pdf {hosted_invoice_url}` (public, **no login**) |
| Already-`.pdf` public URL (`pay.stripe.com/.../pdf`, `assets.withorb.com/...`, Chargify `....pdf?token`) | `run_script reduck.ai/download_pdf_url {url}` — **or** `curl -L -o f.pdf "<url>"` |
| Chargify (`chargifypay.com/invoice/inv_X?token=`) | insert `.pdf` → `.../inv_X.pdf?token=` then download_pdf_url |
| Vercel (detail page) | extract the `pay.stripe.com/.../pdf` from the page → download_pdf_url |
| PDF behind a session (direct `invoicePdfUrl`) | dedicated `loggedIn:true` download on its host, or curl with the cookie |
| Paddle (`my.paddle.com/receipt`), Mailchimp (`billing-receipt`) | HTML receipt, no direct PDF → print-to-PDF / loggedIn Download click |

Both download scripts live in the catalogue: `invoice.stripe.com/download_invoice_pdf` and `reduck.ai/download_pdf_url`.

## Category B — invoice by email (not a web SaaS)

When the vendor has no self-service portal (or isn't a SaaS), don't use Reduck — look in the user's mailbox:

- **AI-first**: ask the model whether there's an invoice, **explicitly requesting EVERY email that could correspond** (all candidates, not just one), then **open and follow every proposed link / attachment** to get the PDF.
- **Fallback (no AI search available)**: keyword search — vendor name + `invoice` / `receipt` / `billing`, and also try the equivalents in the user's language(s) (e.g. FR `facture` / `reçu`, ES `factura` / `recibo` / `comprobante`, DE `Rechnung` / `Beleg` / `Quittung`). Then inspect each candidate's links and attachments.

If the user already has local mail access set up, use it; otherwise propose a small targeted mail search. Let the user choose.

## Auth — what does NOT work via cookies (don't keep trying)
Token/localStorage/Clerk auth → cookie injection never authenticates:
**Supabase, ClickUp, Serper, Discord, usestable, Dropcontact**.
Reauth/SSO/anti-bot: **Adobe** (forced reauth), **Atlassian** (`id.atlassian.com`), **GoDaddy** (Akamai).

## Gotchas
- **Subdomain**: load cookies for the **app subdomain** (e.g. `dashboard.ngrok.com`, `app.mailgun.com`), not the root domain.
- **False "not doable"**: often just **not logged in** at test time (Browserbase/ngrok/Mailgun worked once logged in / on the right subdomain). Re-check after login before concluding token-auth. **Cookie count does NOT prove login.**
- **Cross-profile**: reduck reads only ONE Chrome profile (the one with remote-debugging on); no profile selector. If a SaaS is only logged in on another profile → open it in the profile reduck reads, or enable debugging on that profile.
- **Heavy SPAs** (Mailchimp): `page.goto(..., {waitUntil:"domcontentloaded"})` (`load` never settles). Hidden PDF links → `waitFor(..., "attached")`.
