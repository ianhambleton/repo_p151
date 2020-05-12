** HEADER -----------------------------------------------------
**  DO-FILE METADATA
    //  algorithm name					paper01_11fig2.do
    //  project:				        
    //  analysts:				       	Ian HAMBLETON
    // 	date last modified	            12-MAY-2020
    //  algorithm task			        PAPER 01. Situation Analysis. Figure 1

    ** General algorithm set-up
    version 16
    clear all
    macro drop _all
    set more 1
    set linesize 80

    ** Set working directories: this is for DATASET and LOGFILE import and export
    ** DATASETS to encrypted SharePoint folder
    local datapath "X:\The University of the West Indies\DataGroup - repo_data\data_p151"
    ** LOGFILES to unencrypted OneDrive folder
    local logpath "X:\OneDrive - The University of the West Indies\repo_datagroup\repo_p151"
    ** Reports and Other outputs
    local outputpath "X:\The University of the West Indies\DataGroup - DG_Projects\PROJECT_p151"

    ** Close any open log file and open a new log file
    capture log close
    log using "`logpath'\paper01_11fig2", replace
** HEADER -----------------------------------------------------


** -----------------------------------------
** Pre-Load the COVID metrics --> as Global Macros
** -----------------------------------------
qui do "`logpath'\paper01_04metrics"
** -----------------------------------------

** Close any open log file and open a new log file
capture log close
log using "`logpath'\paper01_11fig2", replace

** HEATMAP preparation - ADD ROWS
** Want symmetric / rectangular matrix of dates. So we need 
** to backfill dates foreach country to date of first 
** COVID appearance - which I think was in JAM
    fillin date iso_num 
    sort iso_num date
    ///drop if date>date[_n+1] & iso_num!=iso_num[_n+1]
    ///drop if inlist(_n, _N)
    replace confirmed = 0 if confirmed==.
    replace deaths = 0 if deaths==.
    replace recovered = 0 if recovered==.

** Attack Rate (per 1,000 --> not yet used)
gen confirmed_rate = (confirmed / pop) * 10000

** Keep selected variables
decode iso_num, gen(country2)
keep date iso_num country2 cgroup iso pop confirmed confirmed_rate deaths recovered
order date iso_num country2 iso pop confirmed confirmed_rate deaths recovered
bysort iso_num : gen elapsed = _n 
keep iso_num cgroup pop date confirmed confirmed_rate deaths recovered

** Fix Guyana 
///replace confirmed = 4 if iso_num==14 & date>=d(17mar2020) & date<=d(23mar2020)
** Fix --> Single Montserrat value 
replace confirmed = 5 if confirmed==0 & iso_num==22 & date==d(01apr2020)
replace pop = 4999 if pop==. & iso_num==22 & date==d(01apr2020)
rename confirmed metric1
rename confirmed_rate metric2
rename deaths metric3
rename recovered metric4
reshape long metric, i(iso_num cgroup pop date) j(mtype)
label define mtype_ 1 "cases" 2 "attack rate" 3 "deaths" 4 "recovered"
label values mtype mtype_
sort iso_num mtype date 
drop if mtype==2 | mtype==4 


** DOUBLING RATE
** Then create a rolling average 
** Using 1-week window for now
** And we only calculate ONCE cases reach N=10 - for stability reasons 
format pop  %14.0fc
sort iso_num mtype date 
gen growthrate = log(metric/metric[_n-1]) if iso_num==iso_num[_n-1] & mtype==mtype[_n-1] 
replace growthrate = 0 if metric<10 & mtype==1
gen doublingtime = log(2)/growthrate
sort iso_num mtype date 
gen gr100 = growthrate*100
bysort iso_num mtype: asrol gr100, stat(mean) window(date 10) gen(gr7)
bysort iso_num mtype: asrol doublingtime , stat(mean) window(date 7) gen(dt7)

** NEW CASES EACH DAY
by iso_num mtype: gen new = metric - metric[_n-1]
replace new = 0 if new==.

** Automate changing bin-width for color bins
** Do this by calulcating # needed to have XX bins
** Max anad Min across ALL countries
bysort mtype: egen maxv = max(metric)
bysort mtype: egen minv = min(metric) 
bysort mtype: egen maxgr = max(gr7)
bysort mtype: egen mingr = min(gr7) 
bysort mtype: egen maxnc = max(new)
bysort mtype: egen minnc = min(new) 

** Count: cumulative cases
gen diffv = maxv - minv 
gen diffc1 = diffv if mtype==1
egen diffc2 = min(diffc1) 
gen diffc = round(diffc2/25)
global binc = diffc 

** Count: attack rate
gen diffar1 = diffv if mtype==2
egen diffar2 = min(diffar1) 
gen diffar = diffar2/20
global binar = diffar 

** Count: cumulative deaths
gen diffd1 = diffv if mtype==3
egen diffd2 = min(diffd) 
gen diffd = round(diffd2/20)
global bind = diffd 

** Daily new events: cases
gen diffnc = maxnc - minnc 
gen diffnc1 = diffnc if mtype==1
egen diffnc2 = min(diffnc1) 
gen diffnc3 = round(diffnc2/10)
global binnc = diffnc3 

** Daily new events: deaths
gen diffnd = maxnc - minnc 
gen diffnd1 = diffnd if mtype==3
egen diffnd2 = min(diffnd1) 
gen diffnd3 = round(diffnd2/5)
global binnd = diffnd3 

** Growth rate : cases
replace gr7 = round(gr7, 1) 
gen diffgrc = maxgr - mingr 
gen diffgrc1 = diffgrc if mtype==1
egen diffgrc2 = min(diffgrc1) 
gen diffgrc3 = round(diffgrc2/10,1)
global bingrc = diffgrc3 

drop maxv minv diffv diffd diffd1 diffd2 diffc diffc1 diffc2 diffar diffar1 diffar2 diffgrc diffgrc1 diffgrc2 diffgrc3
drop maxgr mingr minnc maxnc diffnc diffnc1 diffnc2 diffnc3 diffnd diffnd1 diffnd2 diffnd3


** Automate final date on x-axis 
** Use latest date in dataset 
egen fdate1 = max(date)
global fdate = fdate1 
global fdatef : di %tdD_m date("$S_DATE", "DMY")

** Complete -cgroup- 
keep if mtype==1 
drop doublingtime gr100 dt7 new
rename cgroup cgroup1 
bysort iso_num: egen cgroup = min(cgroup1)
order cgroup, after(cgroup1)
recode cgroup (1 2 3 = 1) (4=2)


** ORDER for plotting 
** New numeric running from 1 to xx
gen corder = .
replace corder = 1 if iso_num==1        /* Anguilla */
replace corder = 2 if iso_num==2        /* Antigua and Barbuda*/
replace corder = 3 if iso_num==3        /* Bahamas */
replace corder = 4 if iso_num==6        /* Barbados order */
replace corder = 5 if iso_num==4        /* Belize order */
replace corder = 6 if iso_num==5        /* Bermuda order */
replace corder = 7 if iso_num==30       /* British Virgin islands */
replace corder = 8 if iso_num==8        /* Cayman islands */
replace corder = 9 if iso_num==7        /* Cuba */
replace corder = 10 if iso_num==10       /* Dominica */
replace corder = 11 if iso_num==11       /* Dominican republic */
replace corder = 12 if iso_num==14      /* Grenada */
replace corder = 13 if iso_num==15      /* Guyana */
replace corder = 14 if iso_num==16      /* Haiti */
replace corder = 15 if iso_num==19      /* Jamaica */
replace corder = 16 if iso_num==23      /* Montserrat */
replace corder = 17 if iso_num==20      /* St Kitts */
replace corder = 18 if iso_num==22      /* St Lucia */
replace corder = 19 if iso_num==29      /* St Vincent switched order*/
replace corder = 20 if iso_num==26      /* Suriname switched order*/
replace corder = 21 if iso_num==28      /* Trinidad switched order*/ 
replace corder = 22 if iso_num==27      /* Turks and Caicos Islands*/
** Comparators
replace corder = 23 if iso_num==12      /* Fiji*/
replace corder = 24 if iso_num==9       /* Germany*/
replace corder = 25 if iso_num==17      /* Iceland*/
replace corder = 26 if iso_num==18      /* Italy */
replace corder = 27 if iso_num==24      /* New Zealand */
replace corder = 28 if iso_num==25      /* Singapore */
replace corder = 29 if iso_num==21      /* South Korea */
replace corder = 30 if iso_num==27      /* Sweden */
replace corder = 31 if iso_num==13      /* United Kingdom*/
replace corder = 32 if iso_num==31      /* Vietnam */

sort cgroup iso_num mtype date 
** Drop fiji 
drop if corder==23


** -----------------------------------------
** HEATMAP -- CASES -- GROWTH RATE
** -----------------------------------------
#delimit ;
    heatplot gr7 i.corder date if mtype==1
    ,
    color(spmap, blues)
    cuts(1($bingrc)@max)
    keylabels(all, range(1))
    p(lcolor(white) lalign(center) lw(0.05))
    discrete
    statistic(asis)

    plotregion(c(gs16) ic(gs16) ilw(thin) lw(thin)) 
    graphregion(color(gs16) ic(gs16) ilw(thin) lw(thin)) 
    ysize(9) xsize(15)

    ylab(   1 "Anguilla"
            2 "Antigua and Barbuda" 
            3 "The Bahamas" 
            4 "Barbados"
            5 "Belize" 
            6 "Bermuda"
            7 "British Virgin Islands" 
            8 "Cayman Islands" 
            9 "Cuba"
            10 "Dominica"
            11 "Dominican Republic"
            12 "Grenada"
            13 "Guyana"
            14 "Haiti"
            15 "Jamaica"
            16 "Montserrat" 
            17 "St Kitts and Nevis"
            18 "St Lucia"
            19 "St Vincent"
            20 "Suriname"
            21 "Trinidad and Tobago"
            22 "Turks and Caicos Islands"

            24 "Germany"
            25 "Iceland"
            26 "Italy"
            27 "New Zealand"
            28 "Singapore"
            29 "South Korea"
            30 "Sweden"
            31 "United Kingdom"
            32 "Vietnam"

    , labs(2.75) notick nogrid glc(gs16) angle(0))
    yscale(reverse fill noline range(0(1)14)) 
    ///yscale(log reverse fill noline) 
    ytitle(" ", size(1) margin(l=0 r=0 t=0 b=0)) 

    xlab(   21984 "10 Mar" 
            21994 "20 Mar" 
            22004 "30 Mar" 
            22015 "10 Apr"
            22025 "20 Apr"
            22035 "30 Apr"
            $fdate "$fdatef"
    , labs(2.75) nogrid glc(gs16) angle(45) format(%9.0f))
    xtitle(" ", size(1) margin(l=0 r=0 t=0 b=0)) 

    title("Growth rate by $S_DATE", pos(11) ring(1) size(3.5))

    legend(size(2.75) position(2) ring(5) colf cols(1) lc(gs16)
    region(fcolor(gs16) lw(vthin) margin(l=2 r=2 t=2 b=2) lc(gs16)) 
    sub("Growth" "Rate (%)", size(2.75))
                    )
    name(heatmap_growthrate) 
    ;
#delimit cr
///graph export "`outputpath'/04_TechDocs/heatmap_growthrate_$S_DATE.png", replace width(4000)