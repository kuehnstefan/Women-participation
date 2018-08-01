*===================================================================
* Date: MARCH 2017 
* Purpose: Gallup Analysis: Model refinement by interaction gap groups
*
* Database: Gallup, reduced for 80% of responses for 5Q on Gender
* Output: 
*===================================================================

clear 
clear matrix
set more off

*************************************************
* Administrative Commands
*************************************************
*Define Directory
global PATH "I:\COMMON\Stefan\Papers\Womans participation\Econometric Analysis"

cd "$PATH"
capture log close
log using "$PATH\Gallup_analysis.log", replace 

	

*****************************************************
* Read in the Dataset & Define Variables
*****************************************************
use "$PATH\Input data\GALLUP_clean.dta", clear

svyset WPID_RANDOM [pweight=wgt], strata(WP5) 
	//stratified sampling based on country, TO CLEAR: svyset, clear 

** list of variables to be used for estimation by age_cat in interaction (list_int) and without interaction (list_base)
global list_int i.educ#i.lowincome i.pref_work i.kids1 i.married ib2.pref_opport c.optimism i.respect i.internet i.phone ib1.poor i.urban i.pref_accept ib1.challenge 
global list_base c.housenum##c.housenum
global socio_challenges 2.challenge 3.challenge 5.challenge 6.challenge 7.challenge 8.challenge 9.challenge 10.challenge
global marginvars educ pref_work poor married kids1 1.pref_opport 3.pref_opport optimism respect $socio_challenges internet phone pref_accept 4.challenge urban

***********************
*** By age category ***
***********************

*** setting the output file
global COEFF_AGE="$PATH\Output data\coeff_age.xls"
global MARGIN_AGE="$PATH\Output data\margins_age.xls"

*** running regression
svy: probit lfpr i.agecat $list_base i.agecat#($list_int ib2.religion) i.WP5
estimates store agecat
outreg2 using "$COEFF_AGE", adds(Countries,e(N_strata))  bdec(2) sdec(2) replace


*** margins for all age groups
margins, vce(unconditional) dydx(agecat $marginvars religion) post
outreg2 using "$MARGIN_AGE", ctitle(Total) dec(2) label replace
estimates restore agecat

*** for sub age groups
margins if agecat==0,  dydx($marginvars religion) post
outreg2 using "$MARGIN_AGE", ctitle(Age 15-24) dec(2) label
estimates restore agecat
margins if agecat==1, dydx($marginvars religion) post
outreg2 using "$MARGIN_AGE", ctitle(Age 25-54) dec(2) label
estimates restore agecat
margins if agecat==2,  dydx($marginvars religion) post
outreg2 using "$MARGIN_AGE", ctitle(Age 55+) dec(2) label
estimates restore agecat

***********************
*** By mix category ***
***********************

*** setting the output file
global COEFF="$PATH\Output data\coeff_mix2.xls"
global MARGIN="$PATH\Output data\margins_mix2.xls"

*** running regression
svy: probit lfpr $list_base i.smartcat#(i.agecat $list_int ib5.religion) i.WP5
estimates store smartcat
outreg2 using "$COEFF", adds(Countries,e(N_strata))  bdec(2) sdec(2) replace

*** margins for all groups
margins, vce(unconditional) dydx(agecat $marginvars religion) post
outreg2 using "$MARGIN", ctitle(Total) dec(2) label replace
estimates restore smartcat

*** for sub groups
margins if smartcat==1,  dydx(agecat $marginvars religion) post
outreg2 using "$MARGIN", ctitle(Developing) dec(2) label
estimates restore smartcat
margins if smartcat==2, dydx(agecat $marginvars religion) post
outreg2 using "$MARGIN", ctitle(Low gap) dec(2) label
estimates restore smartcat
margins if smartcat==3,  dydx(agecat $marginvars religion) post
outreg2 using "$MARGIN", ctitle(High gap) dec(2) label
estimates restore smartcat

***********************
*** By age_cat and gap ***
***********************

*** setting the output file
global COEFF_COMB="$PATH\Output data\coeff_comb4.xls"
global MARGIN_COMB="$PATH\Output data\margins_comb4.xls"

*** running regression
set more off
svy: probit lfpr i.agecat $list_base i.smartcat#i.agecat#($list_int ib5.religion) i.WP5
estimates store combcat
outreg2 using "$COEFF_COMB", adds(Countries,e(N_strata))  bdec(2) sdec(2) replace

*** margins for all groups
margins, vce(unconditional) dydx($marginvars religion) post
outreg2 using "$MARGIN_COMB", ctitle(Total) dec(2) label replace
estimates restore combcat

*** 
forvalues age=0/2{
local name1 : label agecat `age'  
forvalues gap=1/3{
local name2 : label smartcat2 `gap'
margins if smartcat==`gap' & agecat==`age', dydx($marginvars religion) post
outreg2 using "$MARGIN_COMB", ctitle(`name1' `name2') dec(2) label
estimates restore combcat
}
}


***********************
*** By doing conditional effects ***
***********************
set matsize 1000
set more off
svy: probit lfpr i.agecat $list_base i.smartcat#i.agecat#(i.educ i.kids1 ib2.pref_opport c.optimism i.pref_work#(i.married i.pref_accept i.urban i.islam) ib1.challenge i.respect  i.internet i.phone ib1.poor ) i.WP5
estimates store cascade1
estimates save "$PATH\Output data\cascade1", replace
save "$PATH\Output data\dataset_esample.dta", replace all

*estimates use "$PATH\Output data\cascade1"

global genderrole0 = "urban=0 pref_accept=0 respect=0"
global genderrole1 = "urban=1 pref_accept=1 respect=1"
global socio0 = "phone=0 internet=0 optimism=0 pref_opport=3"
global socio1 = "phone=1 internet=1 optimism=1 pref_opport=1"
global family0 =" kids1=1 married=1"
global family1 = "kids1=0 married=0"

*cascading
putexcel set "$PATH\Output data\Cascade LFPR.xlsx", modify sheet("test2")
putexcel A1="Characteristic" A2="Base" A3="Preference" A4="Family" A5="Socio-economic" A6="Gender role" A7="Challenge" A8="Muslim" A9="Education"


local mainchallenge 8 8 8 8 4 3 8 4 2
local leastchallenge 1 1 1 1 1 1 1 10 10
*** 
local loop=1
forvalues age=0/2{
local name1 : label agecat `age'  
forvalues gap=1/3{
local name2 : label smartcat `gap'
*cascading
local ch: word  `loop' of `mainchallenge'
local chr: word  `loop' of `leastchallenge'
local ++loop
quietly excelcol `loop'
local col=r(column)
putexcel `r(column)'1="`name1' `name2'"
local line=2
margins if agecat==`age' & smartcat==`gap', at(pref_work=0 $genderrole0 islam=1 $socio0 $family0 poor=1 challenge=`ch' educ=1)
matrix c=r(b)
putexcel `col'`line'=c[1,1]
local ++line
margins if agecat==`age' & smartcat==`gap', at(pref_work=1 $genderrole0 islam=1 $socio0 $family0 poor=1 challenge=`ch' educ=1)
matrix c=r(b)
putexcel `col'`line'=c[1,1]
local ++line
margins if agecat==`age' & smartcat==`gap', at(pref_work=1 $genderrole0 islam=1 $socio0 $family1 poor=1 challenge=`ch' educ=1)
matrix c=r(b)
putexcel `col'`line'=c[1,1]
local ++line
margins if agecat==`age' & smartcat==`gap', at(pref_work=1 $genderrole0 islam=1 $socio1 $family1 poor=1 challenge=`ch' educ=1)
matrix c=r(b)
putexcel `col'`line'=c[1,1]
local ++line
margins  if agecat==`age' & smartcat==`gap', at(pref_work=1 $genderrole1 islam=1 $socio1 $family1 poor=1 challenge=`ch' educ=1)
matrix c=r(b)
putexcel `col'`line'=c[1,1]
local ++line
margins  if agecat==`age' & smartcat==`gap', at(pref_work=1 $genderrole1 islam=1 $socio1 $family1 poor=1 challenge=`chr' educ=1)
matrix c=r(b)
putexcel `col'`line'=c[1,1]
local ++line
margins  if agecat==`age' & smartcat==`gap', at(pref_work=1 $genderrole1 islam=0 $socio1 $family1 poor=1 challenge=`chr' educ=1)
matrix c=r(b)
putexcel `col'`line'=c[1,1]
local ++line
margins  if agecat==`age' & smartcat==`gap', at(pref_work=1 $genderrole1 islam=0 $socio1 $family1 poor=1 challenge=`chr' educ=3)
matrix c=r(b)
putexcel `col'`line'=c[1,1]
local ++line
}
}



***********************
*** By development ***
***********************
/*
*** setting the output file
global COEFF_DEV="$PATH\Output data\coeff_dev.xls"
global MARGIN_DEV="$PATH\Output data\margins_dev.xls"

*** running regression
svy: probit lfpr i.devcat $list_base i.devcat#(i.agecat $list_int ib2.religion) i.WP5
estimates store devcat
outreg2 using "$COEFF_DEV", adds(Countries,e(N_strata))  bdec(2) sdec(2) replace

*** margins for all age groups
margins, vce(unconditional) dydx(agecat $marginvars religion) post
outreg2 using "$MARGIN_DEV", ctitle(Total) dec(2) label replace
estimates restore devcat

*** for sub age groups
margins if devcat==1,  dydx(agecat $marginvars religion) post
outreg2 using "$MARGIN_DEV", ctitle(Developing countries) dec(2) label
estimates restore devcat
margins if devcat==2, dydx(agecat $marginvars religion) post
outreg2 using "$MARGIN_DEV", ctitle(Emerging countries) dec(2) label
estimates restore devcat
margins if devcat==3,  dydx(agecat $marginvars religion) post
outreg2 using "$MARGIN_DEV", ctitle(Developed countries) dec(2) label
estimates restore devcat
margins if devcat==4,  dydx(agecat $marginvars religion) post
outreg2 using "$MARGIN_DEV", ctitle(ASNA countries) dec(2) label
estimates restore devcat

***********************
*** By age_cat and development ***
***********************

*** setting the output file
global COEFF_COMB="$PATH\Output data\coeff_comb.xls"
global MARGIN_COMB="$PATH\Output data\margins_comb.xls"

*** running regression
set more off
svy: probit lfpr i.devcat i.agecat $list_base i.devcat#i.agecat#($list_int ib2.religion) i.WP5
estimates store combcat
outreg2 using "$COEFF_COMB", adds(Countries,e(N_strata))  bdec(2) sdec(2) replace

*** margins for all groups
margins, vce(unconditional) dydx($marginvars religion) post
outreg2 using "$MARGIN_COMB", ctitle(Total) dec(2) label replace
estimates restore combcat

*** 
forvalues dev=1/4{
local name1 : label devcat `dev'
forvalues age=0/2{
local name2 : label agecat `age'  
margins if devcat==`dev' & agecat==`age', dydx($marginvars religion) post
outreg2 using "$MARGIN_COMB", ctitle(`name1' `name2') dec(2) label
estimates restore combcat
}
}
*/
