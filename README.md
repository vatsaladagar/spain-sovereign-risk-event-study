# "Devastating," Said No One in the Bond Market

### Why Spain's Renewable Energy Reforms Produced Hundreds of Millions in Arbitration Awards - But Barely Moved Sovereign Bond Spreads

Read the full write-up on Substack: \[https://vatsaladagar.substack.com/]

\---

## Overview

This project tests whether Spain's sovereign bond spread reacted to the 2013 renewable energy subsidy reforms that later triggered a wave of ICSID arbitration awards against the Spanish state, using daily Spain and Germany 10-year government bond yields (June 2013–January 2014).

The underlying question: do bond markets and arbitration tribunals price the same underlying government credibility risk — or are they pricing two genuinely different things? Bond markets price diffuse, aggregate risk across all of a government's obligations, continuously, across thousands of anonymous traders. Arbitration tribunals price a specific, contractual breach against a specific, named investor, adjudicated after the fact by three arbitrators applying a treaty standard. Spain's 2013 reforms — arising from the same fiscal crisis that motivated Draghi's "Whatever It Takes" speech — offer a natural experiment for comparing the two.

Three tests are run:

|Test|Specification|Key Finding|
|-|-|-|
|Event-study plot|Spain–Germany spread, ±20 trading days around each event|No visible break at either reform date|
|Pre/post mean comparison|10-day mean before vs. after, incl. placebo baseline|Law 24/2013 diff exceeds placebo; RDL 9/2013 does not|
|OLS trend|Spread regressed on event-time, within each window|RDL 9/2013 slope ≈ placebo slope; Law 24/2013 slope steeper|

\---

## Data

|Series|Source|Period|
|-|-|-|
|Spain 10-year government bond yield (daily)|investing.com|1 Jun 2013 - 31 Jan 2014|
|Germany 10-year government bond yield (daily)|investing.com|1 Jun 2013 - 31 Jan 2014|
|Spain–Germany spread|Calculated (Spain - Germany)|—|

Raw CSVs are in `/data`. Note: the two files were exported under different regional date formats (Spain: DD/MM/YYYY; Germany: MM/DD/YYYY) - both are parsed correctly in the do-file, with the format explicitly documented in-line since this is a common silent failure mode when merging investing.com exports.

**Event dates tested:**

1. **12 July 2013** - Royal Decree-Law 9/2013 announced (the reform an ICSID tribunal later called "devastating")
2. **26 December 2013** - Law 24/2013 passed, formally abolishing the fixed feed-in tariff system
3. **16 September 2013** - placebo date (no Spain-specific news), used as a noise baseline

\---

## Results

|Event|Pre-mean|Post-mean|Diff (pp)|Trend slope (pp/day)|
|-|-|-|-|-|
|RDL 9/2013 (12 Jul)|3.036|3.098|+0.062|−0.0047|
|Law 24/2013 (26 Dec)|2.279|2.032|−0.247|−0.0134|
|Placebo (16 Sep)|2.537|2.446|−0.090|−0.0051|

RDL 9/2013's trend slope is essentially identical to the placebo's, indicating no detectable break from the reform announcement. Law 24/2013 shows a steeper decline than the placebo, but December 2013 also sat inside a broader Eurozone periphery rally, the current test cannot cleanly separate a reaction to the specific law from that background trend without wider controls (e.g. Italy/Portugal spreads over the same window), which is left as a direction for further work rather than claimed here.

<img width="1600" height="985" alt="full_period_spread" src="https://github.com/user-attachments/assets/c18c738d-fffc-451c-b538-dc5cd38f7c34" />

<img width="1400" height="1018" alt="eventstudy_rdl9" src="https://github.com/user-attachments/assets/8c45f906-fa8a-41f3-9a9c-f2a8b51fd648" />

<img width="1400" height="1018" alt="eventstudy_law24" src="https://github.com/user-attachments/assets/c94f4e60-e6d6-42d6-8c23-a37021c6dfb2" />

For context, a selection of ICSID awards against Spain arising from the same reforms:

<img width="1600" height="1164" alt="arbitration_awards" src="https://github.com/user-attachments/assets/a8939082-d6cc-44ee-bd2c-9d9dcd98b1d0" />


Note: Eiser's figure reflects the 2025 re-award (€260m) after the original 2017 award (€128m) was annulled on procedural grounds and the case was re-filed before a reconstituted tribunal.

\---

## Repository structure

```
├── spain\_events\_analysis.do     # full replication code
├── data/                        # raw investing.com CSV exports
├── figures/                     # exported charts (PNG)
└── output/
    └── prepost\_summary.txt      # pre/post mean comparison table
```

\---

## Limitations

* Pre/post t-tests on daily yield data are not a rigorous causal test - cannot establish that any observed difference is caused by the event itself
* Daily bond yields are highly autocorrelated, which makes standard t-tests anti-conservative (they can show "significance" even on a placebo date with no news, as this analysis does)
* A single placebo date is a useful but limited baseline; a stronger design would use multiple placebo dates and/or a synthetic control built from other Eurozone periphery spreads (e.g. Italy, Portugal)
* This is an illustrative/descriptive exercise accompanying a Substack article, not a standalone causal paper

\---

## Author

Vatsala Dagar

📝 Substack: [https://vatsaladagar.substack.com/](https://vatsaladagar.substack.com/)
🐙 GitHub: [https://github.com/vatsaladagar](https://github.com/vatsaladagar)
💼 LinkedIn: [www.linkedin.com/in/vatsaladagar](https://www.linkedin.com/in/vatsaladagar)

