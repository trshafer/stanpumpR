

context("processDoseTable")
source(system.file(package = "stanpumpR", mustWork=TRUE, "helpers/calculateCe.R"))

test_that("it returns the correct array", {
emerge <- 1


pkSet2 <- list(
  "v1" = 5.961157,
  "v2" = 17.28924,
  "v3" = 745.6759,
  "cl1" = 1.621863,
  "cl2" = 1.350588,
  "cl3" = 2.381382,
  "k10" = 0.2720718,
  "k12" = 0.2265647,
  "k13" = 0.3994831,
  "k21" = 0.07811724,
  "k31" = 0.003193588,
  "ka_PO" = 0,
  "bioavailability_PO" = 0,
  "tlag_PO" = 0,
  "ka_IM" = 0,
  "bioavailability_IM" = 0,
  "tlag_IM" = 0,
  "ka_IN" = 0,
  "bioavailability_IN" = 0,
  "tlag_IN" = 0,
  "customFunction" = "",
  "lambda_1" = 0.9205201,
  "lambda_2" = 0.05763095,
  "lambda_3" = 0.001279441,
  "ke0" = 0.4341694,
  "p_coef_bolus_l1" = 0.1634289,
  "p_coef_bolus_l2" = 0.003847417,
  "p_coef_bolus_l3" = 0.0004763047,
  "e_coef_bolus_l1" = -0.1458944,
  "e_coef_bolus_l2" = 0.004436282,
  "e_coef_bolus_l3" = 0.0004777124,
  "e_coef_bolus_ke0" = 0.1409804,
  "p_coef_infusion_l1" = 0.1775398,
  "p_coef_infusion_l2" = 0.06675956,
  "p_coef_infusion_l3" = 0.3722755,
  "e_coef_infusion_l1" = -0.1584912,
  "e_coef_infusion_l2" = 0.07697742,
  "e_coef_infusion_l3" = 0.3733758,
  "e_coef_infusion_ke0" = 0.3247129,
  "p_coef_PO_l1" = 0,
  "p_coef_PO_l2" = 0,
  "p_coef_PO_l3" = 0,
  "p_coef_PO_ka" = 0,
  "e_coef_PO_l1" = 0,
  "e_coef_PO_l2" = 0,
  "e_coef_PO_l3" = 0,
  "e_coef_PO_ke0" = 0,
  "e_coef_PO_ka" = 0,
  "p_coef_IM_l1" = 0,
  "p_coef_IM_l2" = 0,
  "p_coef_IM_l3" = 0,
  "p_coef_IM_ka" = 0,
  "e_coef_IM_l1" = 0,
  "e_coef_IM_l2" = 0,
  "e_coef_IM_l3" = 0,
  "e_coef_IM_ke0" = 0,
  "e_coef_IM_ka" = 0,
  "p_coef_IN_l1" = 0,
  "p_coef_IN_l2" = 0,
  "p_coef_IN_l3" = 0,
  "p_coef_IN_ka" = 0,
  "e_coef_IN_l1" = 0,
  "e_coef_IN_l2" = 0,
  "e_coef_IN_l3" = 0,
  "e_coef_IN_ke0" = 0,
  "e_coef_IN_ka" = 0
)
  actual <- calculateCe(Cp, ke0, dt, L)

  expectedCe <- c(0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0)
  expect_equal(actual, expectedCe)
})
