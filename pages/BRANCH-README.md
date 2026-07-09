# Package repository branch (`gh-pages`)

This branch contains **only** the published RPM repository for GitHub Pages.

Do not commit source code here. All changes are made on `main` and deployed by `.github/workflows/pages.yml`.

## Layout

```
/
├── CNAME                  # pkgs.photon.lemric.com
├── .nojekyll
├── index.html
├── photon-php.repo
├── repodata.json
├── x86_64/
│   ├── *.rpm
│   └── repodata/
└── aarch64/
    ├── *.rpm
    └── repodata/
```

## Install

```bash
ARCH=$(uname -m)
curl -fsSL https://pkgs.photon.lemric.com/photon-php.repo \
  | sed "s|/x86_64|/${ARCH}|g" \
  > /etc/yum.repos.d/photon-php.repo
tdnf makecache
tdnf install -y php85 php85-fpm php85-opcache
```
