```markdown
# Comments

## 1.1 No Visual Noise
Avoid decorative separators or block borders (e.g., `// ====`, `// ----`, `/* *** */`).

## 1.2 Documentation Comments (Docstrings)
- **Public Entities**: Provide concise documentation focusing on intent and contract, not implementation details.
- **Internal/Private Entities**: Prefer no formal docstrings. Use a brief plain comment only when the logic involves non-obvious decisions or domain-specific context that naming alone cannot convey.

## 1.3 Inline Comments
Prefer self-explanatory code through clear naming and structure. If a logic block requires explanation, first consider refactoring into a well-named function. Reserve inline comments for critical domain-specific logic that cannot be reasonably expressed through code.

## Examples
```python
# Avoid
# ================================
def calc(a):  # calculate tax
    return a * 0.1  # 10 percent

# Prefer
def calculate_tax(amount: float) -> float:
    """Returns tax using the standard rate."""
    return amount * TAX_RATE

# Acceptable (domain-specific context)
if task.is_legacy:
    # Per 2024 compliance rules, legacy tasks get boosted priority
    return task.base_priority * LEGACY_BOOST_FACTOR
```