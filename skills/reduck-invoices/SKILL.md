---
name: reduck-invoices
description: |
    Fetch and download invoices for paid SaaS. Use for the invoice or receipt PDF
    of one vendor, every invoice for one tool, or a sweep across all paid
    subscriptions: a per-host `list_invoices` script returns each invoice's URL,
    then a generic download step fetches the PDF.
    NOT for vendors that only email invoices (search the user's mail instead),
    and NOT for making payments or changing a billing account.
---

# Requirements

- **Reduck MCP, with the browser extension installed.** If it isn't set up, follow the instructions at [start.reduck.ai](https://start.reduck.ai/).

**Per-vendor listing** — one script per host, slug `list_invoices`

- **`reduck/<host>/list_invoices`** — find the ones that exist with `list_scripts q:"list_invoices"`, or `list_scripts host:"<host>"` for one vendor.

**Downloading**

- **`reduck/invoice.stripe.com/download_invoice_pdf`**
- **`reduck/reduck.ai/download_pdf_url`**

**Self-login, where a host has it**

- **`reduck/<host>/login_with_google`** — find with `list_scripts q:"login" host:"<host>"`.

Read their contracts live with `read_script` Reduck MCP.

Everything runs on your paired browser and inherits its sessions, so a vendor
you're already signed into needs no extra step.

# Triage — pick the category first

- **A. The SaaS has a web billing portal** → the flow below.
- **B. The invoice arrives by email** (no self-service portal: agencies,
  freelancers, one-off suppliers) → don't use a browser script, search the user's
  mail. Ask for **every** candidate message, then open each proposed link and
  attachment. If there's no AI mail search, keyword-search the vendor name plus
  `invoice` / `receipt` / `billing` — and the same words in the user's other
  languages (FR `facture`, ES `factura`, DE `Rechnung`).

If a vendor doesn't look like a web SaaS, offer category B rather than forcing a
browser run.

# The flow — category A

1. **Find the script.** `list_scripts host:"<host>"`. The slug convention is
   `list_invoices`, sometimes `list-invoices` or `latest-invoice`. **A vendor
   missing from your memory is not a vendor missing from the catalogue** — always
   search before concluding anything.
2. **List.** Run it. Every one returns the same normalised shape: per invoice a
   date, amount, status, and exactly one URL field —
   `hostedInvoiceUrl` / `pdfUrl` / `invoiceUrl` / `receiptUrl` / `invoicePdfUrl`.
   Some hosts download the PDF themselves and return a path instead.
3. **Route the download on the URL's domain**, not on the vendor. Routing happens
   here, in the agent — one script covers one host and one session, so there is no
   dispatcher inside a script.

| Invoice URL | How to download |
| --- | --- |
| `invoice.stripe.com/i/…` | `invoice.stripe.com/download_invoice_pdf` — public tokenized link, no login, works for any Stripe-billed vendor |
| An already-`.pdf` public URL (`pay.stripe.com/…/pdf`, `assets.withorb.com/…`, Chargify `….pdf?token`) | `reduck.ai/download_pdf_url` |
| Chargify `chargifypay.com/invoice/inv_X?token=` | insert `.pdf` → `…/inv_X.pdf?token=`, then `download_pdf_url` |
| A vendor detail page (e.g. Vercel) | open it, extract the Stripe PDF link, then `download_pdf_url` |
| A PDF behind the vendor's own session | that vendor's own download script — a public downloader can't reach it |
| An HTML receipt with no PDF (Paddle, Mailchimp) | print to PDF |

# Auto-SSO — ask once, upfront

Many hosts have a `login_with_google` script that drives the Google SSO flow.
**Only offer this where such a script actually exists** — search, never invent one.

At the start of the run, once you know which vendors are in scope, ask **one**
question covering all of them: may you use auto-SSO on the hosts that support it,
and — only if several Google accounts are signed into the browser — which account.
Offer the same account for all hosts by default. With a single account signed in,
that's the default; don't ask.

When a host turns out not to be logged in, chain its `login_with_google` before
`list_invoices` rather than concluding "not doable".

# Rules

- **Missing a host? Build it.** Every `list_invoices` is the same shape, so a new
  one is quick: sign in on the **app subdomain** that actually holds the session
  (`dashboard.<host>`, `app.<host>`, not the root domain), navigate to the billing
  page, scrape each row, and return the normalised records above. The download
  step is already generic, so a new host needs no new download code. Copy the
  closest existing vendor and swap the navigation and row selectors. Publish under
  your own handle — the `reduck` catalogue is write-locked.
- **"Not doable" is usually "not signed in."** Check the session on the right
  subdomain, try auto-SSO, and re-check before writing a vendor off.
- **Only one Chrome profile is paired.** If a vendor is signed in on a different
  profile, that run can't see it — open the vendor in the paired profile, or pair
  the other one.
- Heavy SPAs need `waitUntil: "domcontentloaded"`; `load` never settles. Hidden
  PDF links need `waitFor(…, "attached")`.
- Fan out across vendors in one `run_script` call by passing `scripts` — each gets
  its own browser. They share nothing, and one failing doesn't stop the others.
