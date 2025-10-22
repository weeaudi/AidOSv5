#!/usr/bin/env bash
set -euo pipefail
status=0

check_file () {
  local f="$1" line n=0
  while IFS= read -r line || [ -n "$line" ]; do
    n=$((n+1))
    # no tabs
    if [[ "$line" == *$'\t'* ]] && ! [[ "$line" =~ \;\ *STYLE-IGNORE\ TABS ]]; then
      echo "$f:$n: TABS: tab character found"; status=1
    fi
    # trailing whitespace
    if [[ "$line" =~ [[:space:]]$ ]] && ! [[ "$line" =~ \;\ *STYLE-IGNORE\ TRAILWS ]]; then
      echo "$f:$n: TRAILWS: trailing whitespace"; status=1
    fi
    # line length
    if (( ${#line} > 100 )) && ! [[ "$line" =~ \;\ *STYLE-IGNORE\ LONGLINE ]]; then
      echo "$f:$n: LONGLINE: >100 cols"; status=1
    fi
    # label case
    if [[ "$line" =~ ^[A-Za-z0-9_]+:\ *$ ]]; then
      lbl="${line%:}"; if [[ "$lbl" != "${lbl,,}" ]] && ! [[ "$line" =~ \;\ *STYLE-IGNORE\ LABELCASE ]]; then
        echo "$f:$n: LABELCASE: labels must be lowercase"; status=1
      fi
    fi
    # mnemonic case + 4-space indent for instructions
    stripped="${line#"${line%%[! ]*}"}" # leading spaces removed
    if [[ -n "$stripped" && "${stripped:0:1}" != ';' && "${stripped:0:1}" != '.' && ! "$line" =~ ^[a-z0-9_]+:\ *$ ]]; then
      indent=$(( ${#line} - ${#stripped} ))
      if (( indent != 4 )) && ! [[ "$line" =~ \;\ *STYLE-IGNORE\ INDENT ]]; then
        echo "$f:$n: INDENT: instructions indented by 4 spaces"; status=1
      fi
      mnem="${stripped%%[[:space:]]*}"
      if [[ "$mnem" != "${mnem,,}" ]] && ! [[ "$line" =~ \;\ *STYLE-IGNORE\ MNEMONICCASE ]]; then
        echo "$f:$n: MNEMONICCASE: mnemonic must be lowercase"; status=1
      fi
    fi
  done < "$f"
  # ISA tag check (vector use but no header tag)
  if grep -Eq '\b[yz]mm[0-9]+\b|\bv[a-z0-9]{2,}\b' "$f"; then
    if ! head -n 8 "$f" | grep -Eq '^\;\s*ISA:'; then
      echo "$f:1: ISATAG: file uses vector ISA but lacks '; ISA: ...' tag"; status=1
    fi
  fi
}

mapfile -t files < <(git ls-files '*.asm' '*.s' '*.S')
for f in "${files[@]}"; do
  [ -f "$f" ] && check_file "$f"
done

exit $status
