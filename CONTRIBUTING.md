# Contributing to strava-cli

Thank you for your interest in contributing to strava-cli! This document provides guidelines and instructions for contributing.

## Development Setup

### Prerequisites

- OCaml >= 4.14
- opam (OCaml package manager)
- dune (build system)

### Getting Started

1. Clone the repository:
```bash
git clone https://github.com/fetsh/strava-cli.git
cd strava-cli
```

2. Install dependencies:
```bash
opam install . --deps-only
```

3. Build the project:
```bash
dune build
```

4. Run the CLI:
```bash
dune exec strava -- --help
```

## Project Structure

```
strava-cli/
├── bin/
│   └── main.ml              # CLI entry point (cmdliner)
├── lib/
│   ├── db.ml                # SQLite credential storage
│   ├── auth.ml              # OAuth 2.0 authentication
│   ├── api.ml               # Strava API client
│   ├── commands.ml          # Command implementations
│   └── strava.ml            # Public interface
├── dune-project             # Project configuration
└── README.md
```

## Making Changes

### Code Style

- Follow OCaml conventions
- Use 2-space indentation for OCaml files
- Use meaningful variable and function names
- Add comments for complex logic

### Adding a New Command

1. Add the API endpoint in `lib/api.ml` and `lib/api.mli`
2. Add the command implementation in `lib/commands.ml` and `lib/commands.mli`
3. Add the CLI definition in `bin/main.ml`
4. Update the completion scripts:
   - `strava-completion.bash`
   - `strava-completion.zsh`
5. Update `README.md` with usage examples

### Testing

Before submitting changes:

1. Build the project:
```bash
dune build
```

2. Test your changes:
```bash
dune exec strava -- init  # Set up credentials if needed
dune exec strava -- YOUR_COMMAND --help
dune exec strava -- YOUR_COMMAND [args]
```

3. Test with different output modes:
```bash
dune exec strava -- YOUR_COMMAND --raw
dune exec strava -- YOUR_COMMAND --output test.json
dune exec strava -- YOUR_COMMAND --quiet
```

### Commit Messages

Write clear, descriptive commit messages:

```
Add support for gear endpoints

- Implement get_gear API function
- Add gear command to CLI
- Update completion scripts
- Add usage examples to README
```

## Submitting Changes

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/your-feature-name`
3. Make your changes
4. Commit your changes: `git commit -m "Description of changes"`
5. Push to your fork: `git push origin feature/your-feature-name`
6. Open a Pull Request

## Pull Request Guidelines

- Provide a clear description of the changes
- Reference any related issues
- Ensure the code builds without errors
- Update documentation as needed
- Keep PRs focused on a single feature or fix

## Code Review Process

1. Maintainers will review your PR
2. Address any feedback or requested changes
3. Once approved, your PR will be merged

## Questions?

Feel free to open an issue for:
- Bug reports
- Feature requests
- Questions about the codebase
- General discussion

## License

By contributing, you agree that your contributions will be licensed under the MIT License.
