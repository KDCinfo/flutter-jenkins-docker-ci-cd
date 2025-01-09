#!/bin/bash

set -e

# This script can be used to validate that code coverate is 100%
#
# To run in main project:
# ./tool/validate_coverage.sh
#
# To run in other directory:
# ./tool/validate_coverage.sh ./path/to/other/project

very_good test --recursive --coverage --min-coverage 80 --test-randomize-ordering-seed random
