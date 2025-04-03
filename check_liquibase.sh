#!/bin/bash
REQUIRED_VERSION = "4.30.0"

function version_to_number() {
    echo "$@" | awk -F. '{ printf("%d%03d%03d\n", $1, $2, $3); }'
}

function install_liquibase() {
    local allows_install=${1:-false}  # Default to false if not provided

    # Check if liquibase is installed
    if ! command -v liquibase &> /dev/null; then
        if [ "$allows_install" = false ]; then
            echo "WARNING: Liquibase not found. Please install version 4.30.0 or higher"
            exit 1
        else
            echo "Liquibase not found. Installing..."
            if [[ "$OSTYPE" == "darwin"* ]]; then
                brew install liquibase
            elif [[ "$OSTYPE" == "msys" || "$OSTYPE" == "cygwin" ]]; then
                choco install liquibase
            else
                echo "Unsupported OS for automatic installation"
                exit 1
            fi
        fi
    else
        # Get current version.
        current_version=$(liquibase --version | grep -o "[0-9]\+\.[0-9]\+\.[0-9]\+" | tail -1)
        required_version=$REQUIRED_VERSION

        current_num=$(version_to_number $current_version)
        required_num=$(version_to_number $required_version)
        
        if [ $current_num -lt $required_num  ]; then
            echo "Currently installed Liquibase version $current_version is below minumum required version $required_version"
            if [ "$allows_install" = false ]; then
                echo "WARNING: Please update Liquibase to version $required_version or higher"
                echo "You can update Liquibase by running the following function in bash:"
                echo "  install_liquibase true"
                echo "Or by running the following command in your terminal on :"
                if [[ "$OSTYPE" == "darwin"* ]]; then
                    echo "brew update | brew upgrade liquibase"
                elif [[ "$OSTYPE" == "msys" || "$OSTYPE" == "cygwin" ]]; then
                    echo "choco upgrade liquibase"
                fi
                exit 1
            else
                echo "Updating Liquibase to latest version..."
                if [[ "$OSTYPE" == "darwin"* ]]; then
                    brew update | brew upgrade liquibase
                elif [[ "$OSTYPE" == "msys" || "$OSTYPE" == "cygwin" ]]; then
                    choco upgrade liquibase
                fi
            fi
        else
            echo "Liquibase version $current_version is already installed (minimum required version is $required_version)."
        fi
    fi
}

# Example usage:
# install_liquibase true  # Allows install/update mode
# install_liquibase false # Does not allow install/update; only check version mode
# install_liquibase       # Does not allow install/update; only check version mode (default)

#install_liquibase true