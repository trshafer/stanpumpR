# UI for stanpumpR

source("global.r")

#enableBookmarking(store = "url")

# UI ------------------------------------------------------
ui <- function(request) {
  useShinyjs()
  dashboardPage(
  dashboardHeader(
    title = config$title
    # Dropdown menu for messages
    ),
  dashboardSidebar(
      collapsed = TRUE,
      width = "200px",
      sidebarMenu(
        id = "simType",
        menuItem("stanpumpR", tabName = "SimulationMode", selected = TRUE)
      )
    ),

  dashboardBody(
    style = "max-height: 95vh; overflow-y: auto;" ,
    tags$style(
      HTML(
        '.form-first-row {
          height: 100px;
      }
        .cancel-margin > .form-group {
        margin: 0;
        }
        '
      )
    ), # End of tags$style
    fluidRow(
      column(
        width=4,
        HTML('<input type="text" id="client_time" name="client_time" style="display: none;"> '
             ), # end of HTML
        
        tags$script('
   $(function() {
    var time_now = new Date()
    $("input#client_time").val(time_now.toLocaleTimeString())
  });    
'), # end of tags$script
        
        fluidRow(  # start of fluid row within this column
          h4("Patient Covariates"),
          style = "border-style: solid; border-color: white;  border-radius: 5px;",
          column(
            width = 4,
            div(
              class = "form-first-row",
              div( # Age ************************************
                class = "cancel-margin",
                numericInput(
                  inputId = "age",
                  label = "Age",
                  value = defaultAge,
                  step = 1,
                  min = 1,
                  max = 110
                ),
                bsTooltip(
                  id = "age", 
                  title = "Enter  age and select years or months",
                  placement = "top", 
                  options = list(container = "body")
                )
              ), # end of cancel-margin div
              div( #style = "font-size: 10px;",
                radioButtons(
                  inputId = "ageUnit",
                  label = NULL,
                  choiceNames = c("years","months"),
                  choiceValues = c(1,0.08333333),
                  inline = TRUE,
                  selected = defaultAgeUnit
                )
              )
            ), # end of form-first-row div
            div( # weight *****************************************
              class = "cancel-margin",
              numericInput(
                inputId = "weight",
                label = "Weight",
                value = defaultWeight,
                step = 1,
                min = 5
              ),
              bsTooltip(
                id = "weight", 
                title = "Enter weight and select kilograms or pounds",
                placement = "top", 
                options = list(container = "body")
              )
            ), # End of class cancel-margin div
            radioButtons(
              inputId = "weightUnit",
              label = NULL,
              choiceNames = c("kg", "lb"),
              choiceValues = c(1,0.453592),
              inline = TRUE,
              selected = defaultWeightUnit
            ),
            div( # Height ********************************************
              class = "cancel-margin",
              numericInput(
                inputId = "height",
                label = "Height",
                value = defaultHeight,
                step = 1,
                min = 20
              ),
              bsTooltip(
                id = "height", 
                title = "Enter height and select centimeters or inches",
                placement = "right", 
                options = list(container = "body")
              )
            ), # end of cancel-margin div
            radioButtons(
              inputId = "heightUnit",
              label = NULL,
              choiceNames = c("cms","inches"),
              choiceValues = c(1, 2.56),
              inline = TRUE,
              selected = defaultHeightUnit
            )
          ), # end of column
          column(
            width = 6,
            # div(
            #   class = "form-first-row",
              radioButtons(
                inputId = "sex",
                label = "Sex",
                choiceNames = c("Male","Female"),
                choiceValues = c("male","female"),
                inline = TRUE,
                selected = defaultSex
              ),
#            ), # end of class: form-first-row div
            conditionalPanel(
              condition = "input.age && input.ageUnit && input.ageUnit == 1 && input.age > 11 & input.age < 60 && input.sex == 'female'",
              radioButtons(
                inputId = "pregnant",
                label = "Pregnant",
                choiceNames = c("Yes","No"),
                choiceValues = c(TRUE, FALSE),
                inline = TRUE,
                selected = FALSE
              ),
              bsTooltip(
                id = "pregnant", 
                title = "Not imkplemented yet",
                placement = "right", 
                options = list(container = "body")
              )
            ),
            radioButtons(
              inputId = "cyp2d6",
              label = "CYP 2D6",
              choiceNames = c("Rapid","Typical", "Slow"),
              choiceValues = c("rapid","typical", "slow"),
              inline = TRUE,
              selected = "typical"
            ),
            bsTooltip(
              id = "cyp2d6", 
              title = "Not imkplemented yet",
              placement = "right", 
              options = list(container = "body")
            ),
            radioButtons(
              inputId = "renal",
              label = "Renal Function",
              choiceNames = c("Normal","Impaired", "ESRD"),
              choiceValues = c("normal","impaired", "ESRD"),
              inline = TRUE,
              selected = "normal"
            ),
            bsTooltip(
              id = "renal", 
              title = "Not imkplemented yet",
              placement = "right", 
              options = list(container = "body")
            )
          )
        ), # fluidrow within column
        fluidRow(
          h4("Dose Table"),
          style = "border-style: solid; border-color: white;  border-radius: 5px; height: 450px; ",
          
          column(
            width=12,
            fluidRow(
              column(
                width = 4,
                h5("Reference Time")
              ),
              uiOutput( # Width = 1
                outputId = "getReferenceTime"
              ),
              column(
                width=1,
                actionButton(
                  inputId = "Refresh",
                  label = "Refresh",
                  width = NULL
                )
              )
            ), # end of fluid row
            tags$style(
              HTML(
                '.ht_master table.htCore > tbody td {
                position: relative;
                overflow: hidden;
                text-overflow: ellipsis;
                padding-right: 10px;
                }
                .htAutocompleteArrow {
                position: absolute;
                right: 0;
                }
                '
              ) # end of HTML
              ), # end of tags$style
            rHandsontableOutput(outputId = "doseTableHTML"),
            bsTooltip(
              id = "doseTableHTML",
              title = "Enter the drug and the units by typing or by using the pull down menu. Clock times are entered as HH:MM.",
              placement = "right",
              options = list(container = "body")
            )
          ) # End of column
        ) # end of second fluid row in width 5 column
      ), # end of width 5 column
      column(
        width=8,
        fillPage(
          div(
            style = "position:relative",
            # Start of plot Output
            plotOutput(
              outputId = "PlotSimulation",
              width="100%",
              height="500px",
              click = clickOpts(
                id = "plot_click",
                clip = FALSE
              ),
              dblclick = dblclickOpts(
                id = "plot_dblclick",
                clip=FALSE
              ),
              hover = hoverOpts(
                id = "plot_hover",
                delay = 500,
                delayType = "debounce",
                clip = TRUE,
                nullOutside = TRUE
              )
            ), # End of plotOutput
            uiOutput("hover_info")
          ) # End of div
        ), # End of fillPage
        ############################################################################
        fluidRow(
          style = "border-style: solid; border-color: white;  border-radius: 5px; height: 300px",
          h4("Graph Options"),
          column( # Column 1, Simulation Mode
            width = 2,
            textInput(
              inputId = "title",
              label = "Title",
              value = paste("Simulation on",Sys.time())
            ),
            bsTooltip(
              id = "title", 
              title = "Enter a title for your simulation",
              placement = "top", 
              options = list(container = "body")
            ),
            textInput(
              inputId = "caption",
              label = "Caption",
              value = "",
              placeholder = "Enter figure caption"
            ),
            bsTooltip(
              id = "caption", 
              title = "Text to appear below your simulation",
              placement = "bottom", 
              options = list(container = "body")
            ),
            div(
              style = "padding-bottom: 10px;",
              actionButton(
              inputId = "setTarget",
              label = "Suggest",
              icon=icon("fas fa-syringe"),
              width = NULL
              )
            ),
            actionButton(
              inputId = "editDrugs",
              label = "Edit Drugs",
              icon=icon("fas fa-syringe"),
              width = NULL
            )
          ), # End of column
          # Column 2, Simulation Mode
          column(
            width = 2,
            radioButtons(
              inputId = "typical",
              label = "Show typical:",
              choices = c("none","Mid", "Range"),
              selected = "Range",
              inline = FALSE
            ),
            bsTooltip(
              id = "typical", 
              title = "Show typical clinical values",
              placement = "top", 
              options = list(container = "body")
            ),
            radioButtons(
              inputId = "normalization",
              label = "Normalize to:",
              choices = c("none","Peak plasma", "Peak effect site"),
              selected = "none",
              inline = FALSE
            ),
            bsTooltip(
              id = "normalization", 
              title = "Normalization can help show relationships",
              placement = "top", 
              options = list(container = "body")
            )
          ),
          # Select MEAC, Select Interaction, events, and time to emergence
          column(
            width = 2,
            checkboxGroupInput(
              inputId = "addedPlots",
              label = "Additional Plots",
              choices = c("MEAC", "Interaction", "Events", "Time to Emergence"),
            ),
            bsTooltip(
              id = "addedPlots", 
              title = "MEAC normalizes each opioid to the minimum effective analgesic concentration, a measure of opioid potency. Interation shows the opioid hypnotic interaction. It is very preliminary.",
              placement = "top", 
              options = list(container = "body")
            ),
#            conditionalPanel(
#              condition = "output.addedPlots[1] != 'Time to Emergence'",
              checkboxInput(
                inputId = "logY",
                label = "Log Y axis",
                value = FALSE
              ),
              # Add Conditional Panel here - this goes away Time to Emergence appears as an added plot
              bsTooltip(
                id = "logY", 
                title = "Plot Y axis on a log scale",
                placement = "top", 
                options = list(container = "body")
              )
 #           ) # End conditional Panel
            
          ),
          # Column 5, Simulation Mode
          column(
            width = 2,
            selectInput(
              inputId = "maximum",
              label = "Max Time",
              choices = maxtimes$times,
              selected = 60
            ),
            bsTooltip(
              id = "maximum", 
              title = "Maximum time. Axis will automatically expand as you enter more doses, unless maximum is set to 10 minutes",
              placement = "top", 
              options = list(container = "body")
            ),
            uiOutput( # Width = 1
              outputId = "Linetype"
            )
          ),
          column(
            offset = 0,
            width = 4,
            fluidRow(
              column(
                width = 9,
                textInput(
                  inputId = "recipient",
                  label = "Email slide to:"
                ),
                bsTooltip(
                  id = "recipient", 
                  title = "Enter a valid e-mail address",
                  placement = "top", 
                  options = list(container = "body")
                )
              ),
              column(
                width = 3,
                uiOutput("EmailButton")
              )
            ), # End of fluid row
            imageOutput(
              outputId = "sentPlot", 
              height = "100px",
              width = "166px"
              )
          ) # end columnn 
        ) # end fluidRow
      ) # End of right hand colunn
    ), # end of first fluid row
fluidRow(
  uiOutput("plotInfo")
)

) # end dashboardBody
) # end dashboardPage
}

