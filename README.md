# finbase

A personal finance ledger. The one feature that justifies everything: **upload a bank e-statement → Claude extracts and categorizes every transaction → rows land in the database as `pending` → you approve or reject each one.**

Everything else (dashboard, wallets, subscriptions) is a view over a single `transactions` table.

---

## Why

Tracked finances for ~4 years in Simple (formerly Budgetify). App became abandonware. The real pain was manual monthly entry from bank PDFs — that's the thing being automated.

**Guiding principle: cabin before cathedral.** Ship the lean core; add features only after it earns its keep.

---

## Architecture

```
┌───────────────────────────────────────────────────────────────────────┐
│  INGESTION                                                            │
│                                                                       │
│   Bank PDF e-statement                                                │
│          │                                                            │
│          ▼                                                            │
│   Python backend (FastAPI / CLI)                                      │
│   ├── pdfplumber / pikepdf  →  extract raw text                       │
│   └── Anthropic SDK  →  Claude (claude-sonnet-4-6)                    │
│          │   structured output: forced tool-use record_transaction    │
│          │   returns guaranteed-valid JSON array                      │
│          ▼                                                            │
│   fingerprint = sha256(account | date | amount | description)         │
│          │                                                            │
│          │   INSERT … ON CONFLICT DO NOTHING                          │
│          │   re-uploading the same statement is a silent no-op        │
│          ▼                                                            │
│   Supabase Postgres  ─────────────────────────────────────────────┐   │
│   status = 'pending'  +  model_confidence (0–1)                   │   │
└───────────────────────────────────────────────────────────────────│───┘
                                                                    │
┌───────────────────────────────────────────────────────────────────│───┐
│  FRONTEND  (Next.js on Vercel — talks to Supabase directly)       │   │
│                                                                   │   │
│   ┌─────────────────────┐      ┌───────────────────────────────┐  │   │
│   │   Review queue      │      │   Analytics dashboard         │  │   │
│   │   (approval inbox)  │      │   · savings rate              │  │   │
│   │                     │      │   · spending by category      │  │   │
│   │   pending rows  ────┼──────┼── monthly totals              │  │   │
│   │   approve / reject  │      │   · wallet balances           │  │   │
│   └──────────┬──────────┘      └───────────────────────────────┘  │   │
│              │ status = 'approved' / 'rejected'                   │   │
│              └────────────────────────────────────────────────────┘   │
└───────────────────────────────────────────────────────────────────────┘
```

The Python backend is only needed for ingestion — it holds the Anthropic API key and runs PDF parsing, neither of which can live in the browser. All other reads and writes go from the frontend to Supabase directly via `supabase-js`.

---

## Project structure

```
finbase-backend/
├── app/                          # Python package — application logic
│   ├── main.py                   # CLI entry point (typer): ingest, ingest-dir, import-csv
│   ├── core/
│   │   ├── config.py             # Settings loaded from .env
│   │   └── database.py           # Supabase client singleton
│   ├── models/                   # Dataclasses mirroring DB table shapes
│   ├── schemas/                  # Pydantic v2 — validates Claude output & CSV rows
│   ├── repositories/             # All Supabase queries (dedup upsert, FK lookups)
│   └── services/                 # Orchestration: ingest.py, csv_import.py
│
├── pkg/                          # External integration package
│   └── parser/
│       ├── pdf_reader.py         # pikepdf (decrypt) + pdfplumber (extract text)
│       ├── claude_extractor.py   # Anthropic SDK: forced tool-use record_transactions
│       └── fingerprint.py        # sha256(wallet | date | amount | description)
│
├── migrations/                   # Sqitch — SQL-native versioned migrations
│   ├── sqitch.plan
│   ├── sqitch.conf
│   ├── deploy/initial_schema.sql
│   ├── revert/initial_schema.sql
│   └── verify/initial_schema.sql
│
├── data/                         # gitignored — local files only
│   ├── statements/               # drop PDF e-statements here
│   └── imports/                  # CSV for one-time migration
│
├── Makefile                      # make ingest / import-csv / migrate
├── requirements.txt
└── .env.example
```

### Key design decisions

| Decision | Rationale |
|---|---|
| Frontend → Supabase directly | Eliminates a whole backend layer for CRUD; Python exists only for Anthropic calls and PDF parsing |
| Structured output, not an agent | One forced `record_transactions` tool call returns guaranteed-valid JSON. Linear pipeline: PDF → Claude → insert |
| Dedup via `fingerprint UNIQUE` | Re-uploading the same statement is a silent no-op instead of doubling balances |
| Human-in-the-loop | Every row inserts as `status='pending'`; never auto-approve financial data |
| Python not on Vercel | PDF/OCR libs are native binaries. Host on Cloud Run (scale-to-zero) or run as a local CLI |

---

## Tech stack

| Layer | Choice |
|---|---|
| Frontend | Next.js + TypeScript, Tailwind CSS, shadcn/ui, Recharts |
| Database | Supabase (Postgres) + supabase-js |
| Backend | Python — CLI (`make ingest`) via typer; Cloud Run / Railway when hosted |
| PDF parsing | pdfplumber + pikepdf; pytesseract for scanned statements |
| AI | Anthropic SDK — `claude-sonnet-4-6` (swap to `claude-haiku-4-5` to cut cost) |
| Hosting | Vercel (frontend), Cloud Run or Railway (Python backend) |

Cost: effectively $0/month except a few cents of Claude API per statement.

---

## Database schema

The schema lives in `migrations/deploy/initial_schema.sql` (managed via Sqitch). Core tables:

- **`transactions`** — the ledger; every row is one transaction
- **`wallets`** — accounts (BCA Leisure, BRI Credit Card, Mandiri Opr. Cash, etc.)
- **`categories`** / **`category_groups`** — 50-category taxonomy (Food, Coffee, Investment, Salary…)
- **`wallet_types`** / **`wallet_institutions`** / **`currencies`** — lookup tables
- **`securities`** / **`holdings`** — investment positions (Nanovest, GoTrade)

All tables carry `created_at` / `updated_at` with an auto-trigger (`set_updated_at`). Transfers are validated by a `check_transfer_shape` trigger that enforces `to_wallet_id` is set and source ≠ destination.

---

## Build roadmap

**Phase 1 — kill the pain**
1. Spin up Supabase; run `make migrate` (Sqitch deploys `migrations/deploy/initial_schema.sql`)
2. `make import-csv` — seed 809 historical transactions from `data/imports/`
3. `make ingest f=<pdf> w="<wallet>"` — PDF → Claude extraction → Supabase insert with dedup
4. Frontend review queue: approve / reject pending rows per transaction

**Phase 2 — only after Phase 1 earns its keep**
5. Analytics dashboard: savings rate, spending by category, monthly totals, wallet balances
6. MCP server wrapping the ledger (`query_spending`, `list_pending`, `get_savings_rate`) — additive learning exercise, not a Phase 1 dependency

---

## Scope

**In:** e-statement ingestion, categorization, analytics dashboard, wallet tracking, subscription tracking.

**Out:** portfolio tracker (already solved in Google Sheets), multi-user/family, always-on hosted backend for MVP.
