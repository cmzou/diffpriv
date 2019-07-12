# Data

Data is cleaned using a modified version of yyz's preprocessing.

Deleted co_applicant, rate_spread, sequence_number, respondent_id, purchaser_type_name, preapproval_name, msamd_name, hoepa_status_name, edit_status_name, and the other applicant_race_name (except for first) columns because they are not relevant, are too granular, or have many missing values.

Deleted population and number_of_1_to_4_family_units columns due to multicollinearity concerns.

Deleted rows with "Not applicable"/"Information not provided" applicant race/sex/ethnicity because it implies that they are corporations and we don't want missing data.

Deleted Multifamily dwelling from property_type_name since all the income fields were blank.

Deleted rows with denial reason = application incomplete.

Deleted HOEPA loans because there are not many.

One hot encoded action_taken_name to 1 for "loan originated"/"loan purchased"/"loan approved but not accepted" and 0 for "loan denied".

Took natural log of income and loan amount because it looks more normal. Clipped loan amount log(100) < x < log(700) for loan amounts that are more relevant to population.

Took sqrt of minority_population and number_of_owner_occupied_units because it looks more normal.

Removed rows with missing data. 

# Future plans

1. Rerun for all eps values (base 2 instead of 10)
2. Standardize output/data
3. More data

# Files

1. `hmda balance.Rmd`: takes hmda data and creates datasets that are balanced in accept/deny and protected/non-protected classes.
2. `hmda filter for state.ipynb`: filters entire hmda dataset for state
3. `hmda model.Rmd`: creates model and graphs interesting things. currently only works with encoded data
4. `hmda results visualization r.Rmd`: uses outputs from scripts to create cool visualizations. some of the plots in `./output/` are created using this

# Scripts

1. `hmda_privatelr_model_averaging.R`: creates many models and averages them. to be used on command line
2. `hmda_privatelr_script.R`: runs k-fold cross validation. to be used on command line
3. `functions.R`: useful functions for plotting, data filtering, etc. 

Last updated: 7/12/2019