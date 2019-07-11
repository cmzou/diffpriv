################
# 
# Script of useful functions.
# 
################

# --------------
# Functions primarily used in "hmda results visualization r.Rmd"
# AKA Functions to help with plotting
# --------------

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
  data[, col] <- as.numeric(format(data[, col], digits=3))
  
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






