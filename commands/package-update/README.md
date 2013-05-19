Set the description and labels for the specified package.

Example
-------

    rerun bintray:package-update --user ${USER} --apikey ${APIKEY} \
        --org ahonor --repo rerun-bintray --package bintray \
        --labels shell,rerun,bintray --description "rerun module for bintray."
