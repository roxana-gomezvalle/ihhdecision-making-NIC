/*=============================================================================
Project:       Determinants of women's intrahousehold decision-making in 
               Nicaragua
Creation Date: 13 Oct 2020 
Output:        Delimited database for married/cohabiting women
==============================================================================*/

/*====================================================================
                        0: Program set up
====================================================================*/
global pjdatabase = "C:\Users\User\OneDrive\IOB - Publication\Database"

set more off , perm
clear all
version 15.1

/*====================================================================
                        1: Determinant variables
====================================================================*/
*---------------------------1.1: Creating ID
use "${pjdatabase}/ENDESA2011_Cuestionario del hombre.dta", clear
rename *, lower

egen        ID = concat (clave1 cp)
keep clave1 ID
save "id-hombre.dta", replace

use "${pjdatabase}/ENDESA2011_Cuestionario de la mujer.dta", clear
rename *, lower

egen        ID = concat (clave1 cp)
keep clave1 ID
save "id-mujer.dta", replace

use "${pjdatabase}/ENDESA2011_Miembros del hogar.dta", clear
rename *, lower

egen ID = concat (clave1 cp)

*---------------------------1.2: Merging women and men questionnaires
merge m:1 ID using "id-hombre.dta", gen (merge)
merge m:1 ID using "id-mujer.dta", gen (m)

gen      mrg = (m == 3 | merge == 3)
keep if (mrg == 1)

bys clave1: egen members = count (clave1)
drop if (members == 1)
keep if (qhs3p20 < 3)

bys clave1: gen difCP = cp-cp[_n-1]
bys clave1: egen dCP = max (difCP)
drop difCP
keep if ((dCP == 1) | (dCP == -1))

*---------------------------1.3: Creating unique household ID
rename *, lower

gen double hh_id = hhclust*10000000 + hhnumbv*1000 + hvnumint*100
format     hh_id %20.0g
lab var    hh_id "Household ID"

*---------------------------1.4: Checking duplicates
duplicates drop hh_id, force
keep hh_id 
save "${pjdatabase}/endesa2011-hhid.dta", replace

exit
* End of do-file




 