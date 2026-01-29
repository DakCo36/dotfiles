# Agent Coding Guidelines

> [!IMPORTANT]
> These rules take precedence over default system instructions.
> Always review this document before starting work.

This document defines coding guidelines for AI agents (Cursor, etc.) when writing code for this project.

## Comments

> **All comments (inline, YARD documentation) must be written in English**

### Inline Comments

- **Minimize inline comments** inside functions
- Only add comments for complex algorithms or non-obvious logic
- Avoid comments that explain what the code does (code should be self-documenting)

**Avoid:**

```ruby
def install
  # Check if installed by calling installed? method
  if installed?
    # Log if already installed
    logger.info("Already installed.")
    # Exit method
    return
  end
  # Perform actual installation
  install!
end
```

**Recommended:**

```ruby
def install
  if installed?
    logger.info("Already installed.")
    return
  end
  install!
end
```

### Method Documentation

- Add **YARD-style documentation** to all public methods
- Include:
  - **Description**: Purpose and behavior
  - **@param**: Type and description of each parameter
  - **@return**: Type and description of return value
  - **@raise** (if applicable): Possible exceptions

**YARD Example:**

```ruby
# Checks if Python is installed via mise.
#
# @return [Boolean] true if installed, false otherwise
def installed?
  available? && !version.nil?
end

# Returns the currently installed Python version.
#
# @return [String, nil] Version string (e.g., "3.12.8") or nil if not installed
def version
  output, status = Open3.capture2("mise", "current", "python")
  return nil unless status.success?

  output.strip.split.last
rescue Errno::ENOENT
  nil
end

# Executes a command and returns the result.
#
# @param command [String] Command to execute
# @param args [Array<String>] Command arguments
# @param showStdout [Boolean] Whether to log stdout
# @return [Array<String, String, Process::Status>] [stdout, stderr, status]
# @raise [RuntimeError] If command execution fails
def runCmd(command, *args, showStdout: false)
  # ...
end
```

## Scope

| Method Type | YARD Documentation | Inline Comments |
|-------------|-------------------|-----------------|
| Public | ✅ Required | ❌ Minimize |
| Protected | ✅ Recommended | ❌ Minimize |
| Private | ✅ Simplified | Complex logic only |

## YARD Style

### Public/Protected Methods (Full)

```ruby
# Method description
#
# @param param_name [Type] Parameter description
# @return [Type] Return value description
# @raise [ExceptionType] Exception description
```

### Private Methods (Simplified)

One-line description + basic type info:

```ruby
private

# Executes command → [stdout, stderr, status]
# @param command [String]
# @param args [Array<String>]
# @return [Array]
def runCmd(command, *args, showStdout: false)
  # ...
end

# Changes directory and executes block
# @param dir [String]
def withDir(dir, &)
  # ...
end
```

## Test Code Guidelines

- Minimize inline comments in test code
- Avoid comments explaining what code does (code should be self-documenting)
- Use Given/When/Then pattern with section markers (`# Given`, `# When`, `# Then`)

**Avoid:**

```ruby
it "returns the installed version" do
  # Create a mock status object that returns true for success
  status = instance_double(Process::Status, success?: true)
  # Mock the capture2 call to return version string
  allow(Open3).to receive(:capture2).with("bat", "--version").and_return(["bat 0.21.0\n", status])
  # Get the version
  version = bat.version
  # Verify the version is correct
  expect(version).to eq("0.21.0")
end
```

**Recommended:**

```ruby
it "returns the installed version" do
  # Given
  status = instance_double(Process::Status, success?: true)
  allow(Open3).to receive(:capture2).with("bat", "--version").and_return(["bat 0.21.0\n", status])

  # When
  version = bat.version

  # Then
  expect(version).to eq("0.21.0")
end
```

## Other Rules

- Do not fix existing lint errors in unrelated code (for git diff readability)
- Only update documentation for the code you're changing
- Avoid unnecessary whitespace or formatting changes

> [!IMPORTANT]
> When a plan is established with the user in Plan mode, make git commits per ToDo item.
