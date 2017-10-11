# Shell functions for the bintray-upload module.
#/ usage: source RERUN_MODULE_DIR/lib/functions.sh command
#

# Read rerun's public functions
. $RERUN || {
    echo >&2 "ERROR: Failed sourcing rerun function library: \"$RERUN\""
    return 1
}

# Check usage. Argument should be command name.
[[ $# = 1 ]] || rerun_option_usage

# Source the option parser script.
#
if [[ -r $RERUN_MODULE_DIR/commands/$1/options.sh ]] 
then
    . $RERUN_MODULE_DIR/commands/$1/options.sh || {
        rerun_die "Failed loading options parser."
    }
fi

# - - -
# Your functions declared here.
# - - -

#Constants
API=https://api.bintray.com
NOT_FOUND=404
CONFLICT=409
SUCCESS=200
CREATED=201
PACKAGE_DESCRIPTOR=descriptor.json


# check if package exists
# args:
#   1 - subject
#   2 - api key
#   3 - org
#   4 - repo
#   5 - package
# return codes:
#   0 - $SUCCESS
#   1 - not $SUCCESS
#   2 - input error
package_exists() {
   [ $# -ne 5 ] && {
       echo >&2 'usage: package_exists subject apikey org repo package'
       return 2
   }
   local subject=$1 apikey=$2 org=$3 repo=$4 package=$5

   http_code=$(curl -u${subject}:${apikey} --silent -H Accept:application/json \
       --write-out %{http_code} --output /dev/null \
       -X GET ${API}/packages/${org}/${repo}/${package})

   return $(test "$http_code" = ${SUCCESS}; echo $?)
}


# create package
# args:
#   1 - subject
#   2 - api key
#   3 - org
#   4 - repo
#   5 - package
#   6 - (optional) descriptor
# return codes:
#   0 - package exists / package created
#   1 - unexpected response code
#   2 - input error
package_create() {
   [ $# -lt 5 ] && {
       echo >&2 'usage: package_create subject apikey org repo package descriptor'
       return 2
   }
   local subject=$1 apikey=$2 org=$3 repo=$4 package=$5 descriptor=${6:-}
   #search for a descriptor in the current folder or generate one on the fly
   if [ -f "${descriptor}" ]
   then
       data="@${descriptor}"
   else
       data="{
    \"name\": \"${package}\",
    \"desc\": \"\",
    \"desc_url\": \"\",
    }"
   fi

   http_code=$(curl -u${subject}:${apikey} \
       -H Accept:application/json -H Content-Type:application/json \
       --write-out %{http_code}  -o /dev/null -s \
        -X POST -d  "${data}" "${API}/packages/${org}/${repo}")

   case ${http_code} in
       ${CONFLICT}) echo >&2 "Package already created";  return 0 ;;
       ${CREATED}) echo >&2 "Created /${org}/${repo}/${package}"; return 0 ;;
       *) echo >&2 "unexpected response code: $http_code" ; return 1 ;;
   esac
}


# upload package - deb
# args:
#   1 - subject
#   2 - api key
#   3 - org
#   4 - repo
#   5 - package
#   6 - version
#   7 - file
#   8 - distribution
#   9 - component
#   10 - architecture
# return codes:
#   2 - input error
#   see bintray_upload
package_upload_deb() {
   [ $# -ne 10 ] && {
       echo >&2 'usage: package_upload subject apikey org repo package version file dist comp arch'
       return 2
   }
   local subject=$1 apikey=$2 org=$3 repo=$4 package=$5 version=$6 file=$7 dist=$8 comp=$9 arch=${10}

   headers="-H X-Bintray-Package:${package} \
      -H X-Bintray-Version:${version} \
      -H X-Bintray-Publish:1 \
      -H X-Bintray-Override:1 \
      -H X-Bintray-Debian-Distribution:${dist} \
      -H X-Bintray-Debian-Component:${comp} \
      -H X-Bintray-Debian-Architecture:${arch}"

   bintray_upload $subject $apikey $org $repo $package $version $file "$headers"
}


# upload package
# args:
#   1 - subject
#   2 - api key
#   3 - org
#   4 - repo
#   5 - package
#   6 - version
#   7 - file
# return codes:
#   2 - input error
#   see bintray_upload
package_upload() {
   [ $# -ne 7 ] && {
       echo >&2 'usage: package_upload subject apikey org repo package version file'
       return 2
   }
   local subject=$1 apikey=$2 org=$3 repo=$4 package=$5 version=$6 file=$7

   headers="-H X-Bintray-Package:${package} \
      -H X-Bintray-Version:${version} \
      -H X-Bintray-Publish:1 \
      -H X-Bintray-Override:1"

   bintray_upload $subject $apikey $org $repo $package $version $file "$headers"
}


# upload to bintray
# args:
#   1 - subject
#   2 - api key
#   3 - org
#   4 - repo
#   5 - package
#   6 - version
#   7 - file
#   8 - headers
# return codes:
#   0 - uploaded
#   1 - unexpected response code
#   $CONFLICT - conflict
#   2 - input error
bintray_upload() {
   [ $# -ne 8 ] && {
       echo >&2 'usage: bintray_upload subject apikey org repo package version file headers'
       return 2
   }
   local subject=$1 apikey=$2 org=$3 repo=$4 package=$5 version=$6 file=$7 headers="$8"
   filename=$(basename $file)

   http_code=$(curl -u${subject}:${apikey} -H Accept:application/json \
       --write-out %{http_code} --silent --output /dev/null \
       -T ${file} ${headers} \
       -X PUT ${API}/content/${org}/${repo}/${package}/${version}/${filename})

   case ${http_code} in
       ${CREATED}) echo >&2 "Uploaded."; return 0 ;;
       ${CONFLICT}) echo >&2 "Conflict. File already uploaded for /$org/$repo/$package/$version";  return $http_code ;;
       *) echo >&2 "unexpected response code: $http_code" ; return 1 ;;
   esac
}


# publish package
# args:
#   1 - subject
#   2 - api key
#   3 - org
#   4 - repo
#   5 - package
#   6 - version
#   7 - file
# return codes:
#   0 - published / already uploaded
#   1 - unexpected response code
#   2 - input error
package_publish() {
    [ $# -ne 7 ] && {
        echo >&2 'usage: package_publish subject apikey org repo package version file'
        return 2
    }
    local subject=$1 apikey=$2 org=$3 repo=$4 package=$5 version=$6 file=$7

    http_code=$(curl -u${subject}:${apikey} \
        --write-out %{http_code} --silent --output /dev/null \
        -H Accept:application/json -H Content-Type:application/json \
        -d "{ \"discard\": \"false\" }" \
        -X POST ${API}/content/${org}/${repo}/${package}/${version}/publish)

   case ${http_code} in
       ${CONFLICT}) echo >&2 "Package already uploaded";  return 0 ;;
       ${SUCCESS}) echo >&2 "Published file."; return 0 ;;
       *) echo >&2 "unexpected response code: $http_code" ; return 1 ;;
   esac        
}


# delete package
# args:
#   1 - subject
#   2 - api key
#   3 - org
#   4 - repo
#   5 - package
# return codes:
#   0 - deleted
#   1 - unexpected response code
#   2 - input error
package_delete() {
    [ $# -ne 5 ] && {
        echo >&2 'usage: package_delete subject apikey org repo package'
        return 2
    }
    local subject=$1 apikey=$2 org=$3 repo=$4 package=$5

    http_code=$(curl -u${subject}:${apikey} \
        --write-out %{http_code} --silent --output /dev/null \
        -H Accept:application/json -H Content-Type:application/json \
        -X DELETE ${API}/packages/${org}/${repo}/${package} )

   case ${http_code} in
       ${SUCCESS}) echo >&2 "Deleted package."; return 0 ;;
       *) echo >&2 "unexpected response code: $http_code" ; return 1 ;;
   esac        
}


# update package
# args:
#   1 - subject
#   2 - api key
#   3 - org
#   4 - repo
#   5 - package
#   6 - description
#   7 - labels
# return codes:
#   0 - updated
#   1 - unexpected response code
#   2 - input error
package_update() {
    [ $# -ne 7 ] && {
        echo >&2 'usage: package_update subject apikey org repo package desc labels'
        return 2
    }
    local subject=$1 apikey=$2 org=$3 repo=$4 package=$5 desc=$6 labels=$7

    quote_listmembers() {
        comma_separated_list=$1
        declare -a arr
        arr=( ${comma_separated_list//,/ } )
        printf '"%s",' ${arr[*]}
    }

       data="{
    \"desc\": \"${desc}\",
    \"labels\": [$(quote_listmembers ${labels})],
    }"
    http_code=$(curl -u${subject}:${apikey} \
        --write-out %{http_code} --silent --output /dev/null \
        -H Accept:application/json -H Content-Type:application/json \
        -X PATCH -d "${data}" ${API}/packages/${org}/${repo}/${package} )

   case ${http_code} in
       ${SUCCESS}) echo >&2 "Updated package."; return 0 ;;
       *) echo >&2 "unexpected response code: $http_code" ; return $http_code ;;
   esac        
}


# set package attributes
# args:
#   1 - subject
#   2 - api key
#   3 - org
#   4 - repo
#   5 - package
#   6 - (optional) version
# return codes:
#   0 - attributes set
#   1 - unexpected response code
#   2 - input error
package_attributes() {
   [ $# -gt 5 ] && {
       echo >&2 'usage: package_attributes subject apikey org repo package ?version?'
       return 2
   }
   local subject=$1 apikey=$2 org=$3 repo=$4 package=$5 version=${6:-}

   if [ -n "$version" ]
   then
       url=${API}/packages/${org}/${repo}/${package}/versions/$version/attributes
   else
       url=${API}/packages/${org}/${repo}/${package}/attributes
   fi
   TMPFILE='mktemp /tmp/bintray-attributes.XXXXXXXXXX' || exit 1
   http_code=$(curl -u${subject}:${apikey} --silent -H Accept:application/json \
       --write-out %{http_code}  -o $TMPFILE \
       -X GET ${url})
   case ${http_code} in
       ${SUCCESS})    cat $TMPFILE && rm $TMPFILE; return 0 ;;
       *) echo >&2 "unexpected response code: $http_code" ; return 1 ;;
   esac     
}


# scrape bintray package endpoint for versions
# args:
#   1 - bintray subject name
#   2 - bintray repo name
#   3 - bintray package name
# return codes:
#   0 - success, found versions
#   1 - general error
#   2 - input error
#   3 - no versions found when extracting with regex
scrape_bintray_package_for_versions() {
  # input variables
  
  local subject_name="${1:-}"
  local repo_name="${2:-}"
  local package_name="${3:-}"
  
  # function variables
  
  local bintray_endpoint="https://dl.bintray.com"
  local curl_connect_timeout=30
  local curl_max_time=300
  local curl_command="curl --silent --connect-timeout ${curl_connect_timeout} --max-time ${curl_max_time}"
  local curl_endpoint=
  local curl_output=
  local version_re='([0-9]{1,})\.([0-9]{1,})(\.([0-9]{1,})(-(([0-9a-zA-Z]{1,}[.-]{0,1}){0,}[0-9a-zA-Z]{1,})){0,1}){0,1}'
  local grep_re="rel=\"nofollow\">$version_re\/<\/a><\/pre>$"
  local trim_prefix="rel=\"nofollow\">"
  local trim_suffix="\/<\/a></pre>"
  local version_results=
  local version_temp=
  local parsed_version_results=
  local validated_version_results=
  
  # variable validation
  
  if [ -z "$subject_name" ]; then
    rerun_log error 'subject name is null or empty'; return 2
  fi
  
  if [ -z "$repo_name" ]; then
    rerun_log error 'repo name is null or empty'; return 2
  fi
  
  if [ -z "$package_name" ]; then
    rerun_log error 'package name is null or empty'; return 2
  fi
  
  # build endpoint
  
  curl_endpoint="${bintray_endpoint}/${subject_name}/${repo_name}/${package_name}/"
  
  # curl endpoint
  
  curl_output=$($curl_command $curl_endpoint) || {
    rerun_log error "curl command failed with exit code: $?"
    if [ -n "$curl_output" ]; then
      rerun_log error 'dumping curl output:'
      rerun_log error "$curl_output"
    fi
    return 1
  }
  
  # validate results
  
  if [ -z "$curl_output" ]; then
    rerun_log error 'curl output is null or empty'; return 1
  fi
  
  # parse results
  #   return 3 if none matched
  
  version_results=$(echo "$curl_output" | grep -Eo "$grep_re") || return 3
  
  # trim prefix and suffix from results
  
  for version_result in $version_results; do
    version_temp="$version_result"
    version_temp="${version_temp#$trim_prefix}"
    version_temp="${version_temp%$trim_suffix}"
    parsed_version_results+=("$version_temp")
  done
  
  # validate versions
  #   hopefully catches if they were malformed
  #   after trimming prefix and suffix
  
  for parsed_version in ${parsed_version_results[@]}; do
    validated_version_results+=($(echo $parsed_version | grep -Eo "^$version_re$")) || {
      rerun_log error "version failed to validate post-extraction: $parsed_version"; return 1
    }
  done
  
  for validated_version in ${validated_version_results[@]}; do
    echo "$validated_version"
  done
  
  return 0
}


# scrape bintray package version endpoint for files
# args:
#   1 - bintray subject name
#   2 - bintray repo name
#   3 - bintray package name
#   4 - bintray package version
# return codes:
#   0 - success, found files
#   1 - general error
#   2 - input error
#   3 - no versions found when extracting with regex
scrape_bintray_package_version_for_files() {
  # input variables
  
  local subject_name="${1:-}"
  local repo_name="${2:-}"
  local package_name="${3:-}"
  local version="${4:-}"
  
  # function variables
  
  local bintray_endpoint="https://dl.bintray.com"
  local curl_connect_timeout=30
  local curl_max_time=300
  local curl_command="curl --silent --connect-timeout ${curl_connect_timeout} --max-time ${curl_max_time}"
  local curl_endpoint=
  local curl_output=
  local version_re='([0-9]{1,})\.([0-9]{1,})(\.([0-9]{1,})(-(([0-9a-zA-Z]{1,}[.-]{0,1}){0,}[0-9a-zA-Z]{1,})){0,1}){0,1}'
  local grep_re="rel=\"nofollow\">.*$version_re.*<\/a><\/pre>$"
  local trim_prefix="rel=\"nofollow\">"
  local trim_suffix="<\/a></pre>"
  local file_results=
  local file_temp=
  local parsed_file_results=
  local validated_file_results=
  
  # variable validation
  
  if [ -z "$subject_name" ]; then
    rerun_log error 'subject name is null or empty'; return 2
  fi
  
  if [ -z "$repo_name" ]; then
    rerun_log error 'repo name is null or empty'; return 2
  fi
  
  if [ -z "$package_name" ]; then
    rerun_log error 'package name is null or empty'; return 2
  fi
  
  if [ -z "$version" ]; then
    rerun_log error 'version is null or empty'; return 2
  fi
  
  # build endpoint
  
  curl_endpoint="${bintray_endpoint}/${subject_name}/${repo_name}/${package_name}/${version}/"
  
  # curl endpoint
  
  curl_output=$($curl_command $curl_endpoint) || {
    rerun_log error "curl command failed with exit code: $?"
    if [ -n "$curl_output" ]; then
      rerun_log error 'dumping curl output:'
      rerun_log error "$curl_output"
    fi
    return 1
  }
  
  # validate results
  
  if [ -z "$curl_output" ]; then
    rerun_log error 'curl output is null or empty'; return 1
  fi
  
  # parse results
  #   return 3 if none matched
  
  file_results=$(echo "$curl_output" | grep -Eo "$grep_re") || return 3
  
  # trim prefix and suffix from results
  
  for file_result in $file_results; do
    file_temp="$file_result"
    file_temp="${file_temp#$trim_prefix}"
    file_temp="${file_temp%$trim_suffix}"
    parsed_file_results+=("$file_temp")
  done
  
  # validate files
  #   hopefully catches if they were malformed
  #   after trimming prefix and suffix
  
  for parsed_file in ${parsed_file_results[@]}; do
    validated_file_results+=($(echo $parsed_file | grep -Eo "^.*$version_re.*$")) || {
      rerun_log error "file failed to validate post-extraction: $parsed_file"; return 1
    }
  done
  
  for validated_file in ${validated_file_results[@]}; do
    echo "$validated_file"
  done
  
  return 0
}


# format bintray download uri
# args:
#   1 - bintray subject name
#   2 - bintray repo name
#   3 - bintray package name
#   4 - bintray package version
#   4 - bintray file name(s)
# return codes:
#   0 - success
#   2 - input error
format_bintray_download_uri() {
  # input variables
  
  local subject_name="${1:-}"
  local repo_name="${2:-}"
  local package_name="${3:-}"
  local version="${4:-}"
  local input_file_names="${5:-}"
  
  # function variables
  
  local bintray_endpoint="https://dl.bintray.com"
  
  # variable validation
  
  if [ -z "$subject_name" ]; then
    rerun_log error 'subject name is null or empty'; return 2
  fi
  
  if [ -z "$repo_name" ]; then
    rerun_log error 'repo name is null or empty'; return 2
  fi
  
  if [ -z "$package_name" ]; then
    rerun_log error 'package name is null or empty'; return 2
  fi
  
  if [ -z "$version" ]; then
    rerun_log error 'version is null or empty'; return 2
  fi
  
  if [ -z "$input_file_names" ]; then
    rerun_log error 'input file names is null or empty'; return 2
  fi
  
  # format urls
  
  for file_name in $input_file_names; do
    echo "${bintray_endpoint}/${subject_name}/${repo_name}/${package_name}/${version}/${file_name}"
  done
  
  return 0
}
