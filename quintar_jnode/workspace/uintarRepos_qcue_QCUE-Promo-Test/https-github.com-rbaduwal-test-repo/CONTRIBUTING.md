# How to contribute
Welcome to the Q.reality development team! Use this as a guide to contributing.

## Branching
>`develop` HEAD is latest stable release - will be `main` in the future

|BRANCH|DESCRIPTION|
|--|--|
|`main`|Tagged releases only|
|`develop`|Active development, most pull requests target this branch|
|`release_<version>`|Internal release branch, used for preparing or bumping a release. Once ready, it will be merged to main and tagged|
|\<your_branch\>|New features, bug fixes, documentation updates. Usually used by a single developer and assoociated with a project management system|

## Merging

A Contributor makes a pull request, a Reviewer reviews it. There should be open communication between the two parties and brief walkthroughs are encouraged.

### CONTRIBUTOR
1. Create a **pull request (PR)** from \<your branch\> to the target branch
   - In the description (or first comment) field, add a detailed summary about what you did and why you did it. Include links and references to tasks, and keep this updated throughout the life of the PR
   - Include as many reviewers as you like, but ensure at least one of them has merge permissions
2. Do a quick review of your own PR. Your PR should include a clean and expected diff with changes only related to the effort in your summary. Extraneous or erroneous diffs waste the reviewer's time and might keep your PR from getting merged
3. Respond to and address all **review** concerns - including resolving conversations. Address all conflicts and ensure all tests pass
4. Sometimes a brief walkthrough with the reviewer is the most efficient way to get your code merged
5. Unless otherwise specified, the reviewer will merge your code

### REVIEWER
1. Ensure there are no conflicts
2. Ensure all review concerns are addressed, including conversations
3. Ensure the summary is adequate - you shouldn't need to guess what the goal of the PR is
   - Reach out to the developer if the summary demonstrates a poor understanding of the context. This saves the contributor and reviewer from wasting time
4. Approve, decline, or comment on the PR.
   - It's important to understand the context of the PR - is this a hack for a short-lived branch or is this production code for the next 3 years? This will help you decide how to respond
   - Sometimes you just want to fix the code yourself. If you do this, add the contributor as a reviewer and ensure they have a chance to review what you did, even if for their own benefit
5. Once approved and all the above criteria are met, you the reviewer will **squash and merge** the branch. You will need to **replace the default commit message** with the brief summary posted by the contributor - do not merely stack up the commit messages! This helps maintain a clean and concise history

## Testing
>Testing leads to failure, and failure leads to understanding

Multiple operating systems and development tools are supported.
Tests are grouped into [unit tests](#unit-tests) and [end-to-end (E2E) tests](#e2e-tests)

### Unit tests

|OS|UNIT TEST FRAMEWORK|
|--|--|
|iOS|XCTest|
|Android|TBD|
|Unity|TBD|

### E2E tests
TBD

## Code
>When in Rome, do as the Romans do

If you are editing existing code, just follow suite and you'll probably be fine. For new code (or if you are cleaning up existing code) follow these guidelines.

### NAMES
- filenames are camelCase unless required otherwise by a toolset
- camelCase for classes, properties and functions unless required otherwise by a toolset
- abbreviate only if you are confident all other developers will understand it. When in doubt spell it out, or provide comments in key places describing the acronym.
- function names should attempt to describe what they do. Be reasonable; both `d()` and `deliverMyMessageToAnyoneWhoMayBeListeningOnThisSocket()` are terrible - something like `deliverMsg()` is probably good enough

### COMMENTS
- Never use file headers. Remove auto-generated file headers unless required
- Use function headers only when it isn't obvious what's going on
- Comment liberally the guts of functions, captures, lambdas, computed properties, etc. Your comments should read like a story

### FORMATTING
- 3 space indents, no tabs
- `/n` newlines for all code/script files, including Unity

## Architecture
Overview: ![UML](/doc/q_reality_sdk_overview.png)

UML: ![UML](/doc/q_reality_sdk_uml.png)

With comments: ![UML](/doc/q_reality_sdk_uml_with_comments.png)
