/*==============================================================================
Project:       Determinants of women's intrahousehold decision-making in 
               Nicaragua
Creation Date: 13 Oct 2020 
Output:        Database with determinants for men 
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
use "${pjdatabase}/ENDESA2011_Cuestionario del hombre.dta", clear
rename *, lower
numlabel, add

*---------------------------1.1: Man's level of education
recode m112n (0/3 = 1) (4 = 2) (5/8 = 3) (9/11 = 4) (else = .) ///
    , gen (level_educ_men)

replace    level_educ = 1 if (m108 == 2)
lab define level_educ_men 1 "None" 2 "Primary" 3 "Secondary" 4 "Tertiary/Tech" ///
    , replace
lab values level_educ_men level_educ_men
lab var    level_educ_men "Man's level of education"

*---------------------------1.2: Man's years of schooling
replace m112g = . if (m112g == 9)
recode  m112n (0/4 = 0) (5/6 8 = 6)(7 = 9) (9/10 = 11) (11 = 16) (else = .) ///
    , gen (grade_school)

gen     years_schooling_men = grade_school + m112g
replace years_schooling_men = 0 if (m108 == 2)
drop    grade_school
lab var years_schooling_men "Years of schooling"

*---------------------------1.3: Man's age
rename m102 age_men
lab var     age_men "Man's age"

*---------------------------1.4: Man's employment status
recode m117 (1 = 1) (2 = 0) (else = .), gen (aux1)
recode m118 (1 = 1) (2 = 0) (else = .), gen (aux2)

egen       income_labor_m = rsum (aux1 aux2)
lab var    income_labor_m "Employment status of spouse"
lab define income_labor_m 0 "Unemployed" 1 "Employed", replace
lab values income_labor_m income_labor_m
drop aux1 aux2
replace    income_labor_m = 0 if ((m122 == 6) | (m122 == 7))
	
/*====================================================================
                        2: Dependent variables
====================================================================*/

*---------------------------2.1: Decision-making questions
local decisions m702a m702b m702c m702d m702e m702f m702g
foreach decision of local decisions {
    recode   `decision' (2 = 1 "Women alone") (3 = 2 "Jointly decision") ///
	    (1 96 = 3 "Someone else") (else = .), gen (decision_`decision')
    _crcslbl `decision' decision_`decision'
}

clonevar men706 = m706
replace  men706 = . if (clave1 == 2050480)
replace  men706 = 3 if (clave1 == 4080350)
recode   men706 (1 = 1 "Women alone") (3 = 2 "Jointly decision") ///
                (2 96 = 3 "Someone else")(else = .), gen (decision_m706)
_crcslbl m706 decision_m706
lab var  decision_m706 "Decision-making variables"

drop if (clave1 == 2310570) //Man did not have a partner
drop if (clave1 == 4170650) //Man did not have a partner

/*====================================================================
                        3: Keeping variables
====================================================================*/
gen double hh_id = hhclust * 10000000 + hhnumbv * 1000 + hvnumint * 100
format     hh_id %20.0g
lab var    hh_id "Household ID"

keep  hh_id clave1 hhclust hhnumbv hvnumint pesohef level_educ_men ///
    years_schooling_men age_men income_labor_m decision_m702a decision_m702b ///
    decision_m702c decision_m702d decision_m702e decision_m702f decision_m702g ///
	decision_m706
order hh_id, first
save "${pjdatabase}/endesa2011-mdeterminant.dta", replace

exit
* End of do-file



