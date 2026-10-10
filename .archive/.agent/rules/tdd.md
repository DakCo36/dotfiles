---
trigger: always_on
description: TDD workflow rules for Red-Green-Refactor cycle
---

# Test-Driven Development Workflow

## Description
This document defines the **mandatory protocol** for writing new features, fixing bugs, or refactoring code. It enforces a strict **Red-Green-Refactor** cycle with a target of 80%+ test coverage across unit, integration, and E2E tests.

## When to Activate
**Apply this workflow automatically** when the user requests:
- **New Features**: Implementing business logic, API endpoints, or CLI tools.
- **Bug Fixes**: resolving issues, errors, or unexpected behaviors.
- **Refactoring**: Improving code structure, performance, or readability without changing behavior.[](https://github.com/affaan-m/everything-claude-code/blob/main/skills/tdd-workflow/SKILL.md#e2e-tests-playwrigh
- **Infrastructure**: Writing complex IaC logic (e.g., CDK, Pulumi, complex Helm charts) where logic can be tested.
- **Components**: Creating new modules, services, or shared libraries.

## Core Principles

### 1. Tests BEFORE Code
Strictly follow the **Red-Green-Refactor** cycle: you **MUST** write failing tests before writing any implementation code.
### 2. Coverage & Scopes
- **Target**: Minimum 80% coverage for **Unit and Integration** tests.
- **E2E**: **Highly Recommended** for critical flows.
	- If E2E tests are omitted, you **MUST explicitly explain the reason** to the user (e.g., lack of environment, excessive mocking complexity, or technical limitations).
- **Focus**: Prioritize business logic and critical integration points (DB, API Clients).
### 3. Input Robustness (Rule of Three)
- For logic accepting variable inputs (fuzzy/dynamic), you MUST provide at least **3 distinct test cases**:
	1. **Happy Path**: Standard valid input.
	2. **Edge Case**: Empty, min/max values, boundary 
limits.
	3. **Error Case**: Invalid format, nulls (if applicable), or unexpected types.
### 4. BDD Structure (Describe-Context-It)
- **Priority**: Adopt **BDD (Behavior-Driven Development)** patterns (e.g., `describe`/`it` style) to document behavior.
- **Context First**: Always inspect the existing codebase and `AGENTS.md` for established conventions before writing new tests.
- **Fallback**: If the language or framework does not natively support BDD, use the language's idiomatic testing style (e.g., Table-Driven Tests in Go) while maintaining clear, behavior-focused structure.
### 5. Test Types
#### Unit Tests
- **Scope**: Individual units of logic (Functions, Classes, Components).
- **Goal**: Verify logic in complete isolation. **Mock all external dependencies.**
#### Integration Tests
- **Scope**: Communication between modules (APIs, Databases, UI State, Service Layers).
- **Goal**: Verify that distinct parts of the system work together correctly.
#### E2E Tests (Playwright)
- **Scope**: Critical user journeys from entry to exit (Browser, CLI, or API Client).
- **Goal**: Verify the system behaves correctly as a whole, simulating real usage.

### 6. Test File Organization

Organize tests based on their scope and purpose. While you **MUST** adhere to the specific file naming conventions of the language (e.g., `_test.go` for Go, `Spec` or `Test` suffix for Kotlin/Java), follow this directory structure:

#### Structural Rules
**Attention**: **ALWAYS follow the language's standard conventions** regarding file location and naming (e.g., `_test.go` in Go, `src/test` in Kotlin).
1.  **Unit Tests (Co-location)**: Place unit tests **adjacent** to the source file they test. This ensures high visibility and easier refactoring.
2.  **Integration Tests (Separated)**: Place in a dedicated `test/integration` (or `it`) directory at the module or project root.
3.  **E2E Tests (Separated)**: Place in a dedicated `test/e2e` (or `e2e`) directory.

#### Visual Example
```text
root/
├── src/
│   ├── main/
│   │   └── com/example/auth/
│   │       └── AuthService.kt       # Source Logic
│   └── test/
│       ├── unit/ (or mirroring package)
│       │   └── com/example/auth/
│       │       └── AuthServiceTest.kt  # Unit Test (Mirrors package structure)
│       ├── integration/                # Dedicated folder
│       │   └── AuthApiTest.kt          # Integration Tests
│       └── e2e/                        # Dedicated folder
│           └── LoginScenario.kt        # End-to-End Tests
```

### 7. Execution Cycle (The "Red-Green-Refactor" Loop)
1. **Design**: Define the API contract or User Journey clearly _before_ coding.
2. **Red (Failing Test)**: Write a test that asserts the desired behavior. Run it to confirm it fails (avoids false positives).
3. **Green (Minimal Implementation)**: Write just enough code to pass the test. Ignore elegance for now.
4. **Refactor**: Clean up the code (DRY, naming, structure) while ensuring tests stay green.
5. **Verify**: Check coverage and edge cases (Rule of Three).

### 8. Anti-Patterns (Mistakes to Avoid)
1. **Testing Implementation Details**: Assert on _outputs_ (return values, state changes, DB records), not internal private methods or variables.
2. **Leaky Isolation**: Never share state between tests. Each test must setup and teardown its own data.
3. **Mocking Reality**: Do not mock data objects (DTOs) or standard libraries. Mock only uncontrollable I/O (Network, DB Connection, Time).
4. **Sleep/Wait**: Avoid fixed delays (e.g., `sleep(1s)`). Use polling or event-based waits (e.g., `Eventually` in Gomega, `await` assertions).

### 9. Tooling & Environment
1. **Run Command**: Use the standard command for the current language (e.g., `go test ./...`, `./gradlew test`, `npm test`).
2. **Watch Mode**: Use watch mode during active development for instant feedback.
3. **CI/CD**: Ensure tests pass in the CI environment (GitHub Actions) before merging.
