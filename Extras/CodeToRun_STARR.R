library()

install.packages("renv")
packageLocation <- "/workdir/workdir/ExecutionVersion/ApPhenotypeEvaluation" # will need >=510MB of disk space for all packages and dependencies
if (!file.exists(packageLocation)) {
  dir.create(packageLocation, recursive = TRUE)
}
setwd(packageLocation)
download.file("https://raw.githubusercontent.com/eminty/ApPhenotypeEvaluation/main/renv.lock", "renv.lock")
renv::init()

# database settings ============================================================

databaseId <- "STARR"
cdmDatabaseSchema <- "som-rit-phi-starr-prod.starr_omop_cdm5_deid_latest"
cohortDatabaseSchema <- "som-nero-nigam-starr.acute_panc_phe_eval"
cohortTable <- "ap_phe_eval"

# local settings ===============================================================
studyFolder <- "/workdir/workdir/"
tempFolder <- ""
options(andromedaTempFolder = tempFolder,
        spipen = 999)
outputFolder <- file.path(studyFolder, databaseId)

# specify connection details ===================================================

jsonPath <- "/workdir/gcloud/application_default_credentials.json"
bqDriverPath <- "/workdir/workdir/BQDriver/"
project_id <- "som-nero-nigam-starr"
dataset_id <- "acute_panc_phe_eval"

connectionString <-  BQJdbcConnectionStringR::createBQConnectionString(projectId = project_id,
                                                                       defaultDataset = dataset_id,
                                                                       authType = 2,
                                                                       jsonCredentialsPath = jsonPath)

connectionDetails <- DatabaseConnector::createConnectionDetails(dbms="bigquery",
                                                                connectionString=connectionString,
                                                                user="",
                                                                password='',
                                                                pathToDriver = bqDriverPath)
# # Create a test connection
# connection <- DatabaseConnector::connect(connectionDetails)
# 
# sql <- "
# SELECT
#  COUNT(1) as counts
# FROM
#  `bigquery-public-data.cms_synthetic_patient_data_omop.care_site`
# "
# 
# counts <- DatabaseConnector::querySql(connection, sql)
# 
# print(counts)
# DatabaseConnector::disconnect(connection)
# execute study ================================================================
library(magrittr)
ApPhenotypeEvaluation::execute(
  connectionDetails = connectionDetails,
  cdmDatabaseSchema = cdmDatabaseSchema,
  cohortDatabaseSchema = cohortDatabaseSchema,
  cohortTable = cohortTable,
  outputFolder = outputFolder,
  databaseId = databaseId,
  createCohortTable = TRUE, # TRUE will delete the cohort table and all existing cohorts if already built X_X
  createCohorts = TRUE,
  runCohortDiagnostics = TRUE,
  runValidation = TRUE
)

# review results ===============================================================
ApPhenotypeEvaluation::compileShinyData(outputFolder)
ApPhenotypeEvaluation::launchResultsExplorer(outputFolder)

## share results ===============================================================
ApPhenotypeEvaluation::shareResults(
  outputFolder = outputFolder,
  keyFileName = "", # data sites will receive via email
  userName = "" # data sites will receive via email
)
