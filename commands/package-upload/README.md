Use *bintray:package-upload* to upload a package to bintray.

The organization and repository must already exist but
`bintray:package-upload` will create the package and version
if they do not exist at the time of upload.

If a file already has been uploaded for the given package
and version, `bintray:package-upload` will fail with a non-zero
exit code and print a message stating there is a conflict.

See `bintray:package-delete` to delete a package in the repository.

Uploading a file
----------------

    APIKEY=999ea33268d7796006b9793a4xe3434343433ddfdsafdadafsdfs
    USER=ahonor
    
    rerun bintray:package-upload  --user ${USER} --apikey ${APIKEY} \
      --org ahonor --repo rerun-bintray --package bintray --version 1.0.0 \
      --file rerun.bin
