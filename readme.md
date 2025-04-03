# Weclome!

This repo is a barebones setup to wrap Liquibase with a few additional checks and constraints in order to target multiple servers and databases. Changesets can be labeled to only apply to specific databases and/or servers.

# Using Liquibase to deploy from the command line

In order to use Liquibase to deploy database changes to your databases, you'll need to:

- clone/copy this repo, to setup source control for your migration scripts
- install [Liquibase](https://docs.liquibase.com/start/install/home.html)
    - Starting with version 4.30.0, you can use Homebrew or Chocolatey to install
    ```shell
    #Homebrew:
    >brew install liquibase

    #Chocolatey:
    >choco install liqibase
    ```
- run a preview of changes to verify that connections are working


## Bash scripts

1. lb_utility.sh
You won't need to run this script directly, but it is good to know that this is where all of the logic is kept for easy maintenance. This means that there is a single place to make changes, which will then be used by the preview and apply scripts. This script is where the list of default servers is located.

2. lb_previewChanges.sh
This script runs the Liquibase `update-sql` command, which generates an output file per target database with the sql that would be run. This is a what-if operation that does not actually execute any sql against the target database, and is useful for verifying that your parameters are correct on the command line and that the labels are correct in the sql files.

3. lb_applyChanges.sh
This script runs the Liquibase `update` command, executes the sql statements from the included changesets against the target databases.

## Command line parameters

`-f` - Label filter: This parameter expects a string value that is used to filter the changesets to include by matching to a label. Typically this will either be a ticket reference or a release tag. If no value is provided, the default will result in no matched changesets.

`-e` - Environment: This parameter expects a value such as `stage` or `prod`. Controls the environment configurations to use.

`-s` - Server list: This parameter can either be a single server or a quoted list of servers like `"server1 server2"`. If specified, this list is used instead of the default target server list, which means that this parameter can also be used to apply changes to servers not included in the default list.

`-u` - Username: Specifying this value controls which root changelog file is used, allowing different changes per username.

## Deployment examples

### WIP changes
Add .sql scripts to the apropriate work in progress folder:
- <default_username> changes: `./src/work-in-progress/`
- <secondary_username> changes: `./src/work-in-progress-<username>/`

Deploy to stage using default list of servers/databases using default NDS user:
```
\> bash lb_applyChanges.sh -f TICKET-12345
or
\> bash lb_applyChanges.sh -f TICKET-12345 -e stage
```

Deploy to stage using specified list of servers/databases using default NDS user:
```
\> bash lb_applyChanges.sh -f TICKET-12345 -s "server1 server2"
or
\> bash lb_applyChanges.sh -f TICKET-12345 -s "server1 server2" -e stage
```

deploy to stage using default list of servers/databases using specified user:
```
\> bash lb_applyChanges.sh -f TICKET-12345 -u <secondary_username>
or
\> bash lb_applyChanges.sh -f TICKET-12345 -e stage -u <secondary_username>
```

## Common Liquibase SQL changeset parameters

|Parameter|Definition|
|---|---|
|`--stripComments:false`|Use this if you want to keep any comments within the object definition.|
|`--splitStatements:false`|Use this for PL/SQL objects or anonomus PL/SQL blocks to avoid splitting the statements on the default delimiter (;).|
|`--endDelimiter:/`|Use this to change the default delimiter to something other than a semi-colon (;), such as for PL/SQL objects and anonomus PL/SQL blocks.|
|`--runOnChange:true`|Use this to allow a changeset to be re-run after it was successful and there have been additional changes, such as for PL/SQL objects.|
|`--runAlways:true`|Use this to force a changeset to be re-run every time, whether or not it previously succeeded.|
|`ignore:true`|Use this to skip a changeset.|
