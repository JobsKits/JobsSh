# MacOS elasticsearch

![Jobs出品，必属精品](https://picsum.photos/1500/400)

[TOC]

## 1、使用`brew` 安装 `elasticsearch`

*相关资料*

[CSDN/Mac安装ES：elasticsearch has been deprecated，incompatible license，no bottle available!](https://blog.csdn.net/lilyssh/article/details/119646563)

**注意：brew install elasticsearch 已被弃用**

```ruby
brew install elastic/tap/elasticsearch-full
```

```bash
➜  ~ brew list elastic/tap/elasticsearch-full      
Warning: Calling plist_options is deprecated! Use service.require_root instead.
Please report this issue to the elastic/tap tap (not Homebrew/brew or Homebrew/homebrew-core), or even better, submit a PR to fix it:
  $(brew --prefix)/Library/Taps/elastic/homebrew-tap/Formula/elasticsearch-full.rb:68

$(brew --prefix)/Cellar/elasticsearch-full/7.17.4/bin/elasticsearch
$(brew --prefix)/Cellar/elasticsearch-full/7.17.4/bin/elasticsearch-certgen
$(brew --prefix)/Cellar/elasticsearch-full/7.17.4/bin/elasticsearch-certutil
$(brew --prefix)/Cellar/elasticsearch-full/7.17.4/bin/elasticsearch-cli
$(brew --prefix)/Cellar/elasticsearch-full/7.17.4/bin/elasticsearch-croneval
$(brew --prefix)/Cellar/elasticsearch-full/7.17.4/bin/elasticsearch-env
$(brew --prefix)/Cellar/elasticsearch-full/7.17.4/bin/elasticsearch-env-from-file
$(brew --prefix)/Cellar/elasticsearch-full/7.17.4/bin/elasticsearch-geoip
$(brew --prefix)/Cellar/elasticsearch-full/7.17.4/bin/elasticsearch-keystore
$(brew --prefix)/Cellar/elasticsearch-full/7.17.4/bin/elasticsearch-migrate
$(brew --prefix)/Cellar/elasticsearch-full/7.17.4/bin/elasticsearch-node
$(brew --prefix)/Cellar/elasticsearch-full/7.17.4/bin/elasticsearch-plugin
$(brew --prefix)/Cellar/elasticsearch-full/7.17.4/bin/elasticsearch-saml-metadata
$(brew --prefix)/Cellar/elasticsearch-full/7.17.4/bin/elasticsearch-service-tokens
$(brew --prefix)/Cellar/elasticsearch-full/7.17.4/bin/elasticsearch-setup-passwords
$(brew --prefix)/Cellar/elasticsearch-full/7.17.4/bin/elasticsearch-shard
$(brew --prefix)/Cellar/elasticsearch-full/7.17.4/bin/elasticsearch-sql-cli
$(brew --prefix)/Cellar/elasticsearch-full/7.17.4/bin/elasticsearch-syskeygen
$(brew --prefix)/Cellar/elasticsearch-full/7.17.4/bin/elasticsearch-users
$(brew --prefix)/Cellar/elasticsearch-full/7.17.4/bin/x-pack-env
$(brew --prefix)/Cellar/elasticsearch-full/7.17.4/bin/x-pack-security-env
$(brew --prefix)/Cellar/elasticsearch-full/7.17.4/bin/x-pack-watcher-env
$(brew --prefix)/Cellar/elasticsearch-full/7.17.4/homebrew.mxcl.elasticsearch-full.plist
$(brew --prefix)/Cellar/elasticsearch-full/7.17.4/libexec/bin/ (23 files)
$(brew --prefix)/Cellar/elasticsearch-full/7.17.4/libexec/jdk.app/ (432 files)
$(brew --prefix)/Cellar/elasticsearch-full/7.17.4/libexec/lib/ (45 files)
$(brew --prefix)/Cellar/elasticsearch-full/7.17.4/libexec/modules/ (418 files)
```

