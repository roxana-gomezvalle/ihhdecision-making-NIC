/*==============================================================================
Project:       Determinants of women's intrahousehold decision-making in 
               Nicaragua
Creation Date: 13 Oct 2020 
Output:        Master database to estimate determinants of women's 
               decision-making
==============================================================================*/

/*====================================================================
                        0: Program set up
====================================================================*/
global pjdatabase = "C:\Users\User\OneDrive\IOB - Publication\Database"
global dofiles = "C:\Users\User\OneDrive\IOB - Publication\Do-files"

set more off , perm
clear all
version 15.1

/*====================================================================
                        1: External do-files
====================================================================*/
qui {
    do "${dofiles}/determinants-women"
    do "${dofiles}/determinants-men"
    do "${dofiles}/endesa2011-mpi"
    do "${dofiles}/selecting-hh"
    do "${dofiles}/endesa2011-marriage"
}

/*====================================================================
                        2: Creating remaining variables
====================================================================*/
use "${pjdatabase}/ENDESA2011_Miembros del hogar.dta", clear
rename *, lower
numlabel, add

*---------------------------2.1: Household composition
gen double hh_id = hhclust * 10000000 + hhnumbv * 1000 + hvnumint * 100
format     hh_id %20.0g
lab var    hh_id "Household ID"

recode qhs3p04 (1/5 15 = 1) (6/14 = 0) (else = .), gen (nuclear_members)

bys hh_id: egen nuclear_hh = mean (nuclear_members)
replace         nuclear_hh = 2 if ((nuclear_hh != 1) & !missing(nuclear_hh))
lab var         nuclear_hh "Household composition"
recode          nuclear_hh (1 = 0) (2 = 1) (else = .)
lab define      nuclear_hh 1 "Extended household" 0 "Nuclear  household (ref.)" ///
    , replace
lab values      nuclear_hh nuclear_hh

*---------------------------2.2: Number of additional adult members
egen      ID = concat (clave1 cp)
merge m:1 ID using "id-hombre.dta", gen (mh)
merge m:1 ID using "id-mujer.dta", gen (mm)

merge m:1 hh_id using "endesa2011-hhid.dta", gen (merge_married)
keep if (merge_married == 3)

gen     adult_18 = ((qhs3p03 > 17) & (qhs3p05 == 1) & (mh != 3))
replace adult_18 = 1 if ((q  hs3p03 > 17) & (qhs3p05 == 2) & (mm != 3))

bys hh_id: egen size2 = sum (adult_18) 
lab var         size2 "Additional adult members"

bys hh_id: gen hogar = _n
keep if (hogar == 1)

keep hh_id clave1 hhclust hhnumbv hvnumint pesohogar cp nuclear_hh size2 ///
    merge_married
save "endesa2011-database.dta", replace

/*====================================================================
                        3: Merging databases
====================================================================*/
*---------------------------3.1: Merging
foreach file in "${pjdatabase}/endesa2011-gmpi.dta" "${pjdatabase}/endesa2011-mdeterminant.dta" ///
    "${pjdatabase}/endesa2011-wdeterminant.dta" "${pjdatabase}/endesa2011-marriage.dta"{
    merge 1:1 hh_id using "`file'", gen (merge)
    drop merge
}

order hh_id, first

*---------------------------3.2: Remaining variables: Age gap
gen     age_gap = age_men - age
lab var age_gap "Age gap of the couple"
recode  age_gap (min/-1 = 1 "Woman older (ref.)") (0 = 2 "Same age") ///
                (1/max = 3 "Woman younger") (else = .), gen(interval_agegap)
lab var interval_agegap "Age gap of the couple - intervals"

*---------------------------3.3: Remaining variables: Educational gap - Level of education
gen    educ_gap_interval = level_educ_men - level_educ
recode educ_gap_interval (min/-1 = 1 "Woman more education (ref.)") ///
                         (0 = 2 "Same education") (1/max = 3 "Woman less education") ///
						 (else = .), gen (educational_gap_level)
lab var educational_gap_level "Educational gap of the couple"

*---------------------------3.4: Remaining variables: Employment status categories
gen     relative_employment = ((income_labor_m == 0) & (income_labor == 1))
replace relative_employment = 0 if ((income_labor_m == 1) & (income_labor == 0)) 
replace relative_employment = 2 if ((income_labor_m == 1) & (income_labor == 1)) 
replace relative_employment = . if ((income_labor_m == 0) & (income_labor == 0))
lab var relative_employment "Employment status"

/*====================================================================
          4: Keeping cohabitating couples' complete information
====================================================================*/
*---------------------------4.1: Keeping for couples
keep if (merge_married == 3)
drop    merge_married

save "endesa2011-database.dta", replace

*---------------------------4.2: Redefining decision-making over contraceptive use
clonevar decision_contraceptiveuse = decision_m702f
lab var  decision_contraceptiveuse "Decision-making over contraceptive use clean"
replace  decision_contraceptiveuse = . if (Restriction_contraceptive == 0)

*---------------------------4.3: Restricting children-related decisions
clonevar decision_doctor = decision_m702c
lab var  decision_doctor "Decision-making taking children to doctor"
replace  decision_doctor = . if (child_hh == 0)

clonevar decision_education = decision_m702d
lab var  decision_doctor "Decision-making children's education"
replace  decision_education = . if (child_hh == 0)

clonevar decision_disc = decision_m702g
lab var  decision_disc "Decision-making children's disciplining"
replace  decision_disc = . if (child_hh == 0)

*---------------------------4.4: Labelling variables
clonevar Household_welfare = m0_3333p
lab var  Household_welfare "Household welfare"

/*====================================================================
                     5: Summary statistics
===================================================================*/
*----------------------5.1: Dependent variables
tabm decision_m702b decision_m706 decision_m702c decision_m702d decision_m702g ///
    decision_m702a decision_m702e decision_contraceptiveuse, row

numlabel, add
sum role_index ibn.income_contribution ibn. income_labor ibn.income_labor_m ///
    ibn.interval_agegap ibn.educational_gap_level years_cohabitation       ///
	ibn.age_interval ibn.level_educ ibn.religion ibn.ethnic_group         ///
	ibn.remarried_women Household_welfare ibn.nuclear_hh size2           ///
	ibn.region_4 ibn.rural

/*====================================================================
                     6: Tests
===================================================================*/
global xlist Household_welfare i.income_contribution i.nuclear_hh size2   ///
    i.age_interval i.interval_agegap i.level_educ i.educational_gap_level ///
    years_cohabitation i.religion i.ethnic_group i.remarried_women i.region_4 ///
	i.rural role_index
numlabel, add

*----------------------6.1: Tests of IIA: MNL models
local decision_indicators decision_m702b decision_m706 decision_m702c ///
    decision_m702d decision_m702g decision_m702a decision_m702e      ///
	decision_contraceptiveuse
	
foreach decision_indicator of local decision_indicators {
    mlogit `decision_indicator' $xlist
    estimates store m1
    quietly mlogit `decision_indicator' $xlist if (`decision_indicator' != 1)
    estimates store m2
    quietly mlogit `decision_indicator' $xlist if (`decision_indicator' != 3)
    estimates store m3
    estimates dir
    suest m1 m2, noomitted
    test [m1_3__Someone_else = m2_3__Someone_else], cons
    suest m1 m3, noomitted
    test [m1_1__Women_alone = m3_1__Women_alone], cons
    drop _est*
}

*----------------------6.2: Tests goodness of fit - Hosmer-Lemeshow: MNL
foreach decision_indicator of local decision_indicators {
    mlogit `decision_indicator' $xlist [pw = pesomef]
    mlogitgof
}

*----------------------6.3: Test Wald - Joint variables
local decision_indicators decision_m702b decision_m706 decision_m702c ///
    decision_m702d decision_m702g decision_m702a decision_m702e      ///
	decision_contraceptiveuse
foreach decision_indicator of local decision_indicators {
    mlogit `decision_indicator' $xlist [pw = pesomef]
    mlogtest, combine
}

/*====================================================================
                     7: Estimations
===================================================================*/
*---------------------------7.1: MNL regressions - Relative incomes (1)
global xlist role_index i.income_contribution i.interval_agegap                ///
    i.educational_gap_level years_cohabitation i.age_interval i.level_educ     ///
    i.religion i.ethnic_group i.remarried_women Household_welfare i.nuclear_hh ///
    size2 i.region_4 i.rural
	
est clear

local a = 1
local b = 1
local setone_variables decision_m702b decision_m706 decision_m702c decision_m702d
foreach setone_variable of local setone_variables {
    mlogit `setone_variable' $xlist [pw = pesomef] 
    est store m`a'
    est res m`a'
    margins, dydx (*) predict (outcome(1)) vce (unconditional) post
    est store r`b'
    est res m`a'
    margins, dydx (*) predict (outcome(2)) vce (unconditional) post
    local b = `b' + 1
    est store r`b'
    est res m`a'
    margins, dydx (*) predict (outcome(3)) vce (unconditional) post
    local b = `b' + 1
    est store r`b'
    local b = `b' + 1
    local a = `a' + 1
}

esttab r* using table1.xls, replace compress unstack b (3) se (2) ///
    star (* 0.10 ** 0.05 *** 0.01) lab varwidth (35)             ///
	title (Marginal effects of determinants on decision-making) ///
    mgroups ("Large household purchases" "General income expenditures" ///
    "Take children to doctor" "Children's education"                  ///
	, pattern (1 0 0 1 0 0 1 0 0 1 0 0 )) ///
    mtitles ("Woman alone" "Joint decision" "Someone else" "Woman alone" ///
	"Joint decision" "Someone else" "Woman alone" "Joint decision"      ///
	"Someone else" "Woman alone" "Joint decision" "Someone else") nonumbers

estout r*
esttab r* using table1.tex, replace b (3) se (2) star (* 0.10 ** 0.05 *** 0.01) ///
    booktabs compress alignment (D{.}{.}{-1})                          ///
	title (Marginal effects of determinants on decision-making) label  ///
    mgroups ("Large household purchases" "General income expenditures" ///
	"Take children to doctor" "Children's education"                   ///
	, pattern (1 0 0 1 0 0 1 0 0 1 0 0 ) prefix (\multicolumn{@span}{c}{) ///
	suffix(}) span erepeat(\cmidrule(lr){@span})) dropped (" ")           ///
    mtitles ("Alone" "Joint" "Someone else" "Alone" "Joint" "Someone else" ///
	"Alone" "Joint" "Someone else" "Alone" "Joint" "Someone else") nonumbers ///
    refcat (1.income_contribution "\emph{Income contribution}"               ///
	0.nuclear_hh "\emph{Household composition}" 1.age_interval               ///
	"\emph{Woman's age}" 1.interval_agegap "\emph{Couple's age difference}"  ///
    1.level_edu "\emph{Women's education}"                            ///
	1.educational_gap_level "\emph{Couple's educational diff.}"       ///
	0.religion "\emph{Religion}" 0.ethnic_group "\emph{Ethnic group}" ///
	0.remarried_women "\emph{Remaried}" 1.region_4 "\emph{Region of residence}" ///
	0.rural "\emph{Area of residence}", nolabel) longtable

*---------------------------7.2: MNL regressions - Relative incomes (2)
global xlist role_index i.income_contribution i.interval_agegap ///
    i.educational_gap_level years_cohabitation i.age_interval i.level_educ ///
    i.religion i.ethnic_group i.remarried_women Household_welfare i.nuclear_hh ///
	size2  i.region_4 i.rural 
est clear

local a = 1
local b = 1
local settwo_variables decision_m702g decision_m702a decision_m702e ///
    decision_contraceptiveuse
foreach settwo_variable of local settwo_variables {
    mlogit `settwo_variable' $xlist [pw = pesomef] 
    est store m`a'
    est res m`a'
    margins, dydx (*) predict (outcome(1)) vce (unconditional) post
    est store r`b'
    est res m`a'
    margins, dydx (*) predict (outcome(2)) vce (unconditional) post
    local b = `b' + 1
    est store r`b'
    est res m`a'
    margins, dydx (*) predict (outcome(3)) vce (unconditional) post
    local b = `b' + 1 
    est store r`b'
    local b = `b' + 1
    local a = `a' + 1
}

esttab r* using table2.xls, replace compress unstack b (3) se (2) ///
    star (* 0.10 ** 0.05 *** 0.01) lab varwidth (35)              ///
	title (Marginal effects of determinants on decision-making)   ///
    mgroups ("Children's disciplining" "Visit to family and friends" ///
	"Daily meals" "Contraceptive use", pattern (1 0 0 1 0 0 1 0 0 1 0 0 )) ///
    mtitles ("Woman alone" "Joint decision" "Someone else" "Woman alone"   ///
    "Joint decision" "Someone else" "Woman alone" "Joint decision"         ///
	"Someone else" "Woman alone" "Joint decision" "Someone else") nonumbers

estout r*
esttab r* using table2.tex, replace b (3) se (2) star (* 0.10 ** 0.05 *** 0.01) ///
    booktabs compress alignment (D{.}{.}{-1})                              ///
	title (Marginal effects of determinants on decision-making (II)) label ///
    mgroups ("Children's disciplining" "Visit to family/friends" "Daily meals" ///
	"Contraceptive use", pattern (1 0 0 1 0 0 1 0 0 1 0 0 ) ///
    prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) ///
	dropped (" ") mtitles ("Alone" "Joint" "Someone else" "Alone" "Joint" ///
	"Someone else" "Alone" "Joint" "Someone else" "Alone" "Joint" "Someone else") ///
	nonumbers refcat (1.income_contribution "\emph{Income contribution}" ///
	0.nuclear_hh "\emph{Household composition}" 1.age_interval "\emph{Woman's age}" ///
	1.interval_agegap "\emph{Couple's age diff.}"                        ///
	1.level_edu "\emph{Women's education}"                               ///
	1.educational_gap_level "\emph{Couple's educational diff.}"          ///
	0.religion "\emph{Religion}" 0.ethnic_group "\emph{Ethnic group}"    ///
	0.remarried_women "\emph{Remaried}" 1.region_4 "\emph{Region of residence}" ///
	0.rural "\emph{Area of residence}", nolabel) longtable

*---------------------------7.3: MNL regressions with employment (1)
global xlist role_index i.income_labor i.income_labor_m  i.interval_agegap ///
    i.educational_gap_level years_cohabitation i.age_interval i.level_educ ///
    i.religion i.ethnic_group i.remarried_women Household_welfare          ///
	i.nuclear_hh size2  i.region_4 i.rural 
est clear

local a = 1
local b = 1
foreach setone_variable of local setone_variables {
    mlogit `setone_variable' $xlist [pw = pesomef] 
    est store m`a'
    est res m`a'
    margins, dydx (*) predict (outcome(1)) vce (unconditional) post
    est store r`b'
    est res m`a'
    margins, dydx (*) predict (outcome(2)) vce (unconditional) post
    local b = `b' + 1
    est store r`b'
    est res m`a'
    margins, dydx (*) predict (outcome(3)) vce (unconditional) post
    local b = `b' + 1
    est store r`b'
    local b = `b' + 1
    local a = `a' + 1
}

esttab r* using table3.xls, replace compress unstack b (3) se (2) ///
    star (* 0.10 ** 0.05 *** 0.01) lab varwidth (35)              ///
	title (Marginal effects of determinants on decision-making)   ///
    mgroups ("Large household purchases" "General income expenditures" ///
	"Take children to doctor" "Children's education"                   ///
	, pattern (1 0 0 1 0 0 1 0 0 1 0 0 ))                              ///
    mtitles ("Woman alone" "Joint decision" "Someone else" "Woman alone" ///
	"Joint decision" "Someone else" "Woman alone" "Joint decision"       ///
	"Someone else" "Woman alone" "Joint decision" "Someone else") nonumbers

estout r*
esttab r* using table3.tex, replace b (3) se (2) star (* 0.10 ** 0.05 *** 0.01) ///
    booktabs compress alignment(D{.}{.}{-1})  ///
	title (Marginal effects of determinants on decision-making with employment status) label ///
    mgroups ("Large household purchases" "General income expenditures" ///
	"Take children to doctor" "Children's education"                   ///
	, pattern (1 0 0 1 0 0 1 0 0 1 0 0 ) prefix(\multicolumn{@span}{c}{) ///
	suffix(}) span erepeat(\cmidrule(lr){@span})) dropped (" ")            ///
    mtitles ("Alone" "Joint" "Someone else" "Alone" "Joint" "Someone else" ///
	"Alone" "Joint" "Someone else" "Alone" "Joint" "Someone else") nonumbers ///
    refcat (0.income_labor "\emph{Woman's employment status}"                ///
	0.income_labor_m "\emph{Spouse's employment status}"                     ///
	0.nuclear_hh "\emph{Household composition}" 1.age_interval "\emph{Woman's age}" ///
	1.interval_agegap "\emph{Couple's age difference}"                       ///
	1.level_edu "\emph{Women's education}"                                   ///
	1.educational_gap_level "\emph{Couple's educational diff.}"              ///
	0.religion "\emph{Religion}" 0.ethnic_group "\emph{Ethnic group}"        ///
	0.remarried_women "\emph{Remaried}" 1.region_4 "\emph{Region of residence}" ///
	0.rural "\emph{Area of residence}", nolabel) longtable

*---------------------------7.4: MNL regressions with employment (2)
global xlist role_index i.income_labor i.income_labor_m  i.interval_agegap ///
    i.educational_gap_level years_cohabitation i.age_interval i.level_educ ///
    i.religion i.ethnic_group i.remarried_women Household_welfare i.nuclear_hh ///
	size2 i.region_4 i.rural 
est clear

local settwo_variables decision_m702g decision_m702a decision_m702e ///
    decision_contraceptiveuse
local a = 1
local b = 1
foreach settwo_variable of local settwo_variables {
    mlogit `settwo_variable' $xlist [pw = pesomef] 
    est store m`a'
    est res m`a'
    margins, dydx (*) predict (outcome(1)) vce (unconditional) post
    est store r`b'
    est res m`a'
    margins, dydx (*) predict (outcome(2)) vce (unconditional) post
    local b = `b' + 1
    est store r`b'
    est res m`a'
    margins, dydx (*) predict (outcome(3)) vce (unconditional) post
    local b = `b' + 1
    est store r`b'
    local b = `b' + 1
    local a = `a' + 1
}

esttab r* using table4.xls, replace compress unstack b (3) se (2) ///
    star (* 0.10 ** 0.05 *** 0.01) lab varwidth (35)              ///
	title (Marginal effects of determinants on decision-making)   ///
    mgroups ("Children's disciplining" "Visit to family and friends" ///
	"Daily meals" "Contraceptive use", pattern (1 0 0 1 0 0 1 0 0 1 0 0 )) ///
    mtitles ("Woman alone" "Joint decision" "Someone else" "Woman alone" ///
	"Joint decision" "Someone else" "Woman alone" "Joint decision" "Someone else" ///
	"Woman alone" "Joint decision" "Someone else") nonumbers

estout r*
esttab r* using table4.tex, replace b (3) se (2) star (* 0.10 ** 0.05 *** 0.01) ///
    booktabs compress alignment (D{.}{.}{-1}) ///
	title (Marginal effects of determinants on decision-making with employment status (II)) label ///
    mgroups ("Children's disciplining" "Visit to family/friends" "Daily meals" ///
	"Contraceptive use", pattern (1 0 0 1 0 0 1 0 0 1 0 0 )        ///
	prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) ///
	dropped (" ") mtitles ("Alone" "Joint" "Someone else" "Alone" "Joint" ///
	"Someone else" "Alone" "Joint" "Someone else" "Alone" "Joint" "Someone else") ///
	nonumbers refcat (0.income_labor "\emph{Woman's employment status}" ///
	0.income_labor_m "\emph{Spouse's employment status}"                ///
	0.nuclear_hh "\emph{Household composition}" 1.age_interval "\emph{Woman's age}" ///
	1.interval_agegap "\emph{Couple's age diff.}"                       ///
	1.level_edu "\emph{Women's education}"                              ///
	1.educational_gap_level "\emph{Couple's educational diff.}"         ///
	0.religion "\emph{Religion}" 0.ethnic_group "\emph{Ethnic group}"   ///
	0.remarried_women "\emph{Remaried}" 1.region_4 "\emph{Region of residence}" ///
	0.rural "\emph{Area of residence}", nolabel) longtable

save "master-database.dta", replace
exit
* End of do-file
