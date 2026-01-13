---
trigger: model_decision
description: When completing a task check the following are true
---

- `chef exec cookstyle` does not return any syntax or stlye errors
- markdownlint-cli2 "**/*.md" "!vendor" --fix
- yamllint
- `kitchen test` does not return any errors
  - run all suites
  - do not skip suites
  This gives us knowledge that we have not broken areas of the cookbook we are not currently changing (regression)
  No matter what we have done, even if you think it is outside our control, kitchen test must pass
