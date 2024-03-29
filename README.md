﻿# Protecting Individual Privacy Using Differential Privacy

This repository contains the outputs and code for the Duke Summer Undergraduate Programs in Computer Science project in 2019. 

Additional plots of AUC and disparate impact can be found on this interactive [web app](https://diffpriv-viz.herokuapp.com/).

For a pdf of more feature rankings plots, see [`./Outputs/All_Results.pdf`](https://github.com/cmzou/diffpriv/blob/master/Outputs/All_results.pdf).

We presented our summer research findings at Computer Science Summer Research Poster Session at Duke University. For more details, see [Protecting Individual Privacy Using Differential Privacy Poster](https://www.cs.duke.edu/sites/default/files/2019-08/privacyPoster.pdf).

## Motivation
When it comes to protecting individual privacy, common de-identification methods have their limitations. With relevant background information, an attacker can potentially reconstruct the original dataset with high accuracy. In order to provide a stronger privacy guarantee, the Census Bureau will deploy differential privacy for the 2020 Census.

As previous studies have suggested, however, training with differentially private data can potentially compromise the fairness of machine learning models that make predictions or allocate resources.

We want to find out whether implementing differential privacy would have an impact on the fairness of binary prediction models for housing mortgages.

## Data
The dataset we use is the Home Mortgage Disclosure Act Loan/Application Register (HMDA-LAR) data from 2017. 

In particular, we focus on the loan records from four states: North Carolina, South Carolina, Georgia, and Virginia.

In the full dataset, most of the features we focus on are imbalanced. For instance, the loan outcome is approximately 80% approval and 20% denial. The demographic features we investigate for the fairness aspect of the project are similarly disproportinate<sup id="a1">[1](#f1)</sup>, containing significanly higher number of records of the unprotected groups. 

Therefore, after initial testing with the full dataset, we quickly transitioned to using various balanced datasets<sup id="a2">[2](#f2)</sup>.

## Methods
The dataset is cleaned using `./Preprocessing/Data_Preprocessing.ipynb`.  We balance the dataset by `action_taken_name` and by different protected classes so that we can create a better model and start with unbiased data.

We measure fairness using disparate impact because it has connections to US labor law. We measure disparate impact with respect to approval, false negative, and false positive.

We build classifiers to predict whether an applicant's loan application was accepted or denied. We are using two differentially private packages for machine learning, [Tensorflow Privacy](https://github.com/tensorflow/privacy) and [PrivateLR](https://cran.r-project.org/web/packages/PrivateLR/PrivateLR.pdf) to compare how privacy affects different algorithms. We use neural networks and regularized logistic regression.

We run each algorithm for 6 epsilons, from 2 to 0.0625. For each epsilon, we create 50 models, including stratified 5-fold cross validation to measure variance in outputs.

We use the package [LIME](https://github.com/marcotcr/lime) to aid in neural network interpretation. 

## Results

**Finding #1**:  As a ML model becomes more private, AUC can **decrease** by up to 15%.

**Finding #2**:  When training data is balanced by both action and race, both regression and neural net model **achieve optimal fairness**.

**Finding #3**:  When training with data balanced by action, as privacy guarantee increases, neural net model becomes **more fair**.

**Finding #4**:  As privacy increases, the features that the private neural network deem important **vary more** than the non-private model, potentially showing why accuracy decreases.

## References

C. Dwork and A. Roth (2014), “The Algorithmic Foundations of Differential Privacy”, Foundations and Trends in Theoretical Computer Science: Vol. 9: No. 3–4, pp 211-407. http://dx.doi.org/10.1561/0400000042.

M. Hay, A. Machanavajjhala, G. Miklau, Y. Chen, D. Zhang (2015), “Principled Evaluation of Differentially Private Algorithms using DPBench”, In Proceedings of the 2016 International Conference on Management of Data (SIGMOD '16). ACM, New York, NY, USA, pp 139-154. https://arxiv.org/abs/1512.04817.

S. Kuppam, R. Mckenna, D. Pujol, M. Hay, A. Machanavajjhala, and G. Miklau (2019), “Fair Decision Making using Privacy-Protected Data”. https://arxiv.org/abs/1905.12744.


## Footnotes
<b id="f1">1</b> Imbalanced features and their ratio

| Feature  |unprotected group : protected group| approximate ratio  |
|---|:-:|:-:|
| Race  | White : non-White  | 3 : 1  |
| Ethnicity  | not Hispanic/Latino : Hispanic/Latino  |  18 : 1 |
| Gender  | Male : Female  |  2 : 1 |

[↩](#a1)

<b id="f2">2</b> We have balanced our datasets in the following ways:
* balance by loan outcome (approval/denial)
* balance by race
* balance by ethnicity
* balance by gender
* balance by loan outcome and race

[↩](#a2)
