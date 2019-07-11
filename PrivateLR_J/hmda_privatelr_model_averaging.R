##############
# 
# DP Logistic Regression on HMDA dataset using PrivateLR package
# Averages n models with different epsilon values.
# Outputs:
#   average_data.csv: coefficients, accuracy, and auc for all runs
# 
##############

pkg_loc <- "/home/home2/jmz15/rpackages/" # directory of libraries
write_dir <- "/usr/project/xtmp/output_and_data/" # where outputs are written
data_dir <- "/usr/project/xtmp/output_and_data/" # where data is located

.libPaths(pkg_loc)

if(!require("optparse")) {
  install.packages("optparse")
  library("optparse")
}
if(!require("PrivateLR")) {
  install.packages("PrivateLR")
  library("PrivateLR")
}
if(!require("dplyr")) {
  install.packages("dplyr")
  library("dplyr")
}
if(!require("readr")) {
  install.packages("readr")
  library("readr")
}
if(!require("caret")) {
  install.packages("caret")
  library("caret")
}

# Packages also needed
# e1071, latest colorspace, rlang

# Flags
option_list = list(
  make_option(c("-if", "--in_file"),
              type="character",
              default=paste0(data_dir, "hmda_nc_noencode.csv"),
              help="name of input data file",
              metavar="character"),
  make_option(c("--num_runs"),
              type="numeric",
              default=500,
              help="number of models to create",
              metavar="character"),
  make_option(c("--subset"),
              type="logical",
              default=FALSE,
              help="subset the data to about 10,000 points?",
              metavar="character")
)


# Runs script
process <- function(opt) {
  set.seed(2019)
  
  data <- read_csv(opt$in_file)
  
  ### CHANGE VARS HERE --------
  # Remove NA? Do not set to FALSE, it hasn't been implemented.
  remove_na <- TRUE
  
  # Variables to use in model
  predic <- "loan_status"
  explan <- c("tract_to_msamd_income", 
              "number_of_owner_occupied_units", 
              "minority_population",
              "loan_amount_000s",
              "hud_median_family_income_000s",
              "applicant_income_000s",
              "property_type_name", "loan_type_name", "loan_purpose_name",
              "lien_status_name", "applicant_sex_name", "applicant_race_name_1",
              "applicant_ethnicity_name")
  
  # Categorical variables
  to_factor <- c("loan_status", "property_type_name", "loan_type_name",
                 "loan_purpose_name",
                 "lien_status_name", "applicant_sex_name", "applicant_race_name_1",
                 "applicant_ethnicity_name")
  
  # For fairness - make sure indices match!
  attribute <- c("applicant_race_name_1", "applicant_ethnicity_name", "applicant_sex_name")
  protected <- c("'Black or African American'", "'Hispanic or Latino'", "'Female'") # need single quotes
  not_protected <- c("'White'", "'Not Hispanic or Latino'", "'Male'") # need single quotes
  ########################
  
  if(opt$subset) {
    new_d <- sample_n(data, 10000)
  } else {
    new_d <- data 
  }
  
  # Filter down columns
  new_d <- new_d %>% 
    select(explan, predic) 
  # Remove NA
  if(remove_na) {
    new_d <- new_d[complete.cases(new_d), ]
  }
  # Transform data to factor
  if(length(to_factor) > 0) {
    new_d[to_factor] <- lapply(new_d[to_factor], as.factor)
  }
  
  # Split into test and train - 80/20
  n_samps <- floor(0.8 * nrow(new_d))
  idx <- sample(seq_len(nrow(new_d)), size = n_samps)
  train <- new_d[idx, ]
  test <- new_d[-idx, ]
  
  # Specify variables to use in model
  f <- as.formula(
    paste(predic, 
          paste(explan, collapse = " + "), 
          sep = " ~ "))
  
  print(paste0("---------------Begin----------------", Sys.time()))
  print(paste0("Num rows: ", nrow(new_d), " Num runs: ", opt$num_runs))
  
  # Model averaging
  # The i does nothing.
  # Returns vector of useful info
  create_model <- function(i, eps) {
    m <- dplr(f,train, eps=eps, op=T,do.scale = T, threshold="0.5")
    p <- m$pred(test, type = "class")
    cm <- confusionMatrix(as.factor(p), test$loan_status)
    copy = test %>% dplyr::select(loan_status, attribute) # dont want to modify test
    copy$predicted = p
    ret <- c(m$coefficients, m$CIndex, cm$overall["Accuracy"], cm$table) # add in confusion matrix stuff
    names(ret) <- c(names(ret)[1:(length(ret)-4)], "TrueN", "FalseP", "FalseN", "TrueP") # add row names
    
    # Calculate fairness
    f <- lapply(1:length(attribute), function(i) {
      only_prot <- copy %>% 
        filter_(paste0(attribute[i], "==", protected[i]))
      not_prot <- copy %>% 
        filter_(paste0(attribute[i], "==", not_protected[i]))
      
      cm_prot <- confusionMatrix(only_prot$predicted, only_prot$loan_status)
      cm_nprot <- confusionMatrix(not_prot$predicted, not_prot$loan_status)
      
      ret <- c(cm_prot$table, cm_nprot$table)
      p <- paste0(c("TN", "FP", "FN", "TP"), sep=paste0("prot", attribute[i]))
      np <- paste0(c("TN", "FP", "FN", "TP"), sep=paste0("nprot", attribute[i]))
      names(ret) <- c(p,np)
      return(ret)
    })
    
    ret <- append(ret, unlist(f))
    return(ret)
  }
  
  eps_list <- c(0.00001, 0.0001, 0.001, 0.01, 0.1, 1, 10, 100, 1000)
  many_models <- lapply(eps_list, function(eps) {
    out <- sapply(1:opt$num_runs, create_model, eps=eps) # run several times
    
    # Modify output so that it's easier to work with
    out <- data.frame(t(out))
    
    # Add column to indicate epsilon used
    out$eps <- eps
    
    return(out)
  })
  
  print(paste0("---------------End----------------", Sys.time()))
  
  # Convert output to workable output by merging the outputs in the list into one dataframe
  many_data <- do.call(rbind, many_models)
  
  write_csv(many_data, paste0(write_dir, "average_data", format(Sys.time(), format= "%Y-%m-%d_%H-%M-%S"), ".csv"))
  
  print(summary(many_data)) # we print so that it can be easier to match out file to output csv
}

# Main -- reads in flags and does stuff
main <- function() {
  opt_parser = OptionParser(option_list=option_list);
  opt = parse_args(opt_parser);
  
  process(opt)
}

main()