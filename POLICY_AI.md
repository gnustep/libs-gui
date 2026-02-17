# Policy: Use of AI-Generated Content in GNUstep

## 1. Purpose

GNUstep welcomes contributions that improve the project's codebase,
documentation, tests, and developer tooling. This policy establishes
requirements for contributions created with the assistance of generative
AI systems (for example, code suggestions, documentation drafts,
translations, or refactor proposals), with the goal of preserving
quality, maintainability, licensing clarity, and security.

## 2. Scope

This policy applies to all AI-assisted content proposed for inclusion in
GNUstep project assets, including but not limited to:

-   Source code (Objective-C, C, C++, scripts, build tooling)
-   Documentation (README files, manuals, web pages, tutorials)
-   Tests, CI configurations, and project metadata
-   Issue comments, design proposals, and merge request content intended
    to become authoritative project guidance

## 3. Guiding Principle

AI tools may be used as assistive drafting aids. Contributors remain
fully responsible for the accuracy, safety, quality, and licensing
compliance of anything they submit.

## 4. Mandatory Independent Verification and Enhanced Review

AI-assisted contributions are subject to heightened scrutiny and must
undergo rigorous, independent human validation prior to acceptance.

### 4.1 Independent Human Verification

The contributor must personally:

-   Read and understand every line of AI-assisted code or documentation.
-   Be able to explain the logic, control flow, and design decisions
    without reliance on the AI system.
-   Confirm that no opaque, unexplained, or unnecessary logic is
    included.

Submissions that the contributor cannot fully explain may be rejected
without further review.

### 4.2 Reproducible Validation

AI-assisted changes must include demonstrable validation:

-   All existing tests must pass.
-   New or modified functionality must include tests where applicable.
-   Behavior must be manually verified in supported environments.
-   Claims of performance, portability, or correctness must be supported
    by reproducible evidence.

Compilation alone is not considered validation.

### 4.3 Security Review Requirement

Any AI-assisted contribution that affects:

-   Memory management
-   Concurrency
-   Privilege boundaries
-   Serialization or parsing
-   Cryptographic or authentication logic
-   Network behavior

must receive explicit human review by a maintainer with relevant domain
knowledge. Maintainers may require additional review before merge.

### 4.4 Licensing and Provenance Safeguards

Contributors must take reasonable steps to ensure that AI-assisted
content does not:

-   Contain verbatim copyrighted material
-   Replicate incompatible licensed code
-   Introduce unclear authorship or provenance

If provenance cannot be reasonably established, the contribution will
not be accepted.

### 4.5 Size and Complexity Limits

Large AI-generated diffs that are difficult to audit may be rejected.
Maintainers may require:

-   Splitting into smaller logical commits
-   Manual simplification
-   Rewriting portions that are unnecessarily complex

Opacity is grounds for refusal.

### 4.6 No Automation of Review

AI tools must not be used to generate superficial justifications for
correctness or to bypass meaningful human review. Review must be
substantive, manual, and technically grounded.

## 5. Disclosure Requirement

Contributors should disclose AI assistance when it materially shaped the
submission (for example, where significant portions of code or
documentation were drafted by an AI system).

Disclosure may be included in:

-   The merge request or pull request description
-   The commit message (for example: `AI-Assisted: yes` or `Produced using AI`)

Disclosure is intended to assist reviewers in calibrating review depth,
not to discourage responsible use of tooling.

## 6. Prohibited Uses

AI-generated content must not be used to:

-   Introduce material whose origin or licensing cannot be reasonably
    verified
-   Circumvent normal review processes
-   Generate security-critical logic (e.g., cryptography,
    authentication, privilege boundaries) without expert human review
-   Fabricate references, test results, benchmarks, or performance
    claims

## 7. Contributor Responsibilities

Anyone submitting AI-assisted content must be prepared to:

-   Explain clearly what the change does and why it is correct
-   Provide reproduction steps, tests, or benchmarks when relevant
-   Revise or withdraw a submission if concerns arise regarding
    correctness, security, maintainability, or licensing

## 8. Maintainer Guidance

Maintainers may request:

-   Additional tests
-   Design clarification
-   Smaller, reviewable commits
-   Rewrites of code that is overly complex or opaque

Changes that cannot be safely reviewed may be declined.

## 9. Governance Record

This policy reflects project governance discussion, including discussion
with Fred Kiefer during the meeting held on Saturday, February 14.

## 10. Effective Date and Updates

This policy becomes effective upon inclusion in the GNUstep repository.
Updates should be discussed publicly (for example, via mailing list,
issue tracker, or project meeting) before adoption.

------------------------------------------------------------------------

### References

-   GNU Coding Standards -- GNU Project
    https://www.gnu.org/prep/standards/standards.html

-   Free Software Foundation Licensing Resources
    https://www.fsf.org/licensing/

-   OpenAI Usage Policies (general guidance on responsible AI use)
    https://openai.com/policies/
