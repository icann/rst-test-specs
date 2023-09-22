#!sh
#
# this file converts and merges all the files (supplied as arguments) and emits HTML.
# this is used to get the "Test Area" documents into a machine readable format.
#
# Usage: sh 0.docx2html.sh FILE1 [FILE2 [FILE_N]] > output.html
#

pandoc \
    --from docx \
    --to html \
    --standalone "$@" \
        | tidy \
            -quiet \
            -ashtml \
            -indent
