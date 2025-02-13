# aita
Code for preparing and analyzing data for paper "Whether groups value agreement or dissent depends on the strength of consensus" which uses data from Reddit's r/AmItheAsshole (AITA) subreddit.

## Reproduce results with the steps below. Before running code, be sure to change paths.

### Prepare data. Files in `code/prep_data/`

1. Run `code/prep_data/01_decompress_files.ipynb` to unzip compressed data files. This produces AmItheAsshole_comments.parquet and AmItheAsshole_submissions.parquet.
2. Run `code/prep_data/02_prepare_data.py` with the year (i.e., one of 2013 - 2022) as the argument to the script to prepare intermediate comment files for each year (AITA_comments_intermediate_YEAR.parquet) as well as final STATA data files for each year (aita_data_YEAR.dta).
3. Run `code/prep_data/03_combine_year_files.ipynb` to combine the intermediate year files into one file (AITA_comments_intermediate_all.parquet).
4. Run `code/prep_data/02_prepare_data.py` again with "all" as the argument to prepare dataset for all years (aita_data_all.dta).
5. Run `code/prep_data/04_create_data.do` to create additional variables and dataset for analyses.
6. Run `code/prep_data/05_matching.ipynb` with 2022 data (aita_data_2022_prepped.dta) to produce matched data for the 2022 year (aita_data_2022_prepped_matched.dta)

### Analyze data. Files in `code/analyze_data/`

1. Run `code/analyze_data/01_main_models_final.do` to run all main models and save results.
2. Run `code/analyze_data/02_rdit.do` to run the Regression Discontinuity in Time Analysis.
3. Run `code/analyze_data/03_tables.do` to create all the tables as LaTeX output.