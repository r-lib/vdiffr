
vdiffrUi <- function(cases) {
  shiny::shinyUI(shiny::fluidPage(
    shiny::singleton(shiny::tags$head(
      include_script("toggle.js")
    )),
    shiny::br(),
    shiny::sidebarLayout(
      sidebarPanel(),
      diffPanel()
    )
  ))
}

sidebarPanel <- function() {
  shiny::sidebarPanel(
    shiny::uiOutput("type_controls"),
    shiny::actionButton("group_validation_button", "Validate these"),
    shiny::br(),
    shiny::br(),
    shiny::uiOutput("case_context"),
    shiny::uiOutput("case_controls"),
    shiny::actionButton("case_validation_button", "Validate this"),
    shiny::uiOutput("status"),
    shiny::uiOutput("diff_text_controls"),
    shiny::br(),
    shiny::actionButton("quit_button", "Quit")
  )
}

diffPanel <- function() {
  shiny::mainPanel(
    shiny::tabsetPanel(id = "active_tab",
      shiny::tabPanel("Toggle", toggleOutput("toggle"), value = "toggle"),
      shiny::tabPanel("Slide", slideOutput("slide"), value = "slide"),
      shiny::tabPanel("Diff", diffOutput("diff"), value = "diff"),
      shiny::tabPanel("Textual Diff", shiny::htmlOutput("diff_text"), value = "diff_text")
    )
  )
}

include_script <- function(file) {
  script <- shiny::includeScript(
    system.file("www", file, package = "vdiffr")
  )
  isolate_scope(script)
}

isolate_scope <- function(script) {
  head <- "(function() {\n"
  tail <- "\n})();"
  script$children[[1]] <- paste0(head, script$children[[1]], tail)
  script
}
