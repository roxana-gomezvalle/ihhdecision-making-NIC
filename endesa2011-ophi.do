/*==============================================================================
Project:       Determinants of women's intrahousehold decision-making in 
               Nicaragua     
Creation Date: 13 Oct 2020 
Output:        Global MPI Nicaragua using ENDESA 2011/12 - Indicators 
               OPHIS's do-file. This do-file has been minimally modified and 
			   is presented as downloaded from the OPHI site.
==============================================================================*/

/*====================================================================
                        0: Program set up
====================================================================*/
clear all 
set more off
set maxvar 10000
version 15.1

global path_in "C:\Users\User\OneDrive\IOB - Publication\Database"   
global path_ado "C:\Users\User\OneDrive\IOB - Publication\igrowup_update-master"
global path_out "C:\Users\User\OneDrive\IOB - Publication\Output data"

/*====================================================================
                        1: Malnourished children under 5
====================================================================*/
**-----------------1.1: Recoding children under 5
use "$path_in/ENDESA2011_Historia de nacimientos.dta", clear
rename _all, lower

gen double ind_id = hhclust*10000000 + hhnumbv*1000 + hvnumint*100 + qw221
format ind_id %20.0g
label var ind_id "Individual ID"
codebook ind_id

drop if qw225==2
gen child_KR=1

**-----------------1.2: Estimating nutritional information
*Indicating direction of ado file
adopath + "$path_ado\Children under 5"

*Indicating direction of data files
gen str100 reflib = "$path_ado\Children under 5"
lab var reflib "Directory of reference tables"

gen str100 datalib = "$path_ado\Children under 5" 
lab var datalib "Directory for datafiles"

gen str30 datalab = "children_nutri_nic" 
lab var datalab "Working file"

**-----------------1.3: Checking variables
*Sex
tab qw223, miss
tab qw223, nol 
clonevar gender = qw223
desc gender
tab gender

*Age
tab qw227, miss
tab edad_hijo, miss
tab agemos, miss
codebook agemos
clonevar age_months = agemos 
desc age_months
summ age_months
gen  str6 ageunit = "months" 
lab var ageunit "Months"

gen mdate = mdy(qintm, qintd, qinty)
gen bdate = mdy(qw224m, qw224d, qw224a) if qw224d <= 31
replace bdate = mdy(qw224m, 15, qw224a) if qw224d > 31 
gen age = (mdate-bdate)/30.4375 
replace qw1005=1 if qw1005==. & qw1006==1 & agemos<60 
keep if qw1005==1 

*Weight (KG)
tab qw1009, miss
codebook qw1009, tab (9999)
gen weight = qw1009 if qw1009<90
tab qw1009 if qw1009>9990, miss nol   
replace weight = . if qw1009>=9990 
replace weight=. if qw1006>1 
tab qw1009 qw1006 if qw1006>1, miss 
desc weight 
summ weight

*Height (Cm)
tab qw1007, miss
codebook qw1007, tab (9999)
gen height = qw1007 if qw1007<900
tab qw1007 if qw1007>9990, miss nol    
replace height=. if qw1006>1 
replace height = . if qw1007>=9990
tab qw1007 qw1006 if qw1006>1, miss
desc height 
summ height

*Type of measure: Standung vs Lying
codebook qw1008
gen measure = "l" if qw1008==1 
replace measure = "h" if qw1008==2 
replace measure = " " if qw1008==0 | qw1008==9 | qw1008==.
desc measure
tab measure

*OEDEMA
gen str1 oedema = "n"  
desc oedema
tab oedema

*Individual child sampling weight
gen sw = pesonino
desc sw
summ sw

**-----------------1.4: Estimating z-scores
igrowup_restricted reflib datalib datalab gender age ageunit weight height ///
    measure oedema sw

**-----------------1.5: Using the .dta file with the z-scores
use "$path_ado\Children under 5\children_nutri_nic_z_rc.dta", clear 

**-----------------1.6: Identifying children undernourished
gen	underweight = (_zwei < -2.0) 
replace underweight = . if _zwei == . | _fwei==1
lab var underweight  "Child is undernourished (weight-for-age) 2sd - WHO"
tab underweight, miss

gen stunting = (_zlen < -2.0)
replace stunting = . if _zlen == . | _flen==1
lab var stunting "Child is stunted (length/height-for-age) 2sd - WHO"
tab stunting, miss

gen wasting = (_zwfl < - 2.0)
replace wasting = . if _zwfl == . | _fwfl == 1
lab var wasting  "Child is wasted (weight-for-length/height) 2sd - WHO"
tab wasting, miss
 
count if _fwei==1 | _flen==1

*Keeping variables
keep ind_id child_KR hhclust hhnumbv qw221 underweight* stunting* wasting* 
order ind_id child_KR hhclust hhnumbv qw221 underweight* stunting* wasting* 
sort ind_id
save "$path_out/NIC11-12_KR.dta", replace

/*====================================================================
                        2: Child mortality
====================================================================*/
***---------------------2.1: Child mortality
use "$path_in/ENDESA2011_Historia de nacimientos.dta", clear
rename _all, lower	

gen double ind_id = hhclust*10000000 + hhnumbv*1000 + hvnumint*100 + cp
format ind_id %20.0g
label var ind_id "Individual ID"

desc qw224d qw224m qw224a
gen dnac = qw224d 
gen mnac = qw224m
gen anac = qw224a
replace anac=. if anac>9000
replace mnac=. if mnac>90
replace dnac=. if dnac>90
count if anac!=. & mnac==. 
gen b3 = ym( anac , mnac ) 
format b3 % tm

gen mfall = qw228m 
gen afall = qw228a
replace mfall=. if mfall>=98
replace afall=. if afall>=9998
gen date_death=ym(afall, mfall)
format date_death % tm

gen v008 = ym(qinty, qintm)
format v008 %tm
gen mdead_survey=v008-date_death
gen ydead_survey = mdead_survey/12

gen age_death = date_death - b3
label var age_death "Age at death in months"
tab age_death, miss

codebook qw225, tab (10)
gen b5=0 if qw225==2
replace b5=1 if qw225==1
gen child_died = 1 if b5==0
replace child_died = 0 if b5==1
replace child_died = . if b5==.
label define lab_died 1 "child has died" 0 "child is alive"
label values child_died lab_died
tab b5 child_died, miss

bysort ind_id: egen tot_child_died = sum(child_died)

***---------------------2.2: Identifying children mortality
gen child18_died = child_died 
replace child18_died=0 if age_death>=216 & age_death<.
label values child18_died lab_died
tab child18_died, miss	

bysort ind_id: egen tot_child18_died_5y=sum(child18_died) if ydead_survey<=5
replace tot_child18_died_5y=0 if tot_child18_died_5y==. & tot_child_died>=0 ///
    & tot_child_died<.
replace tot_child18_died_5y=. if child18_died==1 & ydead_survey==.

tab tot_child_died tot_child18_died_5y, miss

bysort ind_id: egen childu18_died_per_wom_5y = max(tot_child18_died_5y)
lab var childu18_died_per_wom_5y ///
"Total child under 18 death for each women in the last 5 years (birth recode)"

bysort ind_id: gen id=1 if _n==1
keep if id==1
drop id
duplicates report ind_id 

gen women_BR = 1 

keep ind_id women_BR childu18_died_per_wom_5y cp qw1006 tot_child_died
order ind_id women_BR childu18_died_per_wom_5y cp qw1006 tot_child_died
sort ind_id
save "$path_out/NIC11-12_BR.dta", replace

*------------------2.3: Identifying more child mortality
use "$path_in/ENDESA2011_Cuestionario de la mujer.dta", clear
rename _all, lower

gen double ind_id = hhclust*10000000 + hhnumbv*1000 + hvnumint*100 + cp
format ind_id %20.0g
label var ind_id "Individual ID"
codebook ind_id
duplicates report ind_id

gen women_IR=1 

tab qw209v, miss
tab qw209m, miss
tab qw209v qw209m, miss

egen tot_child_died_2 = rsum(qw209v qw209m)

keep ind_id women_IR cp imc estacony pesomef qw1011 qw1013 qw102 qw217d qw700 ///
qw208 qw209v qw209m tot_child_died_2 
order ind_id women_IR cp imc estacony pesomef qw1011 qw1013 qw102 qw217d qw700 ///
qw208 qw209v qw209m tot_child_died_2 
sort ind_id
save "$path_out/NIC11-12_IR.dta", replace

/*====================================================================
                        3: Girls 15-19 malnourished
====================================================================*/
*-----------------3.1: Creating ID
use "$path_in/ENDESA2011_Cuestionario de la mujer.dta", clear
rename _all, lower

gen double ind_id = hhclust*10000000 + hhnumbv*1000 + hvnumint*100 + cp
format ind_id %20.0g
label var ind_id "Individual ID"
codebook ind_id
duplicates report ind_id

*-----------------3.2: Checking variables to calculate z-scores
*Sex
gen gender=2 

*Age
codebook qintm, tab (10)
codebook qinty, tab (10)
codebook qw103m, tab (100)
codebook qw103a, tab (100)

gen age_years=qw102
gen age_month=age_years*12
lab var age_month "Age in months, individuals 15-19 years"

gen str6 ageunit = "months" 
lab var ageunit "Months"

*Body weight (Kg)
codebook qw1013, tab (1000)
gen weight = qw1013
summ weight

*Height (Cm)
codebook qw1012, tab (1000)
gen	height = qw1012 
summ height

*OEDEMA
gen oedema = "n"  
tab oedema	

*Sampling weight
gen sw = pesomef 
summ sw	

count if qw102>=15 & qw102<=19
keep if qw102>=15 & qw102<=19

****-----------------3.3: Setting directories
adopath + "$path_ado/Young 5-19"

gen str100 reflib = "$path_ado/Young 5-19"
lab var reflib "Directory of reference tables"

gen str100 datalib = "$path_ado/Young 5-19" 
lab var datalib "Directory for datafiles"

gen str30 datalab = "girl_nutri_nic" 
lab var datalab "Working file"

****-----------------3.4: Estimating z-scores
who2007 reflib datalib datalab gender age_month ageunit weight height oedema sw

****-----------------3.5: Using the z-scores
use "$path_ado/Young 5-19/girl_nutri_nic_z.dta", clear

gen	z_bmi = _zbfa
replace z_bmi = . if _fbfa==1 
lab var z_bmi "z-score bmi-for-age WHO"

****-----------------3.6:Identifying malnourished for MPI
gen	low_bmiage = (z_bmi < -2.0) 
replace low_bmiage = . if z_bmi==.
lab var low_bmiage "Teenage low bmi 2sd - WHO"

gen teen_IR=1 

keep ind_id teen_IR age_month low_bmiage* imc
order ind_id teen_IR age_month low_bmiage* imc
sort ind_id
save "$path_out/NIC11-12_IR_girls.dta", replace

/*====================================================================
                 4: Children mortality in men questionnary
====================================================================*/
use "$path_in/ENDESA2011_Cuestionario del hombre.dta", clear
rename _all, lower

gen double ind_id = hhclust*10000000 + hhnumbv*1000 + hvnumint*100 + cp	
format ind_id %20.0g
label var ind_id "Individual ID"
codebook ind_id

duplicates report ind_id

gen men_MR=1 

keep ind_id men_MR cp pesohef m102 m203t m205t m206 m207t m207m m207v
order ind_id men_MR cp pesohef m102 m203t m205t m206 m207t m207m m207v
sort ind_id
save "$path_out/NIC11-12_MR.dta", replace

/*====================================================================
              5: Identification of households and hh members
====================================================================*/
*----------------------5.1: Identifying households
use "$path_in/ENDESA2011_Vivienda y hogar", clear
rename _all, lower

gen double hh_id = hhclust*10000000 + hhnumbv*1000 + hvnumint*100
format hh_id %20.0g
label var hh_id "Household ID"
codebook hh_id 

duplicates report hh_id
sort hh_id

save "$path_out/NIC11-12_HH.dta", replace

*----------------------5.2: Identifying household members
use "$path_in/ENDESA2011_Miembros del hogar.dta", clear
rename _all, lower

gen double hh_id = hhclust*10000000 + hhnumbv*1000 + hvnumint*100
format hh_id %20.0g
label var hh_id "Household ID"
codebook hh_id 

gen double ind_id = hhclust*10000000 + hhnumbv*1000 + hvnumint*100 + cp
format ind_id %20.0g
label var ind_id "Individual ID"
codebook ind_id
duplicates report ind_id

sort hh_id ind_id

/*====================================================================
                        6: Merging databases
====================================================================*/
merge m:1 hh_id using "$path_out/NIC11-12_HH.dta"
drop _merge
merge 1:1 ind_id using "$path_out/NIC11-12_BR.dta"
drop _merge
merge 1:1 ind_id using "$path_out/NIC11-12_IR.dta"

tab qw1011 women_IR , miss col
count if imc!=. & women_IR==1 
drop _merge

merge 1:1 ind_id using "$path_out/NIC11-12_IR_girls.dta"

tab teen_IR qw1011 if qw102>=15 & qw102<=19, miss col
tab qw1011 if teen_IR==. & (qw102>=15 & qw102<=19), miss 
tab imc if qw1011==1 & teen_IR==. & (qw102>=15 & qw102<=19), miss
drop _merge

merge 1:1 ind_id using "$path_out/NIC11-12_MR.dta"
drop _merge
merge 1:1 ind_id using "$path_out/NIC11-12_KR.dta"
drop _merge

sort ind_id

/*====================================================================
                        7: Specifying control variables
====================================================================*/
*----------------------7.1: No elegible women
gen fem_eligible = (qhs3p05==2 & qhs3p03>=15 & qhs3p03<=49)
bysort hh_id: egen hh_n_fem_eligible = sum(fem_eligible) 	
gen no_fem_eligible = (hh_n_fem_eligible==0) 									
lab var no_fem_eligible "Household has no eligible women"
tab no_fem_eligible, miss

*----------------------7.2: No elegible men 
gen male_eligible = men_MR
bysort hh_id: egen hh_n_male_eligible = sum(male_eligible)  
gen no_male_eligible =  (hh_n_male_eligible==0)
lab var no_male_eligible "Household has no eligible man"
tab no_male_eligible, miss

*----------------------7.3: No elegible children under 5
gen	child_eligible = (child_KR==1) 
bysort	hh_id: egen hh_n_children_eligible = sum(child_eligible)  
gen	no_child_eligible = (hh_n_children_eligible==0) 
lab var no_child_eligible "Household has no children eligible"
tab no_child_eligible, miss

*----------------------7.4: No elegible men and women - Child mortality
gen	no_adults_eligible = (no_fem_eligible==1 & no_male_eligible==1) 
lab var no_adults_eligible "Household has no eligible women or men"
tab no_adults_eligible, miss 

*----------------------7.5: No elegible children and women - Nutrition
gen	no_child_fem_eligible = (no_child_eligible==1 & no_fem_eligible==1)
lab var no_child_fem_eligible "Household has no children or women eligible"
tab no_child_fem_eligible, miss 

sort hh_id ind_id

/*====================================================================
                    8: Renaming demographic variables
====================================================================*/
*Sample weight
desc pesohogar
clonevar weight = pesohogar 
label var weight "Sample weight"

*Area
desc area
codebook area, tab(5)
rename area area_ori
clonevar area = area_ori			
replace area=0 if area_ori==2  
label define lab_area 1 "urban" 0 "rural"
label values area lab_area
label var area "Area: urban-rural"
tab area area_ori, miss

*Sex
codebook qhs3p05
clonevar sex = qhs3p05 
label var sex "Sex of household member"

*Age
codebook qhs3p03, tab (9999)
clonevar age = qhs3p03  
replace age = . if age>=98
label var age "Age of household member"

*Age group
recode age (0/4 = 1 "0-4")(5/9 = 2 "5-9")(10/14 = 3 "10-14") ///
		   (15/17 = 4 "15-17")(18/59 = 5 "18-59")(60/max=6 "60+"), gen(agec7)
lab var agec7 "age groups (7 groups)"	
	   
recode age (0/9 = 1 "0-9") (10/17 = 2 "10-17")(18/59 = 3 "18-59") ///
		   (60/max=4 "60+"), gen(agec4)
lab var agec4 "age groups (4 groups)"

*Marital status
tab qw700 estacony, miss
clonevar marital = estacony 
codebook marital, tab (10)
recode marital (6=1)(1=2)(3=4)(5=3)
label define lab_mar 1"never married" 2"currently married" ///
					 3"widowed" 4"divorced" 5"not living together"
label values marital lab_mar	
label var marital "Marital status of household member"
tab estacony marital, miss

*HH mmebers
gen member = 1
bysort hh_id: egen hhsize = sum(member)
label var hhsize "Household size"
tab hhsize, miss
drop member

*Subnational region
codebook hhdepar, tab (99)
rename region region_ori
decode hhdepar, gen(temp)
replace temp =  proper(temp)
encode temp, gen(region)
lab var region "Region for subnational decomposition"
tab hhdepar region, miss 
codebook region, tab (99)
drop temp

/*====================================================================
                    9: Standardized variables
====================================================================*/
*---------------------9.1: Years of schooling
codebook qhs3p16n, tab(30)
codebook qhs3p16g, tab(30)
codebook totgrado, tab(30)

gen eduyears=totgrado if totgrado>=0
replace eduyears = 0 if qhs3p16n==3
replace eduyears = . if eduyears>30
replace eduyears = . if eduyears>=age & age>0
replace eduyears = 0 if age < 10 

*---------------------9.2:Control variables for information of 2/3 of hh members
gen temp = 1 if eduyears!=. & age>=10 & age!=.
bysort	hh_id: egen no_missing_edu = sum(temp)

gen temp2 = 1 if age>=10 & age!=.
bysort hh_id: egen hhs = sum(temp2)

replace no_missing_edu = no_missing_edu/hhs
replace no_missing_edu = (no_missing_edu>=2/3)

tab no_missing_edu, miss
label var no_missing_edu ///
"No missing edu for at least 2/3 of the HH members aged 10 years & older"

drop temp temp2 hhs

*---------------------9.3: Identifying deprived households
gen	 years_edu6 = (eduyears>=6)
replace years_edu6 = . if eduyears==.
bysort hh_id: egen hh_years_edu6_1 = max(years_edu6)
gen	hh_years_edu6 = (hh_years_edu6_1==1)
replace hh_years_edu6 = . if hh_years_edu6_1==.
replace hh_years_edu6 = . if hh_years_edu6==0 & no_missing_edu==0 
lab var hh_years_edu6 "Household has at least one member with 6 years of edu"

*---------------------9.4: Child school attendance
codebook qhs3p15, tab (10)
clonevar attendance = qhs3p15 
recode attendance (2=0) (9=.)
label define lab_att 0"not attending" 1"attending" 
label values attendance lab_att	
codebook attendance, tab (10)

replace attendance = 0 if (attendance==9 | attendance==.) & qhs3p16n==0 
replace attendance = . if  attendance==9 & qhs3p16n!=0

*---------------------9.5: Control variable for no information 2/3
gen	child_schoolage = (age>=6 & age<=14)
count if child_schoolage==1 & attendance==.
gen temp = 1 if child_schoolage==1 & attendance!=.
bysort hh_id: egen no_missing_atten = sum(temp)	
gen temp2 = 1 if child_schoolage==1	
bysort hh_id: egen hhs = sum(temp2)
replace no_missing_atten = no_missing_atten/hhs 
replace no_missing_atten = (no_missing_atten>=2/3)
tab no_missing_atten, miss
label var no_missing_atten ///
"No missing school attendance for at least 2/3 of the school aged children"		
drop temp temp2 hhs

*---------------------9.6: Identifying deprived households
bysort hh_id: egen hh_children_schoolage = sum(child_schoolage)
replace hh_children_schoolage = (hh_children_schoolage>0) 
lab var hh_children_schoolage "Household has children in school age"

gen	child_not_atten = (attendance==0) if child_schoolage==1
replace child_not_atten = . if attendance==. & child_schoolage==1
bysort	hh_id: egen any_child_not_atten = max(child_not_atten)
gen	hh_child_atten = (any_child_not_atten==0) 
replace hh_child_atten = . if any_child_not_atten==.
replace hh_child_atten = 1 if hh_children_schoolage==0
replace hh_child_atten = . if hh_child_atten==1 & no_missing_atten==0 
lab var hh_child_atten ///
"Household has all school age children up to class 8 in school"
tab hh_child_atten, miss

*----------------------------------9.7: Adult Nutrition
codebook imc
gen ha40 = imc
gen hb40 = .

foreach var in ha40 hb40 {
gen inf_`var' = 1 if `var'!=.
bysort sex: tab age inf_`var' 
drop inf_`var'
}

*---------------------9.7.2: General BMI indicator: Women 15-49
gen	f_bmi = ha40	
lab var f_bmi "Women's BMI"

gen	f_low_bmi = (f_bmi<18.5)
replace f_low_bmi = . if f_bmi==. 
lab var f_low_bmi "BMI of women < 18.5"

bysort hh_id: egen low_bmi = max(f_low_bmi)

gen	hh_no_low_bmi = (low_bmi==0)
replace hh_no_low_bmi = . if low_bmi==.
replace hh_no_low_bmi = 1 if no_fem_eligible==1
	
drop low_bmi
lab var hh_no_low_bmi "Household has no adult with low BMI"

tab hh_no_low_bmi, miss

*---------------------9.7.3: BMI-for-age 15-19 and BMI 20-49
gen low_bmi_byage = 0
replace low_bmi_byage = 1 if f_low_bmi==1
replace low_bmi_byage = 1 if low_bmiage==1 & age_month!=.
replace low_bmi_byage = 0 if low_bmiage==0 & age_month!=.
replace low_bmi_byage = . if f_low_bmi==. & low_bmiage==.
	
bysort	hh_id: egen low_bmi = max(low_bmi_byage)

gen	hh_no_low_bmiage = (low_bmi==0)
replace hh_no_low_bmiage = . if low_bmi==.
replace hh_no_low_bmiage = 1 if no_fem_eligible==1
drop low_bmi
lab var hh_no_low_bmiage "Household has no adult with low BMI or BMI-for-age"

tab hh_no_low_bmi, miss	
tab hh_no_low_bmiage, miss

**--------------------------------------9.8: Child nutrition
*---------------------9.8.1: Child underweight
bysort hh_id: egen temp = max(underweight)
gen	hh_no_underweight = (temp==0) 
replace hh_no_underweight = . if temp==.
replace hh_no_underweight = 1 if no_child_eligible==1 
lab var hh_no_underweight "Household has no child underweight - 2 stdev"
drop temp

*---------------------9.8.2: Child stunting
bysort hh_id: egen temp = max(stunting)
gen	hh_no_stunting = (temp==0) 
replace hh_no_stunting = . if temp==.
replace hh_no_stunting = 1 if no_child_eligible==1 
lab var hh_no_stunting "Household has no child stunted - 2 stdev"
drop temp

*---------------------9.8.3: Child underweight or stunting
gen uw_st = 1 if stunting==1 | underweight==1
replace uw_st = 0 if stunting==0 & underweight==0
replace uw_st = . if stunting==. & underweight==.

bysort hh_id: egen temp = max(uw_st)
gen	hh_no_uw_st = (temp==0) 
replace hh_no_uw_st = . if temp==.
replace hh_no_uw_st = 1 if no_child_eligible==1
lab var hh_no_uw_st "Household has no child underweight or stunted"
drop temp

**----------------------------------9.9: Household nutrition
gen	hh_nutrition_uw_st = 1
replace hh_nutrition_uw_st = 0 if hh_no_low_bmiage==0 | hh_no_uw_st==0
replace hh_nutrition_uw_st = . if hh_no_low_bmiage==. & hh_no_uw_st==.
replace hh_nutrition_uw_st = 1 if no_child_fem_eligible==1   
lab var hh_nutrition_uw_st ///
"Household has no child underweight/stunted or adult deprived by BMI/BMI-for-age"

*-------------------------------------9.10: Child mortality
codebook qw208 qw209v qw209m m207t m207m m207v m206

**--------------------------9.10.1: Children reported by women
egen temp_f = rowtotal(qw209m qw209v), missing
replace temp_f = 0 if qw208==2
replace temp_f = 0 if qw208==. & tot_child_died_2<.
bysort	hh_id: egen child_mortality_f = sum(temp_f), missing
lab var child_mortality_f "Occurrence of child mortality reported by women"
tab child_mortality_f, miss
drop temp_f

**--------------------------9.10.2: Children reported by men
egen temp_m = rowtotal(m207m m207v), missing
replace temp_m = 0 if m206==2
bysort	hh_id: egen child_mortality_m = sum(temp_m), missing
lab var child_mortality_m "Occurrence of child mortality reported by men"
tab child_mortality_m, miss
drop temp_m

**--------------------------9.10.3: Total children reported
egen child_mortality = rowmax(child_mortality_f child_mortality_m)
lab var child_mortality ///
"Total child mortality within household reported by women & men"
tab child_mortality, miss

replace childu18_died_per_wom_5y = 0 if qw208==2
replace childu18_died_per_wom_5y = 0 if no_fem_eligible==1

bysort hh_id: egen childu18_mortality_5y = sum(childu18_died_per_wom_5y), missing
replace childu18_mortality_5y = 0 if childu18_mortality_5y==. & child_mortality==0
label var childu18_mortality_5y ///
"Under 18 child mortality within household past 5 years reported by women"
tab childu18_mortality_5y, miss		
	
gen hh_mortality_u18_5y = (childu18_mortality_5y==0)
replace hh_mortality_u18_5y = . if childu18_mortality_5y==.
lab var hh_mortality_u18_5y ///
"Household had no under 18 child mortality in the last 5 years"
tab hh_mortality_u18_5y, miss 

*----------------------------9.11: Electricity
codebook qhs1p06, tab (10)
gen electricity = 1 if qhs1p06==1 | qhs1p06==2 | qhs1p06==3
replace electricity = 0 if  qhs1p06==4 | qhs1p06==5 | qhs1p06==6 | qhs1p06==7 ///
    | qhs1p06==8 | qhs1p06==96							
replace electricity = . if electricity==99 
label var electricity "Household has electricity"

*----------------------------9.12: Sanitation
clonevar toilet = qhs1p09
codebook toilet, tab(30) 
replace toilet = . if qhs1p09==99
gen shared_toilet = .

gen	toilet_mdg = toilet==1 | toilet==2 | toilet == 3 	
replace toilet_mdg = 0 if toilet == 4 | toilet == 5 
replace toilet_mdg = . if toilet==.  | toilet==99
lab var toilet_mdg "Household has improved sanitation with MDG Standards"
tab toilet toilet_mdg, miss

*----------------------------9.13: Drinking water
clonevar water = qhs1p07  
clonevar timetowater = qhs1p08mn  
codebook water, tab(100)
	
gen	water_mdg = 1 if water==11 | water==12 | water==13 | water==14 | water==51	
replace water_mdg = 0 if water==21 | water==22 | water==31 | water==32 | ///
						 water==33 | water==41 | water==61 | water==96 
replace water_mdg = 0 if water_mdg==1 & timetowater >= 30 & timetowater!=. & ///
						 timetowater!=996 & timetowater!=998 & timetowater!=999 
replace water_mdg = . if water==. | water==99
lab var water_mdg ///
"Household has drinking water with MDG standards (considering distance)"
tab water water_mdg, miss

*--------------------------------9.14: Housing
*--------------------9.14.1: Floor
clonevar floor =qhs1p04 
codebook floor, tab(99)
gen	floor_imp = 1
replace floor_imp = 0 if floor==5 | floor==96  
replace floor_imp = . if floor==. | floor==99 
lab var floor_imp "Household has floor that it is not earth/sand/dung"
tab floor floor_imp, miss	

*--------------------9.14.2: Walls
clonevar wall = qhs1p02
codebook wall, tab(99)	
gen	wall_imp = 1 
replace wall_imp = 0 if wall==13 | wall==14 | wall==15 | wall==96  
replace wall_imp = . if wall== . | wall==99 
lab var wall_imp "Household has wall that it is not of low quality materials"
tab wall wall_imp, miss

*--------------------9.14.3: Roof
clonevar roof = qhs1p03
codebook roof, tab(99)		
gen	roof_imp = 1 
replace roof_imp = 0 if roof==5 | roof==6 | roof==96  
replace roof_imp = . if roof==. | roof==99 
lab var roof_imp "Household has roof that it is not of low quality materials"
tab roof roof_imp, miss

*--------------------9.14.4: Overall indicator
gen housing_1 = 1
replace housing_1 = 0 if floor_imp==0 | wall_imp==0 | roof_imp==0
replace housing_1 = . if floor_imp==. & wall_imp==. & roof_imp==.
lab var housing_1 ///
"Household has roof, floor & walls that it is not low quality material"
tab housing_1, miss

gen housing_2 = 1
replace housing_2 = 0 if (floor_imp==0 & wall_imp==0 & roof_imp==1) ///
    | (floor_imp==0 & wall_imp==1 & roof_imp==0) ///
	| (floor_imp==1 & wall_imp==0 & roof_imp==0) ///
	| (floor_imp==0 & wall_imp==0 & roof_imp==0)
replace housing_2 = . if floor_imp==. & wall_imp==. & roof_imp==.
lab var housing_2 ///
"Household has one of three aspects(either roof,floor/walls) that it is not low quality material"
tab housing_2, miss

*-------------------------------9.15: Cooking fuel
clonevar cookingfuel = qhs1p13 
codebook cookingfuel, tab(99)

gen	cooking_mdg = 1
replace cooking_mdg = 0 if cookingfuel==2 | cookingfuel==3 						    
replace cooking_mdg = . if cookingfuel==. | cookingfuel==99
lab var cooking_mdg "Household has cooking fuel according to MDG standards"			 
tab cookingfuel cooking_mdg, miss

*----------------------------9.16: Asset ownership
codebook qhs2p01d qhs2p01a qhs2p01p qhs2p01q qhs2p01f qhs2p02a qhs2p02c qhs2p02b

clonevar television = qhs2p01d  
replace television = 0 if television == 2
gen bw_television = .

gen	radio=.
replace radio = 1 if qhs2p01a==1 | qhs2p01b==1 | qhs2p01c==1
replace radio = 0 if qhs2p01a==2 & qhs2p01b==2 & qhs2p01c==2

clonevar telephone =  qhs2p01p 
replace telephone = 0 if telephone == 2

clonevar mobiletelephone = qhs2p01q  
replace mobiletelephone = 0 if mobiletelephone == 2

clonevar refrigerator = qhs2p01f 
replace refrigerator = 0 if refrigerator == 2

clonevar car = qhs2p02a  
replace car = 0 if car == 2
	
clonevar bicycle = qhs2p02c 
replace bicycle = 0 if bicycle == 2

clonevar motorbike = qhs2p02b 
replace motorbike = 0 if motorbike == 2

clonevar computer = qhs2p01m
replace computer = 0 if computer == 2

foreach var in television radio telephone mobiletelephone refrigerator car ///
    bicycle motorbike computer{
    replace `var' = . if `var'==9 | `var'==99 | `var'==8 | `var'==98 
}

replace telephone=1 if telephone==0 & mobiletelephone==1
replace telephone=1 if telephone==. & mobiletelephone==1

*--------------9.16.1: Overall asset indicator
egen n_small_assets2 = rowtotal(television radio telephone refrigerator bicycle ///
motorbike computer), missing
lab var n_small_assets2 "Household Number of Small Assets Owned" 
    
gen hh_assets2 = (car==1 | n_small_assets2 > 1) 
replace hh_assets2 = . if car==. & n_small_assets2==.
lab var hh_assets2 ///
"Household Asset Ownership: HH has car or more than 1 small assets"

/*====================================================================
                    20: Rename, keep, saving
====================================================================*/
*-----------------20.1: Data on sampling design
gen psu = hhclust
egen strata = group(hhdepar area)

desc hhinty hhintm hhintd
clonevar year_interview = hhinty	
clonevar month_interview = hhintm 
clonevar date_interview = hhintd

recode hh_mortality_u18_5y  (0=1)(1=0), gen(d_cm)
recode hh_nutrition_uw_st 	(0=1)(1=0), gen(d_nutr)
recode hh_child_atten 		(0=1)(1=0), gen(d_satt)
recode hh_years_edu6 		(0=1)(1=0), gen(d_educ)
recode electricity 			(0=1)(1=0), gen(d_elct)
recode water_mdg 			(0=1)(1=0), gen(d_wtr)
recode toilet_mdg 			(0=1)(1=0), gen(d_sani)
recode housing_1 			(0=1)(1=0), gen(d_hsg)
recode cooking_mdg 			(0=1)(1=0), gen(d_ckfl)
recode hh_assets2 			(0=1)(1=0), gen(d_asst)

char _dta[cty] "Nicaragua"
char _dta[ccty] "NIC"
char _dta[year] "2011-2012" 	
char _dta[survey] "DHS"
char _dta[ccnum] "558"
char _dta[type] "micro"

sort ind_id
compress
la da "Micro data for `_dta[ccty]' (`_dta[ccnum]'). Last save: `c(filedate)'."	
save "$path_out/nic_dhs11-12.dta", replace 

exit
* End of do-file











