** HEADER -----------------------------------------------------
**  DO-FILE METADATA
    //  algorithm name					cdema_trajectory_006.do
    //  project:				        
    //  analysts:				       	Ian HAMBLETON
    // 	date last modified	            04-APR-2020
    //  algorithm task			        HEATMAP

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
    log using "`logpath'\cdema_trajectory_006", replace
** HEADER -----------------------------------------------------

** JH time series COVD-19 data 
use "`datapath'\version01\2-working\jh_time_series", clear

** JH database correction
** UK has 2 names in database
replace countryregion = "UK" if countryregion=="United Kingdom"
** Bahamas has 3 names in database 
replace countryregion = "Bahamas" if countryregion=="Bahamas, The" | countryregion=="The Bahamas"
** South Korea has 2 names
replace countryregion = "South Korea" if countryregion=="Korea, South" 

** COUNTRY RESTRICTION: CARICOM countries only (N=14)
#delimit ; 
keep if 
        countryregion=="Antigua and Barbuda" |
        countryregion=="Bahamas" |
        countryregion=="Barbados" |
        countryregion=="Belize" |
        countryregion=="Dominica" |
        countryregion=="Grenada" |
        countryregion=="Guyana" |
        countryregion=="Haiti" |
        countryregion=="Jamaica" |
        countryregion=="Saint Kitts and Nevis" |
        countryregion=="Saint Lucia" |
        countryregion=="Saint Vincent and the Grenadines" |
        countryregion=="Suriname" |
        countryregion=="Trinidad and Tobago";
#delimit cr    
collapse (sum) confirmed deaths recovered, by(date countryregion)

** HEATMAP preparation - ADD ROWS
** Want symmetric / rectangular matrix of dates. So we need 
** to backfill dates foreach country to date of first 
** COVID appearance - which I think was in JAM
    fillin date country 
    replace confirmed = 0 if confirmed==.
    replace deaths = 0 if deaths==.
    replace recovered = 0 if recovered==.

** Add ISO codes
gen iso = ""
order iso, after(countryregion)
replace iso = "ATG" if countryregion=="Antigua and Barbuda"
replace iso = "BHS" if countryregion=="Bahamas"
replace iso = "BRB" if countryregion=="Barbados"
replace iso = "BLZ" if countryregion=="Belize"
replace iso = "DMA" if countryregion=="Dominica"
replace iso = "GRD" if countryregion=="Grenada"
replace iso = "GUY" if countryregion=="Guyana"
replace iso = "HTI" if countryregion=="Haiti"
replace iso = "JAM" if countryregion=="Jamaica"
replace iso = "KNA" if countryregion=="Saint Kitts and Nevis"
replace iso = "LCA" if countryregion=="Saint Lucia"
replace iso = "VCT" if countryregion=="Saint Vincent and the Grenadines"
replace iso = "SUR" if countryregion=="Suriname"
replace iso = "TTO" if countryregion=="Trinidad and Tobago"

** Create internal numeric code for country (1-14)
encode countryregion, gen(country)
label list country
* Add days since first reported cases
bysort country: gen elapsed = _n 

** Add country populations
gen pop = . 
** CARICOM COUNTRIES (2020 estimates from UN WPP, 2019 release)
replace pop = 97928 if iso == "ATG"
replace pop = 393248 if iso == "BHS"
replace pop = 287371 if iso == "BRB"
replace pop = 397621 if iso == "BLZ"
replace pop = 71991 if iso == "DMA"
replace pop = 112519 if iso == "GRD"
replace pop = 786559 if iso == "GUY"
replace pop = 11402533 if iso == "HTI"
replace pop = 2961161 if iso == "JAM"
replace pop = 53192 if iso == "KNA"
replace pop = 183629 if iso == "LCA"
replace pop = 110947 if iso == "VCT"
replace pop = 586634 if iso == "SUR"
replace pop = 1399491 if iso == "TTO"
order pop, after(iso)

** Labelling
#delimit ; 
label define cname_ 1 "Antigua and Barbuda"
                    2 "The Bahamas"
                    3 "Barbados"
                    4 "Belize"
                    5 "Dominica"
                    6 "Grenada"
                    7 "Guyana"
                    8 "Haiti"
                    9 "Jamaica"
                    10 "Saint Kitts and Nevis"
                    11 "Saint Lucia"
                    12 "Saint Vincent and the Grenadines"
                    13 "Suriname"
                    14 "Trinidad and Tobago"
                    ;
#delimit cr 

** Attack Rate (per 1,000 --> not yet used)
gen confirmed_rate = (confirmed / pop) * 10000

** Keep selected variables
decode country, gen(country2)
keep date country country2 iso pop confirmed confirmed_rate deaths recovered
order date country country2 iso pop confirmed confirmed_rate deaths recovered
bysort country : gen elapsed = _n 

** Scroll through multiple identical graphics
** They vary only by Caribbean country
bysort country: egen elapsed_max = max(elapsed)
local clist "ATG BHS BRB BLZ DMA GRD GUY HTI JAM KNA LCA VCT SUR TTO"
foreach country of local clist {
    /// Elapsed days for each country
    gen el_`country'1 = elapsed_max if iso=="`country'"
    egen el_`country' = min(el_`country'1) 
    local el_`country' = el_`country' 
    local te_`country' = el_`country' + 0.25
    /// Long version name for each country
    gen c3 = country if iso=="`country'"
    label values c3 cname_
    egen c4 = min(c3)
    label values c4 cname_
    decode c4, gen(c5)
    local cname = c5
    drop c3 c4 c5
}

keep country date pop confirmed confirmed_rate deaths recovered
** Fix Guyana 
replace confirmed = 4 if country==7 & date>=d(17mar2020) & date<=d(23mar2020)
rename confirmed metric1
rename confirmed_rate metric2
rename deaths metric3
rename recovered metric4
reshape long metric, i(country date) j(mtype)
label define mtype_ 1 "cases" 2 "attack rate" 3 "deaths" 4 "recovered"
label values mtype mtype_
sort country mtype date 


** CARIBBEAN-WIDE SUMMARY 

** 1. Total count of cases across the Caribbean / CARICOM
** 2. Total count of deaths across the Caribbean / CARICOM
keep if mtype==1 | mtype==3
collapse (sum) metric pop, by(date mtype) 

** New daily cases and deaths
sort mtype date 
gen daily = metric - metric[_n-1] if mtype==mtype[_n-1]

** DOUBLING RATE
** Then create a rolling average 
** Using 1-week window for now
format pop  %14.0fc
gen growthrate = log(metric/metric[_n-1]) if mtype==mtype[_n-1] 
gen doublingtime = log(2)/growthrate
by mtype: asrol doublingtime , stat(mean) window(date 7) gen(dt7)

** NUMBER OF CASES and NUMBER OF DEATHS
sort mtype date 
egen tc1 = max(metric) if mtype==1 
egen tc2 = min(tc1)
egen td1 = max(metric) if mtype==3 
egen td2 = min(td1)
local ncases = tc2
local ndeaths = td2 
drop tc1 tc2 td1 td2 

** LOCAL MACRO FOR MOST RECENT DOUBLING TIME 
sort mtype date 
gen tdt1 = dt7 if mtype==1 & mtype!=mtype[_n+1]
egen tdt2 = min(tdt1)
gen tdt3 = int(tdt2)
local dt_cases = tdt3 
gen tdt4 = dt7 if mtype==3 & mtype!=mtype[_n+1]
egen tdt5 = min(tdt4)
gen tdt6 = int(tdt5)
local dt_deaths = tdt6 
drop tdt1 tdt2 tdt3 tdt4 tdt5 tdt6

dis "Cases are: " `ncases'
dis "Deaths are: " `ndeaths'
dis "Cases Doubled in: " `dt_cases'
dis "Deaths Doubled in: " `dt_deaths'


** CARICOM SUMMARY: CASES FIRST
** 1. BAR CHART    --> CUMULATIVE CASES.
** 2. BAR CHART    --> NEW DAILY CASES.
** 3. LINE CHART   --> RATE OF DOUBLING

** 1. BAR CHART    --> CUMULATIVE CASES
        #delimit ;
        gr twoway 
            (bar metric date if mtype==1, col("160 199 233"))
            (bar metric date if mtype==3, col("233 102 80")
            
            )
            ,

            plotregion(c(gs16) ic(gs16) ilw(thin) lw(thin)) 
            graphregion(color(gs16) ic(gs16) ilw(thin) lw(thin)) 
            bgcolor(white) 
            ysize(10) xsize(10)
            
            xlab(21984 "10 Mar" 21994 "20 Mar" 22004 "30 Mar" 22010 "5 Apr"
            , labs(3) nogrid glc(gs16) angle(45) format(%9.0f))
            xtitle(" ", size(1) margin(l=0 r=0 t=0 b=0)) 
                
            ylab(
            , labs(3) notick nogrid glc(gs16) angle(0))
            yscale(fill noline range(0(1)14)) 
            ytitle(" ", size(1) margin(l=0 r=0 t=0 b=0)) 
            
            title("(1) Cumulative cases in 14 CARICOM countries", pos(11) ring(1) size(4))

            legend(off size(4) position(11) ring(0) bm(t=1 b=1 l=1 r=1) colf cols(1) lc(gs16)
                region(fcolor(gs16) lw(vthin) margin(l=2 r=2 t=2 b=2) lc(gs16)) 
                )
                name(cases_bar_01) 
                ;
        #delimit cr
        graph export "`outputpath'/04_TechDocs/cumcases_region_$S_DATE.png", replace width(4000)


** 2. BAR CHART    --> NEW DAILY CASES.
        #delimit ;
        gr twoway 
            (bar daily date if mtype==1, col("160 199 233"))
            (bar daily date if mtype==3, col("233 102 80")
            
            )
            ,

            plotregion(c(gs16) ic(gs16) ilw(thin) lw(thin)) 
            graphregion(color(gs16) ic(gs16) ilw(thin) lw(thin)) 
            bgcolor(white) 
            ysize(10) xsize(10)
            
            xlab(21984 "10 Mar" 21994 "20 Mar" 22004 "30 Mar" 22010 "5 Apr"
            , labs(3) nogrid glc(gs16) angle(45) format(%9.0f))
            xtitle(" ", size(1) margin(l=0 r=0 t=0 b=0)) 
                
            ylab(
            , labs(3) notick nogrid glc(gs16) angle(0))
            yscale(fill noline range(0(1)14)) 
            ytitle(" ", size(1) margin(l=0 r=0 t=0 b=0)) 
            
            title("(2) Daily cases in 14 CARICOM countries", pos(11) ring(1) size(4))

            legend(off size(4) position(11) ring(0) bm(t=1 b=1 l=1 r=1) colf cols(1) lc(gs16)
                region(fcolor(gs16) lw(vthin) margin(l=2 r=2 t=2 b=2) lc(gs16)) 
                )
                name(cases_bar_02) 
                ;
        #delimit cr
        graph export "`outputpath'/04_TechDocs/newcases_region_$S_DATE.png", replace width(4000)

** 3. LINE CHART    --> RATE OF DOUBLING
        #delimit ;
        gr twoway 
            (line dt7 date if mtype==1, lc("23 83 135") lp("-"))
            (line dt7 date if mtype==3, lc("168 39 29") lp("-")
            )
            ,

            plotregion(c(gs16) ic(gs16) ilw(thin) lw(thin)) 
            graphregion(color(gs16) ic(gs16) ilw(thin) lw(thin)) 
            bgcolor(white) 
            ysize(10) xsize(10)
            
            xlab(21984 "10 Mar" 21994 "20 Mar" 22004 "30 Mar" 22010 "5 Apr"
            , labs(3) nogrid glc(gs16) angle(45) format(%9.0f))
            xtitle(" ", size(1) margin(l=0 r=0 t=0 b=0)) 
                
            ylab(
            , labs(3) notick nogrid glc(gs16) angle(0))
            yscale(fill noline range(0(1)14)) 
            ytitle(" ", size(1) margin(l=0 r=0 t=0 b=0)) 
            
            title("(3) Doubling time (days) in 14 CARICOM countries", pos(11) ring(1) size(4))

            legend(off size(4) position(11) ring(0) bm(t=1 b=1 l=1 r=1) colf cols(1) lc(gs16)
                region(fcolor(gs16) lw(vthin) margin(l=2 r=2 t=2 b=2) lc(gs16)) 
                )
                name(cases_dt_01) 
                ;
        #delimit cr
        graph export "`outputpath'/04_TechDocs/dt_region_$S_DATE.png", replace width(4000)


** ------------------------------------------------------
** PDF REGIONAL REPORT (COUNTS OF CONFIRMED CASES)
** ------------------------------------------------------
    putpdf begin, pagesize(letter) font("Calibri Light", 10) margin(top,0.5cm) margin(bottom,0.25cm) margin(left,0.5cm) margin(right,0.25cm)

** TITLE, ATTRIBUTION, DATE of CREATION
    putpdf paragraph ,  font("Calibri Light", 12)
    putpdf text ("COVID-19 Doubling Time for 14 CARICOM countries "), bold linebreak
    putpdf paragraph ,  font("Calibri Light", 8)
    putpdf text ("Briefing created by staff of the George Alleyne Chronic Disease Research Centre ") 
    putpdf text ("and the Public Health Group of The Faculty of Medical Sciences, Cave Hill Campus, ") 
    putpdf text ("The University of the West Indies. ")
    putpdf text ("Contact Ian Hambleton (ian.hambleton@cavehill.uwi.edu) "), italic
    putpdf text ("for details of quantitative analyses. "), font("Calibri Light", 8) italic
    putpdf text ("Contact Maddy Murphy (madhuvanti.murphy@cavehill.uwi.edu) "), italic 
    putpdf text ("for details of national public health interventions and policy implications."), font("Calibri Light", 8) italic linebreak
    putpdf text ("Updated on: $S_DATE at $S_TIME"), font("Calibri Light", 8) bold italic

** INTRODUCTION
    putpdf paragraph ,  font("Calibri Light", 9)
    putpdf text ("Aim of this briefing. ") , bold
    putpdf text ("We present the numbers of confirmed COVID-19 cases and deaths")
    putpdf text (" 1"), script(super) 
    putpdf text (" among CARICOM countries since the start of the outbreak.  ") 
    putpdf text ("In an outbreak such as this we must monitor the numbers of cases and deaths, and also the rate at which ") 
    putpdf text ("these numbers are increasing. Even if current numbers are small, a fast growth rate can quickly lead to ")
    putpdf text ("very large numbers. To report this rate of change we focus on the question: ") 
    putpdf text ("How long did it take for the number of confirmed deaths to double? "), italic
    putpdf text ("If cases go up by a fixed number over a fixed period – say, by 20 every three days – we call that “linear” growth. ") 
    putpdf text ("If instead, numbers double every three days (for example) we call that “exponential” growth. ") 
    putpdf text ("Without any national interventions for containment, we should expect near exponential growth. ") 
    putpdf text ("National policies to encourage social distancing should encourage linear growth or better. ") 
    putpdf text ("Daily tracking of the growth rate is therefore an important monitoring metric. "), linebreak
    putpdf text (" "), linebreak
    putpdf text ("We use three graphics to explore the rate of increase of cases and deaths up to $S_DATE. ") 
    putpdf text ("(graph 1) "), italic 
    putpdf text ("Cumulative cases and deaths across the 14 CARICOM members states, ")  
    putpdf text ("(graph 2) "), italic 
    putpdf text ("Daily cases and deaths across the 14 CARICOM member states, and ")
    putpdf text ("(graph 3) "), italic 
    putpdf text ("Doubling time (in days) for cases and for deaths (1-week rolling average). ")
    putpdf text ("An increasing doubling time can be an early indication that a national response is working."), linebreak
    putpdf text (" "), linebreak

** TABLE: KEY SUMMARY METRICS
    putpdf table t1 = (2,3), width(75%) halign(center) 
    putpdf table t1(1,1), font("Calibri Light", 13, ffffff) border(all,single,ffffff) bgcolor(215d92) 
    putpdf table t1(2,1), font("Calibri Light", 13, ffffff) border(all,single,ffffff) bgcolor(bd392b) 
    putpdf table t1(1,2), font("Calibri Light", 13, 000000) border(all,nil) 
    putpdf table t1(2,2), font("Calibri Light", 13, 000000) border(all,nil) 
    putpdf table t1(1,3), font("Calibri Light", 13, 000000) border(all,nil) 
    putpdf table t1(2,3), font("Calibri Light", 13, 000000) border(all,nil) 
    putpdf table t1(1,1)=("Confirmed Cases"), halign(center) 
    putpdf table t1(2,1)=("Confirmed Deaths"), halign(center)  
    putpdf table t1(1,2)=("`ncases'"), halign(center) 
    putpdf table t1(2,2)=("`ndeaths'"), halign(center) 
    putpdf table t1(1,3)=("Doubled in: `dt_cases' Days"), halign(center) 
    putpdf table t1(2,3)=("Doubled in: `dt_deaths' Days"), halign(center) 

** FIGURES OF REGIONAL COVID-19 COUNT trajectories
    putpdf table f1 = (1,3), width(100%) border(all,nil) halign(center)
    putpdf table f1(1,1)=image("`outputpath'/04_TechDocs/cumcases_region_$S_DATE.png")
    putpdf table f1(1,2)=image("`outputpath'/04_TechDocs/newcases_region_$S_DATE.png")
    putpdf table f1(1,3)=image("`outputpath'/04_TechDocs/dt_region_$S_DATE.png")

** FINAL WORD ON FTURE COUNTRY-LEVEL COUNTS
    putpdf paragraph ,  font("Calibri Light", 9)
    putpdf text ("Final Note on Country-Level Estimates. "), bold 
    putpdf text ("As of $S_DATE, the numbers of confirmed cases and deaths in individual countries remains thankfully low. ")
    putpdf text ("We will begin reporting the doubling rate for individual countries as the need arises. ")

** DATA REFERENCE
    putpdf table p3 = (1,1), width(100%) halign(center) 
    putpdf table p3(1,1), font("Calibri Light", 8) border(all,nil,000000) bgcolor(ffffff)
    putpdf table p3(1,1)=("(1) Data Source. "), bold halign(left)
    putpdf table p3(1,1)=("Dong E, Du H, Gardner L. An interactive web-based dashboard to track COVID-19 "), append 
    putpdf table p3(1,1)=("in real time. Lancet Infect Dis; published online Feb 19. https://doi.org/10.1016/S1473-3099(20)30120-1"), append

** Save the PDF
    local c_date = c(current_date)
    local c_time = c(current_time)
    local c_time_date = "`c_date'"+"_" +"`c_time'"
    local time_string = subinstr("`c_time_date'", ":", "_", .)
    local time_string = subinstr("`time_string'", " ", "", .)
    ///putpdf save "`outputpath'/05_Outputs/covid19_trajectory_caricom_heatmap_`time_string'", replace
    putpdf save "`outputpath'/05_Outputs/covid19_caricom_doublingtime_`c_date'", replace
