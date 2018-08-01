clear all
set more off

*** This file computes margins, loading already estimated output

*************************************************
* Administrative Commands
*************************************************
*Define Directory
global PATH "D:\Papers\Womans participation\Econometric Analysis"

global ESTPATH "I:\COMMON\Stefan\Papers\Womans participation\Econometric Analysis" /*path where estimates are*/

use "$ESTPATH\Output data\dataset_esample.dta", clear
estimates use "$ESTPATH\Output data\cascade1"


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

