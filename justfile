IMAGE := "ghcr.io/krakjn/timbre"
_:
  @just --list

img:
    docker build -t {{IMAGE}} -< Dockerfile

docs-install:
    pip install -r requirements-docs.txt

docs-serve:
    mkdocs serve -a 0.0.0.0:8000

docs-build:
    mkdocs build --strict
