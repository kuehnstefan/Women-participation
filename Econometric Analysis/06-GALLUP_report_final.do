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
global PATH "D:\WESO\2017 WESO Women\Analysis\Stata"
global OUT_COEF_D "$PATH\Output data\LFPR coef dev 2.tex"
global OUT_MARG1_D "$PATH\Output data\LFPR marg1 dev 2.xls"
global OUT_MARG2_D "$PATH\Output data\LFPR marg2 dev 2.xls"
global OUT_MARG3_D "$PATH\Output data\LFPR marg3 dev 2.xls"
global OUT_MARG4_D "$PATH\Output data\LFPR marg4 dev 2.xls"
global OUT_COEF2 "$PATH\Output data\LFPR coef reg.doc"
global OUT_MARG2 "$PATH\Output data\LFPR marg1 reg.xls"
global OUT_MARG3 "$PATH\Output data\LFPR marg2 reg.xls"

putexcel set "$PATH\Output data\Cascade LFPR.xlsx", modify sheet("test")

cd "$PATH"
capture log close
log using "$PATH\Gallup_analysis.log", replace 


************************************************
* Define baseline regression
*global xlist1 age c.age#c.age kids c.kids#c.kids c.housenum##c.housenum i.ed_second i.ed_tert urban i.internet i.phone i.INDEX_FS i.married i.pref_work i.pref_accept ib2.pref_opport
global xlist1 age c.age#c.age kids c.kids#c.kids c.housenum##c.housenum i.educ i.urban i.internet i.phone ib1.poor i.married i.pref_work i.pref_accept ib2.pref_opport optimism
*global xlist2 age age2 kids kids2 i.ed_second i.ed_tert urban i.internet
************************************************
				

*****************************************************
* Read in the Dataset & Define Variables
*****************************************************
use "$PATH\Input data\GALLUP_clean.dta", clear

*****************************
** SET DATA AS SURVEY DATA **
*****************************

svyset WPID_RANDOM [pweight=wgt], strata(WP5) 
												//stratified sampling based on country, TO CLEAR: svyset, clear 
												//SVY:, standard errors is already robust, accounts for clustering 
**************************************
* Running estimations by development *
**************************************
**DEVELOPING**
keep if development==1  & (subregionbroad!=10 & subregionbroad!=30)
svy: probit lfpr $xlist1 i.respect##i.gap_2 /*i.gap_2#i.pref_work*/ i.pref_work#(i.married i.urban#i.pref_accept i.gap_2) ib5.religion ib5.religion#i.pref_work   ib1.pref_challenge  i.WP5
estimates store dev1 
outreg2 using "$OUT_COEF_D", keep($xlist1 i1.pref_work#i1.married i1.pref_work#i.urban#i.pref_accept ib1.pref_challenge i.gap_2 i2.gap_2#i1.pref_work ib5.religion#i.pref_work) adds(Countries,e(N_strata))  bdec(2) sdec(2) nocons replace ctitle(Developing countries)


estimates restore dev1
margins , vce(unconditional) dydx(pref_work poor married kids urban pref_accept 2.pref_challenge 3.pref_challenge 4.pref_challenge 5.pref_challenge 8.pref_challenge religion internet phone educ)  post
outreg2 using "$OUT_MARG1_D", ctitle(Developing countries) sideway stats(coef pval) noaster replace

estimates restore dev1
margins , vce(unconditional) dydx(pref_work) over(urban pref_accept) post
outreg2 using "$OUT_MARG2_D", ctitle(Developing countries) sideway stats(coef pval) noaster replace

*estimates restore dev1
*margins, vce(unconditional) dydx(educ) post
*outreg2 using "$OUT_MARG3_D", ctitle(Developing countries) sideway stats(coef pval) noaster replace

estimates restore dev1
margins, vce(unconditional) dydx(religion) post
outreg2 using "$OUT_MARG4_D", ctitle(Developing countries)  replace

*define cases
global genderrole0 = "urban=0 pref_accept=0 respect=0"
global genderrole1 = "urban=1 pref_accept=1 respect=1"
global socio0 = "phone=0 internet=0 optimism=0 pref_opport=3 kids=3"
global socio1 = "phone=1 internet=1 optimism=1 pref_opport=1 kids=0"


*cascading
estimates restore dev1
putexcel A1="Characteristic" B1="Developing countries"
local line=2
margins 0.pref_work, at($genderrole0 religion=3 $socio0 poor=1 pref_challenge=8 educ=1)
matrix c=r(b)
putexcel A`line'="Base" B`line'=c[1,1]
local ++line
margins 1.pref_work, at($genderrole0 religion=3 $socio0 poor=1 pref_challenge=8 educ=1)
matrix c=r(b)
putexcel A`line'="Preference" B`line'=c[1,1]
local ++line
margins 1.pref_work, at($genderrole0 religion=3 $socio1 poor=1 pref_challenge=1 educ=1)
matrix c=r(b)
putexcel A`line'="Socio-economic" B`line'=c[1,1]
local ++line
margins 1.pref_work, at($genderrole1 religion=5 $socio1 poor=1 pref_challenge=1 educ=1)
matrix c=r(b)
putexcel A`line'="Gender role" B`line'=c[1,1]
local ++line
margins 1.pref_work, at($genderrole1 religion=5 $socio1 poor=1 pref_challenge=1 educ=3)
matrix c=r(b)
putexcel A`line'="Education" B`line'=c[1,1]
local ++line



**EMERGING**
use "$PATH\Input data\GALLUP_clean.dta", clear
svyset WPID_RANDOM [pweight=wgt], strata(WP5) 
keep if development==2 & (subregionbroad!=10 & subregionbroad!=30)
svy: probit lfpr $xlist1 i.respect##i.gap_2 i.pref_work#(i.married#i.urban#i.pref_accept#i.gap_2) ib5.religion ib5.religion#i.pref_work ib1.pref_challenge  i.WP5
estimates store dev2
outreg2 using "$OUT_COEF_D", keep($xlist1 i1.pref_work#i1.married i1.pref_work#i.urban#i.pref_accept ib1.pref_challenge i.gap_2 i2.gap_2#i1.pref_work ib5.religion#i.pref_work) adds(Countries,e(N_strata))  bdec(2) sdec(2) nocons ctitle(Emerging countries)

*marginal impacts

estimates restore dev2
margins , vce(unconditional) dydx(pref_work 2.poor 3.poor married kids urban pref_accept 2.pref_challenge 3.pref_challenge 4.pref_challenge 5.pref_challenge 8.pref_challenge religion internet phone educ)  post
outreg2 using "$OUT_MARG1_D", ctitle(Emerging countries) sideway stats(coef pval) noaster 

estimates restore dev2
margins , vce(unconditional) dydx(pref_work) over(urban pref_accept) post
outreg2 using "$OUT_MARG2_D", ctitle(Emerging countries) sideway stats(coef pval) noaster 

*estimates restore dev2
*margins, vce(unconditional) dydx(educ) post
*outreg2 using "$OUT_MARG3_D", ctitle(Emerging countries)   sideway stats(coef pval) noaster

estimates restore dev2
margins, vce(unconditional) dydx(religion) post
outreg2 using "$OUT_MARG4_D", ctitle(Emerging countries) 

*cascading
estimates restore dev2
putexcel C1="Emerging countries"
local line=2
margins 0.pref_work, at($genderrole0 religion=3 $socio0 poor=1 pref_challenge=8 educ=1)
matrix c=r(b)
putexcel C`line'=c[1,1]
local ++line
margins 1.pref_work, at($genderrole0 religion=3 $socio0 poor=1 pref_challenge=8 educ=1)
matrix c=r(b)
putexcel C`line'=c[1,1]
local ++line
margins 1.pref_work, at($genderrole0 religion=3 $socio1 poor=1 pref_challenge=1 educ=1)
matrix c=r(b)
putexcel C`line'=c[1,1]
local ++line
margins 1.pref_work, at($genderrole1 religion=5 $socio1 poor=1 pref_challenge=1 educ=1)
matrix c=r(b)
putexcel C`line'=c[1,1]
local ++line
margins 1.pref_work, at($genderrole1 religion=5 $socio1 poor=1 pref_challenge=1 educ=3)
matrix c=r(b)
putexcel C`line'=c[1,1]
local ++line

**DEVELOPED**
use "$PATH\Input data\GALLUP_clean.dta", clear
svyset WPID_RANDOM [pweight=wgt], strata(WP5) 
keep if development==3  & (subregionbroad!=10 & subregionbroad!=30)
local b=1
svy: probit lfpr $xlist1 i.respect i.pref_work#(i.married#i.urban#i.pref_accept) ib5.religion ib5.religion#i.pref_work ib1.pref_challenge  i.WP5
estimates store dev3
outreg2 using "$OUT_COEF_D", keep($xlist1 i1.pref_work#i1.married i1.pref_work#i.urban#i.pref_accept ib1.pref_challenge i.gap_2 i2.gap_2#i1.pref_work ib5.religion#i.pref_work) adds(Countries,e(N_strata))  bdec(2) sdec(2) nocons ctitle(Developed countries)

*marginal impacts

estimates restore dev3
margins , vce(unconditional) dydx(pref_work 2.poor 3.poor married kids urban pref_accept 2.pref_challenge 3.pref_challenge 4.pref_challenge 5.pref_challenge 8.pref_challenge religion internet phone educ)  post
outreg2 using "$OUT_MARG1_D", ctitle(Developed countries) sideway stats(coef pval) noaster

estimates restore dev3
margins , vce(unconditional) dydx(pref_work) over(urban pref_accept) post
outreg2 using "$OUT_MARG2_D", ctitle(Developed countries) sideway stats(coef pval) noaster 

*estimates restore dev3
*margins, vce(unconditional) dydx(educ) post
*outreg2 using "$OUT_MARG3_D", ctitle(Developed countries)  sideway stats(coef pval) noaster

estimates restore dev3
margins, vce(unconditional) dydx(religion) post
outreg2 using "$OUT_MARG4_D", ctitle(Developed countries) 

estimates restore dev3
putexcel D1="Developed countries"
local line=2
margins 0.pref_work, at($genderrole0 religion=3 $socio0 poor=1 pref_challenge=3 educ=1)
matrix c=r(b)
putexcel D`line'=c[1,1]
local ++line
margins 1.pref_work, at($genderrole0 religion=3 $socio0 poor=1 pref_challenge=3 educ=1)
matrix c=r(b)
putexcel D`line'=c[1,1]
local ++line
margins 1.pref_work, at($genderrole0 religion=3 $socio1 poor=1 pref_challenge=1 educ=1)
matrix c=r(b)
putexcel D`line'=c[1,1]
local ++line
margins 1.pref_work, at($genderrole1 religion=5 $socio1 poor=1 pref_challenge=1 educ=1)
matrix c=r(b)
putexcel D`line'=c[1,1]
local ++line
margins 1.pref_work, at($genderrole1 religion=5 $socio1 poor=1 pref_challenge=1 educ=3)
matrix c=r(b)
putexcel D`line'=c[1,1]
local ++line

**N.Africa and Arab States**
use "$PATH\Input data\GALLUP_clean.dta", clear
svyset WPID_RANDOM [pweight=wgt], strata(WP5) 
keep if subregionbroad==10 | subregionbroad==30
local b=1
svy: probit lfpr $xlist1 i.respect i.pref_work#(i.married#i.urban#i.pref_accept) ib5.religion ib5.religion#i.pref_work ib1.pref_challenge  i.WP5
estimates store dev4
outreg2 using "$OUT_COEF_D", keep($xlist1 i1.pref_work#i1.married i1.pref_work#i.urban#i.pref_accept ib1.pref_challenge i.gap_2 i2.gap_2#i1.pref_work ib5.religion#i.pref_work) adds(Countries,e(N_strata))  bdec(2) sdec(2) nocons ctitle(NAAS countries)


*marginal impacts

estimates restore dev4
margins , vce(unconditional) dydx(pref_work 2.poor 3.poor married kids urban pref_accept 2.pref_challenge 3.pref_challenge 4.pref_challenge 5.pref_challenge 8.pref_challenge religion internet phone educ)  post
outreg2 using "$OUT_MARG1_D", ctitle(ASNA countries) sideway stats(coef pval) noaster

estimates restore dev4
margins , vce(unconditional) dydx(pref_work) over(urban pref_accept) post
outreg2 using "$OUT_MARG2_D", ctitle(ASNA countries) sideway stats(coef pval) noaster 

*estimates restore dev4
*margins, vce(unconditional) dydx(educ) post
*outreg2 using "$OUT_MARG3_D", ctitle(ASNA countries)  sideway stats(coef pval) noaster

estimates restore dev4
margins, vce(unconditional) dydx(religion)  post
outreg2 using "$OUT_MARG4_D", ctitle(ASNA countries) 


estimates restore dev4
putexcel E1="ASNA countries"
local line=2
margins 0.pref_work, at($genderrole0 religion=3 $socio0 poor=1 pref_challenge=3 educ=1)
matrix c=r(b)
putexcel E`line'=c[1,1]
local ++line
margins 1.pref_work, at($genderrole0 religion=3 $socio0 poor=1 pref_challenge=3 educ=1)
matrix c=r(b)
putexcel E`line'=c[1,1]
local ++line
margins 1.pref_work, at($genderrole0 religion=3 $socio1 poor=1 pref_challenge=1 educ=1)
matrix c=r(b)
putexcel E`line'=c[1,1]
local ++line
margins 1.pref_work, at($genderrole1 religion=1 $socio1 poor=1 pref_challenge=1 educ=1)
matrix c=r(b)
putexcel E`line'=c[1,1]
local ++line
margins 1.pref_work, at($genderrole1 religion=1 $socio1 poor=1 pref_challenge=1 educ=3)
matrix c=r(b)
putexcel E`line'=c[1,1]
local ++line

/*
levelsof(subregionbroad), local(regions)
*di "`regions'"
local replace replace
foreach i in `regions'{
*local i=11
use "$PATH\Input data\GALLUP_clean.dta", clear
svyset WPID_RANDOM [pweight=wgt], strata(WP5) 
keep if subregionbroad==`i'
local r `:label subregionbroad `i''
svy: probit lfpr $xlist1 i.married#i.pref_work ib1.pref_challenge ib6.religion i.WP5
estimates store dev3
* finding significant challenges
local challenges
	forvalues j=2/10{
	quietly test i`j'.pref_challenge
	quietly if `r(p)'<=0.16 local challenges `challenges' `j'.pref_challenge
	}
* finding significant religions
local religions
	forvalues j=1/5{
	capture quietly test i`j'.religion
	if _rc==0 {
		quietly if `r(p)'<=0.1 local religions `religions' `j'.religion
		}
	}
outreg2 using "$OUT_COEF2", keep($xlist1 ib1.pref_challenge i1.married#i1.pref_work ib6.religion) adds(Countries,e(N_strata)) nocons ctitle(`r') `replace'
estimates restore dev3
margins, vce(unconditional) dydx(pref_work) over(married) post
outreg2 using "$OUT_MARG3", ctitle(`r') `replace'
estimates restore dev3
margins, vce(unconditional) dydx(married) over(pref_work) post
outreg2 using "$OUT_MARG3", ctitle(`r') 
estimates restore dev3
margins, vce(unconditional) dydx(kids) at(kids=(0 3)) post
outreg2 using "$OUT_MARG3", ctitle(`r') 
estimates restore dev3
margins, vce(unconditional) dydx( ed_second ed_tert urban internet phone INDEX_FS pref_accept 1.pref_opport `challenges' `religions') stats(coef) post
outreg2 using "$OUT_MARG2", ctitle(`r') `replace'
local replace
}

