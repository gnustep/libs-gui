# Policy: Use of AI-Generated Content in GNUstep

## 1. Purpose

GNUstep welcomes contributions that improve the project's codebase,
documentation, tests, and developer tooling. This policy establishes
requirements for contributions created with the assistance of generative
AI systems (for example, code suggestions, documentation drafts,
translations, or refactor proposals), with the goal of preserving
quality, maintainability, licensing clarity, and security.

## 2. Scope

While many of these policies apply to contributions in general, 
this policy applies to all AI-assisted content proposed for inclusion in
GNUstep project assets, including but not limited to:

-   Source code (Objective-C, C, C++, scripts, build tooling)
-   Documentation (README files, manuals, web pages, tutorials)
-   Tests, CI configurations, and project metadata
-   Issue comments, design proposals, and merge request content intended
    to become authoritative project guidance

## 3. Guiding Principle

AI tools may be used as assistive drafting aids. Contributors remain
fully responsible for the accuracy, safety, quality, and licensing
compliance with anything they submit.

## 4. Mandatory Independent Verification and Enhanced Review

While we welcome AI-assisted contributions, it is important to remember
that AI can and does make mistakes based on its training.  Because of this
AI-assisted contributions are subject to heightened scrutiny and must
undergo rigorous, independent human validation before acceptance.

### 4.1 Independent Human Verification

AI can make mistakes.  It can produce runnable, but messy/unmaintainable
code.  Because of this, the contributor and the reviewer/maintainer must 
both thoroughly review the code.  As with any code, the contributor is 
requested and required to be responsible for the code that is 
AI-generated.

These responsibilities apply to normal contributions as well, but there
are special considerations for AI-generated contributions.

#### 4.2 Contributor responsibilities

All AI-assisted contributions MUST include tests

The contributor must:

-   Never open a PR before reviewing the code.
-   If the code doesn't make sense to you or you can't explain it,
    it WILL be rejected. (AKA DON'T COMMIT MESSY CODE TO OUR REPO!)
-   A description of what is being tested
-   Why is the test good enough?
-   What failures is this test guarding against?
-   Ensure that Apple-specific coding conventions are NOT being
    used as the project also uses GCC.
    
## 5. Disclosure Requirement

Contributors should disclose AI assistance when it materially shaped the
submission (for example, where significant portions of code or
an AI system drafted documentation).

Disclosure may be included in:

-   The merge request or pull request description
-   The commit message

Disclosure is intended to assist reviewers in calibrating review depth,
not to discourage responsible use of tooling.

## 6. Prohibited Uses

These are requirements under normal circumstances, but they are
emphasized here.

AI-generated content must not be used to:

-   Introduce material whose origin or licensing cannot be reasonably
    verified
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

## 8. Governance Record

This policy reflects project governance discussion, including discussion
with Fred Kiefer during the meeting held on Saturday, February 14.

## 9. Effective Date and Updates

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
