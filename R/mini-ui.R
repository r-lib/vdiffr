
vdiffrUi <- function(cases) {
  
  ui <- miniUI::miniPage(
    miniUI::gadgetTitleBar("Manage visual test cases"),
    shiny::singleton(shiny::tags$head(
      include_script("toggle.js")
    )),
    miniUI::miniTabstripPanel(
      miniUI::miniTabPanel("Summary", icon = shiny::icon("sliders"),
                           miniUI::miniContentPanel(
                             summaryPanel(),
                             diffPanel()
                           )
      )
      # miniUI::miniTabPanel("Mismatch Cases", icon = shiny::icon("map-o"),
      #                      miniUI::miniContentPanel(
      #                                               br()
      #                      )
      # ),
      # miniUI::miniTabPanel("New Cases", icon = shiny::icon("area-chart"),
      #                      miniUI::miniContentPanel(
      #                         br()
      #                      )
      # ),
      # miniUI::miniTabPanel("Orphaned Cases", icon = shiny::icon("table"),
      #                      miniUI::miniContentPanel(
      #                        br()
      #                      ),
      #                      miniUI::miniButtonBlock(
      #                        actionButton("delete_orphaned", "Delete orphaned cases now")
      #                      )
      # ),
      # miniUI::miniTabPanel("Success Cases", icon = shiny::icon("table"),
      #                      miniUI::miniContentPanel(
      #                        br()
      #                      )
      # )
    )
  )
  
  # shiny::shinyUI(shiny::fluidPage(
  #   shiny::singleton(shiny::tags$head(
  #     include_script("toggle.js")
  #   )),
  #   shiny::br(),
  #   shiny::sidebarLayout(
  #     sidebarPanel(),
  #     diffPanel()
  #   )
  # ))
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

summaryPanel <- function(){
  shiny::div(
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

diffPanel2 <- function() {
  shiny::div(
    shiny::radioButtons("diff_selector", "Select diff type", choices = c("toggle", "slide", "diff", "diff_text")),
    shiny::conditionalPanel("input.diff_selector == 'toggle'", toggleOutput("toggle")),
    shiny::conditionalPanel("input.diff_selector == 'slide'", slideOutput("slide")),
    shiny::conditionalPanel("input.diff_selector == 'diff'", diffOutput("diff")),
    shiny::conditionalPanel("input.diff_selector == 'diff_text'", shiny::htmlOutput("diff_text"))
    # shiny::tabsetPanel(id = "active_tab",
    #                    shiny::tabPanel("Toggle", toggleOutput("toggle"), value = "toggle"),
    #                    shiny::tabPanel("Slide", slideOutput("slide"), value = "slide"),
    #                    shiny::tabPanel("Diff", diffOutput("diff"), value = "diff"),
    #                    shiny::tabPanel("Textual Diff", shiny::htmlOutput("diff_text"), value = "diff_text")
    # )
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
