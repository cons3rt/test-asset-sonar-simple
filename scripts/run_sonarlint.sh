#!/bin/bash

# Sample run_sonarlint.sh script
#
# Provided by: Jackpine Technologies Corp.
#
# Authors: John Paulo (john.paulo@jackpinetech.com) and Joe Yennaco
#          (joe.yennaco@jackpinetech.com)
#
# Usage: This script executes your desired Sonarlint build, scan, and report
#        generation actions.
#
# This script will be executed:
#   1. After your Sonarlint Scanner VM initially deploys
#   2. Each time you click the "Retest" button
#
# Feel free to use as is!  It should work in most cases.  If you would like to
# customize your scan output format, results, or build commands, you can edit
# the commands in the run_sonarlint function below.
#
# The following variables are exported for use in the this script:
#
# reportDir: the path to the report directory, to be included in the test results
# logDir: the path to the log directory, to be included in the test results
# combinedPropsFile**: the file that contains both deployment properties, and test asset properties
# sonarDebug: either true or false, based on deployment property
# sourceDir: the path to the source code directory
# sourceCodePath: the path to source code within the source code directory.
# testsDir: the path to the test asset's media/tests directory _(empty if not included in test asset)_
# sonarlint: the path to sonarlint executable
# htmlToPdf: the path to the htmlToPdf converter executable
#

# Source the environment
if [ -f /etc/bashrc ] ; then
    . /etc/bashrc
fi
if [ -f /etc/profile ] ; then
    . /etc/profile
fi
if [ -f /etc/profile.d/scm.sh ] ; then
    . /etc/profile.d/scm.sh
fi
if [ -f /etc/profile.d/mvn.sh ] ; then
    . /etc/profile.d/mvn.sh
fi

# Configure log files
# Establish a log file and log tag
logTag="run_sonarlint"
sonarLogDir="/home/cons3rt/sonar/logs"
sonarLogFile="${sonarLogDir}/${logTag}-$(date "+%Y%m%d-%H%M%S").log"

######################### GLOBAL VARIABLES #########################

# Deployment home and props file
deploymentHome=
deploymentPropertiesFile=
deploymentPropertiesSh=

####################### END GLOBAL VARIABLES #######################

function timestamp() { date "+%F %T"; }
function logInfo() { echo -e "$(timestamp) ${logTag} [INFO]: ${1}" >> ${sonarLogFile}; }
function logWarn() { echo -e "$(timestamp) ${logTag} [WARN]: ${1}" >> ${sonarLogFile}; }
function logErr() { echo -e "$(timestamp) ${logTag} [ERROR]: ${1}" >> ${sonarLogFile}; }

function set_asset_dir() {
    # Ensure ASSET_DIR exists, if not assume this script exists in ASSET_DIR/scripts
    if [ -z "${ASSET_DIR}" ] ; then
        logWarn "ASSET_DIR not found, assuming ASSET_DIR is 1 level above this script ..."
        SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
        export ASSET_DIR="${SCRIPT_DIR}/.."
    fi
}

function read_deployment_properties() {
    # Ensure DEPLOYMENT_HOME exists
    if [ -z "${DEPLOYMENT_HOME}" ] ; then
        logWarn "DEPLOYMENT_HOME is not set, attempting to determine..."
        deploymentDirCount=$(ls /opt/cons3rt-agent/run | grep Deployment | wc -l)
        # Ensure only 1 deployment directory was found
        if [ ${deploymentDirCount} -ne 1 ] ; then
            logErr "Could not determine DEPLOYMENT_HOME"
            return 1
        fi
        # Get the full path to deployment home
        deploymentDir=$(ls /opt/cons3rt-agent/run | grep "Deployment")
        deploymentHome="/opt/cons3rt-agent/run/${deploymentDir}"
        export DEPLOYMENT_HOME="${deploymentHome}"
    else
        deploymentHome="${DEPLOYMENT_HOME}"
    fi
    deploymentPropertiesFile="${deploymentHome}/deployment.properties"
    deploymentPropertiesSh="${deploymentHome}/deployment-properties.sh"
    if [ ! -f ${deploymentPropertiesFile} ]; then logErr "Deployment properties file not found: ${deploymentPropertiesFile}"; return 2; fi
    if [ ! -f ${deploymentPropertiesSh} ]; then logErr "Deployment properties file not found: ${deploymentPropertiesSh}"; return 3; fi
    . ${deploymentPropertiesSh}
    if [ $? -ne 0 ]; then logErr "Souring deployment properties file: ${deploymentPropertiesSh}"; return 4; fi
    return 0
}

function run_sonarlint() {
    logInfo "Running run_sonarlint.sh..."
    set_asset_dir
    read_deployment_properties
    if [ $? -ne 0 ]; then logErr "Problem reading deployment properties"; return 1; fi

    logInfo "Printing environment variables before running the scan..."
    printenv >> ${sonarLogFile} 2>&1

    # Ensure the sourceDir var is set and a valid directory
    if [ -z "${souceDir}" ]; then logErr "Required environment variable is not set: sourceDir"; return 2; fi
    if [ ! -d ${sourceDir} ]; then logErr "sourceDir is not a valid directory: ${sourceDir}"; return 3; fi

    # Ensure the sonarlint env var is set and valid
    if [ -z "${sonarlint}" ]; then logErr "Required environment variable is not set: sonarlint"; return 4; fi
    if [ ! -f ${sonarlint} ]; then logErr "sonarlint is not a valid path: ${sonarlint}"; return 5; fi

    # Ensure the reportDir var is set and a valid directory
    if [ -z "${reportDir}" ]; then logErr "Required environment variable is not set: reportDir"; return 6; fi
    if [ ! -d ${reportDir} ]; then logErr "sourceDir is not a valid directory: ${reportDir}"; return 7; fi

    # Ensure the htmlToPdf env var is set and valid
    if [ -z "${htmlToPdf}" ]; then logErr "Required environment variable is not set: htmlToPdf"; return 8; fi
    if [ ! -f ${htmlToPdf} ]; then logErr "htmlToPdf is not a valid path: ${htmlToPdf}"; return 9; fi

    # Change to the source directory
    logInfo "Changing to directory: ${sourceDir}"
    cd ${sourceDir}
    logInfo "Using sonarlint executable: ${sonarlint}"

    # Build the sonarlint command
    sonarCmd="${sonarlint} --html-report ${reportDir}SonarScan.html"

    # Append debug if set
    if [[ ${sonarDebug} == "true" ]]; then
        logInfo "Found sonarDebug set to true, appending --debug to the sonarlint command..."
        sonarCmd="${sonarCmd} --debug"
    fi

    # Run the command
    logInfo "Beginning Sonarlint scan of directory: ${sourceDir}"
	${sonarCmd} >> ${sonarLogFile} 2>&1
	scanRes=$?
	if [ ${scanRes} -ne 0 ]; then
	    logWarn "Sonarlint scanner exited with code: ${scanRes}"
	else
	    logInfo "Sonarlint scanner exited successfully!"
	fi

    # Create report bundle
    logInfo "Scan Completed. Creating html report bundle..."
    cd ${reportDir}    
    zip -r -x=*log* SonarScanHtmlBundle.zip ./* >> ${sonarLogFile} 2>&1
    if [ $? -ne 0 ]; then
        logErr "There was a problem creating the Sonar scan bundle"
        return 10
    fi
    logInfo "Results Bundle Created"

    # Create the PDF output file
    logInfo "Creating PDF from html report...."
    ${htmlToPdf} ${reportDir}SonarScan.html ${reportDir}SonarScan.pdf >> ${sonarLogFile} 2>&1
    if [ $? -ne 0 ]; then
        logWarn "There was a problem creating the PDF report: ${reportDir}SonarScan.pdf"
    else
        logInfo "Successfully created PDF report: ${reportDir}SonarScan.pdf"
    fi
   
    logInfo "Completed the Sonarlink ETT run!"
    return ${scanRes}
}

# Set up the log file
mkdir -p ${sonarLogDir}
chmod 700 ${sonarLogDir}
touch ${sonarLogFile}
chmod 644 ${sonarLogFile}

run_sonarlint
result=$?
cat ${sonarLogFile}
cp -f ${sonarLogFile} ${logDir}/

logInfo "Exiting with code ${result} ..."
exit ${result}
