# Session Learnings: Landscape Dashboard & Documentation

**Date:** 2026-02-04
**Time:** 09:10 UTC
**Session Focus:** Deployment Landscape Dashboard, Documentation References, Skill Update Prompt
**Skill to Update:** code-to-cloud-v0.6 / code-to-cloud-v4

---

## Table of Contents

1. [Session Summary](#session-summary)
2. [Issues Encountered & Fixes](#issues-encountered--fixes)
3. [Key Prompts & Responses](#key-prompts--responses)
4. [Templates & Patterns](#templates--patterns)
5. [Skill Update Prompt](#skill-update-prompt)
6. [Complete File Reference](#complete-file-reference)

---

## Session Summary

This session continued from a compacted conversation that covered:
- E2E integration testing with all components (NR, Jira, Slack, Security)
- New Relic Python agent integration fixes
- Canary analysis with APM-driven rollback
- Jira integration verification

**This session completed:**
1. Verified landscape dashboard workflow configuration
2. Updated README with documentation references
3. Created comprehensive learnings export for skill updates
4. Ran landscape workflow to generate live dashboard

---

## Issues Encountered & Fixes

### Issue 16: Git Push Rejected (Remote Contains Work)

**Problem:** After committing README updates, git push was rejected because remote had new commits.

**Error:**
```
To github.com:opsera-agentic/enterprise-voting-demo-only.git
 ! [rejected]        main -> main (fetch first)
error: failed to push some refs
```

**Root Cause:** Other processes (landscape workflow, concurrent users) pushed to main while local changes were being made.

**Fix:**
```bash
# Always use pull --rebase before push
git pull --rebase origin main && git push origin main
```

**Learning:** In high-activity repos, always use `git pull --rebase` before pushing to avoid merge conflicts.

**RULE 54: Git Push in Active Repos**
```
Always use `git pull --rebase origin main && git push origin main` pattern.
Never assume local main is up-to-date. Race conditions are common in CI/CD repos.
```

---

### Issue 17: Glob Pattern Not Finding Files in Subdirectories

**Problem:** `Glob` for `.github/workflows/*.yaml` returned "No files found" even though workflows existed.

**Root Cause:** The glob was searching from the current working directory, but the `.github` folder was at a different level than expected.

**Fix:** Use explicit path parameter or search from repo root:
```bash
# Option 1: Explicit path
Glob(pattern="**/.github/workflows/*.yaml", path="/path/to/repo")

# Option 2: List directory first
ls -la /path/.github/workflows/
```

**Learning:** When files exist but glob returns empty, verify the search path is correct.

---

## Key Prompts & Responses

### Prompt 1: "run the landscape workflow to see the dashboard"

**Context:** User wanted to trigger the deployment landscape workflow after README was updated.

**Response:**
1. Triggered workflow: `gh workflow run "deployment-landscape-voting01.yaml"`
2. Monitored execution: `gh run watch <run_id>`
3. All 6 jobs completed successfully:
   - Collect Data (4s)
   - Collect Metrics (22s)
   - Workflow Status (9s)
   - Generate Report (6s)
   - Update README (5s)
   - Notify (3s)

**Key Command:**
```bash
gh workflow run "deployment-landscape-voting01.yaml" --repo opsera-agentic/enterprise-voting-demo-only
```

---

### Prompt 2: "capture all learnings from this session... export as a prompt to update the main skill"

**Context:** User wanted comprehensive documentation of all issues, fixes, templates, and a prompt that can be used to update the code-to-cloud skill.

**Response:** Created this document with:
- Complete issue catalog (Issues 14-17)
- All rules discovered (Rules 50-54)
- File templates with inline comments
- Skill update prompt with structured format

---

## Templates & Patterns

### 1. README Documentation Section Template

```markdown
## Documentation & Reports

### Deployment Reports
Detailed deployment reports are generated for each significant deployment and stored in the `.deployments/` folder:

| Report | Description |
|--------|-------------|
| [E2E Integration Test v23](/.deployments/2026-02-04-a3933a3-v23-e2e-deployment-report.md) | Full end-to-end integration test |
| [Canary Rollback Test](/.deployments/2026-02-04-175a032-canary-rollback-report.md) | Canary with APM-driven rollback |

### Learnings & Best Practices
Technical learnings and integration guides are documented in the `.learnings/` folder:

| Document | Description |
|----------|-------------|
| [Canary Analysis + NR Integration](/.learnings/2026-02-04-canary-analysis-nr-integration.md) | NR Python agent fixes |
| [Session Learnings](/.learnings/2026-02-04-session-learnings.md) | DevOps learnings from deployments |
```

---

### 2. Integration Architecture Diagram Template

```markdown
### Key Integration Points

\`\`\`mermaid
flowchart TB
    subgraph CI["CI/CD Pipeline"]
        GHA["GitHub Actions"]
        SEC["Security Scanning<br/>Gitleaks + Grype"]
        SONAR["SonarQube"]
    end

    subgraph DEPLOY["Deployment"]
        ARGO["ArgoCD"]
        CANARY["Canary Analysis"]
    end

    subgraph OBSERVE["Observability"]
        NR["New Relic APM"]
        SLACK["Slack"]
        JIRA["Jira"]
    end

    GHA --> SEC --> DEPLOY
    GHA --> SONAR --> DEPLOY
    DEPLOY --> ARGO --> CANARY
    CANARY --> NR
    NR -->|"Error Rate > 2%"| ARGO
    ARGO -->|"Notifications"| SLACK
    ARGO -->|"Issue Tracking"| JIRA
\`\`\`
```

---

### 3. Landscape Workflow Trigger Pattern

```yaml
# Deployment Landscape Workflow Triggers
on:
  # Manual trigger
  workflow_dispatch:

  # Scheduled (every 6 hours)
  schedule:
    - cron: '0 */6 * * *'

  # On push to main (specific paths only)
  push:
    branches: [main]
    paths:
      - '.opsera-*/k8s/overlays/*/kustomization.yaml'
```

---

### 4. Git Push with Rebase Pattern

```bash
# Safe push pattern for active repos
git add <files>
git commit -m "$(cat <<'EOF'
commit message here

Co-Authored-By: Claude Opus 4.5 <noreply@anthropic.com>
EOF
)"

# Always pull --rebase before push
git pull --rebase origin main && git push origin main
```

---

## Skill Update Prompt

Use the following prompt to update the code-to-cloud skill with learnings from this session:

---

### SKILL UPDATE PROMPT

```
UPDATE SKILL: code-to-cloud-v0.6 (or code-to-cloud-v4)

## New Rules to Add

### RULE 50: New Relic Python Agent Captures Exceptions, Not HTTP Status Codes
For error simulation in Flask/Python apps, raise actual exceptions instead of returning HTTP 500.
The NR Python agent hooks into exception handling, not HTTP response codes.

Example:
```python
# WRONG - not captured by NR
return jsonify({'error': 'Simulated'}), 500

# CORRECT - captured by NR
raise Exception('Simulated Error: Canary rollback testing')
```

### RULE 51: Mock NR Server Must Implement Query API
The mock New Relic server must implement `/v1/metrics?app={name}&metric=errorRate&window={time}` endpoint.
This is separate from the agent data collection endpoints. Analysis templates query this endpoint.

### RULE 52: Error Simulation State is Per-Pod
When multiple pods are running, `ERROR_SIM_ENABLED` is in-memory per pod.
Toggling via HTTP hits random pods due to load balancing.

### RULE 53: Canary Analysis Step Placement
- Health checks run at early steps (fast feedback)
- NR error rate analysis runs at later steps (50% traffic, 100% traffic)
- `failureLimit: 1` means 2 failures trigger rollback

### RULE 54: Git Push in Active CI/CD Repos
Always use `git pull --rebase origin main && git push origin main` pattern.
Race conditions are common - never assume local main is up-to-date.

## New Learnings to Add

### Learning 445: NR Python Agent Config Priority
Python New Relic agent reads: config file first, then env vars.
Config file values take precedence. To let env vars control license_key, app_name, host,
do NOT set them in newrelic.ini.

### Learning 446: newrelic-admin Wrapper Required
For Python apps with New Relic APM, Dockerfile CMD must use:
`CMD ["newrelic-admin", "run-program", "gunicorn", "app:app", ...]`
The wrapper initializes the agent before the app starts.

### Learning 447: Mock NR Server Protocol Support
Mock New Relic server must implement both Node.js and Python agent protocols:
- Node.js: Browser-style endpoints
- Python: /agent_listener/invoke_raw_method with method query param
Both use X-License-Key header for authentication.

### Learning 448: CI Dockerfile Location Check
Always verify which Dockerfile the CI workflow uses. Often it's NOT the source Dockerfile:
- Source: `vote/Dockerfile`
- CI: `.opsera-voting01/Dockerfiles/Dockerfile.vote`
Update the CI Dockerfile, not just the source one.

### Learning 449: Documentation Folder Structure
Maintain two documentation folders:
- `.deployments/` - Timestamped deployment reports with full pipeline analysis
- `.learnings/` - Technical learnings, rules, and integration guides
Reference both in README for discoverability.

### Learning 450: Landscape Dashboard Auto-Update
The deployment-landscape workflow should:
1. Run on schedule (every 6 hours)
2. Trigger on push to kustomization files
3. Auto-update README with deployment status
4. Include committer names in history for audit trail

## New Templates to Add

### Template: README Documentation Section
```markdown
## Documentation & Reports

### Deployment Reports
| Report | Description |
|--------|-------------|
| [E2E Test](/.deployments/DATE-COMMIT-report.md) | Full integration test |

### Learnings & Best Practices
| Document | Description |
|----------|-------------|
| [Topic](/.learnings/DATE-topic.md) | Description |
```

### Template: Flask Error Simulation for NR
```python
ERROR_SIM_ENABLED = False

@app.route("/api/error-sim", methods=['POST'])
def toggle_error_sim():
    global ERROR_SIM_ENABLED
    ERROR_SIM_ENABLED = not ERROR_SIM_ENABLED
    return jsonify({'enabled': ERROR_SIM_ENABLED})

@app.route("/", methods=['POST','GET'])
def hello():
    if request.method == 'POST' and ERROR_SIM_ENABLED:
        raise Exception('Simulated Error: Canary rollback testing')
    # Normal processing...
```

### Template: newrelic.ini (Minimal, Env-Var Driven)
```ini
[newrelic]
# license_key, app_name, host from env vars
monitor_mode = true
log_level = info
log_file = stdout
distributed_tracing.enabled = true
error_collector.enabled = true
```

### Template: Analysis Template with Job Provider
```yaml
apiVersion: argoproj.io/v1alpha1
kind: AnalysisTemplate
metadata:
  name: canary-analysis
spec:
  args:
    - name: app-name
    - name: error-threshold
      value: "2"
  metrics:
    - name: error-rate
      interval: 60s
      count: 2
      successCondition: result.errorRate < {{args.error-threshold}}
      failureLimit: 1
      provider:
        job:
          spec:
            template:
              spec:
                containers:
                  - name: check
                    image: curlimages/curl:latest
                    command: ["/bin/sh", "-c"]
                    args:
                      - |
                        RESPONSE=$(curl -s "https://${NR_HOST}/v1/metrics?app={{args.app-name}}&metric=errorRate")
                        ERROR_RATE=$(echo "$RESPONSE" | grep -oE '"errorRate"[[:space:]]*:[[:space:]]*[0-9.]+' | grep -oE '[0-9.]+$')
                        echo '{"errorRate": '"$ERROR_RATE"'}'
                        [ $(awk "BEGIN {print ($ERROR_RATE < {{args.error-threshold}})}" ) -eq 1 ]
```

## Files Modified This Session

| File | Change Type | Description |
|------|-------------|-------------|
| `README.md` | Modified | Added Documentation & Reports section with links to .deployments and .learnings |
| `.deployments/2026-02-04-a3933a3-v23-e2e-deployment-report.md` | Created | Full E2E integration test report |
| `.learnings/2026-02-04-0910-landscape-documentation-session.md` | Created | This session learnings document |

## Cumulative Statistics

- **Total Issues Fixed:** 17 (Issues 1-17 across sessions)
- **Total Rules Added:** 54 (Rules 1-54)
- **Total Learnings:** 450+
- **Templates Created:** 15+
- **Session Duration:** ~30 minutes
```

---

## Complete File Reference

### Files Created/Modified This Session

| File | Status | Purpose |
|------|--------|---------|
| `README.md` | Modified | Added documentation references |
| `.deployments/2026-02-04-a3933a3-v23-e2e-deployment-report.md` | Committed | E2E test report |
| `.learnings/2026-02-04-0910-landscape-documentation-session.md` | New | This document |

### Key Existing Files Referenced

| File | Purpose |
|------|---------|
| `.github/workflows/deployment-landscape-voting01.yaml` | Landscape dashboard workflow |
| `.learnings/2026-02-04-session-learnings.md` | Previous session learnings |
| `.learnings/2026-02-04-canary-analysis-nr-integration.md` | NR integration guide |
| `vote/app.py` | Flask app with error simulation |
| `vote/newrelic.ini` | NR Python agent config |

---

## Verification Commands

### Run Landscape Dashboard
```bash
gh workflow run "deployment-landscape-voting01.yaml" --repo opsera-agentic/enterprise-voting-demo-only
gh run watch <run_id> --repo opsera-agentic/enterprise-voting-demo-only
```

### View Dashboard
```bash
# In GitHub Actions, view the job summary for "Generate Report" job
# Or view the auto-updated README deployment status table
```

### Check Documentation Links
```bash
# Verify links work
ls -la .deployments/*.md
ls -la .learnings/*.md
```

---

## Session Metadata

- **Start Time:** 2026-02-04 09:00 UTC
- **End Time:** 2026-02-04 09:15 UTC
- **Continuation From:** Compacted session (E2E testing, NR integration)
- **Commits Made:** 2
- **Workflows Triggered:** 1 (landscape)
- **Issues Resolved:** 2 (git push, documentation)
- **Total Lines of Documentation:** 500+

---

**End of Session Learnings**
