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
if(!require("data.table")) {
  install.packages("data.table")
  library("data.table")
}
if(!require("parallel")) {
  install.packages("parallel")
  library("parallel")
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
              default=100,
              help="number of models to create (technically * 5)",
              metavar="character"),
  make_option(c("--subset"),
              type="logical",
              default=FALSE,
              help="subset the data to about 10%?",
              metavar="character"),
  make_option(c("--file_add"),
              type="character",
              default=NULL,
              help="name to add to end of output and coef files",
              metavar="character")
)


# Runs script
process <- function(opt) {
  set.seed(2019)
  num_cores <- detectCores()
  
  data <- fread(opt$in_file)
  
  # Want unique identifier for everyone
  if("V1" %in% colnames(data)) {
    data$V1 <- NULL
  }
  if("X1" %in% colnames(data)) {
    data$X1 <- NULL
  } 
  if(!"id" %in% colnames(data)) {
    stop("There should be a unique identifier for each applicant in the input data")
  }
  
  # Spaces in column names breaks things
  colnames(data)<-make.names(colnames(data),unique = TRUE)
  
  ### CHANGE VARS HERE (2/2) --------
  # Remove NA? Do not set to FALSE, it hasn't been implemented.
  remove_na <- TRUE
  # Number of k for k-fold cross validation
  k <- 5
  # Epsilons to test
  eps_list <- 2^seq(-4,1)
  
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
  print(paste0("Num rows: ", nrow(new_d), " Num runs: ", opt$num_runs * 5))
  
  # Model averaging
  # Function that creates a model given eps, train df, and test df 
  # Returns a df with the predicted, true, and characteristics that we care about
  create_model <- function(i, eps, train, test) {
    # op MUST be FALSE if eps==0 (nonprivate)
    if(eps == 0){
      op <- F
      eps_write <- Inf
    } else {
      op <- T
      eps_write <- eps
    }
    
    m <- dplr(f,train, eps=eps, op=op,do.scale = T, threshold="0.5", lambda = 0.001)
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
    coef_file <- paste0(write_dir, "coef_", opt$num_runs * 5, "runs_", 
                        nrow(new_d), "rows_", opt$file_add, ".csv")
    fwrite(data.table(t(m$par), eps=eps_write), coef_file, append = TRUE)
    
    return(ret)
  }
  
  # Function that runs k-fold cross validation manually
  # Manually doing so because we want the class attributes for fairness calculations later
  # Args:
  #   eps: which eps to use
  #   df: the full dataset
  #   folds: the indices that are used to separate df into train and test sets
  #   i: the index to indicate which run it is 
  # Returns:
  #   df with columns true, predic, and other attributes
  cross_validate <- function(i, eps, df, folds) {
    ret <- mclapply(1:k, function(j) {
      # Segment df by fold using the which() function 
      idx <- which(folds==j, arr.ind=TRUE)
      test <- df[idx, ]
      train <- df[-idx, ]
      
      m <- create_model(j, eps, train, test)
      return(m)
    },mc.cores = num_cores)
    
    # Modify output so that it's easier to work with
    ret <- rbindlist(ret)
    
    acc <- table(ret$true == as.numeric(ret$pred >= 0.5))
    acc <- acc["TRUE"] / (acc["FALSE"] + acc["TRUE"])
    print(paste0("--------run_5=", i, " eps=", eps, " acc=", acc, "-------", Sys.time()))
    
    return(ret)
  }
  
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
  
  # Nonprivate version -- don't need to run many times since nonprivate is deterministic
  nonprivate_m <- cross_validate(0, 0, new_d, folds)
  nonprivate_m$eps <- Inf
  
  print(paste0("---------------End----------------", Sys.time()))
  
  # Convert output to workable output by merging the outputs in the list into one dataframe
  many_data <- rbindlist(many_models)
  
  many_data <- rbind(many_data, nonprivate_m)
  
  out_file <- paste0(write_dir, "output_r_", opt$num_runs * 5, "runs_", 
                     nrow(new_d), "rows_", opt$file_add,
                     format(Sys.time(), format="%Y-%m-%d_%H-%M-%S"), ".csv")
  fwrite(many_data, out_file)
  
  summary(many_data) # so we can more easily match files
}

# Main -- reads in flags and does stuff
main <- function() {
  opt_parser = OptionParser(option_list=option_list);
  opt = parse_args(opt_parser);
  
  process(opt)
}

main()