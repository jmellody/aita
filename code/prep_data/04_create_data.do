clear
clear matrix
capture log close
set more off

cd "/scratch/network/jm7581/aita/data/"

*****************
* CREATE 2022
*****************

use "aita_data_2022.dta"

// GENERATE VARIABLES
gen time_diff_min_ln = log(time_diff_min)
gen score_log = log(score)
gen comment_length_ln = log(comment_length)
lnskew0 author_skill_ln = author_skill
gen comment_competition_ln = log(comment_competition + 1)
gen cs_majority = comment_competition_ln * current_consensus
gen cs_majority_unweighted = comment_competition_ln * current_consensus_unweighted
gen consensus_disagree = 1 - consensus_agree

save aita_data_2022_prepped.dta, replace


*****************
* CREATE ALL
*****************

use "aita_data_all.dta"


// GENERATE VARIABLES
gen time_diff_min_ln = log(time_diff_min)
gen score_log = log(score)
gen comment_length_ln = log(comment_length)
lnskew0 author_skill_ln = author_skill
gen comment_competition_ln = log(comment_competition + 1)
gen cs_majority = comment_competition_ln * current_consensus
gen cs_majority_unweighted = comment_competition_ln * current_consensus_unweighted
gen consensus_disagree = 1 - consensus_agree

save aita_data_all_prepped.dta, replace





