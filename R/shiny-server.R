
vdiffrServer <- function(cases) {
  shiny::shinyServer(function(input, output) {
    cases <- shiny::reactiveValues(all = cases)
    cases$active <- shiny::reactive({
      type <- input$type %||% "new_case"
      filter_cases(cases$all, type)
    })

    output$type_controls <- renderTypeInput(input, cases)
    output$case_controls <- renderCaseInput(input, cases$active)

    output$toggle <- renderDiffer(input, cases$active, widget_toggle_)
    output$slide <- renderDiffer(input, cases$active, widget_slide_)
    output$diff <- renderDiffer(input, cases$active, widget_diff_)

    output$diff_text <- renderDiffer(
      input,
      cases$active,
      diff_text_,
      renderer = shiny::renderUI,
      watcher = diff_text_watcher
    )
    output$diff_text_controls <- renderDiffControls(input)

    validateGroupCases(input, cases)
    validateSingleCase(input, cases)

    output$status <- renderStatus(input, cases)
    output$case_context <- renderCaseContext(input, cases)

    quitApp(input)
  })
}

diff_text_watcher <- function(input) {
  compact(list(mode = input$mode))
}

prettify_types <- function(x) {
  ifelse(x == "mismatch_case", "Mismatched",
  ifelse(x == "new_case", "New", "Orphaned"
  ))
}

renderTypeInput <- function(input, reactive_cases) {
  shiny::renderUI({
    cases <- reactive_cases$all

    types <- unique(map_chr(cases, function(case) class(case)[[1]]))
    if (length(types) == 0) {
      return(NULL)
    }
    types <- set_names(types, prettify_types(types))

    shiny::selectInput(
      inputId = "type",
      label = "Type:",
      choices = types,
      selected = types[[1]]
    )
  })
}

renderCaseInput <- function(input, active_cases) {
  shiny::renderUI({
    names <- unique(names(active_cases()))

    if (length(names)) {
      shiny::selectInput(
        inputId = "case",
        label = "Case:",
        choices = names,
        selected = names[[1]]
      )
    }
  })
}

renderDiffControls <- function(input) {
  shiny::renderUI({
    if (!identical(input$active_tab, "diff_text")) {
      return(htmltools::tags$div())
    }

    htmltools::tagList(
      shiny::br(),
      shiny::br(),
      shiny::selectInput(
        "mode", "Select a diff mode",
        choices = c("unified", "sidebyside", "context", "auto")
      )
    )
  })
}

#' @param watcher A function that takes the Shiny input as argument
#'   and returns a list of additional arguments to be passed to the
#'   widget
#' @noRd
renderDiffer <- function(input,
                         active_cases,
                         widget,
                         renderer = renderToggle,
                         watcher = NULL) {
  renderer({
    # When renderDiffer() is first called, renderCaseInput() has not
    # been called yet.
    if (is.null(input$case)) {
      return(NULL)
    }

    case <- active_cases()[[input$case]]

    # Somehow dependencies are not resolved well: renderDiffer() gets
    # called before renderCaseInput(). This can result in a
    # temporarily invalid selected case when input changes.
    if (is.null(case)) {
      return(NULL)
    }

    # Inline the SVGs in a src field for now
    pkg_path <- attr(active_cases(), "pkg_path")
    before_path <- file.path(pkg_path, "tests", "testthat", case$path)

    after <- as_inline_svg(read_file(case$testcase))
    if (is_new_case(case)) {
      before <- after
    } else {
      before <- as_inline_svg(read_file(before_path))
    }

    if (is_null(watcher)) {
      args <- NULL
    } else {
      args <- watcher(input)
    }

    eval_bare(expr(widget(before, after, !!!args)))
  })
}

withdraw_cases <- function(cases) {
  validate_cases(filter_cases(cases, c("new_case", "mismatch_case")))
  delete_orphaned_cases(filter_cases(cases, "orphaned_case"))
}

validateSingleCase <- function(input, reactive_cases) {
  shiny::observe({
    if (input$case_validation_button > 0) {
      cases <- shiny::isolate(reactive_cases$all)
      case <- shiny::isolate(input$case)

      withdraw_cases(cases[case])
      cases <- cases[-match(case, names(cases))]

      shiny::isolate(reactive_cases$all <- cases)
    }
  })
}

validateGroupCases <- function(input, reactive_cases) {
  shiny::observe({
    if (input$group_validation_button > 0) {
      active_cases <- shiny::isolate(reactive_cases$active())
      cases <- shiny::isolate(reactive_cases$all)

      if (length(cases) > 0) {
        type <- shiny::isolate(input$type)

        withdraw_cases(active_cases)

        case_types <- c("new_case", "mismatch_case", "orphaned_case")
        types <- case_types[!case_types == type]
        cases <- filter_cases(cases, types)

        shiny::isolate(reactive_cases$all <- cases)
      }
    }
  })
}

renderCaseContext <- function(input, reactive_cases) {
  shiny::renderUI({
    if(length(reactive_cases$active()) > 0 && !is.null(input$case)) {
      active_case <- reactive_cases$active()[[input$case]]
      shiny::p(
        shiny::strong("Context: "),
        shiny::span(
          title = active_case$path %||% "",
          active_case$context %||% "<none>"
        )
      )
    }
  })
}

renderStatus <- function(input, reactive_cases) {
  shiny::renderUI({
    cases <- reactive_cases$all

    if (length(cases) == 0) {
      paragraph <- shiny::p("All done!")
    } else if (input$active_tab == "slide") {
      paragraph <- shiny::p(
        shiny::strong("Slide: "), "Before  |  After"
      )
    } else if (input$active_tab == "toggle") {
      paragraph <- shiny::p(
        shiny::strong("Now Active: "),
        shiny::span(id = "shiny-toggle-status")
      )
    } else {
      paragraph <- shiny::br()
    }

    list(shiny::br(), paragraph)
  })
}

quitApp <- function(input) {
  shiny::observe({
    if (input$quit_button > 0) {
      shiny::stopApp()
    }
  })
}
