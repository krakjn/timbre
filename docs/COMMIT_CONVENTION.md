# Commit Message Convention

This project follows [Conventional Commits](https://www.conventionalcommits.org/) for commit messages.

## Format

```
<type>(<scope>): <subject>

<body>

<footer>
```

## Types

- `feat`: A new feature
- `fix`: A bug fix
- `docs`: Documentation only changes
- `style`: Changes that do not affect the meaning of the code (white-space, formatting, etc)
- `refactor`: A code change that neither fixes a bug nor adds a feature
- `perf`: A code change that improves performance
- `test`: Adding missing tests or correcting existing tests
- `chore`: Changes to the build process or auxiliary tools and libraries
- `build`: Changes that affect the build system or external dependencies
- `ci`: Changes to CI configuration files and scripts

## Breaking Changes

Breaking changes should be indicated by:
1. Adding an exclamation mark after the type/scope: `feat!: remove deprecated API`
2. Adding `BREAKING CHANGE:` in the footer: 
   ```
   feat: change API
   
   BREAKING CHANGE: The API has completely changed
   ```

## Examples

```
feat: add user authentication

fix(parser): handle nested objects correctly

docs: correct API documentation

style: format code according to new style guide

refactor: simplify authentication logic

perf: improve search algorithm performance

test: add tests for user registration

chore: update dependencies

feat!: remove deprecated API
``` 