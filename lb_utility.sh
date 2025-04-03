#!/bin/bash
env="stage" # options: <dev/qa/stage/prod ... etc> ; used to build the properties file name
username="<username>" # options: <list expected options here>; used to determine the changelog file to use
target_servers=( # default list of servers to use when the -s parameter is not specified, in a multi-server environment
    "server1"
    "server2"
    "server3"
)
label_filter="Empty and !Empty" # by default, we don't want to include any changesets, unless specific labels are specified
flag_count=0
usage_message="Usage: $0 -f <label_filter> [-s \"<server1> <server2> ...\"] [-e <env>] [-u <username>]"

# parse command line parameters to override default values
while getopts e:u:f:s: flag
do
    case "${flag}" in
        e)
            p_env=$(echo "${OPTARG}" | tr '[:upper:]' '[:lower:]')
            flag_count=$((flag_count+1))
            ;;
        u) 
            p_username=$(echo "${OPTARG}" | tr '[:lower:]' '[:upper:]')
            flag_count=$((flag_count+1))
            ;;
        f)
            p_label_filter=${OPTARG}
            flag_count=$((flag_count+1))
            ;;
        s)
            p_target_servers=(${OPTARG})
            flag_count=$((flag_count+1))
            ;;
        *) echo "Invalid option: -$OPTARG" >&2; exit 1;;
    esac
done

if [ -z "$p_label_filter" ]; then
    echo "Label filter is required."
    echo $usage_message
    exit 1
fi

# Check that only valid parameters were specified, and no extra parameters
if [ "$#" -gt 0 ] && [ "$#" -ne $((flag_count*2)) ]; then
    echo "Invalid parameters: $@"
    echo $usage_message
    exit 1
fi

# Check if any valid parameters were specified
if [ $flag_count -gt 0 ]; then
    if [ -n "$p_env" ]; then
        env=$p_env
    fi
    if [ -n "$p_username" ]; then
        username=$p_username
    fi
    if [ -n "$p_target_servers" ]; then
        target_servers=(${p_target_servers[@]})
    fi
    if [ -n "$p_label_filter" ]; then
        label_filter=$p_label_filter
    fi
else
    echo "No valid parameters were specified."
    echo $usage_message
    exit 1
fi

# Check for valid environment parameter
case "$env" in
    "stage") ;;
    "prod") ;;
    *)
        echo "Invalid environment specified: $env"
        echo "Expected values: stage, prod"
        exit 1;;
esac

# Check for valid username parameter
case "$username" in
    "<user1>"|"<user2>") ;;
    *)
        echo "Invalid username specified: $username"
        echo "Expected values: <user1>|<user2>"
        exit 1;;
esac

changelog_file_path="src/root-changelog.xml"
if [ "$username" == "<user1>" ]; then
    changelog_file_path="src/root-changelog-<x>.xml"
elif [ "$username" == "<user2>" ]; then
    changelog_file_path="src/root-changelog-<y>.xml"
fi

# echo "env: $env"
# echo "username: $username"
# echo "changelog_file_path: $changelog_file_path"
# echo "filter: $label_filter"
# echo "target_servers: ${target_servers[@]}"
# exit

db_server_config="./db-server.stage.config"
if [ "$env" == "prod" ]; then
    db_server_config="./db-server.prod.config"
fi

# read in properties file to define a variable per server code with the value of the database abbreviation, ignoring commented or empty lines
input=$db_server_config
while IFS= read -r line
do
    case "$line" in
        '#'*) ;;
        '') ;;
        *)
            declare "db_"$line
    esac
done < "$input"

# for target_server in "${target_servers[@]}"; do
#     db_name=db_$target_server
#     echo "server= $target_server, DB=${!db_name}"
# done
# exit



function previewChanges() {
    for target_server in "${target_servers[@]}"; do
        db_name=db_$target_server
        label_filter="(ALL or $target_server) and ($label_filter or POST-DEPLOY-CHECK)"
        echo "============================================================"
        echo "Previewing database changes for $target_server on ${!db_name} $env..."
        liquibase update-sql --labelFilter="$label_filter" --username="$username" --defaults-file="env/$env/liquibase.$env.${!db_name}.properties" --outputfile="output_$target_server.sql" --changelog-file="$changelog_file_path" || {
            echo "An error was encountered... exiting loop..."
            break
        }
        echo "Finished execution for $target_server on ${!db_name} $env!"
        echo "============================================================"
    done
}

function applyChanges() {
    for target_server in "${target_servers[@]}"; do
        db_name=db_$target_server
        label_filter="(ALL or $target_server) and ($label_filter or POST-DEPLOY-CHECK)"
        echo "============================================================"
        echo "Applying database changes for $target_server on ${!db_name} $env..."
        liquibase update --labelFilter="$label_filter" --username="$username" --defaults-file="env/$env/liquibase.$env.${!db_name}.properties" --outputfile="output_$target_server.sql" --changelog-file="$changelog_file_path" || {
            echo "An error was encountered... exiting loop..."
            break
        }
        echo "Finished execution for $target_server on ${!db_name} $env!"
        echo "============================================================"
    done
}