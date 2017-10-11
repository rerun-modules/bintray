#!/usr/bin/env roundup
#
#/ usage:  rerun stubbs:test -m bintray -p package-uri [--answers <>]
#

# Helpers
# -------
[[ -f ./functions.sh ]] && . ./functions.sh

# Constants
DEFAULT_ORG="example-org"
DEFAULT_REPO="example-repo"
DEFAULT_PACKAGE="example-package"
DEFAULT_VERSION="1.0.0"
DEFAULT_EXTENSION=".tar.gz"
DEFAULT_VERSION_URI_W_EXT="https://dl.bintray.com/${DEFAULT_ORG}/${DEFAULT_REPO}/${DEFAULT_PACKAGE}/${DEFAULT_VERSION}/example-${DEFAULT_VERSION}${DEFAULT_EXTENSION}"
DEFAULT_VERSION_URIS=$(cat <<END_HEREDOC
https://dl.bintray.com/${DEFAULT_ORG}/${DEFAULT_REPO}/${DEFAULT_PACKAGE}/${DEFAULT_VERSION}/example-${DEFAULT_VERSION}.bin
https://dl.bintray.com/${DEFAULT_ORG}/${DEFAULT_REPO}/${DEFAULT_PACKAGE}/${DEFAULT_VERSION}/example-${DEFAULT_VERSION}.tar.bz2
https://dl.bintray.com/${DEFAULT_ORG}/${DEFAULT_REPO}/${DEFAULT_PACKAGE}/${DEFAULT_VERSION}/example-${DEFAULT_VERSION}.tar.gz
https://dl.bintray.com/${DEFAULT_ORG}/${DEFAULT_REPO}/${DEFAULT_PACKAGE}/${DEFAULT_VERSION}/example-${DEFAULT_VERSION}.zip
END_HEREDOC
)
DEFAULT_CURL_MOCK_TEMPFILE="/tmp/curl_mock_counter"
DEFAULT_MISSING_VERSION="1.2.0"
DEFAULT_VERSION_NOT_FOUND_ERROR="ERROR: version not found: ${DEFAULT_MISSING_VERSION}"
DEFAULT_MISSING_EXTENSION=".rar"
DEFAULT_EXTENSION_NOT_FOUND_ERROR="ERROR: extension not found: ${DEFAULT_MISSING_EXTENSION}"

DEFAULT_PACKAGE_RESPONSE_MOCK=$(cat <<'END_HEREDOC'
<html>
<head>
<script>
//1507586309599
function navi(e){
	location.href = e.target.href.replace('/:','/'); e.preventDefault();
}
</script>
</head>
<body>
<pre><a onclick="navi(event)" href=":1.0.0/" rel="nofollow">1.0.0/</a></pre>
<pre><a onclick="navi(event)" href=":1.0.3/" rel="nofollow">1.0.3/</a></pre>
<pre><a onclick="navi(event)" href=":1.4.0/" rel="nofollow">1.4.0/</a></pre>
</body>
</html>
END_HEREDOC
)

DEFAULT_VERSION_RESPONSE_MOCK=$(cat <<'END_HEREDOC'
<html>
<head>
<script>
//1507586542701
function navi(e){
	location.href = e.target.href.replace('/:','/'); e.preventDefault();
}
</script>
</head>
<body>
<pre><a onclick="navi(event)" href=":example-1.0.0.bin" rel="nofollow">example-1.0.0.bin</a></pre>
<pre><a onclick="navi(event)" href=":example-1.0.0.tar.bz2" rel="nofollow">example-1.0.0.tar.bz2</a></pre>
<pre><a onclick="navi(event)" href=":example-1.0.0.tar.gz" rel="nofollow">example-1.0.0.tar.gz</a></pre>
<pre><a onclick="navi(event)" href=":example-1.0.0.zip" rel="nofollow">example-1.0.0.zip</a></pre>
</body>
</html>
END_HEREDOC
)

rerun() {
  command $RERUN -M $RERUN_MODULES "$@"
}

after() {
  if [ -e $DEFAULT_CURL_MOCK_TEMPFILE ]; then
    rm $DEFAULT_CURL_MOCK_TEMPFILE
  fi
}

# The Plan
# --------
describe "package-uri"

# ------------------------------
it_returns_req_ver_uri_when_ver_w_ext_exists() {
  # mock the curl calls
  export DEFAULT_PACKAGE_RESPONSE_MOCK
  export DEFAULT_VERSION_RESPONSE_MOCK
  export DEFAULT_CURL_MOCK_TEMPFILE
  echo 0 > $DEFAULT_CURL_MOCK_TEMPFILE
  curl () {
    curl_mock_counter=$(cat $DEFAULT_CURL_MOCK_TEMPFILE)
    case $curl_mock_counter in
      0)
        echo "$DEFAULT_PACKAGE_RESPONSE_MOCK"
        echo 1 > $DEFAULT_CURL_MOCK_TEMPFILE
        return 0
        ;;
      1)
        echo "$DEFAULT_VERSION_RESPONSE_MOCK"
        echo 2 > $DEFAULT_CURL_MOCK_TEMPFILE
        return 0
        ;;
      *)
        echo >&2 "unexpected call to curl: $@"
        return 1
    esac
    
    return 1
  }
  export -f curl
  
  # invoke rerun
  requested_version_uri=$(rerun bintray: package-uri \
    --org "$DEFAULT_ORG" \
    --repo "$DEFAULT_REPO" \
    --package "$DEFAULT_PACKAGE" \
    --version "$DEFAULT_VERSION" \
    --extension "$DEFAULT_EXTENSION") || echo "rerun test call failed with exit code: $?"
  
  # validate results
  test "$requested_version_uri" == "$DEFAULT_VERSION_URI_W_EXT"
}
# ------------------------------
it_returns_req_ver_uris_when_ver_exists() {
  # mock the curl calls
  export DEFAULT_PACKAGE_RESPONSE_MOCK
  export DEFAULT_VERSION_RESPONSE_MOCK
  export DEFAULT_CURL_MOCK_TEMPFILE
  echo 0 > $DEFAULT_CURL_MOCK_TEMPFILE
  curl () {
    curl_mock_counter=$(cat $DEFAULT_CURL_MOCK_TEMPFILE)
    case $curl_mock_counter in
      0)
        echo "$DEFAULT_PACKAGE_RESPONSE_MOCK"
        echo 1 > $DEFAULT_CURL_MOCK_TEMPFILE
        return 0
        ;;
      1)
        echo "$DEFAULT_VERSION_RESPONSE_MOCK"
        echo 2 > $DEFAULT_CURL_MOCK_TEMPFILE
        return 0
        ;;
      *)
        echo >&2 "unexpected call to curl: $@"
        return 1
    esac
    
    return 1
  }
  export -f curl
  
  # invoke rerun
  requested_version_uris=$(rerun bintray: package-uri \
    --org "$DEFAULT_ORG" \
    --repo "$DEFAULT_REPO" \
    --package "$DEFAULT_PACKAGE" \
    --version "$DEFAULT_VERSION") || echo "rerun test call failed with exit code: $?"
  
  # validate results
  test "$requested_version_uris" == "$DEFAULT_VERSION_URIS"
}
# ------------------------------
it_errors_when_version_not_exist() {
  # mock the curl calls
  export DEFAULT_PACKAGE_RESPONSE_MOCK
  export DEFAULT_VERSION_RESPONSE_MOCK
  export DEFAULT_CURL_MOCK_TEMPFILE
  echo 0 > $DEFAULT_CURL_MOCK_TEMPFILE
  curl () {
    curl_mock_counter=$(cat $DEFAULT_CURL_MOCK_TEMPFILE)
    case $curl_mock_counter in
      0)
        echo "$DEFAULT_PACKAGE_RESPONSE_MOCK"
        echo 1 > $DEFAULT_CURL_MOCK_TEMPFILE
        return 0
        ;;
      1)
        echo "$DEFAULT_VERSION_RESPONSE_MOCK"
        echo 2 > $DEFAULT_CURL_MOCK_TEMPFILE
        return 0
        ;;
      *)
        echo >&2 "unexpected call to curl: $@"
        return 1
    esac
    
    return 1
  }
  export -f curl
  
  # invoke rerun
  version_not_found_error=$(rerun bintray: package-uri \
    --org "$DEFAULT_ORG" \
    --repo "$DEFAULT_REPO" \
    --package "$DEFAULT_PACKAGE" \
    --version "$DEFAULT_MISSING_VERSION" 2>&1) && {
			echo >&2 "rerun command returned 0 exit code"; return 1
		} || true
	
  # validate results
  echo "$version_not_found_error" | grep "$DEFAULT_VERSION_NOT_FOUND_ERROR"
}
# ------------------------------
it_errors_when_extension_not_exist() {
  # mock the curl calls
  export DEFAULT_PACKAGE_RESPONSE_MOCK
  export DEFAULT_VERSION_RESPONSE_MOCK
  export DEFAULT_CURL_MOCK_TEMPFILE
  echo 0 > $DEFAULT_CURL_MOCK_TEMPFILE
  curl () {
    curl_mock_counter=$(cat $DEFAULT_CURL_MOCK_TEMPFILE)
    case $curl_mock_counter in
      0)
        echo "$DEFAULT_PACKAGE_RESPONSE_MOCK"
        echo 1 > $DEFAULT_CURL_MOCK_TEMPFILE
        return 0
        ;;
      1)
        echo "$DEFAULT_VERSION_RESPONSE_MOCK"
        echo 2 > $DEFAULT_CURL_MOCK_TEMPFILE
        return 0
        ;;
      *)
        echo >&2 "unexpected call to curl: $@"
        return 1
    esac
    
    return 1
  }
  export -f curl
  
  # invoke rerun
  extension_not_found_error=$(rerun bintray: package-uri \
    --org "$DEFAULT_ORG" \
    --repo "$DEFAULT_REPO" \
    --package "$DEFAULT_PACKAGE" \
    --version "$DEFAULT_VERSION" \
		--extension "$DEFAULT_MISSING_EXTENSION" 2>&1) && {
			echo >&2 "rerun command returned 0 exit code"; return 1
		} || true
	
  # validate results
  echo "$extension_not_found_error" | grep "$DEFAULT_EXTENSION_NOT_FOUND_ERROR"
}
# ------------------------------
