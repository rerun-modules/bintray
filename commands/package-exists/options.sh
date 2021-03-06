# Generated by stubbs:add-option. Do not edit, if using stubbs.
# Created: Tue Oct 10 22:51:29 CDT 2017
#
#/ usage: bintray:package-exists  --user <>  --org <>  --package <>  --repo <>  --apikey <> 

# _rerun_options_parse_ - Parse the command arguments and set option variables.
#
#     rerun_options_parse "$@"
#
# Arguments:
#
# * the command options and their arguments
#
# Notes:
#
# * Sets shell variables for any parsed options.
# * The "-?" help argument prints command usage and will exit 2.
# * Return 0 for successful option parse.
#
rerun_options_parse() {
  
    unrecognized_args=()

    while (( "$#" > 0 ))
    do
        OPT="$1"
        case "$OPT" in
            --user) rerun_option_check $# $1; USER=$2 ; shift 2 ;;
            --org) rerun_option_check $# $1; ORG=$2 ; shift 2 ;;
            --package) rerun_option_check $# $1; PACKAGE=$2 ; shift 2 ;;
            --repo) rerun_option_check $# $1; REPO=$2 ; shift 2 ;;
            --apikey) rerun_option_check $# $1; APIKEY=$2 ; shift 2 ;;
            # help option
            -\?|--help)
                rerun_option_usage
                exit 2
                ;;
            # unrecognized arguments
            *)
              unrecognized_args+=("$OPT")
              shift
              ;;
        esac
    done

    # Set defaultable options.

    # Check required options are set
    [[ -z "$USER" ]] && { echo >&2 "missing required option: --user" ; return 2 ; }
    [[ -z "$ORG" ]] && { echo >&2 "missing required option: --org" ; return 2 ; }
    [[ -z "$PACKAGE" ]] && { echo >&2 "missing required option: --package" ; return 2 ; }
    [[ -z "$REPO" ]] && { echo >&2 "missing required option: --repo" ; return 2 ; }
    [[ -z "$APIKEY" ]] && { echo >&2 "missing required option: --apikey" ; return 2 ; }
    # If option variables are declared exportable, export them.

    # Make unrecognized command line options available in $_CMD_LINE
    if [ ${#unrecognized_args[@]} -gt 0 ]; then
      export _CMD_LINE="${unrecognized_args[@]}"
    fi
    #
    return 0
}


# If not already set, initialize the options variables to null.
: ${USER:=}
: ${ORG:=}
: ${PACKAGE:=}
: ${REPO:=}
: ${APIKEY:=}
# Default command line to null if not set
: ${_CMD_LINE:=}


