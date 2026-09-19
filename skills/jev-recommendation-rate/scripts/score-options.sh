#!/usr/bin/env bash
# Score the options of one round of multiple-choice questions with TypeSafe's Jev.
#
# Reads the round as JSON on stdin:
#   {
#     "brief_file": "<path>",            # shared context, written once per session
#     "decision":   "<1-2 sentences>",   # what this round decides
#     "questions": [
#       { "id": "...", "question": "...",
#         "options": [ { "key": "...", "description": "..." } ] }
#     ]
#   }
#
# Writes one block per question to stdout: every option with its probability,
# the confidence, and the token cost of the call.
#
# Exit: 1 API or network failure, 2 JEV_API_KEY unset, 3 curl or jq missing.

set -euo pipefail

API_URL="${JEV_API_URL:-https://api.typesafe.ai/v1/systemone}"
MODEL="${JEV_MODEL:-jev-latest}"
USAGE_LOG="${JEV_USAGE_LOG:-${TMPDIR:-/tmp}/jev-usage.log}"

for cmd in curl jq; do
  command -v "$cmd" >/dev/null 2>&1 || {
    echo "score-options.sh: '$cmd' not found. Install it (brew install $cmd / apt install $cmd) or ask the question without recommendation rates." >&2
    exit 3
  }
done

[ -n "${JEV_API_KEY:-}" ] || {
  echo "score-options.sh: JEV_API_KEY is not set. Get a key at https://typesafe.ai and export it, or ask the question without recommendation rates." >&2
  exit 2
}

input=$(cat)

brief_file=$(jq -r '.brief_file // ""' <<<"$input")
brief=""
if [ -n "$brief_file" ]; then
  [ -r "$brief_file" ] || { echo "score-options.sh: cannot read brief_file '$brief_file'." >&2; exit 1; }
  brief=$(cat "$brief_file")
fi

# criteria is a map key -> description; none_of_these keeps a bad option set from
# being forced to 100%.
body=$(jq -n \
  --arg model "$MODEL" \
  --arg brief "$brief" \
  --argjson round "$input" \
  '{
    model: $model,
    state: { brief: $brief, decision: ($round.decision // "") },
    questions: ($round.questions
      | map({
          key: .id,
          value: {
            type: "choice",
            instructions: .question,
            criteria: ((.options | map({ key: .key, value: .description }) | from_entries)
                       + { none_of_these: "None of the listed options is a reasonable answer to this question." })
          }
        })
      | from_entries)
  }')

response=$(curl -sS --max-time 20 -w '\n%{http_code}' \
  -X POST "$API_URL" \
  -H "Authorization: Bearer $JEV_API_KEY" \
  -H 'Content-Type: application/json' \
  -d "$body") || { echo "score-options.sh: request to $API_URL failed." >&2; exit 1; }

status=${response##*$'\n'}
payload=${response%$'\n'*}

case "$status" in
  2*) ;;
  *) echo "score-options.sh: API returned HTTP $status." >&2
     echo "$payload" >&2
     exit 1 ;;
esac

jq -r '
  .answers | to_entries[] |
  "## \(.key)  (confidence \(.value.confidence))",
  ( .value.probabilities | to_entries | sort_by(-.value)[]
    | "  \(.value * 100 | round)%  \(.key)" ),
  ""
' <<<"$payload"

in_tok=$(jq -r '.usage.input_tokens // 0' <<<"$payload")
out_tok=$(jq -r '.usage.output_tokens // 0' <<<"$payload")
printf '%s\t%s\t%s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$in_tok" "$out_tok" >> "$USAGE_LOG"

totals=$(awk -F'\t' '{i+=$2; o+=$3} END {printf "%d %d", i, o}' "$USAGE_LOG")
echo "tokens: this call in=$in_tok out=$out_tok / session total in=${totals% *} out=${totals#* } (log: $USAGE_LOG)"
