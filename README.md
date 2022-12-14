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

### Install ruby >= 2.7

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

### Generate script
```bash
# git clone https://github.com/GraphScope/cli.git & cd cli
bashly generate
```
