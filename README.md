# aita
Code for preparing and analyzing data for paper "Whether groups value agreement or dissent depends on the strength of consensus"

## Steps to reproduce
Reproduce results by following these steps:

1.	Raw data
2.	Unzip with 01_decompress_files.ipynb. This produces AmItheAsshole_comments.parquet and AmItheAsshole_submissions.parquet. These are the raw comment and submission files.
3.	Run prepare_data.py with each year in turn – can use Mac terminal. The year is the argument. So in mac terminal: so for year = 2013 – 2022, run the following: python prepare_data.py year.
4.	Run combine_year_files.ipynb
5.	Run python prepare_data.py [with no argument]  might want to update so it properly accepts “all.”
6.	SCP files onto the computing cluster.
7.	Run create_data.slurm  this creates the variables in stata
8.	Download 2022 data -> aita_data_2022_prepped.dta and run through matching.ipynb (for some reason get error when do it as a .py file), to produce aita_data_2022_prepped_matched.dt