
clear
clear matrix
capture log close
set more off

********************
* READ DATA AND SETUP
********************

cd "/pool001/jmellody/aitaoutput/"
use test_df_19.dta
sort postid_encoded
xtset postid_encoded

****************************
* #1 MAIN MODEL - WHICH IS MATCHED SAMPLE
****************************

*use matched_sample
use........

//FOR CEM MATCHING
eststo cem1: areg score_log c.cs_ln##c.cs_ln##i.consensus_agree i.top comment_length c.time_diff_min##c.time_diff_min comment_competition i.mod_comment author_count i.month [aweight = cem_weights], absorb(postid_encoded) vce(cluster postid_encoded)
margins, dydx(consensus_agree) at(cs = (0.1 0.25 0.5 0.75 0.9))
marginsplot, recastci(rarea)

eststo cem2: areg score_log c.certainty##c.current_consensus##i.consensus_agree i.top comment_length c.time_diff_min##c.time_diff_min comment_competition i.mod_comment author_count i.month [aweight = cem_weights], absorb(postid_encoded) vce(cluster postid_encoded)
margins, dydx(consensus_agree) at(certainty = (0.1 0.5 0.9) current_consensus = (0.55 0.75 0.95))
marginsplot, by(current_consensus) recastci(rarea)




summarize comment_competition_ln
local mean = r(mean)
local low = r(mean) - r(sd)
local lowlow = r(mean) - 2*r(sd)
local high = r(mean) + r(sd)
local highhigh = r(mean) + 2*r(sd)

xtreg score_log c.comment_competition_ln##c.comment_competition_ln##i.consensus_agree i.top parent_score_ln c.time_diff_min_ln##c.time_diff_min_ln author_skill_ln i.mod_comment comment_length i.hour i.dayofweek i.month, fe vce(cluster postid_encoded) 
quietly estadd local postfe "Yes", replace
quietly estadd local hourfe "Yes", replace
quietly estadd local dayofweekfe "Yes", replace
quietly estadd local monthfe "Yes", replace
estimates save reg2, replace
margins, dydx(consensus_agree) at (comment_competition_ln = (`lowlow' `low' `mean' `high' `highhigh')) saving(margins2, replace)
marginsplot


*******************
* #2 RDIT
*******************
//RDIT
drop if time_from_first_op_com_min > 180
drop if time_from_first_op_com_min < -180

eststo reg1: xtreg score_log i.op_com_yet##i.consensus_agree##c.time_from_first_op_com_min c.time_diff_min##c.time_diff_min i.top parent_score comment_competition author_skill comment_length i.hour i.dayofweek, fe vce(cluster postid_encoded)

margins, dydx(consensus_agree) at (op_com_yet = (0 1))
marginsplot, recast(bar)
graph export "/home/jmellody/aita/graphs/rdit.tif", as(tif) replace


************************
* ROBUSTNESS CHECKS
************************

//non-matched sample

//alternative matching strategy	

//FOR PSCORE
eststo ps1: areg score_log c.cs##c.cs##i.consensus_agree i.top comment_length c.time_diff_min##c.time_diff_min comment_competition i.mod_comment author_count i.month [fweight = _weight] if _weight != ., absorb(postid_encoded) vce(cluster postid_encoded)
margins, dydx(consensus_agree) at(cs = (0.1 0.25 0.5 0.75 0.9))
marginsplot, recastci(rarea)

eststo ps2: areg score_log c.certainty##c.current_consensus##i.consensus_agree i.top comment_length c.time_diff_min##c.time_diff_min comment_competition i.mod_comment author_count i.month [fweight = _weight] if _weight != ., absorb(postid_encoded) vce(cluster postid_encoded)
margins, dydx(consensus_agree) at(certainty = (0.1 0.5 0.9) current_consensus = (0.55 0.75 0.95))
marginsplot, by(current_consensus) recastci(rarea)

quietly estadd local postfe "Yes", replace
quietly estadd local hourfe "Yes", replace
quietly estadd local dayofweekfe "Yes", replace
quietly estadd local monthfe "Yes", replace
estimates save reg2, replace
margins, dydx(consensus_agree) at (cs = (0.01 0.25 0.5 0.75 0.99)) saving(margins2, replace)

//only comments before decision is posted

use test_df_19.dta
drop if treated == 1

#REGRESSION

//run with posts with >9 comments

use test_df_9.dta

#REGRESSION

//run without deleted and removed 

use test_df_19.dta

drop if deleted == 1
drop if removed == 1
drop if empty == 1

#REGRESSION

//run with negative scores

//unweighted consensus score

use test_df_19.dta

#REGRESSION WITH UNWEIGHTED

//with net-consensus score

use test_df_19.dta

#REGRESSION WITH NET CONSENSUS SCORE

//with just comment_competition_ln

use test_df_19.dta

#REGRESSION WITH Comment competiiton

//with just cs_majority

use test_df_19.dta

#REGRESSION WITH CS MAJORITY

//with just cs_net

use test_df_19.dta

#REGRESSION WITH CS NET

//alternative model specificaiton --> poisson with smaller sample

use test_df_19.dta

#REGRESSION POISSON






*******************
* OUTPUT TABLE
*******************
estimates use reg1
eststo reg1

estimates use reg2
eststo reg2

estimates use reg3
eststo reg3

//estimates esample:
//margins

esttab reg1 reg2 using reg_table.rtf, mtitle("Baseline" "Matched Sample") coeflabel(_cons "Constant" cs "Consensus Strength" c.cs#c.cs "Consensus Strength * Consensus Strength" 1.consensus_agree "Disagree" 1.consensus_agree#c.cs "Disagree * Consensus Strength" 1.consensus_agree#c.cs#c.cs "Disagree * Consensus Strength * Consensus Strength" 1.top "Top Level Comment" parent_score "Score of Parent Comment" time_diff_min "Time Since Post" c.time_diff_min#c.time_diff_min "Time Since Post * Time Since Post" comment_competition "Comment Competition" author_skill "Author Skill" 1.mod_comment "Mod Comment" comment_length "Comment Length" certainty "Certainty" c.certainty#c.current_consensus "Current Consensus" current_consensus "Certainty * Current Consensus" 1.consensus_agree#c.certainty "Disagree * Certainty" 1.consensus_agree#c.current_consensus "Disagree * Current Consensus" 1.consensus_agree#c.certainty#c.current_consensus "Disagree * Certainty * Current Consensus") stats(postfe hourfe dayofweekfe monthfe N, fmt("%9.0fc") label("Post FE" "Hour FE" "Day of Week FE" "Month FE" "Observations")) drop(*.hour *.month *.dayofweek) noomitted nogaps nobaselevels b(2) se(2) compress replace	













