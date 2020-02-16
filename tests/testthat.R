library(testthat)
library(stanpumpR)

source(file.path (proj_dir, 'R/BDProb.R'))

source(file.path("..","helpers", "calculateCe.R"))
test_check("stanpumpR")

# source(file.path("..","globalVariables.R"))
