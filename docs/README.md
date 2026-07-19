# Wheeler documentation system

The manual lives under `docs/docs`. The repository has one opinionated documentation command and no renderer configuration, plugin graph, Node installation, or theme package:

```bash
./bootstrap/gradlew -p bootstrap -q :tools:wheeler --args='site -o docs-site'
```

The command discovers the fixed Wheeler source and manual roots, validates documentation ownership and graph links, builds the canonical semantic bundle, verifies it again at the rendering boundary, emits safe static HTML/CSS, records every output identity, and atomically publishes `docs-site`. Existing output is rejected; remove it before rebuilding. Opening `docs-site/index.html` is sufficient for local inspection.

GitHub Pages runs that same command. Pull requests build the complete site; pushes publish the exact resulting directory. There is no second website parser waiting in the shrubbery.

Reference pages describe implemented contracts. WIPs contain designs, migrations, and implementation status. Draft prose cannot make absent behavior callable.
