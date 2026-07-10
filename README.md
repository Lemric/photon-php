# Package repository branch (`gh-pages`)

This branch contains **only** the published RPM repository for GitHub Pages.

Do not commit source code here. All changes are made on `main` and deployed incrementally by `.github/workflows/ci.yml` and `.github/workflows/build-php.yml`.

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
curl -fsSL https://pkgs.photon.lemric.com/photon-php.repo \
  -o /etc/yum.repos.d/photon-php.repo
tdnf makecache
tdnf install -y php85 php85-fpm php85-opcache
```
