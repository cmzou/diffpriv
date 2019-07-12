################
# 
# Script of useful functions.
# 
################

# --------------
# Functions primarily used in "hmda model.Rmd"
# AKA Functions to help with model building

# Initializes the function needed when using custom models in caret's k-fold cross validation
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
    fwrite(df, paste0("model_data.csv"), append=TRUE)
    
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

# Define new summary function, also to be used with caret's k-fold cross validation
summ <- function(data, lev = NULL, model = NULL) {
  cm <- confusionMatrix(data$pred, data$obs)
  ret <- c(cm$overall[1:2], 
           cm$byClass[1:6], 
           cm$table)
  names(ret) <- c(names(ret)[1:(length(ret)-4)], "TrueN", "FalseP", "FalseN", "TrueP")
  return(ret)
}

# --------------



# --------------
# Functions primarily used in "hmda results visualization r.Rmd"
# AKA Functions to help with plotting

# Function that converts a df that has columns for TN, TP, etc. into
# a plottable confusion matrix
# Args: 
#   data: df
#   idxs: the indices of the start of the TN, TP, etc. to be added to summ
#   summ: the dataframe with columns for true and predicted, the dataframe to be added to
# Returns summ with an extra column with TN, TP, etc. values
convert_one <- function(data, idxs, summ_out) {
  summ <- aggregate(data[,idxs], # indices indicate where the TN, TP, etc. are
                    by = list(data$eps), mean) # group by eps
  
  # What is the name of the new column?
  name <- paste0(substr(colnames(summ)[2], 3, nchar(colnames(summ)[2])))
  
  summ$Group.1 <- NULL # assumming that the dataframe has a column that indicates group
  summ <- t(summ)
  summ <- c(summ)
  
  # Add column
  summ_out[, name] <- summ
  
  return(summ_out)
}

# Function to plot confusion matrix
# true: column of 0s and 1s to use as x-axis
# predicted: column of 0s and 1s to use as y-axis
#   this is so that when plotted, the values at coordinates (true, predicted) represent values in the cm
# col: the column name of the values to go in each box
plot_cm <- function(data, col, true="true", predicted="predicted", title = NULL, 
                    use_facet=FALSE, facet=NULL, lab = NULL) {
  # Formatting digits
  data[, col] <- as.numeric(format(data[[col]], digits=3))
  
  # Creating plots
  if(use_facet) {
    p <- ggplot(data =  data, mapping = aes_string(x = true, y = predicted)) + 
      geom_tile(aes_string(fill = col), colour = "white") +
      geom_text(aes_string(label = col), vjust = 1) +
      scale_fill_gradient(low = "white", high = "red") +
      theme_bw() + theme(legend.position = "none")+
      labs(title = title) + 
      facet_wrap(formula(paste0(". ~", facet)))
  } else {
    p <- ggplot(data =  data, mapping = aes_string(x = true, y = predicted)) + 
      geom_tile(aes_string(fill = col), colour = "white") +
      geom_text(aes_string(label = col), vjust = 1) +
      scale_fill_gradient(low = "white", high = "red") +
      theme_bw() + theme(legend.position = "none")+
      labs(title = title) 
  }
  if(!is.null(lab)) {
    p <- p + labs(lab)
  }
  return(p)
}

# --------------




