#' choreography
#'
#' The choreography is a central concept of the dance
#' package, most of the time you don't need to use it directly, but it is
#' used by many other functions like [tango()], [samba()], ...
#'
#' @param .tbl A data frame
#' @param ... A variable number of formulas. `choreography()` only
#' uses the rhs of each of the formulas.
#'
#' @param .env parent environment of the created function, see [rlang::new_function()]
#'
#' @return a function that can be called with a single argument that
#'   represents indices.
#'
#'   When called with an integer vector `idx`, the function returns a list
#'   of each of the expressions given on the rhs evaluated on the subset
#'   of the columns, i.e. in the formula `~mean(Sepal.Length)` the column
#'   `Sepal.Length` stands for `Sepal.Length[idx]`.
#'
#' @examples
#'
#' moves <- choreography(iris,
#'   Sepal.Length = ~mean(Sepal.Length),
#'   Sepal.Width  = ~mean(Sepal.Width)
#' )
#'
#' moves(1:10)
#' # this returns the same as
#' list(
#'   Sepal.Length = mean(iris$Sepal.Length[1:10]),
#'   Sepal.Width  = mean(iris$Sepal.Width[1:10])
#' )
#'
#' @export
choreography <- function(.tbl, ..., .env = caller_env()) {
  args <- tbl_slicer_args(.tbl)
  body <- expr(list(!!!map(list2(...), f_rhs)))
  structure(rlang::new_function(args, body, env = .env), class = "choreography")
}

#' @export
print.choreography <- function(x, ...) {
  body <- body(x)

  fs <- formals(x)[-1]
  funs <- map_chr(fs, ~{
    # now it's either .subset or vctrs::vec_slice
    res <- if(identical(.x[[1L]], .subset)) {
      "<.subset>"
    } else {
      "<vctrs::vec_slice>"
    }
    green(res)
  })
  index <- red("`.::index::.`")
  txt <- glue(
    "function({index},\n    ",
    glue_collapse(glue("{var} = {fun}(<{data}{var}>, {index})", fun = funs, var = silver(names(funs)), data = silver(".tbl$")), sep = ",\n    "),
    "\n){{\n    ",
    glue_collapse(expr_deparse(body(x)), sep = "    \n"),
    "\n}}\n"
  )
  writeLines(txt)
  invisible(x)
}
