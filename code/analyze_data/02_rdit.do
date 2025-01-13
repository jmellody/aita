clear
clear matrix
capture log close
set more off

cd "/scratch/network/jm7581/aita/data/"
use aita_data_all_prepped.dta
drop if cum_score_absolute == 0
bysort postid_encoded: gen numcoms = _N
drop if numcoms < 15
sort postid_encoded
xtset postid_encoded
drop if time_from_first_op_com_min > 150
drop if time_from_first_op_com_min < -150
drop if time_from_first_op_com_min == 0
//save rdit_data.dta, replace
cd "/scratch/network/jm7581/aita/results/"


//use rdit_data.dta

xtreg score_log i.op_com_yet##i.consensus_disagree##c.time_from_first_op_com_min c.time_diff_min_ln##c.time_diff_min_ln comment_competition_ln author_skill_ln comment_length_ln i.year i.month i.dayofweek i.hour, fe vce(cluster postid_encoded)
quietly estadd local postfe "Yes", replace
quietly estadd local hourfe "Yes", replace
quietly estadd local dayofweekfe "Yes", replace
quietly estadd local monthfe "Yes", replace
quietly estadd local yearfe "Yes", replace
estimates save rdit_1, replace

margins, at(op_com_yet = (0 1) consensus_disagree = (0 1)) post coeflegend
lincom (_b[1bn._at] - _b[2._at]) //difference pre-comment
lincom (_b[3._at] - _b[4._at]) //difference post-comment
lincom (_b[1bn._at] - _b[2._at] ) - (_b[3._at] - _b[4._at]) // difference in the difference




