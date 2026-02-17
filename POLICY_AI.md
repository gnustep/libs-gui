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

## 4. Mandatory Thorough Review

Any AI-assisted contribution **must be reviewed thoroughly** before it
is merged or otherwise accepted.

Thorough review includes, at minimum:

-   **Correctness** -- The content behaves as intended and aligns with
    GNUstep conventions and architectural requirements.
-   **Security & Safety** -- No unsafe patterns, hidden network calls,
    credential leakage, injection risks, or insecure defaults.
-   **Maintainability** -- Code style, naming, structure, and comments
    meet project standards and are understandable to maintainers.
-   **Testing** -- Appropriate tests are added or updated; existing
    tests pass. Compilation alone is not sufficient validation.
-   **Documentation Accuracy** -- Claims and instructions are verified
    against current GNUstep behavior and supported platforms.
-   **Licensing Awareness** -- The contributor ensures that no
    copyrighted or license-incompatible material is introduced.

Reviewers may apply additional scrutiny where changes are large,
complex, security-sensitive, or difficult to reason about.

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
