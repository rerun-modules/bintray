#!/usr/bin/env roundup
#
#/ usage:  rerun stubbs:test -m bintray-upload -p package-upload [--answers <>]
#

# Helpers
# -------
[[ -f ./functions.sh ]] && . ./functions.sh

# The Plan
# --------
describe "package-upload"

# ------------------------------
it_fails_when_file_not_found() {

    if ! rerun bintray:package-upload --file /bogus/not/there \
        --user somebody --apikey X0X0 \
        --org ahonor --repo boguses --name bogus --version 0.0.0
    then
        :
    else
        echo "Should have failed."
        exit 1
    fi
}
# ------------------------------

