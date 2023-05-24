# Utility script for GraphScope

[![Build](https://github.com/GraphScope/cli/actions/workflows/build.yml/badge.svg)](https://github.com/GraphScope/cli/actions/workflows/build.yml)

A command-line tool for GraphScope, powered by
[bash.ly](https://github.com/DannyBen/bashly). 

Get the latest build of the script from artifacts in [Actions](https://github.com/GraphScope/cli/actions).

## Usage


```bash
> # for detailed usage
> ./gs
```

## Develop

1. Install ruby, gem and bashly
2. Make changes to `src/bashly.yml`, and shell scripts within `src`. Refer to the documentation of [bash.ly](https://github.com/DannyBen/bashly)
3. Run `bashly generate` in the root directory, a `gs` file would be generated
4. Copy generated `gs` to `GraphScope` repo and commit.

### Install ruby >= 2.7

#### MacOS
```bash
brew install ruby
gem install bashly

# MacOS bundled with an older bash v3, need to install a newer one which version >= 4
brew install bash
# Optional: Activate new bash
bash
```
#### Ubuntu 20.04 +
```bash
apt update -y && apt install ruby gem -y
gem install bashly
```

#### Centos 7
```bash
yum install centos-release-scl-rh -y
yum install rh-ruby30-ruby -y
/usr/bin/scl enable rh-ruby30 bash
gem install bashly
```

#### Centos 8
```bash
sed -i 's/mirrorlist/#mirrorlist/g' /etc/yum.repos.d/CentOS-*
sed -i 's|#baseurl=http://mirror.centos.org|baseurl=http://vault.centos.org|g' /etc/yum.repos.d/CentOS-*
yum install @ruby:3.0 -y
gem install bashly
```

### Generate script
```bash
# git clone https://github.com/GraphScope/cli.git & cd cli
bashly generate
```
