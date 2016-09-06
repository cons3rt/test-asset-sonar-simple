#!/bin/bash

# Source to get env vars such as JAVA_HOME ( do not remove unless for an explicit reason )
source /etc/bashrc

# Other env vars such as sonarlint, reportDir, and logDir are provided by the adapter itself

function run_and_check_status() {
    "$@"
    local status=$?
    if [ ${status} -ne 0 ] ; then
        echo -n `date "+%D %H:%M:%S"`
        echo " Error executing: $@, exited with code: ${status}"
        exit ${status}
    fi
}

function sonarlint() {
    # Used for debugging of env variables based in by sonar adapter
    printenv > ${logDir}environment_out.log

    echo
    echo -n `date "+%D %H:%M:%S"`
    echo " : Beginning Sonarlint Scan:"
    echo
    echo -n `date "+%D %H:%M:%S"`
    echo " : Using source dir - ${sourceDir}"
    echo
	
    # Change to directory desired for scan:
    echo -n `date "+%D %H:%M:%S"`
    echo " : Changed directory to - ${sourceDir}"
    cd ${sourceDir}

    # Run Scan
    echo -n `date "+%D %H:%M:%S"`
    echo " : Starting Scan."

    run_and_check_status "${sonarlint}" --html-report "${reportDir}SonarScan.html" --debug
    
    echo -n `date "+%D %H:%M:%S"`
    echo " : Scan Completed. Creating html report bundle"
    
    cd ${reportDir}    
    zip -r -x=*log* SonarScanHtmlBundle.zip ./*

    echo -n `date "+%D %H:%M:%S"`
    echo " : Bundle Created."

    echo -n `date "+%D %H:%M:%S"`
    echo " : Creating PDF from html report."

    run_and_check_status "${htmlToPdf}" "${reportDir}SonarScan.html" "${reportDir}SonarScan.pdf"
   
    echo -n `date "+%D %H:%M:%S"`
    echo " : PDF Created."
}

sonarlint > "${logDir}Sonarlint-run.log"
