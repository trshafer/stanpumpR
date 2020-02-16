# Load Libraries
source(file.path("globalPackages.R"), local = TRUE)

options(warn = 2)

source(file.path("globalVariables.R"), local = TRUE)
isShinyLocal <- Sys.getenv('SHINY_PORT') == ""
# cat("isShinyLocal",isShinyLocal,"\n")

if (!isShinyLocal) {
  Sys.setenv(R_CONFIG_ACTIVE = "production")  # Running on Shinyapps
  internetConnected <- TRUE
} else {
  Sys.unsetenv("R_CONFIG_ACTIVE") # Running on laptop
  internetConnected <- FALSE
  appFiles <- dir()
  appFiles <- appFiles[grepl("\\.",appFiles)]
  appFiles <- c(appFiles, "helpers","data","www", "misc")

  source("helpers/havingIP.R")
  if (havingIP() && ping("https://www.google.com")) internetConnected <- TRUE
  library(rsconnect)
  options(shiny.reactlog=TRUE)
  source("misc/deployActive.R")
  source("misc/deployTest.R")
}
config <- config::get()

# Load stanpumpR routines
for (file in list.files("helpers", pattern = "\\.R$")) {
  source(file.path("helpers", file), local = TRUE)
}
# for (file in list.files("R", pattern = "\\.R$")) {
#   source(file.path("R", file), local = TRUE)
# }

# Load other files
#CANCEL <- readPNG("www/cancel.png", native=TRUE)
enableBookmarking(store = "url")

eventDefaults_global <- read.csv("data/Event Defaults.csv", stringsAsFactors = FALSE)
eventDefaults <- eventDefaults_global

drugDefaults_global <- read.csv("data/Drug Defaults.csv", stringsAsFactors = FALSE, na.strings = "")

# Load individual drug routines
for (drug in drugDefaults_global$Drug)
{
  source(file.path("data", "drugs", paste0(drug, ".R")))
}



x <- system.time({
  havingIP <- function() {
    if (.Platform$OS.type == "windows") {
      ipmessage <- system("ipconfig", intern = TRUE)
    } else {
      ipmessage <- system("ifconfig", intern = TRUE)
    }
    validIP <- "((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)[.]){3}(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)"
    any(grep(validIP, ipmessage))
  }
  ping <- function(x, stderr = FALSE, stdout = FALSE, ...){
    pingvec <- system2("ping", x,
                       stderr = FALSE,
                       stdout = FALSE,...)
    if (pingvec == 0) TRUE else FALSE
  }
})
cat("Time to determine if it has an internet connection\n")
print(x)
cat("\n")

# Setup Theme
theme_update(panel.background = element_rect(fill = "white", color = "white"))
theme_update(legend.box.background = element_rect(fill = "white", color = "white"))
theme_update(panel.grid.major.y = element_line(color = "lightgrey"))
theme_update(panel.grid.major.x = element_line(color = "lightgrey"))
theme_update(axis.ticks = element_line(color = "lightgrey"))
theme_update(axis.ticks.length = unit(.25, "cm"))
theme_update(axis.title = element_text(size = rel(1.5)))
theme_update(axis.text = element_text(size = rel(1.2)))
theme_update(axis.line = element_line(size = 1, color = "black"))
theme_update(axis.title = element_text(size = rel(1.5)))
theme_update(legend.key = element_rect(fill = "white"))
theme_update(aspect.ratio = 0.6)
theme_update(plot.title = element_text(size = rel(1.5)))
theme_update(legend.text = element_text(size = rel(0.9)))
theme_update(legend.position = "right")
theme_update(legend.key = element_blank())


introductionPlot <- staticPlot(
  paste(
    "Initializing your session.",
    sep = "\n"
  )
)

nothingtoPlot <- staticPlot(
  paste(
    "Welcome to stanpumpR.",
    "",
    "Please enter the drugs in the table to the left.",
    "Use the pull down menu to select each drug.",
    "Drugs and doses can be entered in any order",
    "Set the units in the last column.",
    "",
    "After plots appear here, you can enter new doses",
    "by clicking on the plot. You can enter new drugs",
    "by double clicking on any plot.",
    sep = "\n"
  )
)


originalUnits <- drugDefaults_global$Units
drugDefaults_global$Units <- strsplit(drugDefaults_global$Units, ",")

blanks <- rep("", 6)
doseTableInit <- data.frame(
  Drug = c("propofol","fentanyl","remifentanil","rocuronium", blanks),
  Time = c(as.character(rep(0,4)), blanks),
  Dose = c(as.character(rep(0,4)), blanks),
  Units = c("mg","mcg","mcg/kg/min","mg", blanks),
  stringsAsFactors = FALSE
)
doseTableNewRow <-  doseTableInit[5, ]

`%then%` <- shiny:::`%OR%`

