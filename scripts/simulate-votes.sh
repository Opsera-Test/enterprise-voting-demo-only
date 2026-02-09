#!/bin/bash
# ════════════════════════════════════════════════════════════════════════
# Vote Simulator - Fuzzy Random Voting for Opsera Voting Demo
# ════════════════════════════════════════════════════════════════════════
#
# Usage: ./simulate-votes.sh [URL] [COUNT] [BIAS]
#   URL   - Vote app URL (default: https://vote-voting01-dev10.agent.opsera.dev)
#   COUNT - Number of votes to cast (default: 50)
#   BIAS  - Cat bias 0-100, where 50=even, 70=cats favored (default: 55)

VOTE_URL="${1:-https://vote-voting01-dev10.agent.opsera.dev}"
TOTAL="${2:-50}"
BIAS="${3:-55}"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

cats=0
dogs=0
errors=0

echo ""
echo -e "${BLUE}╔══════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  🗳️  Opsera Vote Simulator - Fuzzy Logic Engine     ║${NC}"
echo -e "${BLUE}╠══════════════════════════════════════════════════════╣${NC}"
echo -e "${BLUE}║  Target:  ${NC}${VOTE_URL}"
echo -e "${BLUE}║  Votes:   ${NC}${TOTAL}"
echo -e "${BLUE}║  Cat Bias: ${NC}${BIAS}% (fuzzy ±10%)"
echo -e "${BLUE}╚══════════════════════════════════════════════════════╝${NC}"
echo ""

for i in $(seq 1 "$TOTAL"); do
  # Fuzzy logic: add random jitter ±10% to the bias each vote
  jitter=$(( (RANDOM % 21) - 10 ))
  effective_bias=$(( BIAS + jitter ))

  # Clamp to 5-95 range
  [ "$effective_bias" -lt 5 ] && effective_bias=5
  [ "$effective_bias" -gt 95 ] && effective_bias=95

  # Roll the dice
  roll=$(( RANDOM % 100 ))

  if [ "$roll" -lt "$effective_bias" ]; then
    choice="a"  # Cats
    label="Cats"
    color="$GREEN"
  else
    choice="b"  # Dogs
    label="Dogs"
    color="$YELLOW"
  fi

  # Random delay 0.1-0.8s to simulate human-like voting
  delay=$(awk "BEGIN{printf \"%.1f\", 0.1 + rand() * 0.7}")

  # Cast vote
  status=$(curl -s -o /dev/null -w "%{http_code}" \
    -X POST "${VOTE_URL}/" \
    -H "Content-Type: application/x-www-form-urlencoded" \
    -d "vote=${choice}" \
    --max-time 5 2>/dev/null)

  if [ "$status" = "200" ]; then
    [ "$choice" = "a" ] && cats=$((cats + 1)) || dogs=$((dogs + 1))
    printf "${color}  [%3d/%d] %-4s ${NC}(bias:%d%% roll:%d) HTTP %s\n" "$i" "$TOTAL" "$label" "$effective_bias" "$roll" "$status"
  else
    errors=$((errors + 1))
    printf "${RED}  [%3d/%d] ERROR ${NC}HTTP %s\n" "$i" "$TOTAL" "$status"
  fi

  sleep "$delay"
done

# Summary
total_valid=$((cats + dogs))
if [ "$total_valid" -gt 0 ]; then
  cat_pct=$(awk "BEGIN{printf \"%.1f\", ($cats/$total_valid)*100}")
  dog_pct=$(awk "BEGIN{printf \"%.1f\", ($dogs/$total_valid)*100}")
else
  cat_pct="0.0"
  dog_pct="0.0"
fi

echo ""
echo -e "${BLUE}╔══════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  Results                                             ║${NC}"
echo -e "${BLUE}╠══════════════════════════════════════════════════════╣${NC}"
echo -e "${BLUE}║${NC}  ${GREEN}Cats:   ${cats} votes (${cat_pct}%)${NC}"
echo -e "${BLUE}║${NC}  ${YELLOW}Dogs:   ${dogs} votes (${dog_pct}%)${NC}"
[ "$errors" -gt 0 ] && echo -e "${BLUE}║${NC}  ${RED}Errors: ${errors}${NC}"
echo -e "${BLUE}║${NC}  Total:  ${total_valid} votes cast"
echo -e "${BLUE}╚══════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "Check results: ${BLUE}https://result-voting01-dev10.agent.opsera.dev${NC}"
