# Publishing the docs site

The documentation is built with [MkDocs Material](https://squidfunk.github.io/mkdocs-material/) and published to **GitHub Pages** by CI.

## Continuous deployment

Workflow: [`.github/workflows/docs.yml`](https://github.com/krakjn/timbre/blob/main/.github/workflows/docs.yml)

| Event | What runs |
|-------|-----------|
| Pull request (docs-related paths) | `mkdocs build --strict` only |
| Push to `main` | Build, upload artifact, deploy to GitHub Pages |
| `workflow_dispatch` | Same as push to `main` (when run on `main`) |

Live site: **https://krakjn.github.io/timbre/**

## One-time GitHub setup

1. Open the repository on GitHub → **Settings** → **Pages**.
2. Under **Build and deployment**, set **Source** to **GitHub Actions** (not “Deploy from a branch”).
3. Merge changes to `main`; the **docs** workflow creates the `github-pages` environment deployment.

No `gh-pages` branch is required; deployment uses [GitHub’s Pages artifact API](https://docs.github.com/en/pages/getting-started-with-github-pages/configuring-a-publishing-source-for-your-github-pages-site#publishing-with-a-custom-github-actions-workflow).

## Local build

```bash
pip install -r requirements-docs.txt
mkdocs serve          # preview at http://127.0.0.1:8000/
mkdocs build --strict # output in ./site/
```
