RERUN_MODULES=$(pwd)/modules ./rerun stubbs: \
  add-command \
  --command package-uri \
  --description "Retrieves URIs for remote package artifacts of a specified version." \
  --module bintray

# --org
RERUN_MODULES=$(pwd)/modules ./rerun stubbs: \
  add-option \
  --arg "true" \
  --command "package-delete,package-exists,package-update,package-upload,package-upload-deb,package-uri" \
  --description "The bintray organization." \
  --export "false" \
  --long "org" \
  --module "bintray" \
  --option "org" \
  --required "true"

# --repo
RERUN_MODULES=$(pwd)/modules ./rerun stubbs: \
  add-option \
  --arg "true" \
  --command "package-delete,package-exists,package-update,package-upload,package-upload-deb,package-uri" \
  --description "The targeted repo." \
  --export "false" \
  --long "repo" \
  --module "bintray" \
  --option "repo" \
  --required "true"

# --package
RERUN_MODULES=$(pwd)/modules ./rerun stubbs: \
  add-option \
  --arg "true" \
  --command "package-delete,package-exists,package-update,package-upload,package-upload-deb,package-uri" \
  --description "The package name." \
  --export "false" \
  --long "package" \
  --module "bintray" \
  --option "package" \
  --required "true"

# --version
RERUN_MODULES=$(pwd)/modules ./rerun stubbs: \
  add-option \
  --arg "true" \
  --command "package-upload,package-upload-deb,package-uri" \
  --description "The package version." \
  --export "false" \
  --long "version" \
  --module "bintray" \
  --option "version" \
  --required "true"

# --extension
RERUN_MODULES=$(pwd)/modules ./rerun stubbs: \
  add-option \
  --arg "true" \
  --command "package-uri" \
  --description "The package file extension." \
  --export "false" \
  --long "extension" \
  --module "bintray" \
  --option "extension" \
  --required "false"
