/*==============================================================================
Project:       Determinants of women's intrahousehold decision-making in 
               Nicaragua
Creation Date: 23 July 2021 
Output:        Database with determinants for women 
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
use "${pjdatabase}/ENDESA2011_Cuestionario de la mujer.dta", clear
rename *, lower
numlabel, add

*------------------------1.1: Region of residence
recode     region (1 = 1)(2 = 3)(3 = 4), gen (region_4)
replace    region_4 = 2 if ((region_4 == 1) & (hhdepar != 55))
lab define region_4 1 "Managua (capital), ref." 2 "Rest Pacific" 3 "Central" ///
                    4 "Caribbean", replace
lab value  region_4 region_4
lab var    region_4 "Region of residence"

*------------------------1.2: Area of residence
recode area (1 = 0 "Urban (ref.)") (2 = 1 "Rural"), gen (rural)
lab var rural "Area of residence"

*-------------------------1.3: Woman's level of education
recode qw112n (0/3 = 1)(4 = 2)(5/8 = 3)(9/11 = 4)(else = .), gen (level_educ)
replace    level_educ =1 if (qw108 == 2)
lab define level_educ 1 "No formal education (ref.)" 2 "Primary education" ///
                      3 "Secondary education" 4 "Higher than secondary", replace
lab values level_educ level_educ
lab var    level_educ "Woman's level of education"

*-------------------------1.4: Woman's years of schooling
recode  qw112n (0/4 = 0) (5/6 8 = 6) (7 = 9) (9/10 = 11) (11 = 16) (else = .) ///
    , gen (grade_school)
	
gen     years_schooling = grade_school + qw112g
replace years_schooling = 0 if (qw108 == 2)
lab var years_schooling "Years of schooling"

*-------------------------1.5: Woman's religion
recode  qw115 (1 = 1  "No religious (ref.)") (2 = 2 "Catholic") ///
    (3/96 = 3 "Other") (else = .), gen (religion)
	
replace religion = 3 if ((clave1 == 6140640) | (clave1 == 6140840) ///
    | (clave1 == 6140840) | (clave1 == 7011060) | (clave1 == 7210440) ///
	| (clave1 == 7210490) | (clave1 == 7240850))
lab var religion "Woman's religion"

*-------------------------1.6: Woman's ethnic group
recode qw116 (12 98 = 0 "None (ref.)") (1/11 96 = 1 "Indigenous or afrodescendant") ///
    (else = .), gen (ethnic_group)
	
replace ethnic_group = 1 if ((clave1 == 140020) | (clave1 == 280180) ///
    | (clave1 == 940640) | (clave1 == 1050360) | (clave1 == 1050480) ///
	| (clave1 == 1580300) | (clave1 == 1640450) | (clave1 == 4430150) ///
	| (clave1 == 4430360) | (clave1 == 4430420) | (clave1 == 4450600) ///
    | (clave1 == 4450670) | (clave1 == 4450710) | (clave1 == 4460640) ///
	| (clave1 == 4490490) | (clave1 == 4490600) | (clave1 == 4490690) ///
    | (clave1 == 4490740) | (clave1 == 4490750) | (clave1 == 4501540) ///
	| (clave1 == 4501650) | (clave1 == 4511440) | (clave1 == 4511450) ///
    | (clave1 == 4530690) | (clave1 == 4530760) | (clave1 == 4530970) ///
	| (clave1 == 4530990) | (clave1 == 4550120) | (clave1 == 4550160) ///
    | (clave1 == 4550310) | (clave1 == 4570570) | (clave1 == 5060970) ///
	| (clave1 == 5090280) | (clave1 == 5210990) | (clave1 == 5100600) ///
    | (clave1 == 5390540))
replace ethnic_group = 0 if ((clave1 == 2290650) | (clave1 == 3280930))
lab var ethnic_group "Woman's ethnic group"

*-------------------------1.7: Remarried women
recode qw703 (1 = 0 "No (ref.)") (2/max = 1 "Yes") (else = .) ///
    , gen (remarried_women)
lab var remarried_women "Woman is remarried"

*-------------------------1.8: Income labour perceived
recode qw719(1 = 1) (2 = 0) (else = .), gen (aux1)
recode qw720 (1 = 1)(2 = 0)(else = .), gen (aux2)

egen       income_labor = rsum (aux1 aux2)
drop aux1 aux2
replace    income_labor = 0 if ((qw724 == 6) | (qw724 == 7) | (qw724 == 98))
lab var    income_labor "Have an income labor"
lab define income_labor 0 "Unemployed" 1 "Employed", replace
lab values income_labor income_labor

*-------------------------1.9: Income relative contribution
recode qw732 (1/2 = 2 "Low") (3 = 3 "Half")(4/5 = 4 "High") (else = .) ///
    , gen (income_contribution)

replace    income_contribution = 1 if (income_labor == 0)
lab define income_contribution 1 "No contribution (ref.)" 2 "Low contribution" ///
                               3 "Half contribution" 4 "High contribution", replace
lab values income_contribution income_contribution
lab var    income_contribution "Income relative contribution"

*-------------------------1.10: Attitudes towards gender norms
recode qw804 (2 = 1) (1 = 0) (else = .), gen (role_obedience)
recode qw805 (2 = 1) (1 = 0) (else = .), gen (role_familyprobl)
recode qw806 (2 = 1) (1 = 0) (else = .), gen (role_head)
recode qw807 (2 = 1) (1 = 0) (else = .), gen (role_sr)
recode qw808 (1 = 1) (2 = 0) (else = .), gen (role_intervention)

local g_roles qw809a qw809b qw809c qw809d qw809e
foreach g_role of local g_roles {
    recode `g_role' (1 = 0)(2 = 1)(else = .), gen (role_`g_role')
}

factor role_head role_obedience role_familyprobl role_sr role_qw809a ///
    role_qw809b role_qw809c role_qw809d role_qw809e
predict index

note: role_familyprobl and role_sr dropped. The codes below represent the ///
      different compositions tested. 

alpha role_head role_obedience role_qw809a role_qw809b role_qw809c role_qw809d ///
    role_qw809d role_qw809e, i s c //0.7143
alpha role_obedience role_qw809a role_qw809b role_qw809c role_qw809d ///
    role_qw809e, i s c //0.7158
alpha role_head role_qw809a role_qw809b role_qw809c role_qw809d role_qw809e ///
    , i s c //0.7233, allows variation
alpha role_head role_obedience role_qw809a role_qw809b role_qw809c role_qw809d ///
    , i s c //0.6822
alpha role_head role_obedience role_qw809a role_qw809b role_qw809c role_qw809e ///
    , i s c //0.6667
alpha role_head role_obedience role_qw809a role_qw809b role_qw809d role_qw809e ///
    , i s c //0.6554
alpha role_head role_obedience role_qw809a role_qw809c role_qw809d role_qw809e ///
    , i s c //0.6491
alpha role_head role_obedience role_qw809b role_qw809c role_qw809d role_qw809e ///
    , i s c //0.6671
alpha role_qw809a role_qw809b role_qw809c role_qw809d role_qw809e, i s c //0.7662

gen     role_index = role_qw809a + role_qw809b + role_qw809c + role_qw809d ///
                   + role_qw809e + role_head
lab var role_index "Gender roles index"

*--------------------------1.11: Woman's age
clonevar age = qw102

recode qw102 (15/19 = 1 "15-19 years (ref.)") (20/29 = 2 "20-29 years") ///
    (30/39 = 3 "30-39 years") (40/max = 4 "40-49 years") (else = .) ///
	, gen (age_interval) 
lab var age_interval "Woman's age - interval"

*-------------------------1.12: Limiting to pregnancy and STDs
recode qw330 (1/4 = 1 "Including") (5/max = 0 "Excluding") (else = .) ///
    , gen (Restriction_contraceptive)
lab var    Restriction_contraceptive "Restriction only for pregnancy or STD"

*-------------------------1.13: Restriction to children living in the household
recode  qw206t (0 = 1) (1/10 = 0) (else = .), gen (child_hh)
lab var child_hh "Children living in the household"

/*====================================================================
                        2: Keeping variables
====================================================================*/
gen double hh_id = hhclust*10000000 + hhnumbv*1000 + hvnumint*100
format     hh_id %20.0g
lab var    hh_id "Household ID"

keep hh_id clave1 hhclust hhnumbv hvnumint pesomef region region_4 area rural ///
     age age_interval level_educ years_schooling religion ethnic_group ///
	 remarried_women income_labor income_contribution role_obedience role_head ///
	 role_sr role_qw809a role_qw809b role_qw809c role_qw809d role_qw809e ///
	 role_index Restriction_contraceptive child_hh 

order hh_id, first 

save "${pjdatabase}/endesa2011-wdeterminant.dta", replace
exit
* End of do-file




 