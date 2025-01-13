********************
* CORRELATION TABLE AND DESCRIPTIVE STATS
********************
clear
clear matrix
capture log close
set more off


cd "/scratch/network/jm7581/aita/data/"
use aita_data_2022_prepped_matched.dta
sort postid_encoded
xtset postid_encoded
cd "/scratch/network/jm7581/aita/results/"

drop if match_weight == 0


* DESCRIPTIVE STATISTICS TABLE
label variable comment_competition "Comment Competition"
label variable comment_length "Comment Length"
label variable author_skill "Author Score"
label variable time_diff_min "Minutes Since Post"
label variable cs_majority "Consensus Strength"
label variable consensus_disagree "Consensus Dissent"

estpost summarize comment_competition comment_length author_skill time_diff_min cs_majority consensus_disagree

esttab using descriptive_table.tex, cells("mean(fmt(a3)) sd(fmt(a3)) min(fmt(a3)) max(fmt(a3))") label collabels("Mean" "SD" "Min" "Max") nonote nonumber replace nofloat

* CORRELATION TABLE
label variable comment_competition_ln "1"
label variable comment_length_ln "2"
label variable author_skill_ln "3"
label variable time_diff_min_ln "4"
label variable cs_majority "5"
label variable consensus_disagree "6"

estpost correlate comment_competition_ln comment_length_ln author_skill_ln time_diff_min_ln cs_majority consensus_disagree, matrix listwise

esttab using correlation_table.tex, unstack not noobs compress nonumber nostar coeflabels(comment_competition_ln " (1) Comment Competition (ln)" comment_length_ln "(2) Comment Length (ln)" author_skill_ln "(3) Author Score (ln)" time_diff_min_ln "(4) Mintes Since Post (ln)" cs_majority "(5) Consensus Strength (ln)" consensus_disagree "(6) Consensus Dissent") label nogaps width(\hsize) replace nofloat




******************************
* MATCHING BALANCE TABLE
******************************
clear
clear matrix
capture log close
set more off

cd "/scratch/network/jm7581/aita/data/"
use aita_data_2022_prepped_matched.dta
sort postid_encoded
xtset postid_encoded
cd "/scratch/network/jm7581/aita/results/"

drop if match_weight == 0


label variable comment_competition_ln "Comment Competition (ln)"
label variable comment_length_ln "Comment Length (ln)"
label variable author_skill_ln "Author Score (ln)"
label variable time_diff_min_ln "Minutes Since Post (ln)"
label variable cs_majority "Consensus Strength"

eststo precontrol : estpost summarize comment_competition_ln comment_length_ln author_skill_ln time_diff_min_ln cs_majority if consensus_disagree == 0
eststo pretreatment : estpost summarize comment_competition_ln comment_length_ln author_skill_ln time_diff_min_ln cs_majority if consensus_disagree == 1

eststo postcontrol : estpost summarize comment_competition_ln comment_length_ln author_skill_ln time_diff_min_ln cs_majority [iweight = match_weight] if consensus_disagree == 0
eststo posttreatment : estpost summarize comment_competition_ln comment_length_ln author_skill_ln time_diff_min_ln cs_majority [iweight = match_weight] if consensus_disagree == 1


esttab precontrol pretreatment postcontrol posttreatment using balance_table.tex, cells("mean sd") label star(* 0.10 ** 0.05 *** 0.01) replace mtitles("Pre-Match Agree" "Pre-Match Dissent" "Post-Match Agree" "Post-Match Dissent") nonum


******************************
* REGRESSION TABLES
******************************


clear
clear matrix
capture log close
set more off

cd "/scratch/network/jm7581/aita/results/"


//main regression

estimates use "reg_main_1.ster"
estimates store main_model

esttab main_model using main_regs.tex, stats(postfe hourfe dayofweekfe monthfe N, fmt("%9.0fc") label("Post FE" "Hour FE" "Day of Week FE" "Month FE" "Observations")) b(%9.3f) se(%9.3f) nogaps star(* 0.05 ** 0.01 *** 0.001) replace nofloat varlabels(_cons "Constant" cs_majority "Consensus Strength" 1.consensus_disagree "Dissent" c.cs_majority#c.cs_majority "Consensus Strength^2" 1.consensus_disagree#c.cs_majority "Consensus Strength $\times$ Dissent" 1.consensus_disagree#c.cs_majority#c.cs_majority "Consensus Strength^2 $\times$ Dissent" comment_competition_ln "Comment Competition (ln)" time_diff_min_ln "Min Since Post (ln)" c.time_diff_min_ln#c.time_diff_min_ln "Min Since Post (ln)^2" author_skill_ln "Author Score (ln)" comment_length_ln "Comment Length (ln)") nobaselevels nomtitle addnote("\begin{minipage}{12cm} \vspace{0.1cm} \small Note: Standard errors in parentheses are clustered at the post level. Dependent variable is logged comment score. Estimates are from a regression using 2022 data with weights from coarsened exact matching. * p$<$0.05, ** p$<$0.01, *** p$<$0.001 (two-tailed tests). \end{minipage}") nonotes


//rdit table

estimates use "rdit_1.ster"
estimates store rdit_model

esttab rdit_model using rdit_regs.tex, drop(*.hour *.dayofweek *.month *.year) stats(postfe hourfe dayofweekfe monthfe yearfe N, fmt("%9.0fc") label("Post FE" "Hour FE" "Day of Week FE" "Month FE" "Year FE" "Observations")) b(%9.3f) se(%9.3f) nogaps star(* 0.05 ** 0.01 *** 0.001) replace nofloat varlabels(_cons "Constant" 1.op_com_yet "OP Commented" time_from_first_op_com_min "Min Since OP Com" 1.op_com_yet#c.time_from_first_op_com_min "Min Since OP Com $\times$ OP Commented" 1.consensus_disagree#c.time_from_first_op_com_min "Min Since OP Com $\times$ Dissent" 1.op_com_yet#1.consensus_disagree#c.time_from_first_op_com_min "Min Since OP Com $\times$ OP Commented $\times$ Dissent" 1.consensus_disagree "Dissent" 1.op_com_yet#1.consensus_disagree "OP Commented $\times$ Dissent" comment_competition_ln "Comment Competition (ln)" time_diff_min_ln "Min Since Post (ln)" c.time_diff_min_ln#c.time_diff_min_ln "Min Since Post (ln)^2" author_skill_ln "Author Score (ln)" comment_length_ln "Comment Length (ln)") nobaselevels nomtitle addnote("\begin{minipage}{12cm} \vspace{0.1cm} \small Note: Standard errors in parentheses are clustered at the post level. Dependent variable is logged comment score. Estimates are from regression discontinuity in time analysis. * p$<$0.05, ** p$<$0.01, *** p$<$0.001 (two-tailed tests). \end{minipage}") nonotes



// robustness regressions



estimates use "reg_robust_1.ster"
estimates store reg_robust_1

estimates use "reg_robust_2.ster"
estimates store reg_robust_2

estimates use "reg_robust_3.ster"
estimates store reg_robust_3

estimates use "reg_robust_4.ster"
estimates store reg_robust_4

estimates use "reg_robust_5.ster"
estimates store reg_robust_5

estimates use "reg_robust_6.ster"
estimates store reg_robust_6

estimates use "reg_robust_7.ster"
estimates store reg_robust_7



esttab reg_robust_1 reg_robust_2 reg_robust_3 reg_robust_4 reg_robust_5 reg_robust_6 reg_robust_7 using robust_regs.tex, drop(*.hour *.dayofweek *.month *.year) stats(postfe hourfe dayofweekfe monthfe yearfe N, fmt("%9.0fc") label("Post FE" "Hour FE" "Day of Week FE" "Month FE" "Year FE" "Observations")) b(%9.3f) se(%9.3f) nogaps star(* 0.05 ** 0.01 *** 0.001) replace nofloat  varlabels(_cons "Constant" cs_majority "Consensus Strength" 1.consensus_disagree "Dissent" c.cs_majority#c.cs_majority "Consensus Strength^2" cs_majority_unweighted "Consensus Strength Raw" c.cs_majority_unweighted#c.cs_majority_unweighted "Consensus Strength Raw^2" 1.consensus_disagree#c.cs_majority_unweighted "Consensus Strength Raw $\times$ Dissent" 1.consensus_disagree#c.cs_majority_unweighted#c.cs_majority_unweighted "Consensus Strength Raw^2 $\times$ Dissent" 1.consensus_disagree#c.cs_majority "Consensus Strength $\times$ Dissent" 1.consensus_disagree#c.cs_majority#c.cs_majority "Consensus Strength^2 $\times$ Dissent" comment_competition_ln "Comment Competition (ln)" time_diff_min_ln "Min Since Post (ln)" c.time_diff_min_ln#c.time_diff_min_ln "Min Since Post (ln)^2" author_skill_ln "Author Score (ln)" comment_length_ln "Comment Length (ln)") nobaselevels mtitles("Non-Matched" "Pre-18 Hours" "$>$9 Comments" "w/o Deleted/Removed Posts" "Unweighted Consensus" "w/ Balanced Consensus Comments" "All Years") addnote("\begin{minipage}{28cm} \vspace{0.1cm} \small Note: Standard errors in parentheses are clustered at the post level. Dependent variable is logged comment score. Estimates are from regressions with each of the following data semples: (1) non-matched sample from 2022, (2) with only comments made before 18 hours after the post, (3) including posts with a minimum comment threshold of 9, (4) without posts that were deleted or removed, (5) using an unweighted consensus strength, (6) including comments made when the consensus was 0, (7) and including all years. * p$<$0.05, ** p$<$0.01, *** p$<$0.001 (two-tailed tests). \end{minipage}") nonotes


// Topic Regressions


estimates use "reg_topic_0.ster"
estimates store reg_topic_0
quietly estadd local yearfe "Yes", replace


estimates use "reg_topic_1.ster"
estimates store reg_topic_1
quietly estadd local yearfe "Yes", replace

estimates use "reg_topic_2.ster"
estimates store reg_topic_2
quietly estadd local yearfe "Yes", replace

estimates use "reg_topic_3.ster"
estimates store reg_topic_3
quietly estadd local yearfe "Yes", replace

estimates use "reg_topic_4.ster"
estimates store reg_topic_4
quietly estadd local yearfe "Yes", replace

estimates use "reg_topic_5.ster"
estimates store reg_topic_5
quietly estadd local yearfe "Yes", replace

estimates use "reg_topic_6.ster"
estimates store reg_topic_6
quietly estadd local yearfe "Yes", replace

estimates use "reg_topic_7.ster"
estimates store reg_topic_7
quietly estadd local yearfe "Yes", replace

estimates use "reg_topic_8.ster"
estimates store reg_topic_8
quietly estadd local yearfe "Yes", replace

estimates use "reg_topic_9.ster"
estimates store reg_topic_9
quietly estadd local yearfe "Yes", replace


esttab reg_topic_0 reg_topic_1 reg_topic_2 reg_topic_3 reg_topic_4 reg_topic_5 reg_topic_6 reg_topic_7 reg_topic_8 reg_topic_9  using topic_regs.tex, drop(*.hour *.dayofweek *.month *.year) stats(postfe hourfe dayofweekfe monthfe yearfe N, fmt("%9.0fc") label("Post FE" "Hour FE" "Day of Week FE" "Month FE" "Year FE" "Observations")) b(%9.3f) se(%9.3f) nogaps star(* 0.05 ** 0.01 *** 0.001) replace nofloat  varlabels(_cons "Constant" cs_majority "Consensus Strength" 1.consensus_disagree "Dissent" c.cs_majority#c.cs_majority "Consensus Strength^2" 1.consensus_disagree#c.cs_majority "Consensus Strength $\times$ Dissent" 1.consensus_disagree#c.cs_majority#c.cs_majority "Consensus Strength^2 $\times$ Dissent" comment_competition_ln "Comment Competition (ln)" time_diff_min_ln "Min Since Post (ln)" c.time_diff_min_ln#c.time_diff_min_ln "Min Since Post (ln)^2" author_skill_ln "Author Score (ln)" comment_length_ln "Comment Length (ln)") nobaselevels mtitles("Health" "Neighbors" "Money" "Events" "Chores" "Dating" "Bigotry" "Social Media" "School" "Work") addnote("\begin{minipage}{23cm} \vspace{0.1cm} \small Note: Standard errors in parentheses are clustered at the post level. Dependent variable is logged comment score. Estimates are from regressions with data subsetted to each of the following topics: health, neighbors, money, events, chores, dating, bigotry, social media, school, and work. * p$<$0.05, ** p$<$0.01, *** p$<$0.001 (two-tailed tests). \end{minipage}") nonotes

