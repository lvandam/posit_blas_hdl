#!/bin/bash
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"

for l in 100 200 300 400 500 1000 2000 3000 4000 5000 10000 20000
do
    $DIR/build/posit_dot $l
done
