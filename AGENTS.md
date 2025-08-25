# Contributor Guidelines

## Coding Style
- **Indentation:** Use 4 spaces. No tabs.
- **C/C++:**
  - Classes and structs use `PascalCase`.
  - Functions and variables use `snake_case`.
  - Constants use `SCREAMING_SNAKE_CASE`.
  - Place opening braces on the same line as declarations.
- **Python:** Follow [PEP 8](https://peps.python.org/pep-0008/) conventions.
  - Classes use `PascalCase`.
  - Functions and variables use `snake_case`.
  - Constants use `SCREAMING_SNAKE_CASE`.
- **General:** Prefer descriptive names and keep files focused on a single responsibility.

## Verification Commands
Run the following commands in the repository root before committing changes:

1. **Quick environment check**
   ```bash
   pwsh -File scripts/quick-test.ps1
   ```
2. **Firmware build**
   ```bash
   pwsh -File firmware/build_scripts/build.ps1
   ```
3. **Unit tests**
   ```bash
   pytest
   ```

Make a best effort to ensure all commands complete successfully. If a command cannot run (e.g., missing dependencies), note the issue in your commit message or PR.

## Environment-Specific Notes
If a directory has additional environment or platform requirements, create an `AGENTS.md` file in that directory to document them. Instructions in deeper directories override this root file for the files within their scope.
