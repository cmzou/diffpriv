##############
# 
# DP Logistic Regression on HMDA dataset using PrivateLR package
# Averages n models with different epsilon values.
# Implements k-fold cross validation during model averaging, 
# so the actual number of runs is num_runs*k.
# Assumes data has already been filtered and subsetted.
# Outputs:
#   output_r.csv: raw df with columns for 
#     predicted probabilties, true class, eps, id (to keep track of runs), and additional attributes 
#     as specified in the change variables section
#   coef_data.csv: df with coefficients of the models and eps
#
# Variables to be changed are in the process function and before the packages.
# 
##############

### CHANGE VARS HERE (1/2) --------
pkg_loc <- "/home/home2/jmz15/rpackages/" # directory of libraries
write_dir <- "/usr/project/xtmp/output_and_data/" # where outputs are written
data_dir <- "/usr/project/xtmp/output_and_data/" # where data is located
#----------------------------

.libPaths(pkg_loc)

if(!require("optparse")) {
  install.packages("optparse")
  library("optparse")
}
if(!require("PrivateLR")) {
  install.packages("PrivateLR")
  library("PrivateLR")
}
if(!require("readr")) {
  install.packages("readr")
  library("readr")
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
              default=paste0(data_dir, "hmda_gancscva_clean_allraces.csv"),
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
              help="subset the data to about 10%?",
              metavar="character"),
  make_option(c("--coef_file"),
              type="character",
              default=paste0(write_dir, "coef_data", format(Sys.time(), format="%Y-%m-%d_%H-%M-%S"), ".csv"),
              help="filename for coef_data.csv (coefficient data)",
              metavar="character"),
  make_option(c("--out_file"),
              type="character",
              default=paste0(write_dir, "output_r", format(Sys.time(), format="%Y-%m-%d_%H-%M-%S"), ".csv"),
              help="filename for output_r.csv (output file with predicted, true, etc.)",
              metavar="character")
)


# Runs script
process <- function(opt) {
  set.seed(2019)
  
  data <- fread(opt$in_file)
  
  # Want unique identifier for everyone
  if("V1" %in% colnames(data)) {
    colnames(data)[colnames(data)=="V1"] <- "id"
  }
  if("X1" %in% colnames(data)) {
    colnames(data)[colnames(data)=="X1"] <- "id"
  } else {
    data$id <- row.names(data)
  }
  
  # Spaces in column names breaks things
  colnames(data)<-make.names(colnames(data),unique = TRUE)
  
  ### CHANGE VARS HERE (2/2) --------
  # Remove NA? Do not set to FALSE, it hasn't been implemented.
  remove_na <- TRUE
  # Number of k for k-fold cross validation
  k <- 5
  
  # Variables to use in model
  predic <- "action_taken_name"
  explan <- colnames(data)[!(colnames(data) %in% c(predic, "id"))] # get all columns except predic and id
  
  # Categorical variables
  to_factor <- c(predic)
  
  # For fairness - make sure indices match! 
  # We're working so that if possible, 0 is protected and 1 is not protected
  attribute <- c("applicant_race_name_1_Black_or_African_American", 
                 "applicant_race_name_1_White", "applicant_ethnicity_name_Not_Hispanic_or_Latino", 
                 "applicant_sex_name_Male")
  attr_name <- c("race_black", "race_white", "ethni", "sex") # column names of the attributes in the return file
  # ----------------------------
  
  if(opt$subset) {
    temp <- sample(nrow(data), round(nrow(data)*0.10)) # sample 10% of data
    new_d <- data[temp,]
  } else {
    new_d <- data 
  }
  
  # Transform data to factor
  if(length(to_factor) > 0) {
    new_d[, (to_factor) := lapply(.SD, factor), .SDcols = to_factor]
  }
  
  # Specify variables to use in model
  f <- as.formula(
    paste(predic, 
          paste(explan, collapse = " + "), 
          sep = " ~ "))
  
  # Manual k-fold cross validation because can't get all the different models normally
  new_d <- new_d[sample(nrow(new_d)),] # shuffle df
  folds <- cut(seq(1,nrow(new_d)),breaks=k,labels=FALSE) 
  
  print(paste0("---------------Begin----------------", Sys.time()))
  print(paste0("Num rows: ", nrow(new_d), " Num runs: ", opt$num_runs))
  
  # Model averaging
  # Function that creates a model given eps, train df, and test df 
  # Returns a df with the predicted, true, and characteristics that we care about
  create_model <- function(i, eps, train, test) {
    m <- dplr(f,train, eps=eps, op=T,do.scale = T, threshold="0.5")
    p <- m$pred(test, type = "probabilities")
    
    ret <- test
    # Change column names to be used later for evaluation
    ret$pred <- p
    colnames(ret)[colnames(ret)==paste0(predic)] <- "true"
    ret <- ret[, c(attribute, "pred", "true", "id"), with=FALSE] # subsetting columns
    colnames(ret)[colnames(ret) %in% attribute] <- attr_name # renaming columns
    # Add column to indicate which run it is
    ret$run <- i
    
    # Write coefficient information into csv
    fwrite(data.table(t(m$par), eps=eps), opt$coef_file, append = TRUE)
    
    return(ret)
  }
  
  # Function that runs k-fold cross validation manually
  # Args:
  #   eps: which eps to use
  #   df: the full dataset
  #   folds: the indices that are used to separate df into train and test sets
  #   i: the index to indicate which run it is 
  # Returns:
  #   
  cross_validate <- function(i, eps, df, folds) {
    ret <- lapply(1:k, function(j) {
      # Segment df by fold using the which() function 
      idx <- which(folds==j, arr.ind=TRUE)
      test <- df[idx, ]
      train <- df[-idx, ]
      
      m <- create_model(j, eps, train, test)
      return(m)
    })
    
    # Modify output so that it's easier to work with
    ret <- rbindlist(ret)
    
    return(ret)
  }
  
  eps_list <- 2^seq(-8,4)
  many_models <- lapply(eps_list, function(eps) {
    out <- lapply(1:opt$num_runs, cross_validate, eps=eps, df=new_d, folds=folds) # run several times
    
    # Modify output so that it's easier to work with
    out <- rbindlist(out)
    
    # Add column to indicate epsilon used
    out$eps <- eps
    # Modify run column so that it makes more sense (i.e. restarts for each epsilon)
    out$run <- rleid(out$run)
    
    return(out)
  })
  
  print(paste0("---------------End----------------", Sys.time()))
  
  # Convert output to workable output by merging the outputs in the list into one dataframe
  many_data <- rbindlist(many_models)
  
  fwrite(many_data, opt$out_file)
  
  print(summary(many_data)) # we print so that it can be easier to match out file to output csv
}

# Main -- reads in flags and does stuff
main <- function() {
  opt_parser = OptionParser(option_list=option_list);
  opt = parse_args(opt_parser);
  
  process(opt)
}

main()