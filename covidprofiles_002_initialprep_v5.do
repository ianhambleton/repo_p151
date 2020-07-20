** HEADER -----------------------------------------------------
**  DO-FILE METADATA
    //  algorithm name					covidprofiles_002_initialprep_v5.do
    //  project:				        
    //  analysts:				       	Ian HAMBLETON
    // 	date last modified	            19-JUN-2020
    //  algorithm task			        Initial cleaning of OWID / JH data downloads

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
    log using "`logpath'\covidprofiles_002_initialprep_v5", replace
** HEADER -----------------------------------------------------

** RUN covidprofiles_002_jhopkins.do BEFORE this algorithm
use "`datapath'\version01\2-working\owid_time_series", clear 
rename countryregion country 

** RESTRICT TO SELECTED COUNTRIES
** Keep 20 CARICOM countries 
** And keep selected international comparators 
** UK, USA, Sth Korea, Singapore, New Zealand, Iceland
** Plus Cuba and Dom Rep (just in case)
#delimit ; 
keep if 
        /// caricom
        iso=="AIA" | iso=="ATG" | iso=="BHS" |
        iso=="BLZ" | iso=="BMU" | iso=="BRB" |
        iso=="CYM" | iso=="DMA" | iso=="GRD" |
        iso=="GUY" | iso=="HTI" | iso=="JAM" |
        iso=="KNA" | iso=="LCA" | iso=="MSR" |
        iso=="SUR" | iso=="TCA" | iso=="TTO" |
        iso=="VCT" | iso=="VGB" | 
        /// comparators        
        iso=="ISL" | iso=="NZL" | iso=="SGP" |
        iso=="KOR" | iso=="GBR" | iso=="USA" |
        
        /// cuba and dominican republic  
        iso=="CUB" | iso=="DOM"
        ;
#delimit cr    

** Add a variable that creates alphabetical order for graphics (thinking of heatmaps in particular)
gen country_order = .
** CARICOM
replace country_order = 1 if iso=="AIA"
replace country_order = 2 if iso=="ATG"
replace country_order = 3 if iso=="BHS"
replace country_order = 4 if iso=="BRB"
replace country_order = 5 if iso=="BLZ"
replace country_order = 6 if iso=="BMU"
replace country_order = 7 if iso=="VGB"
replace country_order = 8 if iso=="CYM"
replace country_order = 9 if iso=="DMA"
replace country_order = 10 if iso=="GRD"
replace country_order = 11 if iso=="GUY"
replace country_order = 12 if iso=="HTI"
replace country_order = 13 if iso=="JAM"
replace country_order = 14 if iso=="MSR"
replace country_order = 15 if iso=="KNA"
replace country_order = 16 if iso=="LCA"
replace country_order = 17 if iso=="VCT"
replace country_order = 18 if iso=="SUR"
replace country_order = 19 if iso=="TTO"
replace country_order = 20 if iso=="TCA"
** Comparators
replace country_order = 21 if iso=="ISL"
replace country_order = 22 if iso=="NZL"
replace country_order = 23 if iso=="SGP"
replace country_order = 24 if iso=="KOR"
replace country_order = 25 if iso=="GBR"
replace country_order = 26 if iso=="USA"
** Cuba and Dom Rep
replace country_order = 27 if iso=="CUB"
replace country_order = 28 if iso=="DOM"
labmask country_order, values(country)
order country_order, after(country) 


** NUMERIC ISO 
gen iso_num = . 
replace iso_num = 1 if iso=="AIA"
replace iso_num = 2 if iso=="ATG"
replace iso_num = 3 if iso=="BHS"
replace iso_num = 4 if iso=="BRB"
replace iso_num = 5 if iso=="BLZ"
replace iso_num = 6 if iso=="BMU"
replace iso_num = 7 if iso=="VGB"
replace iso_num = 8 if iso=="CYM"
replace iso_num = 9 if iso=="DMA"
replace iso_num = 10 if iso=="GRD"
replace iso_num = 11 if iso=="GUY"
replace iso_num = 12 if iso=="HTI"
replace iso_num = 13 if iso=="JAM"
replace iso_num = 14 if iso=="MSR"
replace iso_num = 15 if iso=="KNA"
replace iso_num = 16 if iso=="LCA"
replace iso_num = 17 if iso=="VCT"
replace iso_num = 18 if iso=="SUR"
replace iso_num = 19 if iso=="TTO"
replace iso_num = 20 if iso=="TCA"
replace iso_num = 21 if iso=="ISL"
replace iso_num = 22 if iso=="NZL"
replace iso_num = 23 if iso=="SGP"
replace iso_num = 24 if iso=="KOR"
replace iso_num = 25 if iso=="GBR"
replace iso_num = 26 if iso=="USA"
replace iso_num = 27 if iso=="CUB"
replace iso_num = 28 if iso=="DOM"
labmask iso_num, values(iso)
order iso_num, after(iso) 

** Some minor cleaning of the Case and Death variables
sort iso date
** But need to fillin some early outbreak dates that have no associated row
** This needed to allow accurate count of days since start of outbreak
fillin iso date 
sort iso date
replace new_cases = 0 if new_cases==. & new_cases[_n-1]<. & iso==iso[_n-1] 
replace new_deaths = 0 if new_death==. & new_deaths[_n-1]<. & iso==iso[_n-1] 
replace total_cases = total_cases[_n-1] if total_cases==. & total_cases[_n-1]<. & iso==iso[_n-1] 
replace total_deaths = total_deaths[_n-1] if total_deaths==. & total_deaths[_n-1]<. & iso==iso[_n-1] 
replace country = country[_n-1] if country=="" & country[_n-1]!="" & iso==iso[_n-1] 
replace country_order = country_order[_n-1] if country_order==. & country_order[_n-1]<. & iso==iso[_n-1] 
replace iso_num = iso_num[_n-1] if iso_num==. & iso_num[_n-1]<. & iso==iso[_n-1] 
replace pop = pop[_n-1] if pop==. & pop[_n-1]<. & iso==iso[_n-1] 
** Drop some rows that exist prior to outbreak onset (
** EITHER both total_case and total_death entries are zero) 
** OR there are no entries at all for total_cases and total_deaths (missing)
** In the second case, we use -pop- as an indicator for a row of missing data 
drop if total_cases==0 | pop==.

** Save the cleaned and restricted dataset
save "`datapath'\version01\2-working\covid_restricted_001", replace