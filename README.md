# diffpriv

## Motivation
When it comes to protecting individual privacy, common de-identification methods have their limitations. With relevant background information, an attacker can potentially reconstruct the original dataset with high accuracy. In order to provide a stronger privacy guarantee, the Census Bureau will deploy differential privacy for the 2020 Census.

As previous studies have suggested, however, training with differentially private data can potentially compromise the fairness of machine learning models that make predictions or allocate resources.

We want to find out whether implementing differential privacy would have an impact on the fairness of binary prediction models for housing mortgages.

## Data
The dataset we use is the Home Mortgage Disclosure Act Loan/Application Register (HMDA-LAR) data from 2017.

## Methods
We build classifiers to predict whether an applicant's loan application was accepted or denied. We are using two differentially private packages for machine learning, Tensorflow Privacy and PrivateLR. 