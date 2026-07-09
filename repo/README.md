# Photon PHP RPM Repository

Public package repository for VMware Photon OS 5.x.

**URL:** https://pkgs.photon.lemric.com  
**Branch:** `gh-pages` (packages only — no source code)

RPM files are built from `main` by CI and published to the `gh-pages` branch automatically.

## Structure (on GitHub Pages)

```
https://pkgs.photon.lemric.com/
├── x86_64/
│   ├── *.rpm
│   └── repodata/
├── aarch64/
│   ├── *.rpm
│   └── repodata/
├── photon-php.repo
└── index.html
```

## Install from GitHub Pages

```bash
ARCH=$(uname -m)

curl -fsSL https://pkgs.photon.lemric.com/photon-php.repo \
  | sed "s|/x86_64|/${ARCH}|g" \
  > /etc/yum.repos.d/photon-php.repo

tdnf makecache
tdnf install -y php85 php85-fpm php85-opcache
```

### Manual tdnf configuration

```bash
ARCH=$(uname -m)

cat > /etc/yum.repos.d/photon-php.repo << EOF
[photon-php]
name=Photon PHP 8.5
baseurl=https://pkgs.photon.lemric.com/${ARCH}
enabled=1
gpgcheck=0
EOF

tdnf makecache
tdnf install -y php85 php85-cli php85-fpm php85-opcache
```

## Local build (offline / development)

```bash
sudo ./scripts/build-rpm.sh all
REPO_BASEURL=https://pkgs.photon.lemric.com sudo -E ./scripts/build-repo.sh
```

Serve locally for testing:

```bash
cd repo && python3 -m http.server 8080
# baseurl=http://localhost:8080/x86_64
```

## DNS setup (custom domain)

Configure in your DNS provider:

| Type | Name | Value |
|------|------|-------|
| CNAME | `pkgs.photon` | `<user>.github.io` |

Then in GitHub repository **Settings → Pages**:

1. **Source:** Deploy from branch → `gh-pages` / `/ (root)`
2. **Custom domain:** `pkgs.photon.lemric.com`
3. Enable **Enforce HTTPS** after DNS propagation.

The `CNAME` file is deployed automatically to the `gh-pages` branch by CI.

## Available packages

| Package | Description |
|---------|-------------|
| `php85` | Meta-package (CLI + common) |
| `php85-cli` | PHP command-line interpreter |
| `php85-fpm` | PHP-FPM FastCGI process manager |
| `php85-common` | Configuration and module directory |
| `php85-devel` | Headers and phpize for PECL builds |
| `php85-opcache` | Zend OPcache with JIT |
| `php85-mbstring` | Multibyte string support |
| `php85-intl` | Internationalization |
| `php85-xml` | DOM, SimpleXML, XMLReader/Writer |
| `php85-curl` | cURL client |
| `php85-gd` | GD imaging |
| `php85-zip` | ZIP archives |
| `php85-bcmath` | Arbitrary precision math |
| `php85-soap` | SOAP protocol |
| `php85-sockets` | Low-level sockets |
| `php85-pcntl` | Process control (CLI) |
| `php85-mysqlnd` | MySQL Native Driver |
| `php85-pgsql` | PostgreSQL driver |
| `php85-pecl-redis` | Redis extension |
| `php85-pecl-igbinary` | Igbinary serializer |
| `php85-pecl-apcu` | APCu user cache |
| `php85-pecl-amqp` | AMQP/RabbitMQ |
| `php85-pecl-imagick` | ImageMagick |
| `php85-pecl-xdebug` | Xdebug (development only) |
| `re2c` | Lexer generator (build dependency) |
