<!--
  ╔══════════════════════════════════════════════════════════════════════╗
  ║                           H I S A B                                  ║
  ║                     حساب  ·  Know Your Money                         ║
  ╚══════════════════════════════════════════════════════════════════════╝
-->

<div align="center">

<br/>

```
██╗  ██╗██╗███████╗ █████╗ ██████╗
██║  ██║██║██╔════╝██╔══██╗██╔══██╗
███████║██║███████╗███████║██████╔╝
██╔══██║██║╚════██║██╔══██║██╔══██╗
██║  ██║██║███████║██║  ██║██████╔╝
╚═╝  ╚═╝╚═╝╚══════╝╚═╝  ╚═╝╚═════╝
```

### **حساب** &nbsp;·&nbsp; *Account. Compute. Reckon.*

<br/>

<img src="https://img.shields.io/badge/v1.0.0-release-173D32?style=flat-square&labelColor=102B24&color=46C89A" />
&nbsp;
<img src="https://img.shields.io/badge/Flutter-3.x-02569B?style=flat-square&logo=flutter&logoColor=white&labelColor=0a0a0a" />
&nbsp;
<img src="https://img.shields.io/badge/Dart-3.x-0175C2?style=flat-square&logo=dart&logoColor=white&labelColor=0a0a0a" />
&nbsp;
<img src="https://img.shields.io/badge/Supabase-Powered-3ECF8E?style=flat-square&logo=supabase&logoColor=white&labelColor=0a0a0a" />
&nbsp;
<img src="https://img.shields.io/badge/Tests-14%20Passing-46C89A?style=flat-square&labelColor=0a0a0a" />

<br/>
<br/>

*A production-grade personal finance operating system.*<br/>
*Built for precision. Designed for sovereignty.*

<br/>

[**Features**](#-features) &nbsp;·&nbsp; [**Architecture**](#-architecture) &nbsp;·&nbsp; [**Design System**](#-design-system) &nbsp;·&nbsp; [**Database**](#-database) &nbsp;·&nbsp; [**Quick Start**](#-quick-start) &nbsp;·&nbsp; [**Install APK**](#-install)

<br/>
<br/>

</div>

---

<br/>

## &nbsp; The Philosophy

> *Most financial applications treat money as a number. Hisab treats it as a discipline.*

Hisab was designed with a singular conviction: that the tools we use to manage wealth must be as rigorous as the decisions they inform. Built from first principles on a foundation of **exact decimal arithmetic**, **immutable domain objects**, and **zero-compromise security**, Hisab is the private finance instrument for those who take precision seriously.

The name *حساب* (Hisab) is the Arabic word for *account*, *calculation*, and *reckoning* — all three meanings intentional.

<br/>

---

<br/>

## &nbsp; Features

<br/>

<table>
<tr>
<td valign="top" width="50%">

### `01` &nbsp; Executive Dashboard
Real-time net worth across all accounts — checking, savings, cash, credit, and investments. Inflow/outflow velocity. Spending pulse. A single tap activates **Privacy Mode**, masking every balance with cryptographic opacity.

</td>
<td valign="top" width="50%">

### `02` &nbsp; Precision Ledger
Full double-entry bookkeeping with categorical taxonomy. Instant search and temporal filters across the entire transaction history. Zero floating-point drift — every calculation is performed in arbitrary-precision decimal.

</td>
</tr>
<tr>
<td valign="top" width="50%">

### `03` &nbsp; Envelope Budgets
Monthly and annual spending ceilings per category. Live pacing velocity with sub-millisecond rendering. Burn-rate projections tell you exactly when a budget will exhaust at the current rate of spend.

</td>
<td valign="top" width="50%">

### `04` &nbsp; Wealth Vaults
Named savings goals with target dates and priority tiers. Dedicated contribution logging. Automated runway calculation: *"At your current pace, you will reach this goal in 47 days."*

</td>
</tr>
<tr>
<td valign="top" width="50%">

### `05` &nbsp; Recurring Engine
Subscription and fixed-obligation tracking. Weekly, bi-weekly, monthly, and annual cadences. Forward-looking liability calendar to eliminate surprise overdrafts.

</td>
<td valign="top" width="50%">

### `06` &nbsp; Offline-First, Zero Config
The application is complete and functional without any backend. A rich mock ledger — pre-seeded with realistic accounts, transactions, and budgets — activates automatically when no Supabase credentials are detected.

</td>
</tr>
</table>

<br/>

---

<br/>

## &nbsp; Architecture

Hisab is structured as a **Clean Architecture** system arranged by **Feature Slice** — each product domain is independently navigable, testable, and deployable.

```
hisab/
│
├── lib/
│   ├── app/                     # Bootstrap, shell, router, theme system
│   │   ├── theme/               # Design tokens: color, spacing, radii, typography
│   │   └── router.dart          # GoRouter • StatefulShellRoute • deep-link ready
│   │
│   ├── core/                    # Pure Dart domain — zero Flutter dependencies
│   │   ├── money/               # Immutable Money value object • Decimal arithmetic engine
│   │   ├── dates/               # Fiscal period logic • calendar utilities
│   │   └── constants/           # Environment configuration • feature flags
│   │
│   ├── data/                    # Persistence boundary
│   │   ├── remote/              # Supabase singleton • auth gateway
│   │   └── repositories/        # Interface contracts + Supabase + Offline Mock implementations
│   │
│   ├── features/                # Product domains
│   │   ├── auth/                # Login • Registration • Passwordless
│   │   ├── dashboard/           # Net worth overview • charts • quick actions
│   │   ├── transactions/        # Ledger • search • Quick-Add modal
│   │   ├── accounts/            # Multi-account wallet management
│   │   ├── budgets/             # Envelope budget management
│   │   ├── goals/               # Savings vault tracking
│   │   ├── recurring/           # Subscription & obligation scheduler
│   │   └── settings/            # Profile • preferences • privacy controls
│   │
│   └── shared/                  # Atomic design system components
│       └── widgets/             # FinancialCard • AmountDisplay • TransactionTile • ...
│
├── supabase/
│   └── migrations/              # 413-line RLS-hardened PostgreSQL schema
│
└── test/                        # Domain unit tests • financial precision verification
```

<br/>

### State Management

All state is managed through **Riverpod 2.x `AsyncNotifier` providers**, providing compile-time safety, zero-surprise lifecycle management, and deterministic invalidation semantics.

| Provider | Pattern | Responsibility |
|---|---|---|
| `currentUserProfileProvider` | `AsyncNotifier` | Authenticated user session & profile |
| `accountsListProvider` | `AsyncNotifier` | Multi-account balances & wallet state |
| `transactionsListProvider` | `AsyncNotifier` | Paginated ledger with live search |
| `budgetsListProvider` | `AsyncNotifier` | Envelope ceilings with pacing metrics |
| `savingsGoalsListProvider` | `AsyncNotifier` | Wealth vault progress & runway |
| `dashboardSummaryProvider` | `Provider` (derived) | Net worth & cashflow delta composition |
| `privacyModeProvider` | `Notifier` | One-tap balance masking toggle |

<br/>

---

<br/>

## &nbsp; Design System

Hisab uses a bespoke chromatic system inspired by **quiet luxury** and **private banking interfaces** — rejecting the saturated palettes of consumer fintech in favour of deep forests, warm paper, and precisely calibrated mint.

<br/>

```
 DARK MODE                         LIGHT MODE
 ──────────────────────────────    ──────────────────────────────
 Canvas       #0F1715  ████████    Canvas       #F8F7F2  ████████
 Surface      #16211E  ████████    Surface      #FFFFFF  ████████
 Primary      #173D32  ████████    Primary      #173D32  ████████
 Accent Mint  #46C89A  ████████    Accent Mint  #46C89A  ████████
 Income       #2E9F75  ████████    Income       #2E9F75  ████████
 Expense      #E58B68  ████████    Expense      #E58B68  ████████
 Warning      #D9A441  ████████    Warning      #D9A441  ████████
 Text/1       #FFFFFF  ████████    Text/1       #202824  ████████
 Text/2       #A3ACA6  ████████    Text/2       #78817B  ████████
```

<br/>

**Typography** — [Manrope](https://fonts.google.com/specimen/Manrope) across the entire interface with `FontFeature.tabularFigures()` engaged on all numerical displays. This ensures that digits never shift or jitter during live balance updates — a property borrowed from precision instruments and stock market terminals.

<br/>

---

<br/>

## &nbsp; Database

The Supabase PostgreSQL schema is contained in a single, self-documenting migration file with **Row-Level Security enforced on every table**. No row is ever readable or writable by any identity except its direct owner.

<br/>

```sql
-- Every table in Hisab follows this exact security contract:
ALTER TABLE public.transactions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users access own transactions only"
  ON public.transactions
  FOR ALL USING (auth.uid() = user_id);
```

<br/>

### Schema

```
profiles ──────────── Extension of auth.users
    │
    ├── accounts ──── Checking · Savings · Credit · Cash · Investment
    │       │
    │       └── transactions ─── Amount · Category · Date · Notes · Type
    │               │
    │               └── transfers ─── from_account_id → to_account_id
    │
    ├── categories ── System taxonomy + custom user-defined tags
    │
    ├── budgets ───── Monthly / annual spend ceilings
    │       └── budget_categories ── Junction table
    │
    ├── savings_goals ── Targets · Priority · Vault naming
    │       └── goal_contributions ── Deposit audit trail
    │
    └── recurring_transactions ── Cadence · Auto-apply · Next-due forecasting
```

<br/>

**Security invariants enforced:**
- All tables: `ROW LEVEL SECURITY` enabled with no default-permissive fallback
- All mutations: `auth.uid() = user_id` predicate enforced at the kernel level
- All timestamps: automatic `updated_at` via database triggers, never trust the client
- Zero public tables: no data is accessible without a valid authenticated JWT

<br/>

---

<br/>

## &nbsp; The Precision Engine

Binary floating-point arithmetic is fundamentally unsuitable for financial computation. The error is not hypothetical:

```dart
// Standard Dart double arithmetic — WRONG for money:
print(0.1 + 0.2);   // → 0.30000000000000004

// Compounding over thousands of transactions this drift becomes material.
```

Every monetary value in Hisab is represented as an **immutable `Money` value object** backed by the `decimal` package's arbitrary-precision arithmetic:

```dart
/// lib/core/money/money.dart
@immutable
class Money {
  final Decimal _amount;
  final String currency;

  const Money._(this._amount, this.currency);

  factory Money.fromDouble(double v, {required String currency}) =>
      Money._(Decimal.parse(v.toStringAsFixed(10)).round(scale: 4), currency);

  Money operator +(Money other) => Money._(_amount + other._amount, currency);
  Money operator -(Money other) => Money._(_amount - other._amount, currency);

  // Exactly 66.67 — every time, forever.
}
```

This is verified by automated tests on every commit.

<br/>

---

<br/>

## &nbsp; Quick Start

<br/>

**Requirements:** Flutter `^3.24` · Dart `^3.5` · Android SDK 34+ or Xcode 15+

<br/>

```bash
# 1. Clone
git clone https://github.com/your-username/hisab.git && cd hisab

# 2. Install dependencies
flutter pub get

# 3. Run immediately — no configuration required
#    Hisab boots in Offline Demo Mode with pre-seeded realistic data
flutter run
```

<br/>

**To connect a live Supabase backend:**

```bash
# Copy the environment template
cp .env.example .env

# Populate with your Supabase project credentials
# SUPABASE_URL=https://your-project.supabase.co
# SUPABASE_ANON_KEY=your-anon-key

# Apply the database migration
supabase db push

# Run with injected environment
flutter run --dart-define-from-file=.env
```

<br/>

---

<br/>

## &nbsp; Install

A compiled Android debug package is available at the root of this repository.

<br/>

```bash
# Sideload via ADB to a connected device or emulator:
adb install -r Hisab.apk
```

Alternatively, transfer [`Hisab.apk`](./Hisab.apk) to any Android device and open it with the system package installer.

<br/>

---

<br/>

## &nbsp; Verification

```
flutter analyze      →   0 errors · 0 warnings · 0 infos
flutter test         →   14 / 14 passed
```

Tests cover: `Money` arithmetic edge-cases · `FinancialCalculator` precision · Date boundary logic · Repository contracts · Provider state transitions.

<br/>

---

<br/>

## &nbsp; Roadmap

| Status | Milestone |
|---|---|
| ✅ | Core architecture, design system, and precision Money engine |
| ✅ | Complete feature matrix: Dashboard · Accounts · Transactions · Budgets · Goals · Recurring |
| ✅ | Supabase RLS schema, authenticated data layer, offline mock store |
| 🔲 | Open Banking — Plaid & Teller automated statement sync |
| 🔲 | Receipt Intelligence — on-device OCR and tax categorization |
| 🔲 | Multi-Currency — live ECB exchange rates with FX conversion ledger |
| 🔲 | iOS App Store release |

<br/>

---

<br/>

<div align="center">

**MIT License** &nbsp;·&nbsp; Open source, forever.

<br/>

*Hisab is engineered for those who believe that clarity of finances<br/>is a prerequisite for clarity of thought.*

<br/>
<br/>

</div>
