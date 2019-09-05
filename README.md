# Sonar Simple Test Asset

## Usage:

In order to begin scanning with Sonar, you must first create a **Sonar Test Asset** just like this one. Then you can 
begin customizing the source code and even the scan itself.

## Customize your Own

* Clone this repo: `git clone https://github.com/cons3rt/test-asset-sonar-simple.git`
* Edit the `asset.properties` file as needed (name, description, etc.)
* Provide source code to be scanned, 2 options are:
  * Clone source code from a git or subversion source code repository:
    * Add one or more repositories to the `scripts/repositories.json` file, use the 
    provided `repositories-samples.json` for format on how to include repo info and credentials
  * Include source code in this test asset
    * Add source code directories and files to the `media/source` directory of this asset(see below)
    * Comment out the `sonar.scm.file` in `config/sonar-config.properties`
* If needed, edit the `scripts/run_sonarlint.sh` script to customize the scan (sonarlint help below)
* Import your new test asset to CONS3RT [instructions here](https://kb.cons3rt.com/kb/elastic-tests/import-a-test-asset)
* Run your scan! [instructions here](https://kb.cons3rt.com/articles/sonar-scans)

# Asset Structure

~~~
asset.properties (required): metadata for the test asset (name, description, etc)
LICENSE (required): User agreement for this test asset
README.md (required): Info about this test asset, such as custom properties, etc.
config/ 
    sonar-config.properties (required): defines the required test asset properties
scripts/
    run_sonarlint.sh (required): main script that contains any user logic and defines sonar flow 
    respositories.json (optional): contains data for one or more repositories to scan
media/ (optional)
    source/ (optional): directory containing source code, provide if repositories.json is not being used
    tests/  (optional): directory containing custom tests
~~~

# Properties

## sonar-config.properties:

~~~
# REQUIRED
# The executable script that runs the sonar scan
# This file contains the necessary logic and flow to run a sonar scan. See Sonar command line help below.
sonar.executable=run_sonarlint.sh

# OPTIONAL
# The file detailing the SCM repositor(y/ies) to be scanned. If not provided, the scan is assumed to be a local source code scan and the test asset's media directory must contain source code.
sonar.scm.file=repositories.json

# OPTIONAL
# Additional path to the source code to be scanned in addition to media/source
# Default: Scan everything in media/source
sonar.source.path=my/sub/module
~~~

###### Sonar Command Line Help

Use the following options to customize your run_sonarlint.sh script using the `${sonarlint}` variable as the 
path to the sonarlint command line executable.  For example:

`${sonarlint} --html-report ${reportDir}SonarScan.html --debug --exclude **/dir/*.png`

Here is the sonarlint help:

~~~
# /opt/sonar/sonarlint-cli-2.0/bin/sonarlint --help
INFO: 
INFO: usage: sonarlint [options]
INFO: 
INFO: Options:
INFO:  -u,--update              Update binding with SonarQube server before analysis
INFO:  -D,--define <arg>        Define property
INFO:  -e,--errors              Produce execution error messages
INFO:  -h,--help                Display help information
INFO:  -v,--version             Display version information
INFO:  -X,--debug               Produce execution debug output
INFO:  -i,--interactive         Run interactively
INFO:  --html-report <path>     HTML report output path (relative or absolute)
INFO:  --src <glob pattern>     GLOB pattern to identify source files
INFO:  --tests <glob pattern>   GLOB pattern to identify test files
INFO:  --exclude <glob pattern> GLOB pattern to exclude files
INFO:  --charset <name>         Character encoding of the source files
~~~

## Custom Properties (add when creating a Deployment or launching a Run):
*   **Optional:**
    *   **sonar.source.path**: the path to the source code to be scanned, this overrides the path in 
    sonar-config.properties if provided.
    *   **sonar.debug**: whether or not to include the debug flag. **Default**: false

## repositories.json File:

If a sonar scan is to access one or more remote SCM repositories for source code checkout, then a `sonar.scm.file` 
property must be provided in the `sonar-config.properties`, and a file with that name must exist in 
the `scripts` directory (e.g. `repositories.json`).

The SCM file contains one or more repository objects, in a JSON array. If no credentials object is provided or 
a type DEFAULT object is provided, the the default CONS3RT credentials will be used to access the repository. 

**Format**: 

    [
        {
                "type":"GIT",                       (Required: Either GIT or SVN)
                "url":"ssh://git@user-info.git",    (Required: The repostiory url)
                "branch":"master",                  (Optional: The specific branch to checkout)                
                "credentials" : {                   
                    "type": "USER_PASS",            (Required: Either DEFAULT or USER_PASS) 
                    "username":"foo",               (Required: if USER_PASS, the username)
                    "password":"bar",               (Required: if USER_PASS, the password)
                }
        }
    ]
    
# Exported Variables

As part of the test tool adapter, the following variables are exported for use in the executable script:

*   **reportDir**: the path to the report directory, to be included in the test results
*   **logDir**: the path to the log directory, to be included in the test results
*   **combinedPropsFile**: the file that contains both deployment properties, and test asset properties
*   **sonarDebug**: either true or false, based on deployment property
*   **sourceDir**: the path to the source code directory
*   **sourceCodePath**: the path to source code within the source code directory.
*   **testsDir**: the path to the test asset's media/tests directory _(empty if not included in test asset)_
*   **sonarlint**: the path to sonarlint executable
*   **htmlToPdf**: the path to the htmlToPdf converter executable

Any of the above variables can be accessed within the sonar executable script, format. **${sourceDir}**

## Use with DI2E and Forge.mil

* [Documentation on integrations with DI2E and Forge.mil](https://kb.cons3rt.com/articles/source-code-accounts/)

# Additional Notes

* The sonarlint CLI has been deprecated, and the development team is working on a replacement
