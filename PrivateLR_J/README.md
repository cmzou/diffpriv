# Data

Data is cleaned using yyz's preprocessing.

# Future plans

1. Rerun on balanced data

# Files

1. `hmda balance.Rmd`: takes hmda data and creates datasets that are balanced in accept/deny and protected/non-protected classes.
2. `hmda filter for state.ipynb`: filters entire hmda dataset for state

# Scripts

1. `hmda_privatelr_model_averaging.R`: creates many models and averages them. to be used on command line
2. `hmda_privatelr_script.R`: runs k-fold cross validation. to be used on command line
3. `functions.R`: useful functions for plotting, data filtering, etc. 

Last updated: 7/16/2019