# Issue tracker: GitHub

Issues and specs live in GitHub Issues for `the-kbA-team/cakephp2-graylog`.
Use `gh` for tracker operations, adding `-R the-kbA-team/cakephp2-graylog` to
the command when needed to select this repository.
Follow the global Jira and GitHub tracking rules.

- Create an issue: `gh issue create --title "..." --body "..."`
- Read an issue: `gh issue view <number> --json number,title,body,labels,comments`
- List issues: `gh issue list --state open --json number,title,body,labels,comments`
- Comment: `gh issue comment <number> --body "..."`
- Apply or remove labels: `gh issue edit <number> --add-label "..."` or `--remove-label "..."`
- Close an issue: `gh issue close <number> --comment "..."`

When a skill says to publish to the issue tracker, create a GitHub issue. When
it says to fetch a ticket, read the issue.

## Pull requests as a triage surface

**PRs as a request surface: no.**

## Wayfinding

Create a map issue labelled `wayfinder:map` with Notes, Decisions-so-far and Fog.
Create child issues as sub-issues where supported, or use a task list in the map
and `Part of #<map>` in each child. Create missing wayfinder labels as needed.
Label children `wayfinder:research`, `wayfinder:prototype`, `wayfinder:grilling`,
or `wayfinder:task`; assign a ticket when claimed.

Use GitHub issue dependencies for blockers, or write `Blocked by: #<number>`
if dependencies are unavailable. The frontier consists of open, unassigned
children without open blockers; claim the first in map order. Resolve a ticket
by commenting the answer, closing it, and summarizing it in the map.
