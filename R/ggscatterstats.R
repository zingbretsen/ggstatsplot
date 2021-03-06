#'
#' @title scatterplot with ggMarginals
#' @name ggscatterstats
#' @aliases ggscatterstats
#' @author Indrajeet Patil
#' @description Scatterplots from `ggplot2`` combined with add marginal histograms/boxplots/density plots with
#' statistical details added as a subtitle
#'
#' @param data data frame from which variables specified are preferentially to be taken
#' @param x a vector containing the explanatory variable
#' @param y the response - a vector of length the number of rows of `x`
#' @param xlab label for x axis variable
#' @param ylab label for y axis variable
#' @param marginal decides whether `ggExtra::ggMarginal()` plots will be displayed; the default is `TRUE`
#' @param marginal.type type of marginal distribution to be plotted on the axes ("histogram", "boxplot", "density", "violin")
#' @param xfill colour fill for x axis distibution (default: "orange")
#' @param yfill colour fill for y axis distribution (default: "green")
#' @param test statistical test to be run and displayed as subtitle ("pearson", "spearman", "robust")
#' @param results.subtitle whether the results of statistical tests are to be displayed as subtitle
#' @param intercept decides whether "mean" or "median" or no intercept lines (`NULL`) are to be plotted
#' @param title title for the plot
#' @param caption caption for the plot
#' @param maxit maximum number of iterations for robust linear regression
#' @param k number of decimal places expected for results
#' @param width.jitter degree of jitter in x direction. Defaults to 40\% of the resolution of the data.
#' @param height.jitter degree of jitter in y direction. Defaults to 40\% of the resolution of the data
#'
#' @import ggplot2
#' @import dplyr
#' @import rlang
#'
#' @importFrom MASS rlm
#' @importFrom sfsmisc f.robftest
#' @importFrom ggExtra ggMarginal
#' @importFrom stats cor.test
#' @importFrom stats na.omit
#'
#'@examples
#' # the most basic and minimalistic way of entering arguments
#' library(datasets)
#' ggscatterstats(data = iris, x = Petal.Length, y = Sepal.Length)
#' # or
#' ggscatterstats(x = iris$Petal.Length, y = iris$Sepal.Length)
#'
#' # more detailed call
#' ggscatterstats(x = iris$Petal.Length, y = iris$Sepal.Length,
#' intercept = 'median', test = 'robust', marginal.type = 'density')
#'
#' @export

ggscatterstats <-
  function(data = NULL,
           x,
           y,
           xlab = NULL,
           ylab = NULL,
           marginal = TRUE,
           marginal.type = "histogram",
           width.jitter = NULL,
           height.jitter = NULL,
           xfill = "orange",
           yfill = "green",
           intercept = NULL,
           test = "pearson",
           results.subtitle = NULL,
           title = NULL,
           caption = NULL,
           maxit = 1000,
           k = 3) {
    ################################################### dataframe ####################################################
    # preparing a dataframe out of provided inputs
    if (!is.null(data)) {
      # preparing labels from given dataframe
      lab.df <- colnames(dplyr::select(.data = data,
                                       !!rlang::enquo(x),
                                       !!rlang::enquo(y)))
      # if xlab is not provided, use the variable x name
      if (is.null(xlab))
        xlab <- lab.df[1]
      # if ylab is not provided, use the variable y name
      if (is.null(ylab))
        ylab <- lab.df[2]
      # if dataframe is provided
      data <-
        dplyr::select(
          .data = data,
          x = !!rlang::enquo(x),
          y = !!rlang::enquo(y)
        )
    } else {
      # if vectors are provided
      data <-
        base::cbind.data.frame(x = x,
                               y = y)
    }

    ######################################## statistical labels ######################################################
    # if results.subtitle argument is not specified, default to showing the results
    if (is.null(results.subtitle))
      results.subtitle <- TRUE
    # if results.subtitle argument is set to FALSE then subtitle should be set to NULL
    if (results.subtitle != TRUE)
      stats_subtitle <- NULL

    if (results.subtitle == TRUE) {
      ################################################### Pearson's r ##################################################
      if (test == "pearson") {
        # running the correlation test and preparing the subtitle text
        c <-
          stats::cor.test(
            formula = ~ x + y,
            data = data,
            method = "pearson",
            alternative = "two.sided",
            exact = FALSE,
            na.action = na.omit
          )
        # preparing the label
        stats_subtitle <-
          base::substitute(
            expr =
              paste(
                "Pearson's ",
                italic("r"),
                "(",
                df,
                ")",
                " = ",
                estimate,
                ", ",
                italic("p"),
                " = ",
                pvalue
              ),
            env = base::list(
              df = c$parameter,
              # degrees of freedom are always integer
              estimate = ggstatsplot::specify_decimal_p(x = c$estimate, k),
              pvalue = ggstatsplot::specify_decimal_p(x = c$p.value, k, p.value = TRUE)
            )
          )
        ################################################### Spearnman's rho ##################################################
      }   else if (test == "spearman") {
        # running the correlation test and preparing the subtitle text
        # note that stats::cor.test doesn't give degress of freedom; it's calculated as df = (no. of pairs - 2)
        c <-
          stats::cor.test(
            formula = ~ x + y,
            data = data,
            method = "spearman",
            alternative = "two.sided",
            exact = FALSE,
            na.action = na.omit
          )
        # preparing the label
        stats_subtitle <-
          base::substitute(
            expr =
              paste(
                "Spearman's ",
                italic(rho),
                "(",
                df,
                ")",
                " = ",
                estimate,
                ", ",
                italic("p"),
                " = ",
                pvalue
              ),
            env = base::list(
              df = (length(data$x) - 2),
              # degrees of freedom are always integer
              estimate = ggstatsplot::specify_decimal_p(x = c$estimate, k),
              pvalue = ggstatsplot::specify_decimal_p(x = c$p.value, k, p.value = TRUE)
            )
          )
        ################################################### robust ##################################################
      } else if (test == "robust") {
        # running robust regression test and preparing the subtitle text
        MASS_res <-
          MASS::rlm(
            scale(y) ~ scale(x),
            maxit = maxit,
            # number of iterations
            na.action = na.omit,
            data = data
          )
        # preparing the label
        stats_subtitle <-
          base::substitute(
            expr =
              paste(
                "robust regression: estimate = ",
                estimate,
                ", ",
                italic("t"),
                "(",
                df,
                ")",
                " = ",
                t,
                ", ",
                italic("p"),
                " = ",
                pvalue
              ),
            env = base::list(
              estimate = ggstatsplot::specify_decimal_p(x = summary(MASS_res)$coefficients[[2]], k),
              t = ggstatsplot::specify_decimal_p(x = summary(MASS_res)$coefficients[[6]], k),
              df = summary(MASS_res)$df[2],
              # degrees of freedom are always integer
              pvalue = ggstatsplot::specify_decimal_p(x = (
                sfsmisc::f.robftest(object = MASS_res)
              )$p.value),
              k,
              p.value = TRUE
            )
          )
        # preparing the message
        base::message(
          paste(
            "For robust regression: no. of iterations = ",
            maxit,
            "; estimate is standardized",
            sep = ""
          )
        )
      }
    }
    ################################################### plot ################################################################

    # preparing the scatterplotplot
    plot <-
      ggplot2::ggplot(data = data,
                      mapping = aes(x = x,
                                    y = y)) +
      geom_point(
        size = 3,
        alpha = 0.5,
        position = position_jitter(width = width.jitter,
                                   height = height.jitter)
      ) +
      geom_smooth(method = "lm",
                  se = TRUE,
                  size = 1.5) +
      ggstatsplot::theme_mprl() +
      labs(
        x = xlab,
        y = ylab,
        title = title,
        subtitle = stats_subtitle,
        caption = caption
      ) +
      coord_cartesian(xlim = c(min(data$x), max(data$x))) +
      coord_cartesian(ylim = c(min(data$y), max(data$y)))

    ################################################ intercept ##################################################

    # by default, if the input is NULL, then no intercept lines will be plotted

    if (is.null(intercept)) {
      plot <- plot

    } else if (intercept == "mean") {
      plot <- plot +
        geom_vline(
          xintercept = mean(data$x),
          linetype = "dashed",
          colour = xfill,
          size = 1.2
        ) +
        geom_hline(
          yintercept = mean(data$y),
          linetype = "dashed",
          colour = yfill,
          size = 1.2
        )

    } else if (intercept == "median") {
      plot <- plot +
        geom_vline(
          xintercept = mean(data$x),
          linetype = "dashed",
          colour = xfill,
          size = 1.2
        ) +
        geom_hline(
          yintercept = mean(data$y),
          linetype = "dashed",
          colour = yfill,
          size = 1.2
        )

    }

    #################################################### ggMarginal ######################################################

    if (isTRUE(marginal)) {
      # creating the ggMarginal plot of a given marginal.type
      plot <-
        ggExtra::ggMarginal(
          p = plot,
          type = marginal.type,
          size = 5,
          xparams = base::list(fill = xfill,
                               col = "black"),
          yparams = base::list(fill = yfill,
                               col = "black")
        )

    }

    return(plot)

  }
