#' @title custom function for getting specified number of decimal places in results for p-value
#' @name specify_decimal_p
#' @aliases specify_decimal_p
#' @description Function to format an R object for pretty printing with a specified number of decimal places. The
#' function also allows highly significant p-values to be denoted as "p < 0.001" rather than "p = 0.000"
#' @author Indrajeet Patil
#'
#' @param x a numeric value
#' @param k the number of digits after decimal point (should be an integer)
#' @param p.value whether the number is a p-value ("TRUE" or "FALSE")
#'
#' @return formatted p-values from statistical tests
#'
#' @export

specify_decimal_p <- function(x,
                              k = NULL,
                              p.value = FALSE) {
  # if the number of decimal places hasn't been specified, use the default of 3
  if (is.null(k))
    k <- 3
  # formatting the output properly
  output <-
    base::trimws(x = base::format(x = base::round(x = x, digits = k),
                                  nsmall = k),
                 which = "both")
  # if it's a p-value, then format it properly
  if (isTRUE(p.value)) {
    # determing the class of output
    if (output < 0.001) {
      output <- "< 0.001"
    }
  }
  return(output) # this will return a character
}
