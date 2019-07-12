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

# .libPaths(pkg_loc)

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
if(!require("data.table")) {
  install.packages("data.table")
  library("data.table")
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
  
  data <- fread(opt$in_file)
  
  colnames(data)<-make.names(colnames(data),unique = TRUE)
  
  ### CHANGE VARS HERE --------
  # Remove NA? Do not set to FALSE, it hasn't been implemented.
  remove_na <- TRUE
  
  # Variables to use in model
  predic <- "action_taken_name"
  explan <- colnames(data)[!(colnames(data) %in% c(predic))] 
  
  # Categorical variables
  to_factor <- c(predic)
  
  # For fairness - make sure indices match!
  attribute <- c("applicant_race_name_1_0", "applicant_ethnicity_name_Hispanic.or.Latino", "applicant_sex_name_Female")
  # ----------------------------
  
  if(opt$subset) {
    new_d <- sample_n(data, 10000)
  } else {
    new_d <- data 
  }
  
  # Filter down columns
  new_d <- new_d[,c(explan, predic), with=FALSE]
  # Remove NA
  if(remove_na) {
    new_d <- new_d[complete.cases(new_d), ]
  }
  # Transform data to factor
  if(length(to_factor) > 0) {
    new_d[, (to_factor) := lapply(.SD, factor), .SDcols = to_factor]
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
    p <- m$pred(test, type = "probabilities")
    
    ret <- test
    # Change column names to be used later for evaluation
    ret$pred <- p
    colnames(ret)[colnames(ret)==paste0(predic)] <- "true"
    ret <- ret[, c(attribute, "pred", "true"), with=FALSE] # subsetting columns
    colnames(ret)[colnames(ret) %in% attribute] <- c("race", "ethni", "sex")
    # Add column to indicate which run it is
    ret$id <- as.numeric(Sys.time())
    
    return(ret)
  }
  
  eps_list <- 2^seq(-8,4)
  many_models <- lapply(eps_list, function(eps) {
    out <- lapply(1:opt$num_runs, create_model, eps=eps) # run several times
    
    # Modify output so that it's easier to work with
    out <- rbindlist(out)
    
    # Add column to indicate epsilon used
    out$eps <- eps
    
    return(out)
  })
  
  print(paste0("---------------End----------------", Sys.time()))
  
  # Convert output to workable output by merging the outputs in the list into one dataframe
  many_data <- rbindlist(many_models)
  
  fwrite(many_data, paste0(write_dir, "output", format(Sys.time(), format= "%Y-%m-%d_%H-%M-%S"), ".csv"))
  
  print(summary(many_data)) # we print so that it can be easier to match out file to output csv
}

# Main -- reads in flags and does stuff
main <- function() {
  opt_parser = OptionParser(option_list=option_list);
  opt = parse_args(opt_parser);
  
  process(opt)
}

main()