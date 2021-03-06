** HEADER -----------------------------------------------------
**  DO-FILE METADATA
    //  algorithm name					covidprofiles_007_region2.do
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
    log using "`logpath'\covidprofiles_007_region2", replace
** HEADER -----------------------------------------------------


** -----------------------------------------
** Pre-Load the COVID metrics --> as Global Macros
** -----------------------------------------
qui do "`logpath'\covidprofiles_004_metrics"
** -----------------------------------------

** Close any open log file and open a new log file
capture log close
log using "`logpath'\covidprofiles_005_country1", replace

** Country Labels
#delimit ; 
label define cname_ 1 "Antigua and Barbuda"
                    2 "The Bahamas"
                    3 "Barbados"
                    4 "Belize"
                    5 "Cuba"
                    6 "Dominica"
                    7 "Dominican Republic"
                    8 "Grenada"
                    9 "Guyana"
                    10 "Haiti"
                    11 "Jamaica"
                    12 "Saint Kitts and Nevis"
                    13 "Saint Lucia"
                    14 "Saint Vincent and the Grenadines"
                    15 "Singapore"
                    16 "South Korea"
                    17 "Suriname"
                    18 "Trinidad and Tobago"
                    19 "UK"
                    20 "USA"
                    ;
#delimit cr 


** COUNTRY RESTRICTION: CARICOM countries only (N=14)
#delimit ; 
keep if 
        iso=="ATG" |
        iso=="BHS" |
        iso=="BRB" |
        iso=="BLZ" |
        iso=="DMA" |
        iso=="GRD" |
        iso=="GUY" |
        iso=="HTI" |
        iso=="JAM" |
        iso=="KNA" |
        iso=="LCA" |
        iso=="VCT" |
        iso=="SUR" |
        iso=="TTO";
#delimit cr   

** HEATMAP preparation - ADD ROWS
** Want symmetric / rectangular matrix of dates. So we need 
** to backfill dates foreach country to date of first 
** COVID appearance - which I think was in JAM
    fillin date country 
    replace confirmed = 0 if confirmed==.
    replace deaths = 0 if deaths==.
    replace recovered = 0 if recovered==.

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
 
keep country date confirmed confirmed_rate deaths recovered

** Fix Guyana 
replace confirmed = 4 if country==9 & date>=d(17mar2020) & date<=d(23mar2020)
rename confirmed metric1
rename confirmed_rate metric2
rename deaths metric3
rename recovered metric4
reshape long metric, i(country date) j(mtype)
label define mtype_ 1 "cases" 2 "attack rate" 3 "deaths" 4 "recovered"
label values mtype mtype_
sort country mtype date 

** Automate changing bin-width for color bins
** Do this by calulcating # needed to have 10 bina
** Max anad Min across ALL countries
bysort mtype: egen maxv = max(metric)
bysort mtype: egen minv = min(metric) 
gen diffv = maxv - minv 
gen diffc1 = diffv if mtype==1
egen diffc2 = min(diffc1) 
gen diffc = round(diffc2/20)
global binc = diffc 
gen diffd1 = diffv if mtype==3
egen diffd2 = min(diffd) 
gen diffd = round(diffd2/15)
global bind = diffd 
drop maxv minv diffv diffd diffd1 diffd2 diffc diffc1 diffc2

** Automate final date on x-axis 
** Use latest date in dataset 
egen fdate1 = max(date)
global fdate = fdate1 
global fdatef : di %tdD_m date("$S_DATE", "DMY")


** -----------------------------------------
** HEATMAP -- CASES
** -----------------------------------------
#delimit ;
    heatplot metric i.country date if mtype==1
    ,
    color(spmap, blues)
    ///ramp(right)
    cuts(@min($binc)@max)
    keylabels(all, range(1))

    plotregion(c(gs16) ic(gs16) ilw(thin) lw(thin)) 
    graphregion(color(gs16) ic(gs16) ilw(thin) lw(thin)) 
    ysize(12) xsize(10)

    ylab(   1 "Antigua and Barbuda" 
            2 "The Bahamas" 
            3 "Barbados"
            4 "Belize" 
            5 "Dominica"
            6 "Grenada"
            7 "Guyana"
            8 "Haiti"
            9 "Jamaica"
            10 "St Kitts and Nevis"
            11 "St Lucia"
            12 "St Vincent"
            13 "Suriname"
            14 "Trinidad and Tobago"
    , labs(3) notick nogrid glc(gs16) angle(0))
    yscale(reverse fill noline range(0(1)14)) 
    ytitle(" ", size(1) margin(l=0 r=0 t=0 b=0)) 

    xlab(   21984 "10 Mar" 
            21994 "20 Mar" 
            22004 "30 Mar" 
            22015 "10 Apr"
            $fdate "$fdatef"
    , labs(3) nogrid glc(gs16) angle(45) format(%9.0f))
    xtitle(" ", size(1) margin(l=0 r=0 t=0 b=0)) 

    title("Confirmed cases by $S_DATE", pos(11) ring(1) size(4))

    legend(size(3) position(2) ring(4) colf cols(1) lc(gs16)
    region(fcolor(gs16) lw(vthin) margin(l=2 r=2 t=2 b=2) lc(gs16)) 
    sub("Confirmed" "Cases", size(3))
                    )
    name(heatmap_cases) 
    ;
#delimit cr
    graph export "`outputpath'/04_TechDocs/heatmap_cases_$S_DATE.png", replace width(4000)


** -----------------------------------------
** HEATMAP -- DEATHS
** -----------------------------------------
#delimit ;
    heatplot metric i.country date if mtype==3
    ,
    cuts(@min($bind)@max)
    color(spmap, reds)
    keylabels(all, range(1))

    plotregion(c(gs16) ic(gs16) ilw(thin) lw(thin)) 
    graphregion(color(gs16) ic(gs16) ilw(thin) lw(thin)) 
    ysize(12) xsize(10)

    ylab(   1 "Antigua and Barbuda" 
            2 "The Bahamas" 
            3 "Barbados"
            4 "Belize" 
            5 "Dominica"
            6 "Grenada"
            7 "Guyana"
            8 "Haiti"
            9 "Jamaica"
            10 "St Kitts and Nevis"
            11 "St Lucia"
            12 "St Vincent"
            13 "Suriname"
            14 "Trinidad and Tobago"
    , labs(3) notick nogrid glc(gs16) angle(0))
    yscale(reverse fill noline range(0(1)14)) 
    ytitle(" ", size(1) margin(l=0 r=0 t=0 b=0)) 

    xlab(   21984 "10 Mar" 
            21994 "20 Mar" 
            22004 "30 Mar" 
            22015 "10 Apr"
            $fdate "$fdatef"
    , labs(3) nogrid glc(gs16) angle(45) format(%9.0f))
    xtitle(" ", size(1) margin(l=0 r=0 t=0 b=0)) 

    title("Confirmed deaths by $S_DATE", pos(11) ring(1) size(4))

    legend(size(3) position(2) ring(4) colf cols(1) lc(gs16)
    region(fcolor(gs16) lw(vthin) margin(l=2 r=2 t=2 b=2) lc(gs16)) 
    sub("Confirmed" "Deaths", size(3))
    )
    name(heatmap_deaths) 
    ;
#delimit cr 
    graph export "`outputpath'/04_TechDocs/heatmap_deaths_$S_DATE.png", replace width(4000)


** ------------------------------------------------------
** PDF REGIONAL REPORT (COUNTS OF CONFIRMED CASES)
** ------------------------------------------------------
    putpdf begin, pagesize(letter) font("Calibri Light", 10) margin(top,0.5cm) margin(bottom,0.25cm) margin(left,0.5cm) margin(right,0.25cm)

** TITLE, ATTRIBUTION, DATE of CREATION
    putpdf table intro = (1,12), width(100%) halign(left)    
    putpdf table intro(.,.), border(all, nil)
    putpdf table intro(1,.), font("Calibri Light", 8, 000000)  
    putpdf table intro(1,1)
    putpdf table intro(1,2), colspan(11)
    putpdf table intro(1,1)=image("`outputpath'/04_TechDocs/uwi_crest_small.jpg")
    putpdf table intro(1,2)=("COVID-19 Heatmap for 14 CARICOM countries"), halign(left) linebreak font("Calibri Light", 12, 000000)
    putpdf table intro(1,2)=("Briefing created by staff of the George Alleyne Chronic Disease Research Centre "), append halign(left) 
    putpdf table intro(1,2)=("and the Public Health Group of The Faculty of Medical Sciences, Cave Hill Campus, "), halign(left) append  
    putpdf table intro(1,2)=("The University of the West Indies. "), halign(left) append 
    putpdf table intro(1,2)=("Group Contacts: Ian Hambleton (analytics), Maddy Murphy (public health interventions), "), halign(left) append italic  
    putpdf table intro(1,2)=("Kim Quimby (logistics planning), Natasha Sobers (surveillance). "), halign(left) append italic   
    putpdf table intro(1,2)=("For all our COVID-19 surveillance outputs, go to "), halign(left) append
    putpdf table intro(1,2)=("https://tinyurl.com/uwi-covid19-surveillance "), halign(left) underline append linebreak 
    putpdf table intro(1,2)=("Updated on: $S_DATE at $S_TIME "), halign(left) bold append

** INTRODUCTION
    putpdf paragraph ,  font("Calibri Light", 9)
    putpdf text ("Aim of this briefing. ") , bold
    putpdf text ("We present the cumulative number of confirmed COVID-19 cases and deaths ")
    putpdf text ("(see note 1)"), bold 
    putpdf text (" among CARICOM countries ") 
    putpdf text ("(see note 2)"), bold
    putpdf text (" since the start of the outbreak. ") 
    putpdf text ("We use heatmaps to visually summarise the situation as of $S_DATE. ") 
    putpdf text ("The intention is to highlight outbreak hotspots."), linebreak 

** FIGURES OF REGIONAL COVID-19 COUNT trajectories
    putpdf table f1 = (1,2), width(100%) border(all,nil) halign(center)
    putpdf table f1(1,1)=image("`outputpath'/04_TechDocs/heatmap_cases_$S_DATE.png")
    putpdf table f1(1,2)=image("`outputpath'/04_TechDocs/heatmap_deaths_$S_DATE.png")

** FOOTNOTE 1: DATA REFERENCE
** FOOTNOTE 2. CARICOM COUNTRIES
    putpdf table p3 = (2,1), width(100%) halign(center) 
    putpdf table p3(.,1), font("Calibri Light", 8) border(all,nil) bgcolor(ffffff)
    putpdf table p3(1,1)=("(NOTE 1) Data Source. "), bold halign(left)
    putpdf table p3(1,1)=("Dong E, Du H, Gardner L. An interactive web-based dashboard to track COVID-19 "), append 
    putpdf table p3(1,1)=("in real time. Lancet Infect Dis; published online Feb 19. https://doi.org/10.1016/S1473-3099(20)30120-1"), append
    putpdf table p3(2,1)=("(NOTE 2) CARICOM member states reported in this briefing.  "), bold halign(left)
    putpdf table p3(2,1)=("Antigua and Barbuda, The Bahamas, Barbados, Belize, Dominica, Grenada, Guyana, Haiti, Jamaica, "), append 
    putpdf table p3(2,1)=("St. Kitts and Nevis, St. Lucia, St. Vincent and the Grenadines, Suriname, Trinidad and Tobago."), append

** Save the PDF
    local c_date = c(current_date)
    local date_string = subinstr("`c_date'", " ", "", .)
    putpdf save "`outputpath'/05_Outputs/covid19_heatmap_version2_`date_string'", replace
