# Aidos Style Guide (C23 / C++23 freestanding / x86-64 NASM)

## Namespaces (C++) and C linkage
- C++: top-level namespace per subproject:
  - `stage2`
  - `kernel`
  - `shared`
  - `hal`
- No `using namespace` at namespace scope.

## File & Function Headers
### Internal/static (current default)
/* brief: <one line>
 * context: <boot-only | kernel-only | shared>
 * notes: <assumptions, e.g., buffer is large enough; IRQ state>
 */

### Public-facing (future)
/* Summary: ...
 * Preconditions: ...
 * Postconditions: ...
 * Ownership: ...
 * Errors: 0=success; >0 specific codes
 * Context: <boot-only | kernel-only | shared | IRQ-safe?>
 */

## C23
Allowed: static_assert, alignas, _Atomic, restrict, designated inits, compound literals, [[nodiscard]].
Banned: VLAs; setjmp/longjmp.
Freestanding: -ffreestanding -fno-builtin.

## C++23 (no stdlib)
- Exceptions: off (-fno-exceptions)
- RTTI: off by default (-fno-rtti); may enable per-target if it doesn't bring stdlib
- Passing/ownership: small trivially-copyable by value; else `const T&`
- `auto`: allowed when obvious; avoid in public signatures
- Prefer `enum class` (explicit underlying type when ABI matters)
- Templates/concepts: ok internally; keep public headers simple
- Operators: only value-semantics ones
- Use `constexpr/consteval`, `noexcept`, `override`

## Assembly (NASM)
- UTF-8 LF; no tabs; ≤100 columns.
- Labels/directives at col 0; instructions indented 4 spaces; lowercase mnemonics/regs.
- Global labels: `aidos_mod_func:`; locals: `_local$label`.
- SysV ABI; 16-byte alignment; red zone disallowed.
- If using YMM/ZMM/etc., add `; ISA: <feature>` in header.

## Sanitizers
- Target: off.
- Host-mode tests/fuzzing: ASan + UBSan on.

## Fuzzing
- Host-only (libFuzzer). Start with external-data parsers (e.g., boot sector, ELF headers).

## Input Validation
- Validate all external inputs; overflow-check size math; reject early on failure.
- `assert()` for programmer errors only (debug).

## Unit Tests & Coverage
- Unit tests in host-mode for pure/shared code; run via ctest.
- Target ≥70% line coverage for `src/shared` in host-mode; assembly excluded.

## Style Waivers
- Suppress locally with `// NOLINT(<rule>)` or `; STYLE-IGNORE <RULE> <why>`.
- CI will comment listing all waivers found in a PR.
