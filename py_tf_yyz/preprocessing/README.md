# Data Preprocessing
This document focus on the HDMA-LAR data for four states (North Carolina, South Carolina, Georgia, and Virginia) in 2017. Ideally, this data preprocessing process can be applied to data from any state or year.

## Explore data
Initially, the dataset has 1,619,698 rows and 48 columns.

## Reduce rows
TL;DR
1. Remove rows where applicant sex, race, or gender is 'not applicable' or 'not provided'
2. Remove rows where `action_taken_name` is 'withdrawn', 'closed', or pertaining to 'preapproval'
3. Remove rows where `hoepa_status_name` is 'HOEPA loan'

After deleting these rows, the resulting dataset has rows. We have shrinked the dataset by %.

---
The HMDA data contains loan records from both individuals and institutions. The goal of the project is to protect individual privacy and fairness, so records belong to institutions should be removed. Since whether or not a record belongs to an institution is not apparent from the dataset, we need to infer this information from the given features.

Naively, if the demographic features of a record is missing, it is likely that this record does not belong to a natural person. However, 'not applicable' is also used in the case of purchased loans <sup>[1](#myfootnote1)</sup>, according to the [Guide to HMDA Reporting (2018)](https://www.ffiec.gov/hmda/pdf/2018guide.pdf?forcedefault=true). Indeed, more than 90% of the records where demographic information is missing are purchased loans (their corresponding `action_taken_name` is *Loan purchased by institution*). In other words, these rows are likely redundant information since the original loan application (before purchased) may be in the dataset elsewhere.

The goal of the machine learning model is to predict whether or not an applicant will be get a loan. Thus, the applications that are ended prematurely (before the financial institution can make a decision) are deleted. Specifically, we remove rows where `action_taken_name` is 'withdrawn', 'closed', or pertaining to 'preapproval'.

We also take out the records with HOEPA loans, which constitute only about 0.01% (235 out of 1,619,698 rows) of the dataset.

Therefore, we can assume for now that deleting these rows will not have a significant impact on the prediction model.


## Reduce columns
TL;DR
Remove 28 columns

---


## Process numerical features
TL;DR
1. Remove rows where numerical features have values of 0
2. Perform log or square root transformation depending on the original distribution of the feature
3. Normalize all numerical features between 0 and 1 using the MinMaxScaler from Sklean.

---
We first remove rows where the numerical features equal 0. Values of 0 are assumed as errors since they do not make sense in this context. In addition, this step facilitates the data transformations that follows. 

The histogram plots on the original data reveals that the numerical features (except `hud_median_family_income`) is positively skewed; in particular, `applicant_income_000s` and `loan_amount_000s` are most significantly skewed. Based on this observation, we apply log transformation to these two features and square root transformation to the other five features. The `hud_median_family_income` corresponds to the Metropolitian Statistical Area/Metropolitian Divisions (MSA/MD) in the four states. It is a discrete feature, so no transformation is applied.

After the transformations, the numerical data appears normally distributed. We then normalize the features between 0 and 1 using the MinMaxScaler from Sklearn.


## Process categorical features
TL;DR
Binarize categorical features

---
`action_taken_name` is divided into either 'loan approved' or 'loan denied'. A loan is considered denied if its corresponding code is 'Application denied'. On the other hand, a loan is considered 'approved' if the loan is 'originated', 'approved but not accepted', or 'purchased by institution'.

The sensitive demographic features, including the race, ethnicity, and sex of the applicant, are binarized as either 'protected' or 'unprotected'. For instance, in `applicant_sex_name`, 'Female' is the protected class and 'Male' is the unprotected class.

The remaining categorical features are binarized so that the two classes contain similar number of records.

## One-hot encode
Since all the categorical features have been binarized, it is not necessary to one-hot encode the features. The resulting accuracy is almost indistinguishable (differ by around 0.1% in favor of the one-hot encoded version).

---
 <a name="myfootnote1">1</a>: The institution that purchases the loan may not have the information of the applicant (or the co-applicant).
