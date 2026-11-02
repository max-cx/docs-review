# Instructions for Openshift Product Merge Reviews

## Task: OpenShift Documentation Merge Review

Perform a comprehensive review of the pull request against the following checklist:

### OCP Docs Repo Merge Request Checklist

- [ ] The PR title and first comment are in the format that is described in the PR template, and a correctly formatted PR title and comment looks like this: https://github.com/openshift/openshift-docs/pull/51056
- [ ] PR contains only one commit
- [ ] The PR description specifies versions, includes a link to the JIRA issue and a deep link to the Netlify preview
- [ ] QE approval box is ticked, with following exceptions:
  - Non-technical updates (fixing broken links, basic typos, or formatting issues) do not need QE review
  - No QE or SME is required for core OCP z-stream release note PRs or core OCP y-stream release note bug fixes
- [ ] A peer review done and approval received
- [ ] All conversations in the PR marked as "Resolved"
- [ ] "WIP" label is removed from title or comments
- [ ] Check that all system tests have passed on the PR (the openshift-ci bot should say "all tests passed!")

Instructions:

  1. When the user provides a PR URL or GitHub PR number, fetch the PR details including: title, body, number, commits, reviews, state, author, labels, comments, and statusCheckRollup
  2. Download the PR webpage using curl to check conversation thread resolution status:
	 - Use: `curl -s "https://github.com/openshift/openshift-docs/pull/{PR_NUMBER}" > /tmp/pr-{PR_NUMBER}.html`
	 - Search for unresolved conversations: `grep -c 'data-resolved="false"' /tmp/pr-{PR_NUMBER}.html`
	 - This provides an exact count of unresolved conversation threads
  3. Go through each checklist item systematically:
	 - PR title and format: Check title matches `JIRA-ID: Description` pattern
	 - Commit count: Verify only 1 commit exists
	 - PR description: Verify presence of versions, JIRA link, and Netlify deep link
	 - QE approval: Check if checkbox is ticked in PR description (look for `- [x]` vs `- [ ]`)
	 - Peer review: Check reviews array for approved status
	 - Conversation threads: Use the curl/grep method to find unresolved threads
	 - WIP label: Check labels array and title for "WIP"
	 - System tests: Check statusCheckRollup for all SUCCESS states and look for openshift-ci bot comment
  4. Report findings for each item clearly using checkmarks: [✔] for pass, [⚠️] for partial pass with issues, [❌] for fail
  5. Provide a summary of what passes and what needs attention
  6. Format the output as a markdown checklist with clear pass/fail indicators
