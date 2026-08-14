# Wheeler documentation system

Public website source lives under `docs/public`. Maintainer and conformance material lives under `docs/internal` and is never added to the public bundle. The repository has one opinionated documentation command and no renderer configuration, plugin graph, Node installation, or theme package:

```bash
./bootstrap/gradlew -p bootstrap -q :tools:wheeler --args='site -o docs-site'
```

The command discovers the fixed Wheeler source and manual roots, validates documentation ownership and graph links, builds the canonical semantic bundle, verifies it again at the rendering boundary, emits safe static HTML/CSS with one fixed local copy helper, records every output identity, and atomically publishes `docs-site`. Existing output is rejected. Remove it before rebuilding. Opening `docs-site/index.html` is sufficient for local inspection.

GitHub Pages runs that same command. Pull requests build the complete public site. Pushes publish the exact resulting directory. A change confined to `docs/**`, Markdown, or MDX skips the dual-JDK bootstrap and example matrix. The documentation workflow remains the required gate. Internal documentation is checked for style and links by repository verification, but it has no public route, search node, navigation entry, or sitemap URL. There is no second website parser waiting in the shrubbery.

Reference pages describe implemented contracts. WIPs contain designs, migrations, and implementation status. Draft prose cannot make absent behavior callable.
