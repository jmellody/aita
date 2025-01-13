/*

****************************
* #1 MAIN MODEL - WHICH IS MATCHED SAMPLE
****************************

clear
clear matrix
capture log close
set more off


cd "/scratch/network/jm7581/aita/data/"
use aita_data_2022_prepped_matched.dta
sort postid_encoded
xtset postid_encoded

cd "/scratch/network/jm7581/aita/results/"


reghdfe score_log c.cs_majority##c.cs_majority##i.consensus_disagree c.comment_competition_ln c.time_diff_min_ln##c.time_diff_min_ln c.author_skill_ln c.comment_length_ln [aweight = match_weight], absorb(postid_encoded i.hour i.dayofweek i.month) vce(cluster postid_encoded)
quietly estadd local postfe "Yes", replace
quietly estadd local hourfe "Yes", replace
quietly estadd local dayofweekfe "Yes", replace
quietly estadd local monthfe "Yes", replace
estimates save reg_main_1, replace


summarize cs_majority[iweight = match_weight]
local mean = r(mean)
local sd = r(sd)
local low = `mean' - `sd'
local lowlow = `mean' - 2*`sd'
local high = `mean' + `sd'
local highhigh = `mean' + 2*`sd'
margins [iweight = match_weight], dydx(consensus_disagree) at(cs_majority = (`lowlow' `low' `mean' `high' `highhigh')) saving(margins_main_1, replace)



************************
* ROBUSTNESS CHECKS
************************

//non-matched sample
clear
clear matrix
cd "/scratch/network/jm7581/aita/data/"
use aita_data_2022_prepped.dta
drop if cum_score_absolute == 0
bysort postid_encoded: gen numcoms = _N
drop if numcoms < 15
sort postid_encoded
xtset postid_encoded
cd "/scratch/network/jm7581/aita/results/"


xtreg score_log c.cs_majority##c.cs_majority##i.consensus_disagree c.comment_competition_ln c.time_diff_min_ln##c.time_diff_min_ln c.author_skill_ln c.comment_length_ln i.hour i.dayofweek i.month, fe vce(cluster postid_encoded)
quietly estadd local postfe "Yes", replace
quietly estadd local hourfe "Yes", replace
quietly estadd local dayofweekfe "Yes", replace
quietly estadd local monthfe "Yes", replace
estimates save reg_robust_1, replace

summarize cs_majority
local mean = r(mean)
local low = r(mean) - r(sd)
local lowlow = r(mean) - 2*r(sd)
local high = r(mean) + r(sd)
local highhigh = r(mean) + 2*r(sd)
margins, dydx(consensus_disagree) at(cs_majority = (`lowlow' `low' `mean' `high' `highhigh')) saving(margins_robust_1, replace)

//only comments before decision is posted
drop if treated == 1

xtreg score_log c.cs_majority##c.cs_majority##i.consensus_disagree c.comment_competition_ln c.time_diff_min_ln##c.time_diff_min_ln c.author_skill_ln c.comment_length_ln i.hour i.dayofweek i.month, fe vce(cluster postid_encoded)
quietly estadd local postfe "Yes", replace
quietly estadd local hourfe "Yes", replace
quietly estadd local dayofweekfe "Yes", replace
quietly estadd local monthfe "Yes", replace
estimates save reg_robust_2, replace

summarize cs_majority
local mean = r(mean)
local low = r(mean) - r(sd)
local lowlow = r(mean) - 2*r(sd)
local high = r(mean) + r(sd)
local highhigh = r(mean) + 2*r(sd)
margins, dydx(consensus_disagree) at(cs_majority = (`lowlow' `low' `mean' `high' `highhigh')) saving(margins_robust_2, replace)

//run with posts with >9 comments
clear
clear matrix
cd "/scratch/network/jm7581/aita/data/"
use aita_data_2022_prepped.dta
drop if cum_score_absolute == 0
bysort postid_encoded: gen numcoms = _N
drop if numcoms < 10
sort postid_encoded
xtset postid_encoded
cd "/scratch/network/jm7581/aita/results/"

xtreg score_log c.cs_majority##c.cs_majority##i.consensus_disagree c.comment_competition_ln c.time_diff_min_ln##c.time_diff_min_ln c.author_skill_ln c.comment_length_ln i.hour i.dayofweek i.month, fe vce(cluster postid_encoded)
quietly estadd local postfe "Yes", replace
quietly estadd local hourfe "Yes", replace
quietly estadd local dayofweekfe "Yes", replace
quietly estadd local monthfe "Yes", replace
estimates save reg_robust_3, replace

summarize cs_majority
local mean = r(mean)
local low = r(mean) - r(sd)
local lowlow = r(mean) - 2*r(sd)
local high = r(mean) + r(sd)
local highhigh = r(mean) + 2*r(sd)
margins, dydx(consensus_disagree) at(cs_majority = (`lowlow' `low' `mean' `high' `highhigh')) saving(margins_robust_3, replace)


//run without deleted and removed 
clear
clear matrix
cd "/scratch/network/jm7581/aita/data/"
use aita_data_2022_prepped.dta
drop if cum_score_absolute == 0
bysort postid_encoded: gen numcoms = _N
drop if numcoms < 15
sort postid_encoded
xtset postid_encoded
cd "/scratch/network/jm7581/aita/results/"

drop if deleted == 1
drop if removed == 1
drop if empty == 1

xtreg score_log c.cs_majority##c.cs_majority##i.consensus_disagree c.comment_competition_ln c.time_diff_min_ln##c.time_diff_min_ln c.author_skill_ln c.comment_length_ln i.hour i.dayofweek i.month, fe vce(cluster postid_encoded)
quietly estadd local postfe "Yes", replace
quietly estadd local hourfe "Yes", replace
quietly estadd local dayofweekfe "Yes", replace
quietly estadd local monthfe "Yes", replace
estimates save reg_robust_4, replace

summarize cs_majority
local mean = r(mean)
local low = r(mean) - r(sd)
local lowlow = r(mean) - 2*r(sd)
local high = r(mean) + r(sd)
local highhigh = r(mean) + 2*r(sd)
margins, dydx(consensus_disagree) at(cs_majority = (`lowlow' `low' `mean' `high' `highhigh')) saving(margins_robust_4, replace)



//unweighted consensus score
clear
clear matrix
cd "/scratch/network/jm7581/aita/data/"
use aita_data_2022_prepped.dta
drop if cum_score_absolute_unweighted == 0
bysort postid_encoded: gen numcoms = _N
drop if numcoms < 15
sort postid_encoded
xtset postid_encoded
cd "/scratch/network/jm7581/aita/results/"


xtreg score_log c.cs_majority_unweighted##c.cs_majority_unweighted##i.consensus_disagree c.comment_competition_ln c.time_diff_min_ln##c.time_diff_min_ln c.author_skill_ln c.comment_length_ln i.hour i.dayofweek i.month, fe vce(cluster postid_encoded)
quietly estadd local postfe "Yes", replace
quietly estadd local hourfe "Yes", replace
quietly estadd local dayofweekfe "Yes", replace
quietly estadd local monthfe "Yes", replace
estimates save reg_robust_5, replace

summarize cs_majority_unweighted
local mean = r(mean)
local low = r(mean) - r(sd)
local lowlow = r(mean) - 2*r(sd)
local high = r(mean) + r(sd)
local highhigh = r(mean) + 2*r(sd)
margins, dydx(consensus_disagree) at(cs_majority_unweighted = (`lowlow' `low' `mean' `high' `highhigh')) saving(margins_robust_5, replace)

//include 0 cum_score_absolute + 0 cum_score_absolute_unweighted
clear
clear matrix
cd "/scratch/network/jm7581/aita/data/"
use aita_data_2022_prepped.dta
bysort postid_encoded: gen numcoms = _N
drop if numcoms < 15
sort postid_encoded
xtset postid_encoded
cd "/scratch/network/jm7581/aita/results/"

xtreg score_log c.cs_majority##c.cs_majority##i.consensus_disagree c.comment_competition_ln c.time_diff_min_ln##c.time_diff_min_ln c.author_skill_ln c.comment_length_ln i.hour i.dayofweek i.month, fe vce(cluster postid_encoded)
quietly estadd local postfe "Yes", replace
quietly estadd local hourfe "Yes", replace
quietly estadd local dayofweekfe "Yes", replace
quietly estadd local monthfe "Yes", replace
estimates save reg_robust_6, replace

summarize cs_majority
local mean = r(mean)
local low = r(mean) - r(sd)
local lowlow = r(mean) - 2*r(sd)
local high = r(mean) + r(sd)
local highhigh = r(mean) + 2*r(sd)
margins, dydx(consensus_disagree) at(cs_majority = (`lowlow' `low' `mean' `high' `highhigh')) saving(margins_robust_6, replace)



//including all years
clear
clear matrix
cd "/scratch/network/jm7581/aita/data/"
use aita_data_all_prepped.dta
drop if cum_score_absolute == 0
bysort postid_encoded: gen numcoms = _N
drop if numcoms < 15
sort postid_encoded
xtset postid_encoded
cd "/scratch/network/jm7581/aita/results/"

xtreg score_log c.cs_majority##c.cs_majority##i.consensus_disagree c.comment_competition_ln c.time_diff_min_ln##c.time_diff_min_ln c.author_skill_ln c.comment_length_ln i.year i.hour i.dayofweek i.month, fe vce(cluster postid_encoded)
quietly estadd local postfe "Yes", replace
quietly estadd local hourfe "Yes", replace
quietly estadd local dayofweekfe "Yes", replace
quietly estadd local monthfe "Yes", replace
quietly estadd local yearfe "Yes", replace
estimates save reg_robust_7, replace

summarize cs_majority
local mean = r(mean)
local low = r(mean) - r(sd)
local lowlow = r(mean) - 2*r(sd)
local high = r(mean) + r(sd)
local highhigh = r(mean) + 2*r(sd)
margins, dydx(consensus_disagree) at(cs_majority = (`lowlow' `low' `mean' `high' `highhigh')) saving(margins_robust_7, replace)


************************
* Top2Vec Regressions
************************


//topic 0
clear
clear matrix
cd "/scratch/network/jm7581/aita/data/"
use aita_data_all_prepped.dta
drop if cum_score_absolute == 0
bysort postid_encoded: gen numcoms = _N
drop if numcoms < 15
sort postid_encoded
xtset postid_encoded
cd "/scratch/network/jm7581/aita/results/"

drop if posttopic != 0

xtreg score_log c.cs_majority##c.cs_majority##i.consensus_disagree c.comment_competition_ln c.time_diff_min_ln##c.time_diff_min_ln c.author_skill_ln c.comment_length_ln i.hour i.dayofweek i.month i.year, fe vce(cluster postid_encoded)
quietly estadd local postfe "Yes", replace
quietly estadd local hourfe "Yes", replace
quietly estadd local dayofweekfe "Yes", replace
quietly estadd local monthfe "Yes", replace
quietly estadd local yearfe "Yes", replace
estimates save reg_topic_0, replace

summarize cs_majority
local mean = r(mean)
local sd = r(sd)
local low = `mean' - `sd'
local lowlow = `mean' - 2*`sd'
local high = `mean' + `sd'
local highhigh = `mean' + 2*`sd'
margins, dydx(consensus_disagree) at(cs_majority = (`lowlow' `low' `mean' `high' `highhigh')) saving(margins_topic_0, replace)

//topic 1
clear
clear matrix
cd "/scratch/network/jm7581/aita/data/"
use aita_data_all_prepped.dta
drop if cum_score_absolute == 0
bysort postid_encoded: gen numcoms = _N
drop if numcoms < 15
sort postid_encoded
xtset postid_encoded
cd "/scratch/network/jm7581/aita/results/"

drop if posttopic != 1

xtreg score_log c.cs_majority##c.cs_majority##i.consensus_disagree c.comment_competition_ln c.time_diff_min_ln##c.time_diff_min_ln c.author_skill_ln c.comment_length_ln i.hour i.dayofweek i.month i.year, fe vce(cluster postid_encoded)
quietly estadd local postfe "Yes", replace
quietly estadd local hourfe "Yes", replace
quietly estadd local dayofweekfe "Yes", replace
quietly estadd local monthfe "Yes", replace
quietly estadd local yearfe "Yes", replace
estimates save reg_topic_1, replace

summarize cs_majority
local mean = r(mean)
local sd = r(sd)
local low = `mean' - `sd'
local lowlow = `mean' - 2*`sd'
local high = `mean' + `sd'
local highhigh = `mean' + 2*`sd'
margins, dydx(consensus_disagree) at(cs_majority = (`lowlow' `low' `mean' `high' `highhigh')) saving(margins_topic_1, replace)

//topic 2
clear
clear matrix
cd "/scratch/network/jm7581/aita/data/"
use aita_data_all_prepped.dta
drop if cum_score_absolute == 0
bysort postid_encoded: gen numcoms = _N
drop if numcoms < 15
sort postid_encoded
xtset postid_encoded
cd "/scratch/network/jm7581/aita/results/"

drop if posttopic != 2

xtreg score_log c.cs_majority##c.cs_majority##i.consensus_disagree c.comment_competition_ln c.time_diff_min_ln##c.time_diff_min_ln c.author_skill_ln c.comment_length_ln i.hour i.dayofweek i.month i.year, fe vce(cluster postid_encoded)
quietly estadd local postfe "Yes", replace
quietly estadd local hourfe "Yes", replace
quietly estadd local dayofweekfe "Yes", replace
quietly estadd local monthfe "Yes", replace
quietly estadd local yearfe "Yes", replace
estimates save reg_topic_2, replace

summarize cs_majority
local mean = r(mean)
local sd = r(sd)
local low = `mean' - `sd'
local lowlow = `mean' - 2*`sd'
local high = `mean' + `sd'
local highhigh = `mean' + 2*`sd'
margins, dydx(consensus_disagree) at(cs_majority = (`lowlow' `low' `mean' `high' `highhigh')) saving(margins_topic_2, replace)


//topic 3
clear
clear matrix
cd "/scratch/network/jm7581/aita/data/"
use aita_data_all_prepped.dta
drop if cum_score_absolute == 0
bysort postid_encoded: gen numcoms = _N
drop if numcoms < 15
sort postid_encoded
xtset postid_encoded
cd "/scratch/network/jm7581/aita/results/"

drop if posttopic != 3

xtreg score_log c.cs_majority##c.cs_majority##i.consensus_disagree c.comment_competition_ln c.time_diff_min_ln##c.time_diff_min_ln c.author_skill_ln c.comment_length_ln i.hour i.dayofweek i.month i.year, fe vce(cluster postid_encoded)
quietly estadd local postfe "Yes", replace
quietly estadd local hourfe "Yes", replace
quietly estadd local dayofweekfe "Yes", replace
quietly estadd local monthfe "Yes", replace
quietly estadd local yearfe "Yes", replace
estimates save reg_topic_3, replace

summarize cs_majority
local mean = r(mean)
local sd = r(sd)
local low = `mean' - `sd'
local lowlow = `mean' - 2*`sd'
local high = `mean' + `sd'
local highhigh = `mean' + 2*`sd'
margins, dydx(consensus_disagree) at(cs_majority = (`lowlow' `low' `mean' `high' `highhigh')) saving(margins_topic_3, replace)


//topic 4
clear
clear matrix
cd "/scratch/network/jm7581/aita/data/"
use aita_data_all_prepped.dta
drop if cum_score_absolute == 0
bysort postid_encoded: gen numcoms = _N
drop if numcoms < 15
sort postid_encoded
xtset postid_encoded
cd "/scratch/network/jm7581/aita/results/"

drop if posttopic != 4

xtreg score_log c.cs_majority##c.cs_majority##i.consensus_disagree c.comment_competition_ln c.time_diff_min_ln##c.time_diff_min_ln c.author_skill_ln c.comment_length_ln i.hour i.dayofweek i.month i.year, fe vce(cluster postid_encoded)
quietly estadd local postfe "Yes", replace
quietly estadd local hourfe "Yes", replace
quietly estadd local dayofweekfe "Yes", replace
quietly estadd local monthfe "Yes", replace
quietly estadd local yearfe "Yes", replace
estimates save reg_topic_4, replace

summarize cs_majority
local mean = r(mean)
local sd = r(sd)
local low = `mean' - `sd'
local lowlow = `mean' - 2*`sd'
local high = `mean' + `sd'
local highhigh = `mean' + 2*`sd'
margins, dydx(consensus_disagree) at(cs_majority = (`lowlow' `low' `mean' `high' `highhigh')) saving(margins_topic_4, replace)



//topic 5
clear
clear matrix
cd "/scratch/network/jm7581/aita/data/"
use aita_data_all_prepped.dta
drop if cum_score_absolute == 0
bysort postid_encoded: gen numcoms = _N
drop if numcoms < 15
sort postid_encoded
xtset postid_encoded
cd "/scratch/network/jm7581/aita/results/"

drop if posttopic != 5

xtreg score_log c.cs_majority##c.cs_majority##i.consensus_disagree c.comment_competition_ln c.time_diff_min_ln##c.time_diff_min_ln c.author_skill_ln c.comment_length_ln i.hour i.dayofweek i.month i.year, fe vce(cluster postid_encoded)
quietly estadd local postfe "Yes", replace
quietly estadd local hourfe "Yes", replace
quietly estadd local dayofweekfe "Yes", replace
quietly estadd local monthfe "Yes", replace
quietly estadd local yearfe "Yes", replace
estimates save reg_topic_5, replace

summarize cs_majority
local mean = r(mean)
local sd = r(sd)
local low = `mean' - `sd'
local lowlow = `mean' - 2*`sd'
local high = `mean' + `sd'
local highhigh = `mean' + 2*`sd'
margins, dydx(consensus_disagree) at(cs_majority = (`lowlow' `low' `mean' `high' `highhigh')) saving(margins_topic_5, replace)



//topic 6
clear
clear matrix
cd "/scratch/network/jm7581/aita/data/"
use aita_data_all_prepped.dta
drop if cum_score_absolute == 0
bysort postid_encoded: gen numcoms = _N
drop if numcoms < 15
sort postid_encoded
xtset postid_encoded
cd "/scratch/network/jm7581/aita/results/"

drop if posttopic != 6

xtreg score_log c.cs_majority##c.cs_majority##i.consensus_disagree c.comment_competition_ln c.time_diff_min_ln##c.time_diff_min_ln c.author_skill_ln c.comment_length_ln i.hour i.dayofweek i.month i.year, fe vce(cluster postid_encoded)
quietly estadd local postfe "Yes", replace
quietly estadd local hourfe "Yes", replace
quietly estadd local dayofweekfe "Yes", replace
quietly estadd local monthfe "Yes", replace
quietly estadd local yearfe "Yes", replace
estimates save reg_topic_6, replace

summarize cs_majority
local mean = r(mean)
local sd = r(sd)
local low = `mean' - `sd'
local lowlow = `mean' - 2*`sd'
local high = `mean' + `sd'
local highhigh = `mean' + 2*`sd'
margins, dydx(consensus_disagree) at(cs_majority = (`lowlow' `low' `mean' `high' `highhigh')) saving(margins_topic_6, replace)



//topic 7
clear
clear matrix
cd "/scratch/network/jm7581/aita/data/"
use aita_data_all_prepped.dta
drop if cum_score_absolute == 0
bysort postid_encoded: gen numcoms = _N
drop if numcoms < 15
sort postid_encoded
xtset postid_encoded
cd "/scratch/network/jm7581/aita/results/"

drop if posttopic != 7

xtreg score_log c.cs_majority##c.cs_majority##i.consensus_disagree c.comment_competition_ln c.time_diff_min_ln##c.time_diff_min_ln c.author_skill_ln c.comment_length_ln i.hour i.dayofweek i.month i.year, fe vce(cluster postid_encoded)
quietly estadd local postfe "Yes", replace
quietly estadd local hourfe "Yes", replace
quietly estadd local dayofweekfe "Yes", replace
quietly estadd local monthfe "Yes", replace
quietly estadd local yearfe "Yes", replace
estimates save reg_topic_7, replace

summarize cs_majority
local mean = r(mean)
local sd = r(sd)
local low = `mean' - `sd'
local lowlow = `mean' - 2*`sd'
local high = `mean' + `sd'
local highhigh = `mean' + 2*`sd'
margins, dydx(consensus_disagree) at(cs_majority = (`lowlow' `low' `mean' `high' `highhigh')) saving(margins_topic_7, replace)


//topic 8
clear
clear matrix
cd "/scratch/network/jm7581/aita/data/"
use aita_data_all_prepped.dta
drop if cum_score_absolute == 0
bysort postid_encoded: gen numcoms = _N
drop if numcoms < 15
sort postid_encoded
xtset postid_encoded
cd "/scratch/network/jm7581/aita/results/"

drop if posttopic != 8

xtreg score_log c.cs_majority##c.cs_majority##i.consensus_disagree c.comment_competition_ln c.time_diff_min_ln##c.time_diff_min_ln c.author_skill_ln c.comment_length_ln i.hour i.dayofweek i.month i.year, fe vce(cluster postid_encoded)
quietly estadd local postfe "Yes", replace
quietly estadd local hourfe "Yes", replace
quietly estadd local dayofweekfe "Yes", replace
quietly estadd local monthfe "Yes", replace
quietly estadd local yearfe "Yes", replace
estimates save reg_topic_8, replace

summarize cs_majority
local mean = r(mean)
local sd = r(sd)
local low = `mean' - `sd'
local lowlow = `mean' - 2*`sd'
local high = `mean' + `sd'
local highhigh = `mean' + 2*`sd'
margins, dydx(consensus_disagree) at(cs_majority = (`lowlow' `low' `mean' `high' `highhigh')) saving(margins_topic_8, replace)


//topic 9
clear
clear matrix
cd "/scratch/network/jm7581/aita/data/"
use aita_data_all_prepped.dta
drop if cum_score_absolute == 0
bysort postid_encoded: gen numcoms = _N
drop if numcoms < 15
sort postid_encoded
xtset postid_encoded
cd "/scratch/network/jm7581/aita/results/"

drop if posttopic != 9

xtreg score_log c.cs_majority##c.cs_majority##i.consensus_disagree c.comment_competition_ln c.time_diff_min_ln##c.time_diff_min_ln c.author_skill_ln c.comment_length_ln i.hour i.dayofweek i.month i.year, fe vce(cluster postid_encoded)
quietly estadd local postfe "Yes", replace
quietly estadd local hourfe "Yes", replace
quietly estadd local dayofweekfe "Yes", replace
quietly estadd local monthfe "Yes", replace
quietly estadd local yearfe "Yes", replace
estimates save reg_topic_9, replace

summarize cs_majority
local mean = r(mean)
local sd = r(sd)
local low = `mean' - `sd'
local lowlow = `mean' - 2*`sd'
local high = `mean' + `sd'
local highhigh = `mean' + 2*`sd'
margins, dydx(consensus_disagree) at(cs_majority = (`lowlow' `low' `mean' `high' `highhigh')) saving(margins_topic_9, replace)







************************
* CHECKING THE CONSENSUS MEASURE --> FOR USE IN MARGINS.IPYNB
************************

//with prop-consensus score
clear
clear matrix
cd "/scratch/network/jm7581/aita/data/"
use aita_data_2022_prepped_matched.dta
drop if cum_score_absolute == 0
bysort postid_encoded: gen numcoms = _N
drop if numcoms < 15
sort postid_encoded
xtset postid_encoded
cd "/scratch/network/jm7581/aita/results/"

reghdfe score_log c.current_consensus##c.current_consensus##i.consensus_disagree c.comment_competition_ln c.time_diff_min_ln##c.time_diff_min_ln c.author_skill_ln c.comment_length_ln [aweight = match_weight], absorb(postid_encoded i.hour i.dayofweek i.month) vce(cluster postid_encoded)
quietly estadd local postfe "Yes", replace
quietly estadd local hourfe "Yes", replace
quietly estadd local dayofweekfe "Yes", replace
quietly estadd local monthfe "Yes", replace
estimates save reg_concheck_1, replace

summarize current_consensus [iweight = match_weight]
local mean = r(mean)
local low = r(mean) - r(sd)
local lowlow = r(mean) - 2*r(sd)
local high = r(mean) + r(sd)
local highhigh = r(mean) + 2*r(sd)
margins [iweight = match_weight], dydx(consensus_disagree) at(current_consensus = (`lowlow' `low' `mean' `high' `highhigh')) saving(margins_concheck_1, replace)


//with just comment_competition_ln
clear
clear matrix
cd "/scratch/network/jm7581/aita/data/"
use aita_data_2022_prepped_matched.dta
drop if cum_score_absolute == 0
bysort postid_encoded: gen numcoms = _N
drop if numcoms < 15
sort postid_encoded
xtset postid_encoded
cd "/scratch/network/jm7581/aita/results/"


reghdfe score_log c.comment_competition_ln##c.comment_competition_ln##i.consensus_disagree c.time_diff_min_ln##c.time_diff_min_ln c.author_skill_ln c.comment_length_ln [aweight = match_weight], absorb(postid_encoded i.hour i.dayofweek i.month) vce(cluster postid_encoded)
quietly estadd local postfe "Yes", replace
quietly estadd local hourfe "Yes", replace
quietly estadd local dayofweekfe "Yes", replace
quietly estadd local monthfe "Yes", replace
estimates save reg_concheck_3, replace

summarize comment_competition_ln [iweight = match_weight]
local mean = r(mean)
local low = r(mean) - r(sd)
local lowlow = r(mean) - 2*r(sd)
local high = r(mean) + r(sd)
local highhigh = r(mean) + 2*r(sd)
margins [iweight = match_weight], dydx(consensus_disagree) at(comment_competition_ln = (`lowlow' `low' `mean' `high' `highhigh')) saving(margins_concheck_2, replace)


//with just cs_majority
clear
clear matrix
cd "/scratch/network/jm7581/aita/data/"
use aita_data_2022_prepped_matched.dta
drop if cum_score_absolute == 0
bysort postid_encoded: gen numcoms = _N
drop if numcoms < 15
sort postid_encoded
xtset postid_encoded
cd "/scratch/network/jm7581/aita/results/"


reghdfe score_log c.cs_majority##c.cs_majority##i.consensus_disagree c.comment_competition_ln c.time_diff_min_ln##c.time_diff_min_ln c.author_skill_ln c.comment_length_ln [aweight = match_weight], absorb(postid_encoded i.hour i.dayofweek i.month) vce(cluster postid_encoded)
quietly estadd local postfe "Yes", replace
quietly estadd local hourfe "Yes", replace
quietly estadd local dayofweekfe "Yes", replace
quietly estadd local monthfe "Yes", replace
estimates save reg_concheck_4, replace

summarize cs_majority [iweight = match_weight]
local mean = r(mean)
local sd = r(sd)
local low = `mean' - `sd'
local lowlow = `mean' - 2*`sd'
local high = `mean' + `sd'
local highhigh = `mean' + 2*`sd'
margins [iweight = match_weight], dydx(consensus_disagree) at(cs_majority = (`lowlow' `low' `mean' `high' `highhigh')) saving(margins_concheck_3, replace)



*/
