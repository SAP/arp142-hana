#!/usr/bin/env bash
#------------------------------------------------------------------
# bashunit migration notes:
# 1. PROGRAM_DIR/PROGRAM_LIBDIR not readonly - bashunit runs all tests in same session
# 2. Conditional assignment prevents conflicts when multiple test files run
#------------------------------------------------------------------
set -u  # treat unset variables as an error

if [[ -z "${PROGRAM_DIR:-}" ]]; then
    PROGRAM_DIR="${BASH_SOURCE[0]%/*}"
    [[ "$PROGRAM_DIR" == "${BASH_SOURCE[0]}" ]] && PROGRAM_DIR="."
fi
if [[ -z "${PROGRAM_LIBDIR:-}" ]]; then
    PROGRAM_LIBDIR="$(cd "${PROGRAM_DIR}/../lib" && pwd)"
fi

function test_checksets_contain_only_valid_checks() {

    #arrange
    for checksetfile in "${PROGRAM_LIBDIR}"/checkset/*.checkset; do

        #printf 'checksetfile: <%s>\n' "${checksetfile}"

        #act
        checklist=$(<"${checksetfile}")

        #assert
        assert_successful_code

        for check in ${checklist}; do

            #printf 'check: <%s>\n' "${check}"

            #act
            file="${PROGRAM_LIBDIR}/check/${check}.check"

            #printf 'check file: <%s>\n' "${file}"

            #assert
            if [[ ! -f "${file}" ]]; then
                bashunit::fail "${checksetfile##*/}:${check} checkfile does NOT exist"
            fi

        done

    done

}

# set_up_before_script() {

# }

# tear_down_after_script
# set_up
# tear_down
