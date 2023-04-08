/*==============================================================================
Project:       Determinants of women's intrahousehold decision-making in 
               Nicaragua     
Creation Date: 13 Oct 2020 
Output:        Global MPI Nicaragua using ENDESA 2011/12 - Based on Alkire, 
               Kanagaratnam, and Suppa (2019)
==============================================================================*/

/*====================================================================
                        0: Program set up
====================================================================*/
global pjoutput   = "C:\Users\User\OneDrive\IOB - Publication\Output data"
global pjdatabase = "C:\Users\User\OneDrive\IOB - Publication\Database"

set more off , perm
clear all
version 15.1

/*====================================================================
                        1: Estimating MPI
====================================================================*/
use "${pjoutput}/nic_dhs11-12.dta", clear

*--------------------1.1: Keeping variables
bys hh_id: gen hogar = _n
keep if (hogar == 1)

keep clave1 hh_id strata year_interview month_interview date_interview d_cm ///
    d_nutr d_satt d_educ d_elct d_wtr d_sani d_hsg d_ckfl d_asst hhsize 

*--------------------1.2: Defining weights
*Health 33.33%
gen w_nutr = (1/6)
gen w_cm   = (1/6)

*Education 33.33%
gen w_educ = (1/6)
gen w_satt = (1/6)

*Living standard 33.33%
gen w_ckfl = (1/18)
gen w_sani = (1/18)
gen w_wtr  = (1/18)
gen w_elct = (1/18)
gen w_hsg  = (1/18)
gen w_asst = (1/18)

*--------------------1.3: Weighted deprivation matrix
local indicators nutr cm educ satt ckfl sani wtr elct hsg asst
foreach indicator of local indicators {
    gen     w_hh_d_`indicator' = d_`indicator' *w_`indicator'
    lab var d_`indicator' "Household deprivad in `indicator'"
    lab var w_`indicator' "Weight of `indicator'"
    lab var w_hh_d_`indicator' "Weighted deprivation of `indicator'"
}

*--------------------1.4: Counting vector
gen     cvec = w_hh_d_nutr + w_hh_d_cm + w_hh_d_educ + w_hh_d_satt + w_hh_d_ckfl ///
             + w_hh_d_sani + w_hh_d_wtr + w_hh_d_elct + w_hh_d_hsg + w_hh_d_asst
lab var cvec "Counting vector"
drop if cvec == .
replace cvec = cvec * 100

forv cutoffs = 10(1)100 {
    gen     h_`cutoffs'p = cvec >= `cutoffs'
    lab var h_`cutoffs'p "Poverty indentification with k = `cutoffs'%"
    gen     a_`cutoffs'p = cvec if (h_`cutoffs'p == 1)
    lab var a_`cutoffs'p "Individual deprivation share with k = `cutoffs'%"
    gen     m0_`cutoffs'p = 0
    replace m0_`cutoffs'p = cvec if (h_`cutoffs'p == 1)
    lab var m0_`cutoffs'p "Individual censored ci with k = `cutoffs'%"
}

sum h_*p a_*p m0_*p, sep(10)

gen     h_3333p = cvec >= 33.33
lab var h_3333p "Poverty indentification with k = 33.33%"

gen     a_3333p = cvec if (h_3333p == 1)
lab var a_3333p "Individual deprivation share with k = 33.33%"

gen     m0_3333p = 0
replace m0_3333p = cvec if (h_3333p == 1)
lab var m0_3333p "Individual censored ci with k = 33.33%"

sum h_3333p a_3333p m0_3333p, sep(10)

/*====================================================================
                        2: Final steps
====================================================================*/
save "${pjdatabase}/endesa2011-gmpi.dta", replace

exit
* End of do-file

><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><

Notes:
1. Alkire, S., Kanagaratnam, U., & Suppa, N.(2019). The Global Multidimensional 
Poverty Index (MPI) 2019. OPHI MPI Methodological Note 47. 
https://www.ophi.org.uk/wp-content/uploads/OPHI_MPI_MN_47_2019_vs2.pdf
