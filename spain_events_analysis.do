*==============================================================================
* Spain vs Germany 10Y Bond Yield — Event Study
* Tests: (1) event-study plots, (2) pre/post mean comparison,
*        (3) placebo comparison
* Events: 12 Jul 2013 (RDL 9/2013), 26 Dec 2013 (Law 24/2013)
* Placebo: 16 Sep 2013
*==============================================================================

clear all
set more off
capture log close
cd "YOUR/PROJECT/FOLDER"          // <-- EDIT: set working directory
log using "spain_event_study_log.txt", replace text

*------------------------------------------------------------------------
* 0. IMPORT — investing.com raw exports
*    Expected raw columns from investing.com: Date, Price, Open, High, Low, Change %
*    "Price" = the closing yield.
*
*    IMPORTANT: the two files were exported under DIFFERENT locale settings.
*    Spain dates are DD/MM/YYYY (e.g. "31/01/2014"). Germany dates are
*    MM/DD/YYYY (e.g. "01/31/2014"). Using the same format string for both
*    silently mis-parses one of them, so they are handled separately below.
*
*    Both files also contain a handful of weekend rows (stale/carried-over
*    quotes investing.com sometimes posts for Sat/Sun) which are not real
*    trading days and are dropped before merging.
*------------------------------------------------------------------------

* --- Spain (DD/MM/YYYY) ---
import delimited "Spain_10year_raw.csv", clear varnames(1) stringcols(_all)
rename price yield_spain
keep date yield_spain

replace yield_spain = subinstr(yield_spain, ",", "", .)
destring yield_spain, replace force

gen date2 = date(date, "DMY", 2050)
format date2 %td
drop date
rename date2 date
drop if missing(yield_spain) | missing(date)

* drop weekend rows (dow: 0=Sun, 6=Sat)
gen dow = dow(date)
drop if inlist(dow, 0, 6)
drop dow

duplicates drop date, force
tempfile spain
save `spain'

* --- Germany (MM/DD/YYYY) ---
import delimited "Germany_10year_raw.csv", clear varnames(1) stringcols(_all)
rename price yield_germany
keep date yield_germany

replace yield_germany = subinstr(yield_germany, ",", "", .)
destring yield_germany, replace force

gen date2 = date(date, "MDY", 2050)
format date2 %td
drop date
rename date2 date
drop if missing(yield_germany) | missing(date)

gen dow = dow(date)
drop if inlist(dow, 0, 6)
drop dow

duplicates drop date, force
tempfile germany
save `germany'

*------------------------------------------------------------------------
* 1. MERGE — inner join on trading date only
*    Deliberately NOT forward-filling mismatched holidays (Spain/Germany
*    don't share a public holiday calendar) — dropping unmatched days
*    keeps the spread defined only on days both markets actually traded.
*------------------------------------------------------------------------

use `spain', clear
merge 1:1 date using `germany'

* inspect what's being dropped (should be near-zero now)
list date if _merge != 3
keep if _merge == 3
drop _merge

gen spread = yield_spain - yield_germany
label var spread "Spain-Germany 10Y spread (pp)"

sort date
gen day_index = _n

save "spain_germany_merged.dta", replace

*------------------------------------------------------------------------
* 2. EVENT WINDOWS — build event-time variables for each event date
*    event_time = trading days relative to event (0 = event day)
*------------------------------------------------------------------------

capture program drop build_event_window
program define build_event_window
    args event_date_str event_label window

    local edate = date("`event_date_str'", "DMY")

    use "spain_germany_merged.dta", clear
    gen diff_days = date - `edate'
    gen abs_diff_days = abs(diff_days)

    * find the closest trading date to the event (handles weekends/holidays)
    gsort abs_diff_days
    local event_row = day_index[1]
    drop abs_diff_days

    gen event_time = day_index - `event_row'
    keep if abs(event_time) <= `window'

    save "event_window_`event_label'.dta", replace
end

* ±20 trading day windows around each date
build_event_window "12/07/2013" "rdl9" 20
build_event_window "26/12/2013" "law24" 20
build_event_window "16/09/2013" "placebo" 20

*------------------------------------------------------------------------
* 3. TEST 1 — EVENT-STUDY PLOTS
*------------------------------------------------------------------------

foreach ev in rdl9 law24 placebo {
    use "event_window_`ev'.dta", clear
    sort event_time

    local ev_title = `"RDL 9/2013 (12 Jul 2013)"'
    if "`ev'" == "law24" local ev_title = `"Law 24/2013 (26 Dec 2013)"'
    if "`ev'" == "placebo" local ev_title = `"Placebo (16 Sep 2013)"'

    twoway (line spread event_time, lcolor(navy) lwidth(medthick)), xline(0, lcolor(red) lpattern(dash)) title("Spain-Germany 10Y Spread: `ev_title'") xtitle("Trading days relative to event") ytitle("Spread (percentage points)") note("Vertical line = event date. Window: +/-20 trading days.") graphregion(color(white)) scheme(s1mono)

    graph export "eventstudy_`ev'.png", replace width(1400)
}


*------------------------------------------------------------------------
* 4. TEST 2 — PRE/POST MEAN COMPARISON (10 trading days each side)
*    Simple t-test, not a causal estimate — descriptive only, as per brief.
*------------------------------------------------------------------------

capture program drop prepost_test
program define prepost_test
    args ev_file ev_label

    use "`ev_file'", clear
    gen period = .
    replace period = 0 if inrange(event_time, -10, -1)   // pre
    replace period = 1 if inrange(event_time, 1, 10)     // post
    * event_time == 0 (event day itself) excluded from both windows

    display as text "===================================================="
    display as text "Pre/Post comparison: `ev_label'"
    display as text "===================================================="
    ttest spread if !missing(period), by(period)
end

prepost_test "event_window_rdl9.dta"    "RDL 9/2013 (12 Jul 2013)"
prepost_test "event_window_law24.dta"   "Law 24/2013 (26 Dec 2013)"
prepost_test "event_window_placebo.dta" "Placebo (16 Sep 2013)"

*------------------------------------------------------------------------
* 5. TEST 3 — PLACEBO COMPARISON
*    Puts all three pre/post mean shifts side by side so the real events
*    can be visually judged against ordinary day-to-day noise.
*------------------------------------------------------------------------

capture program drop get_prepost_diff
program define get_prepost_diff
    args ev_file ev_label outfile

    use "`ev_file'", clear
    gen period = .
    replace period = 0 if inrange(event_time, -10, -1)
    replace period = 1 if inrange(event_time, 1, 10)

    quietly summarize spread if period == 0
    local pre_mean = r(mean)
    quietly summarize spread if period == 1
    local post_mean = r(mean)
    local diff = `post_mean' - `pre_mean'

    quietly ttest spread if !missing(period), by(period)
    local pval = r(p)

    file open results using "`outfile'", write append
    file write results "`ev_label'" _tab (`pre_mean') _tab (`post_mean') _tab (`diff') _tab (`pval') _n
    file close results
end

capture erase "prepost_summary.txt"
file open results using "prepost_summary.txt", write replace
file write results "Event" _tab "Pre-mean" _tab "Post-mean" _tab "Diff" _tab "p-value" _n
file close results

get_prepost_diff "event_window_rdl9.dta"    "RDL_9_2013"    "prepost_summary.txt"
get_prepost_diff "event_window_law24.dta"   "Law_24_2013"   "prepost_summary.txt"
get_prepost_diff "event_window_placebo.dta" "Placebo"       "prepost_summary.txt"

* Print combined summary table to log
type "prepost_summary.txt"

*------------------------------------------------------------------------
* 6. COMBINED OVERLAY PLOT (optional but useful for Part 3/4 of article —
*    shows real events vs placebo on one chart to make the "no different
*    from noise" or "different from noise" case visually, immediately)
*------------------------------------------------------------------------

use "event_window_rdl9.dta", clear
gen series = "RDL 9/2013"
tempfile s1
save `s1'

use "event_window_law24.dta", clear
gen series = "Law 24/2013"
tempfile s2
save `s2'

use "event_window_placebo.dta", clear
gen series = "Placebo"
append using `s1'
append using `s2'

encode series, gen(series_n)

sort series_n event_time

twoway (line spread event_time if series_n==1, lcolor(gray) lpattern(dash)) (line spread event_time if series_n==2, lcolor(navy)) (line spread event_time if series_n==3, lcolor(maroon)), xline(0, lcolor(black) lpattern(dot)) legend(order(1 "Placebo" 2 "RDL 9/2013" 3 "Law 24/2013")) title("Spain-Germany Spread: Real Events vs Placebo") xtitle("Trading days relative to event") ytitle("Spread (percentage points)") graphregion(color(white)) scheme(s1mono)

graph export "eventstudy_combined.png", replace width(1400)

*------------------------------------------------------------------------
* 7. Quantify the underlying trend slope in each window
*    (regression, not just eyeballing the chart)
*------------------------------------------------------------------------

foreach ev in rdl9 law24 placebo {
    use "event_window_`ev'.dta", clear
    sort event_time

    quietly regress spread event_time
    local b = _b[event_time]
    local se = _se[event_time]
    local p = 2*ttail(e(df_r), abs(`b'/`se'))

    display as text "`ev': slope = " %6.4f `b' " pp/day, se = " %6.4f `se' ", p = " %6.4f `p'
}


*------------------------------------------------------------------------
* 8. Full-period spread chart (whole window, both events marked)
*------------------------------------------------------------------------

use "spain_germany_merged.dta", clear
sort date

twoway (line spread date, lcolor("29 66 138") lwidth(medthick)), xline(19551, lcolor("178 34 34") lpattern(dash)) xline(19718, lcolor("178 34 34") lpattern(dash)) title("Spain-Germany 10Y Spread, June 2013-January 2014") subtitle("Dashed lines mark the two reform dates") xtitle("") ytitle("Spread (percentage points)") graphregion(color(white)) plotregion(lcolor(none)) ysize(4) xsize(6.5) scheme(s2color)

graph export "full_period_spread.png", replace width(1600)

*------------------------------------------------------------------------
* 9. Arbitration award bar chart
*------------------------------------------------------------------------

clear
input str20 investor award
"Eiser" 260
"NextEra" 290.6
"Masdar" 64.5
"Novenergia" 53.3
end

graph hbar award, over(investor, sort(award)) blabel(bar, format(%9.1f)) bar(1, color("29 66 138")) title("Selected ICSID Awards Against Spain") subtitle("Renewable energy subsidy cuts, EUR millions") ytitle("Award (EUR millions)") graphregion(color(white)) scheme(s2color)

graph export "arbitration_awards.png", replace width(1600)

*==============================================================================
* END
*==============================================================================
