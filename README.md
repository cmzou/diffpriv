# Protecting Individual Privacy Using Differential Privacy

This repository contains the outputs and code for the Duke Summer Undergraduate Programs in Computer Science project in 2019. 

## Motivation
When it comes to protecting individual privacy, common de-identification methods have their limitations. With relevant background information, an attacker can potentially reconstruct the original dataset with high accuracy. In order to provide a stronger privacy guarantee, the Census Bureau will deploy differential privacy for the 2020 Census.

As previous studies have suggested, however, training with differentially private data can potentially compromise the fairness of machine learning models that make predictions or allocate resources.

We want to find out whether implementing differential privacy would have an impact on the fairness of binary prediction models for housing mortgages.

## Data
The dataset we use is the Home Mortgage Disclosure Act Loan/Application Register (HMDA-LAR) data from 2017. 

## Methods
The dataset is cleaned using `insert_file_here.ipynb`. The reasoning can be found in `location`. We balance the dataset by `action_taken_name` and by different protected classes so that we can create a better model and start with unbiased data.

We measure fairness using disparate impact because it has connections to US labor law. We measure disparate impact with respect to approval, false negative, and false positive because we feel that protecting individuals from being falsely denied is important.

We build classifiers to predict whether an applicant's loan application was accepted or denied. We are using two differentially private packages for machine learning, [Tensorflow Privacy](https://github.com/tensorflow/privacy) and [PrivateLR](https://cran.r-project.org/web/packages/PrivateLR/PrivateLR.pdf) to compare how privacy affects different algorithms. We use neural networks and regularized logistic regression.

We run each algorithm for 6 epsilons, from 2 to 0.0625. For each epsilon, we create 50 models, including stratified 5-fold cross validation to measure variance in outputs.

We use the package [LIME](https://github.com/marcotcr/lime) to aid in neural network interpretation. 

## Results

details

## References

C. Dwork and A. Roth (2014), “The Algorithmic Foundations of Differential Privacy”, Foundations and Trends in Theoretical Computer Science: Vol. 9: No. 3–4, pp 211-407. http://dx.doi.org/10.1561/0400000042.

S. Kuppam, R. Mckenna, D. Pujol, M. Hay, A. Machanavajjhala, and G. Miklau (2019), “Fair Decision Making using Privacy-Protected Data”. https://arxiv.org/abs/1905.12744.
