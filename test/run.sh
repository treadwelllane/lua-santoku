#!/bin/sh

# TODO: getopts to parse iterate options:
#   - test/cov everything
#   - test/cov single with summary of missed
#     lines
#   - custom reporter that understands functions

# TODO: write this in lua

cd "$(dirname "$0")/.."

LUA=$(luarocks config lua_interpreter)

run()
{
  rm -f \
    test/luacov.stats.out \
    test/luacov.report.out
  if [ "$1" = "--build" ]
  then
    luarocks build
    shift
  fi
  if [ "$#" = "0" ]
  then
    covmatch=""
    test_files="test/spec"
    source_files="src"
  else
    covmatch="NR < 4 $(echo "$@" | sed 's/\(\S*\)/|| match(\$0, \"\1\")/')"
    test_files="$(echo "$@" | sed 's/src/test\/spec/')"
    source_files="$@"
  fi
  echo
  if LUA_PATH="./src/?.lua;$LUA_PATH;" \
    busted \
    --lua="$LUA" \
    -f test/busted.lua "$test_files"
  then
    luacov -c test/luacov.lua
    luacheck --config test/luacheck.lua "$source_files"
    cat test/luacov.report.out | \
      awk '/^Summary/ { P = NR } P && NR > P + 1' | \
      awk "$covmatch { print }"
  fi
}

iterate()
{
  while true; do
    run "$@"
    inotifywait -qqr src test/spec test/*.lua test/run.sh \
      -e modify \
      -e close_write
  done
}

[ -z "$1" ] && set run

"$@"
