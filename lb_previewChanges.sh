#!/bin/bash
. ./check_liquibase.sh
. ./lb_utility.sh

# Check if liquibase is installed (pass true to allow installation)
install_liquibase false

previewChanges

echo "Done!"