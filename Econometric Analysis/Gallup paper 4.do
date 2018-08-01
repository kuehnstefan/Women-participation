clear all
set more off


*global PATH "I:\COMMON\Stefan\Papers\Womans participation\Econometric Analysis"
global PATH "D:\Projects\Women participation\Econometric Analysis"

cd "$PATH"

use "$PATH\Input data\GALLUP_clean.dta", clear


svyset WPID_RANDOM [pweight=wgt], strata(WP5) 
	//stratified sampling based on country, TO CLEAR: svyset, clear 

*** setting the interaction terms	
global allvars c.HHM##c.HHM  i.RLS i.EDU i.CHD i.PVT i.COM i.URB ib1.OPP i.CHG i.REL i.ACW i.RDS i.TRP c.LAW c.JCL



********************************
*** using smartcat, the observed gender gap, as category
*******************************

forvalues a=0/2{
forvalues p=1/3{
quietly svy: probit lfpr i.PFW $allvars i.PFW#($allvars)  i.WP5 if agecat==`a' & smartcat==`p'
contrast r.PFW#($allvars), noeffect
}
}

global prefint01 i.URB c.LAW i.OPP
global prefint02 i.CHD i.COM i.URB i.REL i.ACW
global prefint03 i.EDU i.OPP
global prefint11 c.LAW i.CHG i.RDS
global prefint12 i.PVT i.COM i.OPP i.REL
global prefint13 i.EDU i.URB i.OPP
global prefint21 c.HHM c.HHM#c.HHM i.RLS i.URB i.OPP i.REL
global prefint22 i.EDU c.JCL
global prefint23 i.REL i.ACW

forvalues a=0/2{
forvalues p=1/3{
quietly svy: probit lfpr i.PFW $allvars i.PFW#(${prefint`a'`p'}) i.WP5 if agecat==`a' & smartcat==`p'
contrast r.PFW#(${prefint`a'`p'}), noeffect
}
}

global prefint01 i.URB c.LAW i.OPP
global prefint02 i.CHD i.URB i.OPP i.ACW
global prefint03 i.EDU i.OPP
global prefint11 c.LAW i.RDS
global prefint12 i.RLS i.PVT i.COM ib1.OPP i.REL i.CHG i.RDS c.JCL
global prefint13 i.EDU i.URB i.OPP
global prefint21 c.HHM c.HHM#c.HHM i.RLS i.URB i.OPP i.REL
global prefint22 i.EDU c.JCL i.OPP i.ACW
global prefint23 i.REL i.ACW i.OPP


forvalues a=0/2{
forvalues p=1/3{
quietly svy: probit lfpr i.PFW i.PFW#(${prefint`a'`p'}) i.CHD#i.CHG $allvars i.WP5 if agecat==`a' & smartcat==`p'
contrast r.PFW#(${prefint`a'`p'}) r.CHD#i.CHG, noeffect
}
}


forvalues a=0/2{
forvalues p=1/3{
quietly svy: probit lfpr i.PFW i.PFW#(${prefint`a'`p'}) i.CHD#i.CHG $allvars i.WP5 if agecat==`a' & smartcat==`p'
contrast  r.CHD#i.CHG, noeffect
}
}

outreg, clear
forvalues a=0/2{
forvalues p=1/3{
	quietly svy: probit lfpr i.PFW $allvars i.PFW#(${prefint`a'`p'}) i.CHD#i.CHG i.WP5 if agecat==`a' & smartcat==`p'
	quietly indeplist
	local indepvars
	local margvars
	foreach var in `r(X)'{
		if strmatch("`var'","*WP5")==0 local indepvars = "`indepvars' "+"`var'"
		if (strmatch("`var'","*WP5")==0 & strmatch("`var'","*#*")==0 ) local margvars = "`margvars' "+"`var'"
	}
	di "`margvars'"
	margins if agecat==`a' & prefcat==`p', dydx(`margvars')
	outreg, keep(`margvars') sdec(2) se nocons varlabels merge nodisplay marginal
	local step merge
}
}
global OUT_COEF "$PATH\Output data\Coefficients_smart.doc"
outreg using "$OUT_COEF", ctitles("Variables", "Youth","Youth","Youth","Adult","Adult","Adult","Old","Old","Old"\"","Developing","Low gap","High gap","Developing","Low gap","High gap","Developing","Low gap","High gap" ) replay replace

fvset base 98 CHG
svy: probit lfpr i.PFW $allvars i.PFW#(${prefint11} i.CHG) i.CHD#i.CHG i.WP5 if agecat==1 & smartcat==1
margins if agecat==1 & smartcat==1, dydx(LAW RDS CHG) over(PFW)

svy: probit lfpr i.PFW $allvars i.PFW#(${prefint12}) i.CHD#i.CHG i.WP5 if agecat==1 & smartcat==2
margins if agecat==1 & smartcat==2, dydx(1.RLS 1.PVT 1.COM 2.OPP 3.OPP 1.REL 1.RDS JCL) over(PFW)
margins if agecat==1 & smartcat==2, dydx(4.CHG 5.CHG 7.CHG ) over(CHD)

svy: probit lfpr i.PFW $allvars i.PFW#(${prefint13} i.CHG) i.CHD#i.CHG i.WP5 if agecat==1 & smartcat==3
margins if agecat==1 & smartcat==3, dydx(EDU URB 2.OPP 3.OPP 3.CHG 4.CHG 6.CHG 9.CHG) over(PFW)
margins if agecat==1 & smartcat==3, dydx(2.CHG 4.CHG 8.CHG) over(CHD)





********************************
*** using prefcat, the male preferences for female participation, as category
*******************************

forvalues a=0/2{
forvalues p=1/3{
quietly svy: probit lfpr i.PFW i.PFW#($allvars)  i.WP5 if agecat==`a' & prefcat==`p'
contrast r.PFW#($allvars), noeffect
}
}

global prefint01 i.URB c.LAW i.OPP
global prefint02 c.LAW i.COM i.URB i.REL 
global prefint03 c.JCL i.EDU i.PVT 
global prefint11 c.LAW i.CHG i.RDS
global prefint12 c.HHM c.HHM#c.HHM i.RLS i.PVT i.COM i.OPP i.RDS 
global prefint13 i.URB i.PVT i.REL
global prefint21 c.HHM c.HHM#c.HHM i.REL i.URB i.OPP i.CHG i.REL
global prefint22 c.HHM c.HHM#c.HHM i.EDU i.URB i.CHG i.RDS
global prefint23 i.CHD 

forvalues a=0/2{
forvalues p=1/3{
quietly svy: probit lfpr i.PFW i.PFW#(${prefint`a'`p'}) $allvars i.WP5 if agecat==`a' & prefcat==`p'
contrast r.PFW#(${prefint`a'`p'}), noeffect
}
}

global prefint01 i.URB c.LAW
global prefint02 i.COM
global prefint03 c.JCL i.EDU i.PVT 
global prefint11 c.LAW i.CHG i.RDS
global prefint12 c.HHM c.HHM#c.HHM i.RLS i.PVT i.COM i.OPP i.RDS 
global prefint13 i.URB i.PVT i.REL
global prefint21 c.HHM c.HHM#c.HHM i.REL i.URB i.OPP i.CHG i.REL
global prefint22 c.HHM c.HHM#c.HHM i.EDU i.URB i.CHG i.RDS
global prefint23  


forvalues a=0/2{
forvalues p=1/3{
quietly svy: probit lfpr i.PFW i.PFW#(${prefint`a'`p'}) $allvars i.WP5 if agecat==`a' & prefcat==`p'
contrast r.PFW#(${prefint`a'`p'}), noeffect
}
}


outreg, clear
local ctitles = "Variable"
forvalues a=0/2{
forvalues p=1/3{
	quietly svy: probit lfpr i.PFW $allvars i.PFW#(${prefint`a'`p'}) i.WP5 if agecat==`a' & prefcat==`p'
	quietly indeplist
	local indepvars
	local margvars
	foreach var in `r(X)'{
		if strmatch("`var'","*WP5")==0 local indepvars = "`indepvars' "+"`var'"
		if (strmatch("`var'","*WP5")==0 & strmatch("`var'","*#*")==0 ) local margvars = "`margvars' "+"`var'"
	}
	di "`margvars'"
	margins if agecat==`a' & prefcat==`p', dydx(`margvars')
	local ctitles = "`ctitles', age=`a' cat=`p'"
	outreg, keep(`margvars') sdec(2) se nocons varlabels merge nodisplay marginal
	local step merge
}
}
global OUT_COEF "$PATH\Output data\Coefficients_1.doc"
outreg using "$OUT_COEF", ctitles(`ctitles') replay replace






