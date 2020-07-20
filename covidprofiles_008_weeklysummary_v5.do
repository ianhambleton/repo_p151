** HEADER -----------------------------------------------------
**  DO-FILE METADATA
    //  algorithm name					covidprofiles_008_weeklysummary_v5.do
    //  project:				        
    //  analysts:				       	Ian HAMBLETON
    // 	date last modified	            19-JUN-2020
    //  algorithm task			        xxx

    ** General algorithm set-up
    version 16
    clear all
    macro drop _all
    set more 1
    set linesize 80

    ** Create folder with today's date as name 
    local c_date = c(current_date)
    local today = lower(subinstr("`c_date'", " ", "_", .))

    ** Set working directories: this is for DATASET and LOGFILE import and export
    ** DATASETS to encrypted SharePoint folder
    local datapath "X:\The University of the West Indies\DataGroup - repo_data\data_p151"
    ** LOGFILES to unencrypted OneDrive folder
    local logpath "X:\OneDrive - The University of the West Indies\repo_datagroup\repo_p151"
    ** Reports and Other outputs
    ** ! This contains a local Windows-specific location 
    ** ! Would need changing for auto saving of PDF to online sync folder
    local outputpath "X:\The University of the West Indies\DataGroup - DG_Projects\PROJECT_p151"
    local parent "C:\Users\Ian Hambleton\Sync\Link_folders\COVID19 Surveillance Updates\05 weekly summary"
    cap mkdir "`parent'\\`today'
    local syncpath "C:\Users\Ian Hambleton\Sync\Link_folders\COVID19 Surveillance Updates\05 weekly summary\\`today'"

** HEADER -----------------------------------------------------

**! ------------------------------------------
**! The weekly surveillance update
**! Run this every Thursday 
**! ------------------------------------------

** Pre-Load the COVID metrics --> as Global Macros
qui do "`logpath'\covidprofiles_003_metrics_v5"

** Close any open log file and open a new log file
capture log close
log using "`logpath'\covidprofiles_008_weeklysummary_v5", replace


** CARICOM cases in past week
dis $m62caricom

** CARICOM deaths in past week
dis $m63caricom

** HAITI
dis $m62_HTI

** Reminaing cases
dis $m62caricom - $m62_HTI 

** New cases and deaths in past 24 hours
dis $m60caricom
dis $m61caricom

** Total cases in Haiti
dis $m01_HTI 

** Dom Rep
dis $m01_DOM
dis $m62_DOM
dis $m02_DOM


** Create a tentative standard text for this
** Will never be entirely possible - as text may need to change each week
** But should make the writing process a little easier

** DAY OF THE WEEK
local dow = dow(d("$S_DATE"))
if `dow'==0 {
    local day = "Sun" 
}
if `dow'==1 {
    local day = "Mon" 
}
if `dow'==2 {
    local day = "Tue" 
}
if `dow'==3 {
    local day = "Wed" 
}
if `dow'==4 {
    local day = "Thu" 
}
if `dow'==5 {
    local day = "Fri" 
}
if `dow'==6 {
    local day = "Sat" 
}

** Change over most recent week (62 and 63)
dis $m62caricom
dis $m63caricom
** Weekly change in cases (1 week ago) 
local change1 = $m64caricom - $m62caricom 
local change1d = $m65caricom - $m63caricom 
** Weekly change in cases (2 weeks ago) 
local change2 = $m66caricom - $m64caricom 
local change2d = $m67caricom - $m65caricom 

** Remaining deaths after removing Haiti 
local remain = $m62caricom - $m62_HTI 

** How many countries had one ore more cases ?
local number = 0
    if $m62_AIA>0 {
        local number = `number'+1
    }
    if $m62_ATG>0 {
        local number = `number'+1
    }
    if $m62_BHS>0 {
        local number = `number'+1
    }
    if $m62_BLZ>0 {
        local number = `number'+1
    }
    if $m62_BRB>0 {
        local number = `number'+1
    }
    if $m62_BMU>0 {
        local number = `number'+1
    }
    if $m62_VGB>0 {
        local number = `number'+1
    }
    if $m62_CYM>0 {
        local number = `number'+1
    }
    if $m62_DMA>0 {
        local number = `number'+1
    }
    if $m62_GRD>0 {
        local number = `number'+1
    }
    if $m62_GUY>0 {
        local number = `number'+1
    }
    if $m62_JAM>0 {
        local number = `number'+1
    }
    if $m62_MSR>0 {
        local number = `number'+1
    }
    if $m62_KNA>0 {
        local number = `number'+1
    }
    if $m62_LCA>0 {
        local number = `number'+1
    }
    if $m62_VCT>0 {
        local number = `number'+1
    }
    if $m62_SUR>0 {
        local number = `number'+1
    }
    if $m62_TTO>0 {
        local number = `number'+1
    }
    if $m62_TCA>0 {
        local number = `number'+1
    }

** BULLET
local bullet = uchar(8226)

** ------------------------------------------------------
** PDF COUNTRY REPORT
** ------------------------------------------------------
    putpdf begin, pagesize(letter) font("Calibri Light", 10) margin(top,0.5cm) margin(bottom,0.25cm) margin(left,0.5cm) margin(right,0.25cm)

** TITLE, ATTRIBUTION, DATE of CREATION
    putpdf table intro = (1,12), width(100%) halign(left)    
    putpdf table intro(.,.), border(all, nil)
    putpdf table intro(1,.), font("Calibri Light", 8, 000000)  
    putpdf table intro(1,1)
    putpdf table intro(1,2), colspan(11)
    putpdf table intro(1,1)=image("`outputpath'/04_TechDocs/uwi_crest_small.jpg")
    putpdf table intro(1,2)=("COVID-19 Weekly Summary"), halign(left) linebreak font("Calibri Light", 12, 000000)
    putpdf table intro(1,2)=("Briefing created by staff of the George Alleyne Chronic Disease Research Centre "), append halign(left) 
    putpdf table intro(1,2)=("and the Public Health Group of The Faculty of Medical Sciences, Cave Hill Campus, "), halign(left) append  
    putpdf table intro(1,2)=("The University of the West Indies. "), halign(left) append 
    putpdf table intro(1,2)=("Group Contacts: Ian Hambleton (analytics), Maddy Murphy (public health interventions), "), halign(left) append italic  
    putpdf table intro(1,2)=("Kim Quimby (logistics planning), Natasha Sobers (surveillance). "), halign(left) append italic   
    putpdf table intro(1,2)=("For all our COVID-19 surveillance outputs, go to "), halign(left) append
    putpdf table intro(1,2)=("www.uwi.edu/covid19/surveillance "), halign(left) underline append linebreak 
    putpdf table intro(1,2)=("Updated on: $S_DATE at $S_TIME "), halign(left) bold append

** INTRODUCTION
    putpdf paragraph ,  font("Calibri Light", 10)
    putpdf text ("Weekly Summary for the week ending `day' $S_DATE. ") , bold linebreak
    putpdf text ("In the week to `day' $S_DATE among the 20 CARICOM members and associate members, there have been ")
    putpdf text ("$m62caricom "),  
    putpdf text ("new confirmed cases (compared to `change1' last week, and `change2' two weeks ago) "),  
    putpdf text ("and $m63caricom new confirmed deaths (compared to `change1d' last week, and `change2d' two weeks ago). "),  
    putpdf text ("Most of these new cases were identified in Haiti ($m62_HTI). The remaining `remain' cases were reported in `number' countries: "), linebreak  
    putpdf text (" "), linebreak  


    putpdf paragraph ,  font("Calibri Light", 10) indent(left, 35pt)

    if $m62_AIA == 1 {
        putpdf text ("`bullet' Anguilla ($m62_AIA case)"), linebreak 
    }
    if $m62_AIA > 1 {
        putpdf text ("`bullet' Anguilla ($m62_AIA cases) "), linebreak 
    }
    if $m62_ATG == 1 {
        putpdf text ("`bullet' Antigua and Barbuda ($m62_ATG case) "), linebreak 
    }
    if $m62_ATG > 1 {
        putpdf text ("`bullet' Antigua and Barbuda ($m62_ATG cases) "), linebreak 
    }
    if $m62_BHS == 1 {
        putpdf text ("`bullet' The Bahamas ($m62_BHS case) "), linebreak 
    }
    if $m62_BHS > 1 {
        putpdf text ("`bullet' The Bahamas ($m62_BHS cases) "), linebreak 
    }
    if $m62_BRB == 1 {
        putpdf text ("`bullet' Barbados ($m62_BRB case) "), linebreak 
    }
    if $m62_BRB > 1 {
        putpdf text ("`bullet' Barbados ($m62_BRB cases) "), linebreak 
    }
    if $m62_BLZ == 1 {
        putpdf text ("`bullet' Belize ($m62_BLZ case) "), linebreak
    }
    if $m62_BLZ > 1 {
        putpdf text ("`bullet' Belize ($m62_BLZ cases) "), linebreak
    }
    if $m62_BMU == 1 {
        putpdf text ("`bullet' Bermuda ($m62_BMU case) "), linebreak
    }
    if $m62_BMU > 1 {
        putpdf text ("`bullet' Bermuda ($m62_BMU cases) "), linebreak
    }
    if $m62_VGB == 1 {
        putpdf text ("`bullet' The British Virgin Islands ($m62_VGB case) "), linebreak
    }
    if $m62_VGB > 1 {
        putpdf text ("`bullet' The British Virgin Islands ($m62_VGB cases) "), linebreak
    }
    if $m62_CYM == 1 {
        putpdf text ("`bullet' Cayman Islands ($m62_CYM case) "), linebreak
    }
    if $m62_CYM > 1 {
        putpdf text ("`bullet' Cayman Islands ($m62_CYM cases) "), linebreak
    }
    if $m62_DMA == 1 {
        putpdf text ("`bullet' Dominica ($m62_DMA case) "), linebreak
    }
    if $m62_DMA > 1 {
        putpdf text ("`bullet' Dominica ($m62_DMA cases) "), linebreak
    }
    if $m62_GRD == 1 {
        putpdf text ("`bullet' Grenada ($m62_GRD case) "), linebreak
    }
    if $m62_GRD > 1 {
        putpdf text ("`bullet' Grenada ($m62_GRD cases) "), linebreak
    }
    if $m62_GUY == 1 {
        putpdf text ("`bullet' Guyana ($m62_GUY case) "), linebreak
    }
    if $m62_GUY > 1 {
        putpdf text ("`bullet' Guyana ($m62_GUY cases) "), linebreak
    }
    if $m62_JAM == 1 {
        putpdf text ("`bullet' Jamaica ($m62_JAM case) "), linebreak
    }
    if $m62_JAM > 1 {
        putpdf text ("`bullet' Jamaica ($m62_JAM cases) "), linebreak
    }
    if $m62_MSR == 1 {
        putpdf text ("`bullet' Montserrat ($m62_MSR case) "), linebreak
    }
    if $m62_MSR > 1 {
        putpdf text ("`bullet' Montserrat ($m62_MSR cases) "), linebreak
    }
    if $m62_KNA == 1 {
        putpdf text ("`bullet' St Kitts and Nevis ($m62_KNA case) "), linebreak
    }
    if $m62_KNA > 1 {
        putpdf text ("`bullet' St Kitts and Nevis ($m62_KNA cases) "), linebreak
    }
    if $m62_LCA == 1 {
        putpdf text ("`bullet' St Lucia ($m62_LCA case) "), linebreak
    }
    if $m62_LCA > 1 {
        putpdf text ("`bullet' St Lucia ($m62_LCA cases) "), linebreak
    }
    if $m62_VCT == 1 {
        putpdf text ("`bullet' St Vincent and thee Grenadines ($m62_VCT case) "), linebreak
    }
    if $m62_VCT > 1 {
        putpdf text ("`bullet' St Vincent and the Grenadines ($m62_VCT cases) "), linebreak
    }
    if $m62_SUR == 1 {
        putpdf text ("`bullet' Suriname ($m62_SUR case) "), linebreak
    }
    if $m62_SUR > 1 {
        putpdf text ("`bullet' Suriname ($m62_SUR cases) "), linebreak
    }
    if $m62_TTO == 1 {
        putpdf text ("`bullet' Trinidad and Tobago ($m62_TTO case) "), linebreak
    }
    if $m62_TTO > 1 {
        putpdf text ("`bullet' Trinidad and Tobago ($m62_TTO cases) "), linebreak
    }
    if $m62_TCA == 1 {
        putpdf text ("`bullet' Turks and Caicos islands ($m62_TCA case) "), linebreak
    }
    if $m62_TCA > 1 {
        putpdf text ("`bullet' Turks and Caicos Islands ($m62_TCA cases) "), linebreak
    }

    putpdf text (" "), linebreak  

    putpdf paragraph ,  font("Calibri Light", 10) 
    putpdf text ("In the past 24 hours there have been $m60caricom new confirmed cases and $m61caricom new confirmed deaths. "), 
    putpdf text ("With $m01_HTI confirmed cases, $m62_HTI of these in the past week, "),  
    putpdf text ("Haiti remains the outbreak hotspot among the CARICOM members. "),
    putpdf text ("The continuing outbreak in neighbouring Dominican Republic "),
    putpdf text ("($m01_DOM cases, $m62_DOM in the past week, $m02_DOM deaths) compounds the situation in Haiti. "),

** Save the PDF
    local c_date = c(current_date)
    local date_string = subinstr("`c_date'", " ", "", .)
    putpdf save "`syncpath'/covid19_weeklysummary_`date_string'", replace


