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
PACKAGE_DESCRIPTOR=bintray-package.json


function package_exists {
   [ $# -ne 5 ] && {
       echo >&2 'usage: package_exists subject apikey org repo name'
       return 2
   }
   local subject=$1 apikey=$2 org=$3 repo=$4 name=$5

   http_code=$(curl -u${subject}:${apikey} --silent -H Accept:application/json \
       --write-out %{http_code} --output /dev/null \
       -X GET ${API}/packages/${org}/${repo}/${name})

   exists=$(test "$http_code" = ${SUCCESS}; echo $?)
   yn=$(test ${exists} -eq 0 && echo yes || echo no)
   return ${exists} 
}

function package_create {
   [ $# -lt 5 ] && {
       echo >&2 'usage: package_create subject apikey org repo name descriptor'
       return 2
   }
   local subject=$1 apikey=$2 org=$3 repo=$4 name=$5 descriptor=${6:-}
   #search for a descriptor in the current folder or generate one on the fly
   if [ -f "${descriptor}" ]
   then
       data="@${descriptor}"
   else
       data="{
    \"name\": \"${name}\",
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
       ${CREATED}) echo >&2 "Created /${org}/${repo}/${name}"; return 0 ;;
       *) echo >&2 "unexpected response code: $http_code" ; return 1 ;;
   esac
}

function package_upload {
   [ $# -ne 7 ] && {
       echo >&2 'usage: package_upload subject apikey org repo name version file'
       return 2
   }
   local subject=$1 apikey=$2 org=$3 repo=$4 name=$5 version=$6 file=$7
   filename=$(basename $file)

   http_code=$(curl -u${subject}:${apikey} -H Accept:application/json \
       --write-out %{http_code} --silent --output /dev/null \
       -T ${file} -H X-Bintray-Package:${name} -H X-Bintray-Version:${version} \
       -X PUT ${API}/content/${org}/${repo}/${name}/${version}/${filename})

   case ${http_code} in
       ${CREATED}) echo >&2 "Uploaded."; return 0 ;;
       ${CONFLICT}) echo >&2 "Conflict. File already uploaded for /$org/$repo/$name/$version";  return 1 ;;
       *) echo >&2 "unexpected response code: $http_code" ; return 1 ;;
   esac
}

function package_publish {
    [ $# -ne 7 ] && {
        echo >&2 'usage: package_publish subject apikey org repo name version file'
        return 2
    }
    local subject=$1 apikey=$2 org=$3 repo=$4 name=$5 version=$6 file=$7

    http_code=$(curl -u${subject}:${apikey} \
        --write-out %{http_code} --silent --output /dev/null \
        -H Accept:application/json -H Content-Type:application/json \
        -d "{ \"discard\": \"false\" }" \
        -X POST ${API}/content/${org}/${repo}/${name}/${version}/publish)

   case ${http_code} in
       ${CONFLICT}) echo >&2 "Package already uploaded";  return 0 ;;
       ${SUCCESS}) echo >&2 "Published file."; return 0 ;;
       *) echo >&2 "unexpected response code: $http_code" ; return 1 ;;
   esac        
}


function package_delete {
    [ $# -ne 5 ] && {
        echo >&2 'usage: package_delete subject apikey org repo name'
        return 2
    }
    local subject=$1 apikey=$2 org=$3 repo=$4 name=$5

    http_code=$(curl -u${subject}:${apikey} \
        --write-out %{http_code} --silent --output /dev/null \
        -H Accept:application/json -H Content-Type:application/json \
        -X DELETE ${API}/packages/${org}/${repo}/${name} )

   case ${http_code} in
       ${SUCCESS}) echo >&2 "Deleted package."; return 0 ;;
       *) echo >&2 "unexpected response code: $http_code" ; return 1 ;;
   esac        
}

function package_update {
    [ $# -ne 7 ] && {
        echo >&2 'usage: package_update subject apikey org repo name desc labels'
        return 2
    }
    local subject=$1 apikey=$2 org=$3 repo=$4 name=$5 desc=$6 labels=$7

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
        -X PATCH -d "${data}" ${API}/packages/${org}/${repo}/${name} )

   case ${http_code} in
       ${SUCCESS}) echo >&2 "Updated package."; return 0 ;;
       *) echo >&2 "unexpected response code: $http_code" ; return 1 ;;
   esac        
}
