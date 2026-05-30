# EUBC Transport Workflow

## Overview

Edinburgh University Boat Club (EUBC) runs a transport system for getting ~50+ athletes to and from training sessions (typically early morning, e.g. 6:45 am). The workflow involves three spreadsheets and two human steps that should be streamlined or automated.

---

## Current Workflow

### Step 1: Transport Plan (night before)

The **club secretary** creates and sends a transport plan spreadsheet to the club group chat the evening before training. This spreadsheet assigns every travelling athlete to a car or minibus.

#### Transport Plan Structure

| Field | Description |
|---|---|
| **Date** | Date of the training session (e.g. 23/05/2026) |
| **Departure Time** | Single departure time for all cars (e.g. 6:45 am) |
| **Departure Locations** | Multiple pickup points across Edinburgh (e.g. Pleasance, 29 Lauriston Gardens, 20 Upper Gray St, 35 Spottiswoode St, 59 Spottiswoode St, 19 Argyle Pl) |

Each departure location has one or more **cars**, each with:

| Field | Description |
|---|---|
| **Driver** | Name of the driver (e.g. "Grace D", "Murray B", "Lucy L") |
| **Vehicle type** | Either a personal car or implied by context |
| **Passengers** | List of passenger names assigned to that car |
| **Capacity fields** | The plan tracks seats needed vs available: columns for SW (seats for Senior Women), SM (seats for Senior Men), C (coxes), B (unknown/buffer), and a Total |

#### Key details

- Drivers are identified by first name + surname initial (e.g. "Grace D", "Murray B").
- Passengers are listed by first name + surname initial.
- Some athletes travel under "Own Way" (they make their own arrangements — not reimbursed, not charged).
- The plan distinguishes between departure locations; a single location can have multiple cars.
- The destination is the training venue (e.g. a reservoir or river) — not shown on the plan but understood by members.
- The "Need" row at the bottom tallies how many seats are required by squad (SW, SM, C, B) and in total.

#### Example departure point entry

```
Departure Location: Pleasance
  Car 1: Driver = Lucy L
         Passengers = Lara T, Esther N, Nienke N
  Car 2: Driver = Drew M (implied from column header)
         Passengers = Lucy E, Nick B, Alex D
  Car 3: Driver = Ben N
         Passengers = Henrik G, Leo O, Laith I
```

---

### Step 2: Post-Training Attendance Log (after training)

After the training session, **squad captains** (one for Senior Women, one for Senior Men, one for Coxes) fill in an attendance/transport log spreadsheet.

#### Attendance Log Structure

- **Rows**: Every club athlete, grouped by squad:
  - Senior Women
  - Senior Men
  - Coxes
- **Columns**:
  - `Athlete` — full name (e.g. "Charlotte Arthur", "Ben Nussey")
  - `Student Number` — university student number (e.g. "s2682925", "s2320237")
  - One column per training date (e.g. `01-Nov`, `02-Nov`, `12-Nov`, `15-Nov`)

#### Transport Codes

Each cell in the date columns contains one of the following codes:

| Code | Meaning |
|---|---|
| `p` | Was a **passenger** in a car (owes money for the trip) |
| `d` | **Drove own vehicle** (gets reimbursed for fuel/mileage) |
| `v` | **Drove club vehicle** (minibus) — no personal reimbursement but passengers still owe |
| *(blank)* | Did not attend / did not travel with the club |

#### Key details

- Athletes highlighted in **yellow/orange** in the original spreadsheet may indicate something specific (e.g. novice status, or a visual grouping) — clarify with Murray.
- The log is filled retrospectively so it captures what *actually* happened, which may differ from the plan (e.g. someone didn't show up, someone swapped cars).
- Coxes are listed separately at the bottom.

---

### Step 3: Treasurer Reconciliation

The attendance log data gets **copied into the Treasurer's master spreadsheet** (maintained by Murray). This spreadsheet calculates:

1. **Who gets reimbursed** — drivers who used their own vehicle (code `d`) receive mileage/fuel reimbursement.
2. **Who owes money** — passengers (code `p`) owe a per-trip fee to cover fuel costs.
3. **Club vehicle trips** — when the minibus is used (code `v`), passengers still owe but the driver isn't personally reimbursed (the club covers fuel centrally).
4. **Own Way** — athletes who made their own way are neither charged nor reimbursed.

#### Financial logic (to be confirmed/refined with Murray)

- Each trip has a fixed cost or mileage-based cost.
- Cost is split among passengers in a given car, or charged at a flat per-head rate.
- Drivers of personal vehicles are reimbursed at a per-mile or per-trip rate.
- The treasurer aggregates across all training dates to produce a net balance per athlete (positive = owed reimbursement, negative = owes the club).
- Athletes pay via standing order or direct transfer; the treasurer tracks credits and debits.

---

## Pain Points & Automation Opportunities

### Pain Point 1: Manual transport plan creation
The secretary manually assigns ~55 athletes to cars each evening, balancing pickup locations, car capacity, and driver availability. This is tedious and error-prone.

**Potential automation**: Given a list of available athletes, their home locations (mapped to pickup points), and available drivers + car capacities, auto-generate an optimal transport plan.

### Pain Point 2: Manual attendance logging
Squad captains manually fill in codes after each session. This is often delayed or inconsistent.

**Potential automation**: Cross-reference the transport plan with a simple attendance check (who actually showed up) to auto-populate the log. Captains only need to flag discrepancies.

### Pain Point 3: Manual copy-paste into treasurer spreadsheet
The attendance log is manually copied into the treasurer's financial spreadsheet. This is error-prone and time-consuming, especially over a full term.

**Potential automation**: Automatically ingest the attendance log and compute reimbursements/charges per athlete per session, producing a running balance.

### Pain Point 4: Reconciliation across the term
At term end, the treasurer must reconcile all trips, calculate net balances, and chase payments. This involves cross-referencing multiple sheets.

**Potential automation**: A single system that tracks everything from plan → attendance → finance, producing per-athlete statements automatically.

---

## Data Entities

### Athlete
- Full name
- Student number (sXXXXXXX)
- Squad (Senior Women / Senior Men / Cox)
- Home pickup point (mapped to a departure location)
- Can drive (yes/no)
- Car capacity (if driver)
- Has standing order with club (yes/no)

### Training Session
- Date
- Departure time
- Destination (usually fixed for a term)
- Transport plan (list of cars)
- Attendance log (list of athlete codes)

### Car (within a transport plan)
- Driver (Athlete)
- Vehicle type (personal / club minibus)
- Departure location
- Passengers (list of Athletes)
- Capacity

### Financial Record (per athlete per session)
- Athlete
- Session date
- Code (p / d / v / blank)
- Amount owed or reimbursed

---

## File Formats

- **Transport plan**: Excel spreadsheet (.xlsx), structured as a wide table with merged cells and colour coding.
- **Attendance log**: Excel spreadsheet (.xlsx), structured as a tall table (athletes × dates) with single-letter codes.
- **Treasurer spreadsheet**: Excel spreadsheet (.xlsx), structure TBD — likely mirrors the attendance log with added financial columns.

---

## Next Steps

1. Get sample files from Murray (transport plan .xlsx, attendance log .xlsx, treasurer spreadsheet .xlsx) to understand exact formats.
2. Clarify the financial logic: flat rate per trip vs mileage-based, how club vehicle costs are handled, standing order credit system.
3. Decide scope: full end-to-end automation vs targeted tools for specific pain points.
4. Choose stack: likely Python with openpyxl/pandas for spreadsheet manipulation, possibly a simple web UI for the secretary and captains.
