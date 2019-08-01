# Outputs (scripts for generating csv and plots)

For this project, we are using two different machine learning software: logistic regression using R (privacy package: privacyLR) and neural nets using TensorFlow (privacy package: TensorFlow Privacy).

In order to facilitate comparison and analysis, we transform our machine learning results into a result csv file that looks like this:  

race|ethni|sex|pred|true|id|run|eps
----|-----|---|----|----|--|---|---
 0  | 1   | 1 |0.474850754204739|1|256226|1|inf
 

`race` (applicant race), `ethni` (applicant ethnicity), and `sex` (applicant gender) takes either 1 or 0, where 1 stands for the unprotected group and 0 stands for the protected group.

`pred` is the predicted probability of being approved for a loan, and `true` is the truth value where 1 stands for being approved for a loan application and 0 stands for being denied.

`id` is a unique identification number for each applicant. This is included to faciliate comparison across models (so that we can compare the predictions made by different models for one applicant).

`run` value stands for the ith run. We run each machine learning model 10 times with a stratified 5-fold cross validation. `eps` is the epsilon value at this paticular run.

A csv file like this can contain almost a million rows.

Initially, I created plots directly using these large csv files. I would calculate all the results (the mean and variance of various accuracy and fairness metrics for each epsilon across all the runs) and store them in high dimensional lists (lists of lists of lists). Then I would loop through these lists to produce different plots.

This approach has the following major issues:
1. Since the lists are not saved, I have to re-run the calculations everytime when I re-open the script. Considering the size of the input csv file, it usually takes a long time to finish all the calculations.
2. High dimensional lists can be quite confusing, especially for others who are reviewing the code. (As a result, I decided not to upload the first plotting scripts.)

Therefore, to make the process more efficient and intuitive, I decided to make the following changes:
1. Instead of using high dimensional lists to store my calculated results, I store them directly as dataframe and export the results as a summary csv file. This summary csv file contains only 7 rows, each row corresponding to a different epsilon value. Not only is the csv file much smaller, but the dataframe approach also makes plotting extremely intuitive (since the x-axis of the plots are epsilon values).
2. To make the plots easier to read, I added color gradient to facilitate understanding of the epsilon values and their relation to privacy. I also added comparison plots where users can compare metrics or features side by side.
