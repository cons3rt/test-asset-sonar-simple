# Sonar Simple Test Asset

## Usage:

In order to begin scanning with Sonar, you must first create a **Sonar Test Asset** just like this one. Then you can 
begin customizing the source code and even the scan itself.

## Customize your Own

1.  git clone: https://github.com/cons3rt/test-asset-sonar-simple.git
2.  Edit the asset.properties file as needed (e.g. name, description, etc.)
3.  If the scan is to be SCM based: add the required property to sonar-config.properties and the corresponding 
repositories file to the scripts directory (see below)
4.  Otherwise: add the desired source code to the media/source directory (see below)
5.  In the scripts directory, edit the **run_sonarlint.sh** script directly to customize the type of scan to be 
run (if desired).
7.  Upload your new test asset to CONS3RT
8.  Add the new test asset to a deployment or create a test-only deployment and launch
9.  View your results!

# Asset Structure

*   **asset.properties** file: detailing the metadata of the test asset (name, description, etc)
*   **LICENSE** file: Use as desired, defines licensing terms
*   **README.md** file: Add specific information about this test case, such as deployment properties, etc.
*   **config directory**:
    *   **sonar-config.properties** file: defining the required test asset properties (see properties)
*   **scripts directory**:
    *   Required:
        * **executable** script: main script that contains any user logic and defines sonar flow 
    *   Optional:
        *   **SCM** file: contains the json representing one or more repositories to checkout/clone
*   **media directory**: _(optional)_
    * **source directory**: directory containing source code. Must be provided if scan is not SCM based.
    * **tests directory**: directory containing custom tests

# Properties

## sonar-config.properties:

*   **sonar.executable**: _(required)_ the name of the executable file in the scripts directory. This file 
contains the necessary logic and flow to run a sonar scan. See Sonar command line help below.
*   **sonar.scm.file**: _(optional)_ the file detailing the SCM repositor(y/ies) to be accessed. If not provided, 
the scan is assumed to be a local source code scan and the test asset's media directory must contain source code.
*   **sonar.source.path**: _(optional)_ the additional path to the source code to be scanned

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

## Deployment Properties:
*   **Optional:**
    *   **sonar.source.path**: the path to the source code to be scanned, this overrides the path in 
    sonar-config.properties if provided.
    *   **sonar.debug**: whether or not to include the debug flag. **Default**: false

## SCM JSON File:
* **
If a sonar scan is to access one or more remote SCM repositories for source code checkout, then a **sonar.scm.file** 
property must be provided in the **sonar-config.properties**, and the appropriately named file must exist in 
the **scripts directory**.

The SCM file contains one or more repository objects, in a JSON array. If no credentials object is provided or 
a type DEFAULT object is provided, the the default CONS3RT credentials will be used to access the repository. 

**Format**: 

    [
        {
                "type":"GIT",                       (Required: Either GIT or SVN)
                "url":"ssh://git@user-info.git",    (Required: The repostiory url)
                "branch":"master",                  (Optional: The specific branch to checkout)
                
                (Optional Object: used to pass credentials)
                "credentials" : {                   
                    "type": "USER_PASS",            (Required: Either DEFAULT or USER_PASS) 
                    "username":"foo",               (Required: if USER_PASS, the username)
                    "password":"bar",               (Required: if USER_PASS, the password)
                }
        }
    ]
    
# Exported Variables
* **

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

# Additional Notes
* **

As an example the executable script in this test asset, contains logic blocks to do the following:

*   Parse a particular property from the combinedPropsFile, and (if specified) return a default value or the property. 
This is to allow for the use of deployment properties or test asset properties within the executable script that the 
test tool adapter may not export or require normally.


