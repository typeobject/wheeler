# Wheeler documentation harness

The manual uses a deliberately small Docusaurus configuration. Content lives under `docs/docs`; site code is limited to the landing page and shared styling.

## Local development

```bash
npm ci
npm start
```

## Release build

```bash
npm ci
npm run build
```

Docusaurus writes the static site to `docs/build`. The build fails on broken links or malformed MDX. GitHub Actions uses the committed npm lockfile and deploys that directory.

Reference pages describe implemented contracts. WIPs contain designs, migrations, and implementation status. Do not use a draft proposal as current user documentation.
