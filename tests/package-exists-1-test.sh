#!/usr/bin/env roundup
#
#/ usage:  rerun stubbs:test -m bintray -p package-exists [--answers <>]
#

# Helpers
# -------
[[ -f ./functions.sh ]] && . ./functions.sh

# The Plan
# --------
describe "package-exists"

# ------------------------------
# Replace this test. 
it_fails_without_a_real_test() {
###    exit 1
  exit 0
}
# ------------------------------

