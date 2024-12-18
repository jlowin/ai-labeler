# 🦾🏷️ AI Labeler

Let an LLM handle the labeling! 

This GitHub Action uses AI to label your issues and PRs, keeping your repo organized so you can focus on what matters.

## ✨ Features

- **Smart Analysis**: Understands context from titles, descriptions, and code changes
- **Context-Aware**: Uses repository files (CODEOWNERS, templates, etc.) to make informed decisions
- **Incremental**: Works alongside other label management tools and manual labeling
- **Zero Config**: Works out of the box with your existing GitHub labels
- **Customizable**: Fine-tune behavior with optional configuration
- **Reliable**: Supports OpenAI and Anthropic's latest models, orchestrated with ControlFlow

## 🚀 Quick Start

To get started with the default model (OpenAI's `gpt-4o-mini`), follow these steps:

1. Add the following workflow definition to your repo at `.github/workflows/ai-labeler.yml`.

```yaml
name: AI Labeler

on:
  issues:
    types: [opened]
  pull_request:
    types: [opened]

jobs:
  ai-labeler:
    runs-on: ubuntu-latest
    permissions:
      contents: read
      issues: write
      pull-requests: write
    steps:
      - uses: actions/checkout@v4
      - uses: jlowin/ai-labeler@v0.5.1
        with:
          include-repo-labels: true  # Set to false if you're providing a config file with labels
          openai-api-key: ${{ secrets.OPENAI_API_KEY }}
```
1. Add an OpenAI API key to your repository's secrets as `OPENAI_API_KEY`.

1. Optionally, add a fine-tuning configuration file to `.github/ai-labeler.yml`. This example will add the contents of `README.md` and `CONTRIBUTING.md` to the LLM's context when labeling issues and PRs. (See [below](#example-configuration) for a more comprehensive example.)

```yaml
context-files:
  - README.md
  - CONTRIBUTING.md
```

That's it! 

Whenever an issue or PR is opened, the action will read your repository's existing labels and their descriptions to make smart labeling decisions. To improve its accuracy, update your label descriptions in GitHub's UI or provide a fine-tuning configuration file as described below.

## ⚙️ Configuration

The following settings can be provided as part of the workflow definition file:

### Repository Label Behavior

By default, the AI labeler will use all labels found in your repository, as well as those specifically defined in your config file. This can lead to unexpected results if your repository contains labels that don't make sense for the AI to apply, or contains very many labels.

To disable this behavior, set `include-repo-labels` to `false`. In this case, the AI will only use labels defined in your config file. See the fine-tuning section below for more details.

```yaml
- uses: jlowin/ai-labeler@v0.5.1
  with:
    include-repo-labels: false  # Only use labels defined in config
```

### LLM Configuration

You must specify an LLM provider and provide an API key. You can use either OpenAI or Anthropic models:


#### LLM Model

By default, the AI labeler uses OpenAI's `gpt-4o-mini` model. This is an excellent and affordable choice for most users. However, 4o-mini can get confused by complex per-label instructions. You can specify a different model if you'd like:

```yaml
- uses: jlowin/ai-labeler@v0.5.1
  with:
    controlflow-llm-model: openai/gpt-4o-mini
```

Supported formats:
- OpenAI: `openai/<model-name>` (e.g., "openai/gpt-4o-mini")
- Anthropic: `anthropic/<model-name>` (e.g., "anthropic/claude-3-5-sonnet-20241022")

See the [ControlFlow LLM documentation](https://controlflow.ai/guides/configure-llms#automatic-configuration) for more information on supported models.

Note that you must provide an appropriate API key for your selected LLM provider.

#### OpenAI

```yaml
- uses: jlowin/ai-labeler@v0.5.1
  with:
    openai-api-key: ${{ secrets.OPENAI_API_KEY }}
    
    # Optionally specify a different model
    controlflow-llm-model: openai/gpt-4o
```

Set your OpenAI API key as a repository secret named `OPENAI_API_KEY`. Since the default model is `openai/gpt-4o-mini`, you don't need to specify a model unless you want to change it.

#### Anthropic

```yaml
- uses: jlowin/ai-labeler@v0.5.1
  with:
    anthropic-api-key: ${{ secrets.ANTHROPIC_API_KEY }}

    # You must specify a model
    controlflow-llm-model: anthropic/claude-3-5-sonnet-20241022
```

Set your Anthropic API key as a repository secret named `ANTHROPIC_API_KEY`. To use Anthropic, you must specify a model.

### Fine-Tuning Configuration Location

By default, the action looks for additional configuration in `.github/ai-labeler.yml`. You can specify a different location:

```yaml
- uses: jlowin/ai-labeler@v0.5.1
  with:
    config-path: .github/my-custom-config.yml
```

This file controls the labeling behavior - see the Fine-Tuning section below for details.

## 🎯 Fine-Tuning

In addition to choosing a model, you can create a config file to fine-tune the labeling behavior. By default, the action looks for a file at `.github/ai-labeler.yml`. If no file is found, it will use the default behavior.

This file should have the following format; each section is optional and described in full below.

```yaml
instructions: |
  "..."
labels:
  - ...
context-files:
  - ...
```

### Example Configuration

This example provides a focused set of default labels with clear instructions for minimal, accurate labeling. For best results, turn off the `include-repo-labels` option. This will require the AI to use only the labels defined in your config file.

```yaml
instructions: |
  Apply the minimal set of labels that accurately characterize the issue/PR:
  - Use at most 1-2 labels unless there's a compelling reason for more
  - Prefer specific labels (bug, feature) over generic ones (question, help wanted)
  - For PRs that fix bugs, use 'bug' not 'enhancement'
  - Never combine: bug + enhancement, feature + enhancement. For these labels, only choose the most relevant one.
  - Reserve 'question' and 'help wanted' for when they're the primary characteristic

labels:
  - bug:
    description: "Something isn't working as expected"
    instructions: |
      Apply when describing or fixing unexpected behavior:
      - Issues: Clear error messages or unexpected outcomes
      - PRs: Fixes for broken functionality
      Don't apply enhancement/feature for bug fixes unless they add significant new functionality
      beyond fixing the bug

  - documentation:
    description: "Improvements or additions to documentation"
    instructions: |
      Apply only when documentation is the primary focus:
      - README updates
      - Code comments and docstrings
      - API documentation
      - Usage examples
      Don't apply for minor doc updates alongside code changes

  - enhancement:
    description: "Improvements to existing features"
    instructions: |
      Apply only for improvements to existing functionality:
      - Performance improvements
      - UI/UX improvements
      - Expanded capabilities of existing features
      Don't apply to:
      - Bug fixes
      - New features
      - Minor tweaks

  - feature:
    description: "New functionality"
    instructions: |
      Apply only for net-new functionality:
      - New API endpoints
      - New commands or tools
      - New user-facing capabilities
      Don't apply to:
      - Improvements to existing features (use enhancement)
      - Bug fixes

  - good first issue:
    description: "Good for newcomers"
    instructions: |
      Apply very selectively to issues that are:
      - Small in scope
      - Well-documented
      - Require minimal context
      - Have clear success criteria
      Don't apply if the task requires significant background knowledge

  - help wanted:
    description: "Extra attention is needed"
    instructions: |
      Apply only when it's the primary characteristic:
      - Issue needs external expertise
      - Current maintainers can't address it
      - Additional contributors would be valuable
      Don't apply just because an issue is open or needs work

  - question:
    description: "Further information is requested"
    instructions: |
      Apply only when the primary purpose is seeking information:
      - Clarification needed before work can begin
      - Architectural discussions
      - Implementation strategy questions
      Don't apply to:
      - Bug reports that need more details
      - Feature requests that need refinement

# These files will be included in the context if they exist
context-files:
  - README.md
  - CONTRIBUTING.md
  - CODE_OF_CONDUCT.md
  - .github/ISSUE_TEMPLATE/bug_report.md
  - .github/ISSUE_TEMPLATE/feature_request.md
```

### Instructions

Global guidance for the AI labeler:

```yaml
instructions: |
  You're our labeling expert! Please help keep our repository organized by:
  - Using 'bug' only for confirmed issues, not feature requests
  - Applying 'help wanted' to good first-time contributor opportunities
  - Being generous with 'good first issue' to encourage new contributors
```

### Label Definitions

In the labels section, you can define or enhance specific labels that you want the AI to use. Any labels defined here that do not already exist in your repository will be created automatically. The behavior of whether these are used alongside existing repository labels is controlled by the `include-repo-labels` action input.

```yaml
labels:
  # Simple form: just the name
  - question

  # Expanded form with description and instructions
  - documentation:
    description: "Documentation changes"
    instructions: |
      Apply when changes are primarily documentation-focused:
      - Changes to README, guides, or other .md files
      - Updates to docstrings or inline documentation
```

### Context Files

By default, the LLM context includes a variety of information about the issue or PR in question, as well as information about available labels. You can specify additional files the AI should consider when making decisions:

```yaml
context-files:
  - .github/CODEOWNERS
  - CONTRIBUTING.md
  - .github/ISSUE_TEMPLATE/bug_report.md
```

## 🎨 Examples

Here are some examples of interesting labeling behaviors you can configure:

### Basic Label Application

This example shows a basic configuration for a `bug` label, including instructions for the AI to follow when labeling issues.

```yaml
labels:
  - bug:
    description: "Something isn't working"
    instructions: |
      Apply when the issue describes unexpected behavior with:
      - Clear error messages
      - Steps to reproduce
      - Expected vs actual behavior
```

### Maintainer-Specific Labels

By adding `CODEOWNERS` to the context files, the AI can use that information to label issues that need review from specific teams.

```yaml
labels:
  - frontend-review:
    description: "Needs review from frontend team"
    instructions: |
      Apply when changes touch frontend code:
      - Check if files are in frontend/ or ui/ directories
      - Check CODEOWNERS for @frontend-team ownership
      - Look for changes to CSS, JavaScript, or React components

  - backend-review:
    description: "Needs review from backend team"
    instructions: |
      Apply for changes to backend systems:
      - Check if files are in backend/ or api/ directories
      - Check CODEOWNERS for @backend-team ownership
      - Look for database or API changes

context-files:
  - .github/CODEOWNERS
```

### Release Note Management

GitHub can [automatically generate release notes](https://docs.github.com/en/repositories/releasing-projects-on-github/automatically-generated-release-notes#configuring-automatically-generated-release-notes) for each release, using labels to categorize changes. You can use the AI labeler to determine whether a change should be excluded from release notes, or appears to introduce a breaking change, both of which can be reflected in the generated release notes.

```yaml
labels:
  - skip-release-notes:
    description: "Exclude from release notes"
    instructions: |
      Apply to changes that don't need release notes:
      - Simple typo fixes
      - Internal documentation updates
      - CI/CD tweaks
      - Version bumps in test files
      - Changes to development tools

  - breaking-change:
    description: "Introduces breaking changes"
    instructions: |
      Apply when changes require user action:
      - API signature changes
      - Configuration format updates
      - Dependency requirement changes
      - Removed features or endpoints
```

### Automated Triage

Labels are often used for triaging issues, and the AI labeler can use the provided content to assist with a first pass.

```yaml
labels:
  - needs-reproduction:
    description: "Issue needs steps to reproduce"
    instructions: |
      Apply to bug reports that need more info:
      - Check issue templates for missing required info
      - Look for clear reproduction steps
      - Check for environment details

  - good-first-issue:
    description: "Good for newcomers"
    instructions: |
      Apply to encourage new contributors:
      - Small, well-defined scope
      - Clear success criteria
      - Minimal prerequisite knowledge
      - Good documentation exists

context-files:
  - .github/ISSUE_TEMPLATE/bug_report.md
  - CONTRIBUTING.md
```

### Size-based Labeling

Global instructions for labeling PRs based on the number of lines changed:

```yaml
instructions: |
  When labeling pull requests, apply size labels based on these criteria:
  - 'size/XS': 0-9 lines changed
  - 'size/S': 10-29 lines changed
  - 'size/M': 30-99 lines changed
  - 'size/L': 100-499 lines changed
  - 'size/XL': 500+ lines changed
  
  Don't count changes to:
  - Auto-generated files
  - Package-lock.json or similar
  - Simple formatting changes
```

### Security Review Routing

Based on the contents of the PR, the AI can apply a `security-review` label and mark the issue as high priority.

```yaml
instructions: |
  Apply 'security-review' label if the changes involve:
  - Authentication/authorization code
  - Cryptographic operations
  - File system access
  - Network requests
  - Environment variables
  - Dependencies with known vulnerabilities
  
  Also apply 'high-priority' if the changes are in:
  - auth/*
  - security/*
  - crypto/*

context-files:
  - .github/SECURITY.md
  - .github/CODEOWNERS
```

### Automated Dependency Management

For dependency-related changes, the AI can apply a `dependencies` label and add additional labels based on the change type.

```yaml
instructions: |
  For dependency-related changes:
  1. Apply 'dependencies' label to all dependency updates
  2. Additionally:
    - Apply 'security' if it's a security update
    - Apply 'breaking-change' if it's a major version bump
    - Apply 'ci-only' if it only affects dev/test dependencies
  
  For package.json changes:
  - Apply 'frontend-deps' if touching frontend dependencies
  - Apply 'backend-deps' if touching backend dependencies
```

### Avoid Spam PRs

The AI can help maintain PR quality by applying labels based on the PR contents.

```yml
labels:
  - needs-improvement:
    description: "PR needs substantial improvements to meet quality standards"
    instructions: |
      Apply this label to PRs that show signs of being low-effort or opportunistic:
      
      Documentation:
      - Unnecessary formatting changes
      - Broken or circular links
      - Machine-translated content
      
      Code:
      - Changes that introduce complexity without justification
      - Copy-pasted code without attribution
      - Changes that bypass tests or reduce coverage
      - Trivial variable renaming
      
      Patterns:
      - PRs that ignore project conventions
      - Auto-generated or templated content
      - PRs that copy issues without adding value
      
      However, be careful not to discourage genuine first-time contributors who may be unfamiliar with best practices.
      If the PR can be improved with guidance, also apply the 'help-wanted' label.

  - invalid:
    description: "PR does not meet contribution guidelines or appears to be spam"
    instructions: |
      Apply this label when a PR appears to be:
      - Automated spam content
      - Deliberately gaming contribution counts
      - Excessive self-promotion
      - Pure promotional content without value
      
      When this label is applied, include a comment explaining why and link to contributing guidelines.

context-files:
  - .github/pull_request_template.md
  - CONTRIBUTING.md
  - CODE_OF_CONDUCT.md
```


## 💸 Cost

The cost of using the AI labeler depends on the LLM provider and the model you choose, as well as the size of the issue or PR. Since the LLM output is minimal (a few labels), the cost will be primarily driven by input tokens. 

As a rough estimate, this README is approximately 3000 tokens, which is longer than the typical issue or PR. Processing it would cost about $0.00045 with OpenAI's `gpt-4o-mini`.

That means you could process 10,000 PRs of similar length for under $5.

## 🤝 Contributing

Issues and PRs welcome! And don't worry about labels – we've got that covered! 😉