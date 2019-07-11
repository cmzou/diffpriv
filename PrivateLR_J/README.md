# Data

Deleted rows with "Not applicable" applicant race/sex/ethnicity because it implies that they are corporations.

Deleted Multifamily dwelling from property_type_name since all the income fields were blank.

Took natural log of income and loan amount. Clipped loan amount e^4 < x < e^7 for loan amounts that are more relevant to population.

# Scripts

1. `hmda balance.Rmd`: R, takes hmda data and creates datasets that are balanced in accept/deny and protected/non-protected classes.
2. `hmda filter for state.ipynb`: Python, filters entire hmda dataset for state
3. `hmda model.Rmd`: creates model and graphs interesting things. currently only works with encoded data
4. `hmda_privatelr_model_averaging.R`: creates many models and averages them. to be used on commandline
5. `hmda_privatelr_script.R`: runs k-fold cross validation. to be used on commandline