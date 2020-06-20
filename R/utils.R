
is_absolute_path <- function(path) {
  substr(path, 0, 1) %in% c("~", .Platform$file.sep)
}

maybe_concat_paths <- function(base_path, path) {
  if (is_absolute_path(path)) {
    path
  } else {
    file.path(base_path, path)
  }
}

ensure_directories <- function(path) {
  if (!dir.exists(path)) {
    dir.create(path, recursive = TRUE)
  }
  path
}

capitalise <- function(x) {
  map_chr(x, function(string) {
    paste0(
      toupper(substring(string, 1, 1)),
      substring(string, 2)
    )
  })
}

read_file <- function(file) {
  readChar(file, file.info(file)$size, useBytes = TRUE)
}

package_version <- function(pkg) {
  as.character(utils::packageVersion(pkg))
}

adjust_figs_path <- function(path, pkg_path) {
  # normalizePath() does not expand paths that do not exist so this
  # expands "../figs/" manually
  components <- strsplit(path, .Platform$file.sep)[[1]]
  components <- components[-(1:2)]
  args <- c(list(pkg_path, "tests", "figs"), as.list(components))
  path <- do.call(file.path, args)

  path
}

normalise_path <- function(path) {
  path <- normalizePath(path, mustWork = FALSE)

  # Get rid of double separators
  sep <- .Platform$file.sep
  gsub(paste0(sep, "+"), sep, path)
}

str_trim_ext <- function(path) {
  sub("\\..+$", "", path)
}


# R 3.2.0 compat
dir.exists <- function(paths) {
  if (utils::packageVersion("base") >= "3.2.0") {
    (baseenv()$dir.exists)(paths)
  } else {
    purrr::map_lgl(paths, dir_exists)
  }
}

dir_exists <- function(path) {
  !identical(path, "") && file.exists(paste0(path, .Platform$file.sep))
}

cat_line <- function(..., trailing = TRUE, file = "") {
  cat(paste_line(..., trailing = trailing), file = file)
}
paste_line <- function(..., trailing = FALSE) {
  lines <- paste(chr(...), collapse = "\n")
  if (trailing) {
    lines <- paste0(lines, "\n")
  }
  lines
}

push_log <- function(case) {
  log_path <- Sys.getenv("VDIFFR_LOG_PATH")

  # If no envvar is set, check if we are running under R CMD check. In
  # that case, always push a log file.
  if (!nzchar(log_path)) {
    if (!is_checking()) {
      return(invisible(FALSE))
    }
    log_path <- testthat::test_path("..", "vdiffr.Rout.fail")
  }

  log_exists <- file.exists(log_path)

  file <- file(log_path, "a")
  on.exit(close(file))

  if (!log_exists) {
    cat_line(
      file = file,
      "Environment:",
      vdiffr_info(),
      ""
    )
  }

  diff_lines <- diff_lines(case, case$path, case$testcase)
  cat_line(file = file, "", !!!diff_lines, "")
}
is_checking <- function() {
  nzchar(Sys.getenv("CI")) || !nzchar(Sys.getenv("NOT_CRAN"))
}

diff_lines <- function(case,
                       before_path,
                       after_path) {
  before <- readLines(before_path)
  after <- readLines(after_path)

  diff <- diffobj::diffChr(
    before,
    after,
    format = "raw"
  )

  # No format() method?
  lines <- utils::capture.output(print(diff))

  paste_line(
    glue("Failed doppelganger: {case$name} ({case$path})"),
    "",
    !!!lines
  )
}


vdiffr_info <- function() {
  glue(
    "- vdiffr-svg-engine: { SVG_ENGINE_VER }
     - vdiffr: { utils::packageVersion('vdiffr') }
     - freetypeharfbuzz: { utils::packageVersion('freetypeharfbuzz') }"
  )
}

is_vdiffr_stale <- function() {
  deps_file <- testthat::test_path("..", "figs", "deps.txt")

  if (!file.exists(deps_file)) {
    return(FALSE)
  }
  deps <- readLines(deps_file)

  ver <- purrr::detect(deps, function(dep) grepl("^- vdiffr-svg-engine: ", dep))
  if (is_null(ver)) {
    return(TRUE)
  }

  ver <- substr(ver, nchar("- vdiffr-svg-engine: ") + 1, nchar(ver))
  ver <- base::package_version(ver)
  current <- base::package_version(SVG_ENGINE_VER)

  ver < current
}

hash_encode_url <- function(url){
  gsub("#", "%23", url)
}

is_ci <- function() {
  override <- Sys.getenv("VDIFFR_RUN_TESTS")
  if (nzchar(override)) {
    override <- parse_expr(toupper(override))
    if (!is_bool(override)) {
      abort("`VDIFFR_RUN_TESTS` must be \"true\" or \"false\"")
    }
    return(override)
  }

  nzchar(Sys.getenv("CI")) || nzchar(Sys.getenv("NOT_CRAN"))
}

is_bool <- function(x) {
  is_logical(x, n = 1) && !is.na(x)
}

next_element <- function(element, group, direction = 1) {
  if (element == "") {
    return(NULL) # if a type is empty
  }

  next_position <- match(element, group) + direction

  if (next_position > length(group)) {
    next_position <- next_position - length(group)
  } else if (next_position < 1) {
    next_position <- length(group)
  }

  group[next_position]
}
