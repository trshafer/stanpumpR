# deploy stanpumpR to the test site (stanpumpR_test)
library(here)
library(yaml)

getVariable <- function(variableName) {
  envVariable <- Sys.getenv(variableName)
  if (is.na(envVariable) || envVariable == "") {
    stop(paste(variableName, "is empty"))
  }
  envVariable
}

loginAndDeploy <- function()
{
  account <- getVariable("SHINY_ACCOUNT")
  token <- getVariable("SHINY_TOKEN")
  secret <- getVariable("SHINY_SECRET")
  appName <- getVariable("SHINY_APP_NAME")
  emailUsername <- getVariable("SHINY_CONFIG_EMAIL_USERNAME")
  emailPassword <- getVariable("SHINY_CONFIG_EMAIL_PASSWORD")

  appDir <- here()

  shinyConfig <- list(
    default = list(
      title = "stanpumpR",
      email_username = emailUsername,
      email_password = emailPassword
    )
  )
  write_yaml(shinyConfig, "config.yml", fileEncoding = "UTF-8")

  appFiles <- dir()
  appFiles <- appFiles[grepl("\\.", appFiles)]
  appFiles <- c(appFiles, "R","data","www", "misc")

  print(paste("Deploying app:", appName))
  print(paste("Directory:", appDir))
  print(paste("AppFiles:", appFiles))

  rsconnect::setAccountInfo(name=account, token=token, secret=secret)

  rsconnect::deployApp(
    appDir = appDir,
    appFiles = appFiles,
    forceUpdate = TRUE,
    account = account,
    appName = appName,
    launch.browser = FALSE,
  )
}

loginAndDeploy()
