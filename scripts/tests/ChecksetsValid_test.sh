#!/usr/bin/env bash
set -u  # treat unset variables as an error

PROGRAM_DIR="$( cd "${BASH_SOURCE[0]%/*}" && pwd )"
readonly PROGRAM_DIR
PROGRAM_LIBDIR="$(cd "${PROGRAM_DIR}/../lib" && pwd)"
readonly PROGRAM_LIBDIR

testChecksetsContainOnlyValidChecks() {

    #arrange
    for checksetfile in "${PROGRAM_LIBDIR}"/checkset/*.checkset; do

        #printf 'checksetfile: <%s>\n' "${checksetfile}"

        #act
        checklist=$(<"${checksetfile}")

        #assert
        assertTrue "Could not load checkset file ${checksetfile}"   "$?"

        for check in ${checklist}; do

            #printf 'check: <%s>\n' "${check}"

            #act
            file="${PROGRAM_LIBDIR}/check/${check}.check"

            #printf 'check file: <%s>\n' "${file}"

            #assert
            assertTrue "${checksetfile##*/}:${check} checkfile does NOT exist"   "[ -f \"${file}\" ]"

        done

    done

}

# oneTimeSetUp() {

# }

# oneTimeTearDown
# setUp
# tearDown

#Import Libraries
# - order is important - sourcing shunit triggers testing
# - that's also the reason, why it could not be done during oneTimeSetup

#Load and run shUnit2
#shellcheck source=./shunit2
source "${PROGRAM_DIR}/shunit2"
