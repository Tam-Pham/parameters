#' Parameters from multinomial or cumulative link models
#'
#' Parameters from multinomial or cumulative link models
#'
#' @param model A model with multinomial or categorical response value.
#' @inheritParams model_parameters.default
#' @inheritParams simulate_model
#'
#' @details Multinomial or cumulative link models, i.e. models where the
#'   response value (dependent variable) is categorical and has more than two
#'   levels, usually return coefficients for each response level. Hence, the
#'   output from \code{model_parameters()} will split the coefficient tables
#'   by the different levels of the model's response.
#'
#' @seealso \code{\link[insight:standardize_names]{standardize_names()}} to rename
#'   columns into a consistent, standardized naming scheme.
#'
#' @examples
#' library(parameters)
#' if (require("brglm2")) {
#'   data("stemcell")
#'   model <- bracl(
#'     research ~ as.numeric(religion) + gender,
#'     weights = frequency,
#'     data = stemcell,
#'     type = "ML"
#'   )
#'   model_parameters(model)
#' }
#' @return A data frame of indices related to the model's parameters.
#' @inheritParams simulate_model
#' @importFrom insight get_response
#' @export
model_parameters.mlm <- function(model,
                                 ci = .95,
                                 bootstrap = FALSE,
                                 iterations = 1000,
                                 standardize = NULL,
                                 exponentiate = FALSE,
                                 p_adjust = NULL,
                                 verbose = TRUE,
                                 ...) {

  # detect number of levels of response
  nl <- tryCatch(
    {
      nlevels(insight::get_response(model))
    },
    error = function(e) {
      0
    }
  )

  # merge by response as well if more than 2 levels
  if (nl > 2) {
    merge_by <- c("Parameter", "Response")
  } else {
    merge_by <- "Parameter"
  }

  out <-
    .model_parameters_generic(
      model = model,
      ci = ci,
      bootstrap = bootstrap,
      iterations = iterations,
      merge_by = merge_by,
      standardize = standardize,
      exponentiate = exponentiate,
      robust = FALSE,
      p_adjust = p_adjust,
      ...
    )

  attr(out, "object_name") <- deparse(substitute(model), width.cutoff = 500)
  out
}


#' @rdname model_parameters.mlm
#' @export
model_parameters.multinom <- model_parameters.mlm


#' @export
model_parameters.brmultinom <- model_parameters.mlm


#' @rdname model_parameters.mlm
#' @export
model_parameters.bracl <- model_parameters.mlm



#' @rdname model_parameters.mlm
#' @export
model_parameters.DirichletRegModel <- function(model,
                                               ci = .95,
                                               bootstrap = FALSE,
                                               iterations = 1000,
                                               component = c("all", "conditional", "precision"),
                                               standardize = NULL,
                                               exponentiate = FALSE,
                                               verbose = TRUE,
                                               ...) {
  component <- match.arg(component)
  if (component == "all") {
    merge_by <- c("Parameter", "Component", "Response")
  } else {
    merge_by <- c("Parameter", "Response")
  }

  ## TODO check merge by

  junk <- utils::capture.output(out <- .model_parameters_generic(
    model = model,
    ci = ci,
    component = component,
    bootstrap = bootstrap,
    iterations = iterations,
    merge_by = merge_by,
    standardize = standardize,
    exponentiate = exponentiate,
    robust = FALSE,
    ...
  ))

  out$Response[is.na(out$Response)] <- ""
  attr(out, "object_name") <- deparse(substitute(model), width.cutoff = 500)
  out
}


#' @rdname model_parameters.mlm
#' @export
model_parameters.clm2 <- function(model,
                                  ci = .95,
                                  bootstrap = FALSE,
                                  iterations = 1000,
                                  component = c("all", "conditional", "scale"),
                                  standardize = NULL,
                                  exponentiate = FALSE,
                                  p_adjust = NULL,
                                  verbose = TRUE,
                                  ...) {
  component <- match.arg(component)
  if (component == "all") {
    merge_by <- c("Parameter", "Component")
  } else {
    merge_by <- "Parameter"
  }

  ## TODO check merge by

  out <-
    .model_parameters_generic(
      model = model,
      ci = ci,
      component = component,
      bootstrap = bootstrap,
      iterations = iterations,
      merge_by = c("Parameter", "Component"),
      standardize = standardize,
      exponentiate = exponentiate,
      p_adjust = p_adjust,
      ...
    )

  attr(out, "object_name") <- deparse(substitute(model), width.cutoff = 500)
  out
}


#' @export
model_parameters.clmm2 <- model_parameters.clm2
