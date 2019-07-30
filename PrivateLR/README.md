# Files

## `hmda_privatelr_model_averaging.R`

### Description

Creates many nonprivate and private regularized logistic regression models with different values of epsilon and averages them. Includes stratified k-fold cross validation as separate runs. To be used on command line. Utilizes parallel processing.

We use objective perturbation and a regularizer of 0.001. We use 0.001 because it is the default regularizer for the nonprivate model.

We use 5-fold cross validation. We use epsilons from [2, 0.0625] in powers of 2 because they are reasonable epsilons in real life settings.

### Outputs

1. `output_r.csv`: raw df with columns for predicted probabilties (pred), true class (true), epsilon (eps), id (to keep track of runs), and additional attributes as specified in the change variables section in the file
2. `coef_data.csv`: csv with the model coefficients and the epsilon of the model

### Arguments

1. `in_file`: name of the input data file
2. `num_runs`: number of runs for each epsilon, technically equal to num_runs * k since we include the k-fold results as a run, but the nonprivate model is deterministic, so we only run it k times.
3. `subset`: use a subset, 10%, of the data
4. `file_add`: name to add to the end of output and coefficient files, used to distinguish files

## `Output_coef.ipynb`

### Description

File that creates the plots from `../Outputs/Logistic_Coefficient_Results.pdf`. Takes in coefficient data, with each row as the coefficient values, and plots them to examine variation.