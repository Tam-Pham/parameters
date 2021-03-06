#' Parameters from hypothesis tests
#'
#' Parameters of h-tests (correlations, t-tests, chi-squared, ...).
#'
#' @param model Object of class \code{htest} or \code{pairwise.htest}.
#' @param bootstrap Should estimates be bootstrapped?
#' @param cramers_v,phi Compute Cramer's V or phi as index of effect size.
#'   Can be \code{"raw"} or \code{"adjusted"} (effect size will be bias-corrected).
#'   Only applies to objects from \code{chisq.test()}.
#' @param ci Level of confidence intervals for Cramer's V or phi. Currently only
#'   applies to objects from \code{chisq.test()}.
#' @inheritParams model_parameters.default
#' @param ... Arguments passed to or from other methods.
#'
#' @examples
#' model <- cor.test(mtcars$mpg, mtcars$cyl, method = "pearson")
#' model_parameters(model)
#'
#' model <- t.test(iris$Sepal.Width, iris$Sepal.Length)
#' model_parameters(model)
#'
#' model <- t.test(mtcars$mpg ~ mtcars$vs)
#' model_parameters(model)
#'
#' model <- t.test(iris$Sepal.Width, mu = 1)
#' model_parameters(model)
#'
#' data(airquality)
#' airquality$Month <- factor(airquality$Month, labels = month.abb[5:9])
#' model <- pairwise.t.test(airquality$Ozone, airquality$Month)
#' model_parameters(model)
#'
#' smokers <- c(83, 90, 129, 70)
#' patients <- c(86, 93, 136, 82)
#' model <- pairwise.prop.test(smokers, patients)
#' model_parameters(model)
#' @return A data frame of indices related to the model's parameters.
#' @export
model_parameters.htest <- function(model,
                                   cramers_v = NULL,
                                   phi = NULL,
                                   ci = .95,
                                   bootstrap = FALSE,
                                   verbose = TRUE,
                                   ...) {

  if (bootstrap) {
    stop("Bootstrapped h-tests are not yet implemented.")
  } else {
    parameters <- .extract_parameters_htest(model, cramers_v = cramers_v, phi = phi, ci = ci)
  }

  if (!is.null(parameters$Method)) {
    parameters$Method <- trimws(gsub("with continuity correction", "", parameters$Method))
  }

  parameters <- .add_htest_parameters_attributes(parameters, model, ci, ...)
  class(parameters) <- c("parameters_model", class(parameters))
  parameters
}






# ==== extract parameters ====


#' @keywords internal
.extract_parameters_htest <- function(model,
           cramers_v = NULL,
           phi = NULL,
           ci = 0.95) {

  m_info <- insight::model_info(model)

  if (m_info$is_correlation) {
    out <- .extract_htest_correlation(model)
  } else if (m_info$is_ttest) {
    out <- .extract_htest_ttest(model)
  } else if (m_info$is_onewaytest) {
    out <- .extract_htest_oneway(model)
  } else if (m_info$is_chi2test) {
    out <- .extract_htest_chi2(model)
    if (!grepl("^McNemar", model$method)) {
      out <- .add_effectsize_chi2(model, out, cramers_v = cramers_v, phi = phi, ci = ci)
    }
  } else if (m_info$is_proptest) {
    out <- .extract_htest_prop(model)
  } else if (m_info$is_binomtest) {
    out <- .extract_htest_binom(model)
  } else {
    stop("model_parameters not implemented for such h-tests yet.")
  }

  row.names(out) <- NULL
  out
}



# extract htest correlation ----------------------

.extract_htest_correlation <- function(model) {
  names <- unlist(strsplit(model$data.name, " and ", fixed = TRUE))
  out <- data.frame(
    "Parameter1" = names[1],
    "Parameter2" = names[2],
    stringsAsFactors = FALSE
  )

  if (model$method == "Pearson's Chi-squared test") {
    out$Chi2 <- model$statistic
    out$df <- model$parameter
    out$p <- model$p.value
    out$Method <- "Pearson"
  } else if (grepl("Pearson", model$method)) {
    out$r <- model$estimate
    out$t <- model$statistic
    out$df <- model$parameter
    out$p <- model$p.value
    out$CI_low <- model$conf.int[1]
    out$CI_high <- model$conf.int[2]
    out$Method <- "Pearson"
  } else if (grepl("Spearman", model$method)) {
    out$rho <- model$estimate
    out$S <- model$statistic
    out$df <- model$parameter
    out$p <- model$p.value
    out$Method <- "Spearman"
  } else {
    out$tau <- model$estimate
    out$z <- model$statistic
    out$df <- model$parameter
    out$p <- model$p.value
    out$Method <- "Kendall"
  }
  out
}



# extract htest ttest ----------------------

.extract_htest_ttest <- function(model) {
  if (grepl(" and ", model$data.name)) {
    names <- unlist(strsplit(model$data.name, " and ", fixed = TRUE))
    out <- data.frame(
      "Parameter1" = names[1],
      "Parameter2" = names[2],
      "Mean_Parameter1" = model$estimate[1],
      "Mean_Parameter2" = model$estimate[2],
      "Difference" = model$estimate[1] - model$estimate[2],
      "t" = model$statistic,
      "df" = model$parameter,
      "p" = model$p.value,
      "CI_low" = model$conf.int[1],
      "CI_high" = model$conf.int[2],
      "Method" = model$method,
      stringsAsFactors = FALSE
    )
  } else if (grepl(" by ", model$data.name)) {
    if (length(model$estimate) == 1) {
      names <- unlist(strsplit(model$data.name, " by ", fixed = TRUE))
      out <- data.frame(
        "Parameter" = names[1],
        "Group" = names[2],
        "Mean_Difference" = model$estimate,
        "t" = model$statistic,
        "df" = model$parameter,
        "p" = model$p.value,
        "CI_low" = model$conf.int[1],
        "CI_high" = model$conf.int[2],
        "Method" = model$method,
        stringsAsFactors = FALSE
      )
    } else {
      names <- unlist(strsplit(model$data.name, " by ", fixed = TRUE))
      out <- data.frame(
        "Parameter" = names[1],
        "Group" = names[2],
        "Mean_Group1" = model$estimate[1],
        "Mean_Group2" = model$estimate[2],
        "Difference" = model$estimate[2] - model$estimate[1],
        "t" = model$statistic,
        "df" = model$parameter,
        "p" = model$p.value,
        "CI_low" = model$conf.int[1],
        "CI_high" = model$conf.int[2],
        "Method" = model$method,
        stringsAsFactors = FALSE
      )
    }
  } else {
    out <- data.frame(
      "Parameter" = model$data.name,
      "Mean" = model$estimate,
      "mu" = model$null.value,
      "Difference" = model$estimate - model$null.value,
      "t" = model$statistic,
      "df" = model$parameter,
      "p" = model$p.value,
      "CI_low" = model$conf.int[1],
      "CI_high" = model$conf.int[2],
      "Method" = model$method,
      stringsAsFactors = FALSE
    )
  }
  out
}



# extract htest oneway ----------------------

.extract_htest_oneway <- function(model) {
  data.frame(
    "F" = model$statistic,
    "df_num" = model$parameter[1],
    "df_denom" = model$parameter[2],
    "p" = model$p.value,
    "Method" = model$method,
    stringsAsFactors = FALSE
  )
}



# extract htest chi2 ----------------------

.extract_htest_chi2 <- function(model) {
  data.frame(
    "Chi2" = model$statistic,
    "df" = model$parameter,
    "p" = model$p.value,
    "Method" = model$method,
    stringsAsFactors = FALSE
  )
}



# extract htest prop ----------------------

#' @importFrom insight format_value
.extract_htest_prop <- function(model) {
  out <- data.frame(
    Proportion = paste0(insight::format_value(model$estimate, as_percent = TRUE), collapse = " / "),
    stringsAsFactors = FALSE
  )
  if (length(model$estimate) == 2) {
    out$Difference <- insight::format_value(
      abs(model$estimate[1] - model$estimate[2]),
      as_percent = TRUE
    )
  }
  if (!is.null(model$conf.int)) {
    out$CI_low <- model$conf.int[1]
    out$CI_high <- model$conf.int[2]
  }
  out$Chi2 <- model$statistic
  out$df <- model$parameter[1]
  out$Null_value <- model$null.value
  out$p <- model$p.value
  out$Method <- model$method
  out
}



# extract htest binom ----------------------

.extract_htest_binom <- function(model) {
  out <- data.frame(
    "Probability" = model$estimate,
    "CI_low" = model$conf.int[1],
    "CI_high" = model$conf.int[2],
    "Success" = model$statistic,
    "Trials" = model$parameter,
    stringsAsFactors = FALSE
  )
  out$Null_value <- model$null.value
  out$p <- model$p.value
  out$Method <- model$method
  out
}





# ==== effectsizes =====

.add_effectsize_chi2 <- function(model,
           out,
           cramers_v = NULL,
           phi = NULL,
           ci = .95) {

  if (is.null(cramers_v) && is.null(phi)) {
    return(out)
  }

  if (!is.null(cramers_v) && requireNamespace("effectsize", quietly = TRUE)) {
    # Cramers V
    es <- effectsize::cramers_v(model$observed, ci = ci, adjust = cramers_v == "adjusted")
    es$CI <- NULL
    ci_cols <- grepl("^CI", names(es))
    names(es)[ci_cols] <- paste0("Cramers_", names(es)[ci_cols])
    out <- cbind(out, es)
  }

  if (!is.null(phi) && requireNamespace("effectsize", quietly = TRUE)) {
    # Phi
    es <- effectsize::phi(model$observed, ci = ci, adjust = phi == "adjusted")
    es$CI <- NULL
    ci_cols <- grepl("^CI", names(es))
    names(es)[ci_cols] <- paste0("phi_", names(es)[ci_cols])
    out <- cbind(out, es)
  }

  # reorder
  col_order <- c("Chi2", "df", "Cramers_v", "Cramers_v_adjusted", "Cramers_CI_low",
                 "Cramers_CI_high", "phi", "phi_adjusted", "phi_CI_low",
                 "phi_CI_high", "p", "Method", "method")
  out <- out[col_order[col_order %in% names(out)]]
  out
}





# ==== add attributes ====


.add_htest_parameters_attributes <- function(params, model, ci = 0.95, ...) {
  dot.arguments <- lapply(match.call(expand.dots = FALSE)$`...`, function(x) x)
  if ("digits" %in% names(dot.arguments)) {
    attr(params, "digits") <- eval(dot.arguments[["digits"]])
  } else {
    attr(params, "digits") <- 2
  }

  if ("ci_digits" %in% names(dot.arguments)) {
    attr(params, "ci_digits") <- eval(dot.arguments[["ci_digits"]])
  } else {
    attr(params, "ci_digits") <- 2
  }

  if ("p_digits" %in% names(dot.arguments)) {
    attr(params, "p_digits") <- eval(dot.arguments[["p_digits"]])
  } else {
    attr(params, "p_digits") <- 3
  }

  attr(params, "ci") <- ci
  attr(params, "ci_test") <- attributes(model$conf.int)$conf.level
  params
}
