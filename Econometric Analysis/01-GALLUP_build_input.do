*===================================================================
* Date: February 2017 
* Purpose: Clean and Recode Data for Gallup Analysis 
*
* Database: Gallup, reduced for 80% of responses for 5Q on Gender
* Output: GALLUP_clean.dta
* Key Variables: 
*do "C:\Users\yoons\AppData\Local\Temp\STD0f000000.tmp"

*===================================================================

clear 
clear matrix
set more off


*************************************************
* Administrative Commands
*************************************************
*Define Directory
*global PATH "I:\COMMON\Stefan\Papers\Womans participation\Econometric Analysis"
global PATH "D:\Projects\Women participation\Econometric Analysis"

global REGIONS "I:\COMMON\TEM\_Latest Version\ILO regional groupings 2016.dta"

cd "$PATH"

capture log close
log using "$PATH\Gallup_clean.smcl", replace 

***********************************************
* Loading GET LFPR rates for the country
***********************************************
/*
use "D:\TEM\LFEP Model July 2015\Dissemination datasets\Dissemination LFEP - Country data (1990-2050, including TOTALS) July 2015.dta", clear
keep if age_group=="Total (15+)"
keep if year==2016
gen PR_GAP = PR_M-PR_F
keep iso3code ilo_code PR_M PR_F PR_GAP
*/ 
use "$PATH\Input data\GET LFPR.dta", clear
gen year=2016
merge 1:1 ilo_code year using "D:\TEM\GET Model November 2017\Final Datasets\Productivity per country November 2017.dta", keepusing(pcgdppp)
drop if _merge==2
drop _merge
merge 1:1 iso3code using "$REGIONS", keepusing(incomegroup)
drop if _merge==2
drop _merge
regress PR_F c.pcgdppp##c.pcgdppp PR_M c.PR_M#c.PR_M if incomegroup!=1
predict pred_F if incomegroup!=1
gen pred_gap=PR_M-pred_F
egen mgap=mean(pred_gap)
replace pred_gap=mgap if pred_gap==. & incomegroup!=1
gen gapdiff=PR_GAP-pred_gap
gen gapcat2=gapdiff>0
drop year pcgdppp pred_F pred_gap mgap gapdiff
label define gapcat2 0 "Low gap" 1 "High gap"
label value gapcat2 gapcat2
save "$PATH\Output data\GET LFPR with gapcat.dta", replace


*****************************************************
* Read in the Dataset
*****************************************************
use "$PATH\Input data\Gallup almost complete dataset.dta", clear 


*************************************************
* RECODING KEY VARIABLES 
*************************************************
tab emp_lfpr WP1230
br WP1223 WP1230 WP1230Recoded WP1220 WP1219

*covariates*
gen female=WP1219
replace female=0 if female==1
replace female=1 if female==2

gen lfpr=emp_lfpr

gen married=0
replace married=1 if WP1223==2 | WP1223==8 //married, domestic partner
replace married=. if WP1223==6 | WP1223==7 //DK, refused
label variable married "In Relationship"

gen kids=WP1230
replace kids=. if kids>90 // 98 (DK), 99=refused

gen kids2=kids^2

gen kids1=0
replace kids1=1 if WP1230>=1
replace kids1=. if WP1230>90
label variable kids1 "Children"

gen housenum = WP12
replace housenum=. if housenum>=90

gen age=WP1220
replace age=. if age==100 //100=refused

generate age2=age^2

** defining the category
egen agecat=cut(age) , at(15,25,55,100) label
label define agecat 0 "Age 15-24" 1 "Age 25-54" 2 "Age 55+", modify


*education dummies, baseline for comparison is primary*
	*gen ed_prim=0
	*replace ed_prim=1 if wp3117==1

gen educ=wp3117
replace educ=. if educ>3
label define educ 1 "Primary education" 2 "Secondary education" 3 "Tertiary education"
label value educ educ
	
gen ed_second=0
replace ed_second=1 if wp3117==2
replace ed_second=. if wp3117==4 | wp3117==5

gen ed_tert=0
replace ed_tert=1 if wp3117==3
replace ed_tert=. if wp3117==4 | wp3117==5


*urban/rural*
gen urban=0
replace urban=1 if WP14==3 | WP14==6 //large city or suburb of a large city
replace urban=. if WP14==4 | WP14==5 //refused or DK
label variable urban "Urban"

/*gen rural=0
replace rural=1 if WP14==1 | WP14==2 //small town or rural area
replace rural=. if WP14==4 | WP14==5
*/ 

*Internet*
gen internet=0
replace internet=1 if WP16056==1
replace internet=. if WP16056==. | WP16056==3 | WP16056==4
label variable internet "Internet"

*Landline*
gen landline=0
replace landline=1 if  WP17625==1
replace landline=. if WP17625==. | WP17625==3 | WP17625==4

*mobile phone
gen mobile=0
replace mobile=1 if  WP17626==1
replace mobile=. if WP17626==. | WP17626==3 | WP17626==4

egen phone = rowmax(mobile landline)
label variable phone "Phone"

egen comm=rowmax(mobile landline internet)

* Religion
gen religion=1
replace religion=2 if WP1233==1 | WP1233==2 | WP1233==3 | WP1233==28
replace religion=3 if WP1233==4 | WP1233==5 | WP1233==6
replace religion=4 if WP1233==8
*replace religion=5 if WP1233==9
*replace religion=6 if WP1233==15
replace religion=5 if WP1233==26
label define religion 1 "Other" 2 "Christian" 3 "Islam" 4 "Hinduism" /*5 "Budism" 6 "Judaism"*/ 5 "Secular"
label value religion religion
label variable religion "Religion"
gen dreligion=1
replace dreligion=0 if religion==5
label variable dreligion "Religion dummy"
label define dreligion 0 "Secular" 1 "Religion"
label value dreligion dreligion

gen islam=0
replace islam=1 if religion==3

*Female Preference to Work at Paid Job or Stay at Home*
tab WP17632
gen pref_work=1 if WP17632==1 | WP17632==3
replace pref_work=. if WP17632==4 | WP17632==5 
replace pref_work=0 if WP17632==2 
label variable pref_work "Prefer to work"


*Acceptable for Women in Family to Have a Paid Job Outside Home*
tab WP17634 
gen pref_accept=0 
replace pref_accept=1 if WP17634==1
replace pref_accept=. if WP17634==. | WP17634==3 | WP17634==4
label variable pref_accept "Acceptible to work"

*Biggest Challenge of Women Who Work at Paid Jobs*
tab WP17635
gen challenge=WP17635
replace challenge=. if WP17635==99 //97=other, 98=DK
label define challenge 1 "Lack of flexibility" 2 "Work-family balance" 3 "Lack of affordable care" 4 "Non-approval by family" 5 "Abuse, harassement, discrimination" 6 "Lack of good-paying jobs" 7 "Unequal pay" 8 "Lack of transportation" 9 "Men prefered in job" 10 "Lack of skills" 11 "Other"
label value challenge challenge
** http://www.stata.com/manuals13/u25.pdf **
	**FACTOR VARIABLE, SPECIFYING BASE LEVEL**//baseline for comparison is DK
		*ib98.pref_challenge 
	
*Opportunity For Women to Find a Good Job Compared to Men: worse or better*
tab WP17636
gen pref_opport=WP17636
replace pref_opport=. if WP17636==5 //refused 
label define opport 1 "Better opportunity for women" 2 "Same opportunity for women" 3 "Worse opportunity for women"
label value pref_opport opport
label variable pref_opport "Opportunity"
		

*WOMEN TREATED WITH RESPECT 
tab WP9050	//	1-yes, 2-no, 3-dk
gen respect=WP9050
replace respect=. if respect==4 
replace respect=0 if respect==2 | respect==3
label variable respect "Women treated with respect"

*Financial Well-Being Index		
tab INDEX_FL //continuous?

* infracstructure


*POVERTY*
gen poor=1
replace poor=0 if INDEX_FS==100
replace poor=. if INDEX_FS==. 

gen optimism = INDEX_OT/100
gen laworder = INDEX_LO/100
gen jobclimate = INDEX_JC/100
gen financial= INDEX_FL/100


*INFRASTRUCTURE*
gen roads=WP92
replace roads=. if WP92==3 | WP92==4
replace roads=0 if WP92==2
gen transport=WP91
replace transport=. if WP91==3 | WP91==4
replace transport=0 if WP91==2


save "$PATH\Input data\GALLUP_clean1.dta", replace


br WP17632 WP17633 WP17634 WP17635 WP17636 WP17637 


*************************************************************
* Clean and Merge for EU Sample // set obs `=_N+1' 
*************************************************************
/*Adding N. Cyprus:
replace iso3code="NCYP" if country=="Northern Cyprus"
replace ilo_code=800 if country=="Northern Cyprus"
replace region=5 if country=="Northern Cyprus"
replace subregionbroad=52 if country=="Northern Cyprus"
replace incomegroup=4 if country=="Northern Cyprus"
replace development=3 if country=="Northern Cyprus"
save "D:\TEM\Regions and Countries\ILO regional groupings 2017.dta"
*/

use "$PATH\Input data\GALLUP_clean1.dta", clear
decode WP9048, generate(countryborn)
replace countryborn=countrynew if countryborn==""
foreach country in countrynew countryborn{
*replace country="Bolivia, Plurinational State of" if country=="Bolivia" 
replace `country'="Antigua and Barbuda" if `country'=="Antigua & Barbuda"
replace `country'="Congo, Democratic Republic of the" if `country'=="Congo Kinshasa" 
replace `country'="Congo, Democratic Republic of the" if `country'=="Congo (Kinshasa)" 
replace `country'="Congo" if `country'=="Congo Brazzaville" 
replace `country'="Gambia" if `country'=="The Gambia"
replace `country'="Hong Kong, China" if `country'=="Hong Kong" 
replace `country'="Iran, Islamic Republic of" if `country'=="Iran" 
replace `country'="Côte d'Ivoire" if `country'=="Ivory Coast" 
replace `country'="Macedonia, the former Yugoslav Republic of" if `country'=="Macedonia" 
replace `country'="Moldova, Republic of" if `country'=="Moldova" 
replace `country'="Occupied Palestinian Territory" if `country'=="Palestine" 
replace `country'="Occupied Palestinian Territory" if `country'=="Palestinian Territories"
replace `country'="Réunion" if `country'=="Reunion Island"
replace `country'="Russian Federation" if `country'=="Russia" 
replace `country'="Sao Tome and Principe" if `country'=="Sao Tome & Principe"
replace `country'="Korea, Republic of" if `country'=="South Korea"
replace `country'="Syrian Arab Republic" if `country'=="Syria"
replace `country'="Taiwan, China" if `country'=="Taiwan" 
replace `country'="Tanzania, United Republic of" if `country'=="Tanzania"
replace `country'="Trinidad and Tobago" if `country'=="Trinidad & Tobago"
replace `country'="Venezuela, Bolivarian Republic of" if `country'=="Venezuela"
replace `country'="Viet Nam" if `country'=="Vietnam" 
replace `country'="Central African Republic" if `country'=="Central Africa Republic" 
}
rename countryborn country
merge m:1 country using "$REGIONS", keepusing(iso3code)
drop if _merge!=3
drop _merge

*** computing country shares of men opinion on women
preserve 
collapse (sum) wgt, by(iso3code WP17633)
drop if WP17633==.
egen total=total(wgt), by(iso3code)
gen pref_men_=wgt/total*100
drop wgt total
reshape wide pref_men_ ,i(iso3code) j(WP17633)
gen pref_men_home=pref_men_2
gen pref_men_work=pref_men_1 + pref_men_3
drop pref_men_?
drop if pref_men_work==. | pref_men_home==.
egen mean_pref=mean(pref_men_work)
gen cat_pref=pref_men_work<mean_pref
drop mean_pref
label variable pref_men_work "Share of men prefereing women to work" 
label variable pref_men_home "Share of men prefereing women to stay home" 
label variable cat_pref "Index whether country has high share of men prefering women to work"
label define cat_pref 0 "Low share of men prefer women to work" 1 "High share of men prefer women to work"
label value cat_pref cat_pref
save "$PATH\Output data\male preferences country data.dta", replace
restore

*** computing country shares of women opinion on women
preserve 
collapse (sum) wgt, by(iso3code WP17632)
drop if WP17632==.
egen total=total(wgt), by(iso3code)
gen pref_women_=wgt/total*100
drop wgt total
reshape wide pref_women_ ,i(iso3code) j(WP17632)
gen pref_women_home=pref_women_2
gen pref_women_work=pref_women_1 + pref_women_3
drop pref_women_?
drop if pref_women_work==. | pref_women_home==.
egen mean_pref=mean(pref_women_work)
gen catw_pref=pref_women_work<mean_pref
drop mean_pref
label variable pref_women_work "Share of men prefereing women to work" 
label variable pref_women_home "Share of men prefereing women to stay home" 
label variable catw_pref "Index whether country has high share of men prefering women to work"
label define catw_pref 0 "Low share of men prefer women to work" 1 "High share of men prefer women to work"
label value catw_pref catw_pref
save "$PATH\Output data\female preferences country data.dta", replace
restore


merge m:1 iso3code using "$PATH\Input data\GET LFPR.dta", keepusing(PR_F PR_M)
drop if _merge==2
drop _merge
rename PR_F PR_F_origin
rename PR_M PR_M_origin
drop country

merge m:1 iso3code using "$PATH\Output data\male preferences country data.dta"
drop _merge
merge m:1 iso3code using "$PATH\Output data\female preferences country data.dta"
drop _merge

rename countrynew country
merge m:1 country using "$REGIONS", keepusing(iso3code subregionbroad incomegroup development)
drop if _merge!=3
drop _merge

merge m:1 iso3code using "$PATH\Output data\GET LFPR with gapcat.dta"
drop if _merge==2
drop _merge


*************************
* Set thresholds, into variable gap_3 for 3 thresholds by group
* gap_2 to distinguish high gap only
*************************
gen gap_3=0
* developing countries
generate byte threshold=recode(PR_GAP,10,30,50) if development==1
egen temp = group(threshold)
replace gap_3=temp if development==1
drop threshold temp
* emerging countries
generate byte threshold=recode(PR_GAP,20,40,60) if development==2
egen temp = group(threshold)
replace gap_3=temp if development==2
drop threshold temp
* developed countries
generate byte threshold=recode(PR_GAP,15,30,50) if development==3
egen temp = group(threshold)
replace gap_3=temp if development==3
drop threshold temp

gen gap_2=0
* developing countries
generate byte threshold=recode(PR_GAP,30,50) if development==1
egen temp = group(threshold)
replace gap_2=temp if development==1
drop threshold temp
* emerging countries
generate byte threshold=recode(PR_GAP,40,60) if development==2
egen temp = group(threshold)
replace gap_2=temp if development==2
drop threshold temp
* developed countries
generate byte threshold=recode(PR_GAP,30,50) if development==3
egen temp = group(threshold)
replace gap_2=temp if development==3
drop threshold temp


*** development categories, with extra ASNA
gen devcat=development
replace devcat=4 if subregionbroad==10 | subregionbroad==30
label copy development devcat
label define devcat 4 "ASNA countries", add
label value devcat devcat

gen lowincome=1 if development==1
replace lowincome=0 if lowincome==.
label define lowincome 0 "Middle or high income country" 1 "Low income country"
label value lowincome lowincome

gen smartcat=1 if development<=1
replace smartcat=2 if gapcat2==0 & development>1
replace smartcat=3 if gapcat2==1 & development>1
label define smartcat 1 "Developing country" 2 "Low gap" 3 "High gap"
label value smartcat smartcat

gen prefcat=1 if development<=1
replace prefcat=2 if cat_pref==0 & development>1
replace prefcat=3 if cat_pref==1 & development>1
label define prefcat 1 "Developing country" 2 "Low male preference" 3 "High male preference"
label value prefcat prefcat

rename kids1 CHD
rename married RLS
rename housenum HHM
rename educ EDU
rename urban URB
rename comm COM
rename islam REL
rename pref_work PFW
rename pref_accept ACW
rename pref_opport OPP
rename challenge CHG
rename poor PVT
rename laworder LAW
rename jobclimate JCL
rename roads RDS
rename transport TRP


save "$PATH\Input data\GALLUP_clean.dta", replace
*



log close 
