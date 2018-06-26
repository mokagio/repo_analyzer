# 🔬 Repo Analyzer

Scrappy prototype of what could be an app to get information about the health of a codebase and take empirical decisions about refactoring.

## Usage

Using the terminal `cd` in the root folder of the Git repository you want to analyze, then run:

```
/usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/mokagio/repo_analyzer/master/analyze_repo.rb)"
```

This will generate an HTML report in the current folder.

## Limitations

This is an uber duper prototype, very opinionated and limited. In particular the analysis is performed only on `.swift` files.
