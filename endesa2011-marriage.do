/*==============================================================================
Project:       Determinants of women's intrahousehold decision-making in 
               Nicaragua
Creation Date: 13 Oct 2020 
Output:        Database with variable lenght of marriage
==============================================================================*/

/*====================================================================
                        0: Program set up
====================================================================*/
global pjdatabase = "C:\Users\User\OneDrive\IOB - Publication\Database"

set more off , perm
clear all
version 15.1

/*====================================================================
                        1: Length of marriage
====================================================================*/
use "${pjdatabase}/ENDESA2011_Registro de nupcialidades.dta", clear
rename *, lower

gen double hh_id = hhclust * 10000000 + hhnumbv * 1000 + hvnumint * 100
format     hh_id %20.0g
lab var    hh_id "Household ID"


bys hh_id: egen last_marriage = max (orden)
keep if (orden == last_marriage)
drop last_marriage

gen interview = ym(qinty, qintm)
gen marriage = ym(qw705a, qw705m)

gen     years_cohabitation = (interview-marriage) / 12
replace years_cohabitation = . if (years_cohabitation <= 0)
lab var years_cohabitation "Years of cohabitation of the couple"

keep hh_id years_cohabitation 
save "${pjdatabase}/endesa2011-marriage.dta", replace

exit
* End of do-file
