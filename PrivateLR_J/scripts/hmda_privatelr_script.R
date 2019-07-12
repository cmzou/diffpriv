##############
# 
# DP Logistic Regression on HMDA dataset using PrivateLR package
# Implements k-fold cross validation with different epsilon values and threshold types
# Outputs three things: 
#   results.csv: cross-validation results
#   model_data.csv: coefficient and AUC results
# results.csv can be used to recreate plots.pdf
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
              metavar="character")
)

init_cv <- function() {
  lr_init <- list(type="Classification",
                  library="PrivateLR",
                  loop = NULL)
  lr_init$parameters <- data.frame(
    parameter = c("eps", "do.scale", "threshold", "op"),
    class = c("numeric", "logical", "character", "logical"),
    label = c("eps", "do.scale", "threshold", "op")
  )
  
  lr_fit <- function(x, y, wts, param, lev, last, weights, classProbs, ...) {
    
    d <- as.data.frame(x)
    d$y <- y
    
    # Spaces in column names breaks stuff since by here, the dplr function has one hot encoded everything
    colnames(d)<-make.names(colnames(d),unique = TRUE)
    
    m <- PrivateLR::dplr(
      y ~ ., 
      data=d,
      eps = param$eps,
      do.scale = param$do.scale,
      threshold = param$threshold,
      op = param$op,
      ...
    )
    
    # Write coefficients etc to file
    coef <- m$coefficients
    df <- data.frame(t(coef))
    df$CIndex <- m$CIndex
    df <- cbind(df, param)
    write_csv(df, paste0(write_dir, "model_data", format(Sys.time(), format= "%Y-%m-%d_%H-%M-%S"), ".csv"), append=TRUE)
    
    return(m)
  }
  lr_init$fit <- lr_fit
  
  lr_pred <- function(modelFit, newdata, preProc=NULL, submodels=NULL) {
    PrivateLR::predict.dplr(object = modelFit, data = newdata, type = "class")
  }
  lr_init$predict <- lr_pred
  
  lr_init$prob <- function(modelFit, newdata, preProc=NULL, submodels=NULL) {
    PrivateLR::predict.dplr(modelFit, newdata)
  }
  
  # Tuning parameters
  lr_grid <- function(x, y, len = NULL, search = "grid") {
    # Create df of all possible combinations
    ret <- expand.grid(eps = 2^seq(-8,4), 
                       op = c(T,F), 
                       threshold = c("0.5", "youden", "topleft"),
                       do.scale = c(T), stringsAsFactors = FALSE)
    # If eps=0, op must=F.
    ret <- rbind(ret, expand.grid(eps = c(0),
                                  op = c(F),
                                  threshold = c("0.5", "youden", "topleft"),
                                  do.scale = c(T), stringsAsFactors = FALSE))
    
    return(ret)
  }
  lr_init$grid <- lr_grid
  
  return(lr_init)
}

# Runs script
process <- function(opt) {
  set.seed(2019)
 
  data <- read_csv(opt$in_file)
  
  ### CHANGE VARS HERE --------
  # For K-fold cross validation
  k <- 5
  
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
  
  new_d <- data
  
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
  
  # I don't actually know if this is being used
  f <- as.formula(
    paste(predic, 
          paste(explan, collapse = " + "), 
          sep = " ~ "))
  
  lr_init <- init_cv()
  
  # Define new summary function
  summ <- function(data, lev = NULL, model = NULL) {
    cm <- confusionMatrix(data$pred, data$obs)
    ret <- c(cm$overall[1:2], 
             cm$byClass[1:6], 
             cm$table)
    names(ret) <- c(names(ret)[1:(length(ret)-4)], "TrueN", "FalseP", "FalseN", "TrueP")
    return(ret)
  }
  
  # Remove model_data.csv
  if(file.exists(paste0(write_dir, "model_data.csv"))) {
    temp <- file.remove(paste0(write_dir, "model_data.csv"))
    print("model_data file removed") 
  }
  
  print(paste0("---------------Begin Training----------------", Sys.time()))
  print(paste0("Num rows: ", nrow(new_d)))
  
  # Run model with k-fold cross validation
  fitControl <- trainControl(method = "cv",
                             p=0.8,
                             number = 5, # k
                             summaryFunction = summ
  )
  Laplacian <- train(f, data = new_d, # called Laplacian for no reason
                     method = lr_init,
                     trControl = fitControl)
  results <- Laplacian$results
  
  print(Laplacian)
  
  print(paste0("---------------End Training----------------", Sys.time()))
  
  write_csv(results, paste0(write_dir, "results", format(Sys.time(), format= "%Y-%m-%d_%H-%M-%S"), ".csv"))
  
  # Num loan approved / Popu
  base_accpt = new_d %>% 
    group_by(loan_status) %>% 
    summarise(n=n())
  base_accpt = base_accpt[base_accpt$loan_status == 1, ]$n / sum(base_accpt$n)
  
  # Let's see model data
  model_data <- read_csv(paste0(write_dir, "./model_data.csv"), col_names = FALSE)
  extras <- c("CIndex", "eps", "do.scale","threshold", "op")
  colnames(model_data) = c("Intercept", Laplacian$coefnames, extras)
  
  # Write back, with column names this time
  write_csv(model_data, paste0(write_dir, "./model_data", format(Sys.time(), format= "%Y-%m-%d_%H-%M-%S"), ".csv"))
  
}

# Main -- reads in flags and does stuff
main <- function() {
  opt_parser = OptionParser(option_list=option_list);
  opt = parse_args(opt_parser);
    
  process(opt)
}

main()