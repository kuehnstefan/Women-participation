clear all
set more off


*global PATH "I:\COMMON\Stefan\Papers\Womans participation\Econometric Analysis"
global PATH "D:\Projects\Women participation\Econometric Analysis"

cd "$PATH"

use "$PATH\Input data\GALLUP_clean.dta", clear


svyset WPID_RANDOM [pweight=wgt], strata(WP5) 
	//stratified sampling based on country, TO CLEAR: svyset, clear 

*** setting some indices to be included in regression
*global INDICES c.INDEX_LO c.INDEX_OT c.INDEX_JC
global INDICES c.optimism c.laworder c.jobclimate
	
*** setting the interaction terms	
global joint_int c.housenum##c.housenum  i.married i.educ i.kids1 i.poor i.comm i.pref_work  i.urban ib2.pref_opport ib1.challenge i.islam i.pref_accept i.roads i.transport
*** running regression
set matsize 900 /*because first estimation has too many variables */
svy: probit lfpr ib1.agecat  ib2.smartcat#ib1.agecat#($INDICES $joint_int) i.WP5
*** testing the interaction contrast
contrast r.smartcat#r.agecat#($INDICES $joint_int) , noeffect /*noeffect removes the differences in coefficient display, only showing the F-test*/

*** Step 2: identify variables where joint interaction is not significant, take out of joint interaction, and define individual interaction
global joint_int c.housenum##c.housenum  i.married i.educ i.kids1 i.poor i.comm 
global age_int i.pref_work  i.urban ib2.pref_opport ib1.challenge i.islam i.pref_accept i.roads i.transport
global smart_int i.pref_work  i.urban ib2.pref_opport ib1.challenge i.islam i.pref_accept i.roads i.transport
svy: probit lfpr ib1.agecat ib2.smartcat#ib1.agecat#($joint_int) ib2.smartcat#($INDICES $smart_int) ib1.agecat#($INDICES $age_int) i.WP5
contrast r.smartcat#r.agecat#($joint_int) , noeffect
contrast r.smartcat#($smart_int $INDICES) , noeffect
contrast r.agecat#($age_int $INDICES), noeffect
	
*** Step 3: investigae F-values, and adjust the interaction groups. Also, test for interaction with pref_work
global joint_int c.housenum##c.housenum  i.married i.educ i.kids1 i.poor i.comm
global age_int i.pref_work  i.urban ib2.pref_opport ib1.challenge c.optimism c.laworder c.jobclimate
global smart_int i.pref_work  ib2.pref_opport c.optimism c.jobclimate
global pref_int i.islam i.pref_accept i.poor i.urban ib2.pref_opport i.married i.educ i.kids1 i.comm c.optimism c.laworder c.jobclimate i.roads i.transport
svy: probit lfpr ib1.agecat i.pref_work#($pref_int) ib2.smartcat#ib1.agecat#($joint_int) ib2.smartcat#($smart_int) ib1.agecat#($age_int) i.WP5

contrast r.smartcat#r.agecat#($joint_int) , noeffect
contrast r.smartcat#($smart_int) , noeffect
contrast r.agecat#($age_int), noeffect
contrast r.pref_work#($pref_int), noeffect

*** Step final: adjust prefwork interaction, to get final regression
global joint_int c.housenum##c.housenum  i.married i.educ i.kids1 i.poor i.internet i.phone
global age_int i.pref_work  i.urban ib2.pref_opport ib1.challenge  c.laworder c.jobclimate
global smart_int i.pref_work  ib2.pref_opport  c.jobclimate
global pref_int i.islam i.pref_accept i.poor i.urban ib2.pref_opport i.educ i.comm c.laworder i.roads

*** estimating the baseline. 
use "$PATH\Input data\GALLUP_clean.dta", clear
svyset WPID_RANDOM [pweight=wgt], strata(WP5) 
svy: probit lfpr ib1.agecat i.pref_work#($pref_int) ib2.smartcat#ib1.agecat#($joint_int) ib2.smartcat#($smart_int) ib1.agecat#($age_int) i.WP5
estimates store est_final

global MARGINS_BASE="$PATH\Output data\margins_base.xls"
*** computing marginal effects
global socio_challenges 2.challenge 3.challenge 5.challenge 6.challenge 7.challenge 8.challenge 9.challenge 10.challenge
global marginvars educ pref_work pref_accept poor married kids1 1.pref_opport 3.pref_opport $socio_challenges internet phone  jobclimate laworder 4.challenge urban roads
margins if agecat==1 & smartcat==2, dydx($marginvars islam) post
outreg2 using "$MARGINS_BASE", ctitle(Baseline) dec(4) label sideway replace

estimates restore est_final


global MARGINS_youth="$PATH\Output data\margins_youth.xls"
global MARGINS_prime="$PATH\Output data\margins_prime.xls"
global MARGINS_elder="$PATH\Output data\margins_elder.xls"


*** to be done: present margins of interest for different groups.
margins if agecat==0 & smartcat==2, dydx(i.pref_work i.married i.educ i.kids1 i.poor i.internet i.phone i.urban ib2.pref_opport ib1.challenge c.laworder c.jobclimate i.roads) post
outreg2 using "$MARGINS_youth", ctitle(youth) dec(4) label sideway replace
estimates restore est_final
margins if agecat==1 & smartcat==2, dydx(i.pref_work i.married i.educ i.kids1 i.poor i.internet i.phone i.urban ib2.pref_opport ib1.challenge c.laworder c.jobclimate i.roads) post
outreg2 using "$MARGINS_prime", ctitle(prime) dec(4) label sideway replace
estimates restore est_final
margins if agecat==2 & smartcat==2, dydx(i.pref_work i.married i.educ i.kids1 i.poor i.internet i.phone i.urban ib2.pref_opport ib1.challenge c.laworder c.jobclimate i.roads) post
outreg2 using "$MARGINS_elder", ctitle(elder) dec(4) label sideway replace
estimates restore est_final          


margins if agecat==1 & smartcat==, dydx(i.pref_work i.married i.educ i.kids1 i.poor i.comm i.urban ib2.pref_opport ib1.challenge c.optimism c.laworder c.jobclimate) post
outreg2 using "$MARGINS_youth", ctitle(youth) dec(4) label sideway replace
estimates restore est_final
margins if agecat==1 & smartcat==2, dydx(i.pref_work i.married i.educ i.kids1 i.poor i.comm i.urban ib2.pref_opport ib1.challenge c.optimism c.laworder c.jobclimate) post
outreg2 using "$MARGINS_prime", ctitle(prime) dec(4) label sideway replace
estimates restore est_final
margins if agecat==2 & smartcat==2, dydx(i.pref_work i.married i.educ i.kids1 i.poor i.comm i.urban ib2.pref_opport ib1.challenge c.optimism c.laworder c.jobclimate) post
outreg2 using "$MARGINS_elder", ctitle(elder) dec(4) label sideway replace
estimates restore est_final                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 



global MARGINS_joint="$PATH\Output data\margins_joint.xls"

forvalues gap=1/3{
local name1 : label smartcat `gap'
forvalues age=0/2{
local name2 : label agecat `age'  
di "Estimating `name1' `name2'"
margins if agecat==`age' & smartcat==`gap', dydx(married kids educ) post
 outreg2 using "$MARGINS_joint", ctitle("`name1' `name2'") dec(2) label
estimates restore est_final 
}
}


*** first: check which contrasts are interesting
contrast ib2.smartcat#r.agecat#($joint_int) 

contrast r.smartcat#r.agecat#(married) 

contrast (smartcat 1)#r.agecat#(married), effects
contrast ib2.smartcat#r.agecat#(married), effects
contrast ib3.smartcat#r.agecat#(married), effects


contrast r.smartcat#(married), effects
contrast r.smartcat#(married), effects

contrast r.agecat#($age_int)


contrast r.smartcat#($smart_int)


contrast r.agecat#($age_int)



capture log close
log using "$PATH\Gallup_contrast.log", replace 

contrast rb1.smartcat#r.agecat#(educ), effects
contrast rb2.smartcat#r.agecat#(educ), effects
contrast rb3.smartcat#r.agecat#(educ), effects

contrast rb1.smartcat#r.agecat#(married) 
contrast rb2.smartcat#r.agecat#(married) 
contrast rb3.smartcat#r.agecat#(married) 

contrast rb1.smartcat#r.agecat#(kids) 
contrast rb2.smartcat#r.agecat#(kids) 
contrast rb3.smartcat#r.agecat#(kids) 

log close

/*
contrast ib2.smartcat#ib1.agecat#(married) 
contrast ib2.smartcat#r.agecat#(married) 

contrast rb1.smartcat#r.agecat#(married) 
contrast ib3.smartcat#r.agecat#(married) 









