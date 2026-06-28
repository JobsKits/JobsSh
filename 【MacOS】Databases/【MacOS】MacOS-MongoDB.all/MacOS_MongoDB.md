# MacOS 平台上 关于芒果🥭数据库

![Jobs出品，必属精品](https://picsum.photos/1500/400)

[toc]
- [MacOS 平台上 关于芒果🥭数据库](#macos-平台上-关于芒果数据库)
  - [1、MacOS\_MongoDB](#1macos_mongodb)
    - [1.1、简介](#11简介)
    - [1.2、安装 `MongoDB`](#12安装-mongodb)
      - [2.1、使用`Homebrew`安装 `mongodb`（废弃）](#21使用homebrew安装-mongodb废弃)
      - [2.1、使用 `Homebrew Cask` 安装 `gcollazo-mongodb`](#21使用-homebrew-cask-安装-gcollazo-mongodb)
      - [2.2、使用 `Homebrew Cask` 安装 `MongoDB 6.0 Community Edition`](#22使用-homebrew-cask-安装-mongodb-60-community-edition)
    - [1.3、端口](#13端口)
  - [2、`MongoDB Compass`](#2mongodb-compass)
    - [2.1、安装 `MongoDB Compass`](#21安装-mongodb-compass)
    - [2.2、相关说明](#22相关说明)
  - [3、`Mongosh`](#3mongosh)
    - [3.1、安装 `mongosh`](#31安装-mongosh)
    - [3.2、利用`mongosh`访问`MongoDB`](#32利用mongosh访问mongodb)
    - [3.3、利用`mongosh` CRUD 操作`MongoDB`](#33利用mongosh-crud-操作mongodb)
      - [3.3.1、创建（Create）名为`Jobs`的数据库](#331创建create名为jobs的数据库)
      - [3.3.2、查询（Read）名为`Jobs`的数据库](#332查询read名为jobs的数据库)
      - [3.3.3、删除（Delete）名为`Jobs`的数据库](#333删除delete名为jobs的数据库)
      - [3.3.4、更新（Update）名为`Jobs`的数据库](#334更新update名为jobs的数据库)

*资料来源*

[今日头条/一文详解Mongodb数据库，适合大数据存储](https://www.toutiao.com/article/7199175994111033871/?tt_from=copy_link&utm_campaign=client_share&app=news_article&utm_source=copy_link&iid=424846500052268&utm_medium=toutiao_ios&use_new_style=1&share_token=68F663DD-D220-4190-9013-E541DEEABF55)

[runoob/MongoDB 教程](https://www.runoob.com/mongodb/mongodb-tutorial.html)

[w3cschool/MongoDB 查询文档](https://www.w3cschool.cn/mongodb/mongodb-query.html)

## 1、MacOS_MongoDB

### 1.1、简介

```json
MongoDB 是由C++语言编写的，是一个基于分布式文件存储的开源数据库系统
MongoDB 是一个介于关系数据库和非关系数据库之间的产品，是非关系数据库当中功能最丰富，最像关系数据库的
MongoDB 将数据存储为一个文档，数据结构由键值(key=>value)对组成
MongoDB 文档类似于 JSON 对象
字段值可以包含其他文档，数组及文档数组
举例：
{
	name:"sue",
	age:26,
	status:"A",
	groups:["new","sport"]
}
```

### 1.2、安装 `MongoDB`

*资料来源*

[runoob/Mac OSX 平台安装 MongoDB](https://www.runoob.com/mongodb/mongodb-osx-install.html)

[Mongodb官网/Install MongoDB Community Edition on macOS](https://www.mongodb.com/docs/manual/tutorial/install-mongodb-on-os-x/)

[Github/The easiest way to get started with mongoDB on the Mac](https://github.com/gcollazo/mongodbapp)

[稀土掘金/使用 brew 安装使用 mongodb](https://juejin.cn/post/7069566026655989767)

#### 2.1、使用`Homebrew`安装 `mongodb`（废弃）

```bash
➜  ~ brew install mongodb
==> Downloading https://formulae.brew.sh/api/formula.jws.json
######################################################################### 100.0%
==> Downloading https://formulae.brew.sh/api/cask.jws.json
######################################################################### 100.0%
Warning: No available formula with the name "mongodb". Did you mean mongosh or monetdb?
==> Searching for similarly named formulae and casks...
==> Formulae
mongodb-atlas-cli
mongodb/brew/libmongocrypt
mongodb/brew/mongodb-community ✔
mongodb/brew/mongodb-community-shell
mongodb/brew/mongodb-community-shell@4.2
mongodb/brew/mongodb-community-shell@4.4
mongodb/brew/mongodb-community@4.2
mongodb/brew/mongodb-community@4.4
mongodb/brew/mongodb-community@5.0
mongodb/brew/mongodb-csfle
mongodb/brew/mongodb-database-tools ✔
mongodb/brew/mongodb-enterprise
mongodb/brew/mongodb-enterprise@4.2
mongodb/brew/mongodb-enterprise@4.4
mongodb/brew/mongodb-enterprise@5.0
mongodb/brew/mongodb-mongocryptd
mongodb/brew/mongodb-mongocryptd@4.2
mongodb/brew/mongodb-mongocryptd@4.4
mongodb/brew/mongodb-mongocryptd@5.0
mongosh ✔
monetdb

To install mongodb-atlas-cli, run:
  brew install mongodb-atlas-cli

==> Casks
gcollazo-mongodb ✔                       mongodb-realm-studio
mongodb-compass                          mongodbpreferencepane
mongodb-compass-isolated-edition         mongotron
mongodb-compass-readonly                 nosqlbooster-for-mongodb

To install gcollazo-mongodb ✔, run:
  brew install --cask gcollazo-mongodb ✔
```

#### 2.1、使用 `Homebrew Cask` 安装 `gcollazo-mongodb`

```bash
➜  ~ brew reinstall --cask gcollazo-mongodb
==> Downloading https://github.com/gcollazo/mongodbapp/releases/download/6.0.0-b
==> Downloading from https://objects.githubusercontent.com/github-production-rel
######################################################################### 100.0%
==> Uninstalling Cask gcollazo-mongodb
==> Backing App 'MongoDB.app' up to '$(brew --prefix)/Caskroom/gcollazo-mongodb/6.0
==> Removing App '$APPLICATIONS_DIR/MongoDB.app'
==> Purging files for version 6.0.0-build.1 of Cask gcollazo-mongodb
==> Installing Cask gcollazo-mongodb
==> Moving App 'MongoDB.app' to '$APPLICATIONS_DIR/MongoDB.app'
🍺  gcollazo-mongodb was successfully installed!
```

```bash
➜  ~ brew list gcollazo-mongodb       
==> App
$APPLICATIONS_DIR/MongoDB.app (185 files, 224.7MB)
```

```bash
➜  ~ brew info gcollazo-mongodb      
==> gcollazo-mongodb: 6.0.0-build.1
https://elweb.co/mongodb-app/
$(brew --prefix)/Caskroom/gcollazo-mongodb/6.0.0-build.1 (121B)
From: https://github.com/Homebrew/homebrew-cask/blob/HEAD/Casks/gcollazo-mongodb.rb
==> Name
MongoDB
==> Description
App wrapper for MongoDB
==> Artifacts
MongoDB.app (App)
==> Analytics
install: 9 (30 days), 286 (90 days), 1,129 (365 days)
```

```bash
➜  ~ mongod --version
db version v6.0.5
Build Info: {
    "version": "6.0.5",
    "gitVersion": "c9a99c120371d4d4c52cbb15dac34a36ce8d3b1d",
    "modules": [],
    "allocator": "system",
    "environment": {
        "distarch": "aarch64",
        "target_arch": "aarch64"
    }
}
```

#### 2.2、使用 `Homebrew Cask` 安装 `MongoDB 6.0 Community Edition`

```bash
➜  ~ brew reinstall mongodb-community
==> Fetching dependencies for mongodb/brew/mongodb-community: node@16 and mongosh
==> Fetching node@16
==> Downloading https://ghcr.io/v2/homebrew/core/node/16/manifests/16.20.0
######################################################################### 100.0%
==> Downloading https://ghcr.io/v2/homebrew/core/node/16/blobs/sha256:9a935f6418
==> Downloading from https://pkg-containers.githubusercontent.com/ghcr1/blobs/sh
######################################################################### 100.0%
==> Fetching mongosh
==> Downloading https://ghcr.io/v2/homebrew/core/mongosh/manifests/1.8.2
######################################################################### 100.0%
==> Downloading https://ghcr.io/v2/homebrew/core/mongosh/blobs/sha256:a097528d6a
==> Downloading from https://pkg-containers.githubusercontent.com/ghcr1/blobs/sh
######################################################################### 100.0%
==> Fetching mongodb/brew/mongodb-community
==> Downloading https://fastdl.mongodb.org/osx/mongodb-macos-arm64-6.0.5.tgz
######################################################################### 100.0%
==> Reinstalling mongodb/brew/mongodb-community 
Warning: Your Xcode (14.2) is outdated.
Please update to Xcode 14.3 (or delete it).
Xcode can be updated from the App Store.

==> Installing dependencies for mongodb/brew/mongodb-community: node@16 and mongosh
==> Installing mongodb/brew/mongodb-community dependency: node@16
==> Pouring node@16--16.20.0.arm64_ventura.bottle.tar.gz
🍺  $(brew --prefix)/Cellar/node@16/16.20.0: 1,890 files, 47.5MB
==> Installing mongodb/brew/mongodb-community dependency: mongosh
==> Pouring mongosh--1.8.2.arm64_ventura.bottle.tar.gz
🍺  $(brew --prefix)/Cellar/mongosh/1.8.2: 8,228 files, 40.8MB
==> Installing mongodb/brew/mongodb-community
==> Caveats
To restart mongodb/brew/mongodb-community after an upgrade:
  brew services restart mongodb/brew/mongodb-community
Or, if you don't want/need a background service you can just run:
  $(brew --prefix)/opt/mongodb-community/bin/mongod --config $(brew --prefix)/etc/mongod.conf
==> Summary
🍺  $(brew --prefix)/Cellar/mongodb-community/6.0.5: 11 files, 200.5MB, built in 5 seconds
==> Running `brew cleanup mongodb-community`...
Disable this behaviour by setting HOMEBREW_NO_INSTALL_CLEANUP.
Hide these hints with HOMEBREW_NO_ENV_HINTS (see `man brew`).
Warning: Calling plist_options is deprecated! Use service.require_root instead.
Please report this issue to the elastic/tap tap (not Homebrew/brew or Homebrew/homebrew-core), or even better, submit a PR to fix it:
  $(brew --prefix)/Library/Taps/elastic/homebrew-tap/Formula/elasticsearch-full.rb:68

==> Caveats
==> mongodb-community
To restart mongodb/brew/mongodb-community after an upgrade:
  brew services restart mongodb/brew/mongodb-community
Or, if you don't want/need a background service you can just run:
  $(brew --prefix)/opt/mongodb-community/bin/mongod --config $(brew --prefix)/etc/mongod.conf
```

```bash
➜  ~ brew list mongodb-community                
$(brew --prefix)/Cellar/mongodb-community/6.0.5/bin/install_compass
$(brew --prefix)/Cellar/mongodb-community/6.0.5/bin/mongod
$(brew --prefix)/Cellar/mongodb-community/6.0.5/bin/mongos
$(brew --prefix)/Cellar/mongodb-community/6.0.5/homebrew.mongodb-community.service
$(brew --prefix)/Cellar/mongodb-community/6.0.5/homebrew.mxcl.mongodb-community.plist
$(brew --prefix)/Cellar/mongodb-community/6.0.5/MPL-2
$(brew --prefix)/Cellar/mongodb-community/6.0.5/THIRD-PARTY-NOTICES
```

### 1.3、端口

`默认端口：27017`

## 2、`MongoDB Compass`

### 2.1、安装 `MongoDB Compass`

*相关资料*

[[Homebrew Formulae/mongodb-compass]](https://formulae.brew.sh/cask/mongodb-compass)

[MongoDB Compass教程](https://www.tizi365.com/topic/59.html)

```bash
brew install --cask mongodb-compass

==> Downloading https://formulae.brew.sh/api/cask.jws.json
######################################################################### 100.0%
==> Downloading https://downloads.mongodb.com/compass/mongodb-compass-1.36.4-dar
######################################################################### 100.0%
==> Installing Cask mongodb-compass
==> Moving App 'MongoDB Compass.app' to '$APPLICATIONS_DIR/MongoDB Compass.app'
🍺  mongodb-compass was successfully installed!
```

### 2.2、相关说明

```
MongoDB Compass是一个可视化GUI工具，方便我们通过可视化页面操作MongoDB
```

## 3、`Mongosh`

*MongoDB Shell工具：mongosh*

```javascript
资料来源

https://juejin.cn/post/7091969764024647710
```

### 3.1、安装 `mongosh`

```bash
➜  ~ brew install Mongosh                      
==> Downloading https://formulae.brew.sh/api/formula.jws.json
######################################################################### 100.0%
==> Downloading https://formulae.brew.sh/api/cask.jws.json
#=#=#                                                                          
Warning: mongosh 1.8.2 is already installed and up-to-date.
To reinstall 1.8.2, run:
  brew reinstall mongosh
```

```bash
➜  ~ mongosh --version
1.8.2
```

### 3.2、利用`mongosh`访问`MongoDB`

```bash
➜  ~ mongosh
Current Mongosh Log ID:	645a7441bc18d837c3730a34
Connecting to:		mongodb://127.0.0.1:27017/?directConnection=true&serverSelectionTimeoutMS=2000&appName=mongosh+1.8.2
Using MongoDB:		6.0.0
Using Mongosh:		1.8.2

For mongosh info see: https://docs.mongodb.com/mongodb-shell/

------
   The server generated these startup warnings when booting
   2023-05-09T21:20:21.356+07:00: Access control is not enabled for the database. Read and write access to data and configuration is unrestricted
   2023-05-09T21:20:21.356+07:00: Soft rlimits for open file descriptors too low
------

------
   Enable MongoDB's free cloud-based monitoring service, which will then receive and display
   metrics about your deployment (disk utilization, CPU, operation statistics, etc).
   
   The monitoring data will be available on a MongoDB website with a unique URL accessible to you
   and anyone you share the URL with. MongoDB may use this information to make product
   improvements and to suggest MongoDB products and deployment options to you.
   
   To enable free monitoring, run the following command: db.enableFreeMonitoring()
   To permanently disable this reminder, run the following command: db.disableFreeMonitoring()
------

test> show dbs
admin   40.00 KiB
config  60.00 KiB
local   40.00 KiB
test> 
```

```
admin： 从权限的角度来看，这是"root"数据库。要是将一个用户添加到这个数据库，这个用户自动继承所有数据库的权限。一些特定的服务器端命令也只能从这个数据库运行，比如列出所有的数据库或者关闭服务器。
local: 这个数据永远不会被复制，可以用来存储限于本地单台服务器的任意集合
config: 当Mongo用于分片设置时，config数据库在内部使用，用于保存分片的相关信息。
```

### 3.3、利用`mongosh` CRUD 操作`MongoDB`

#### 3.3.1、创建（Create）名为`Jobs`的数据库

```
1、直接use数据库，优化create环节；
test> use Jobs
switched to db Jobs
Jobs> 

2、不往数据库里面写入数据，是无法show出来的
DeprecationWarning: Collection.insert() is deprecated. Use insertOne, insertMany, or bulkWrite.
```

```bash
Jobs> db.Jobs.insertOne({"name":"4"})
等价
Jobs> db.Jobs.insertOne({name:'4'})

Jobs> db.Jobs.insertOne({name:4})
{
  acknowledged: true,
  insertedId: ObjectId("645a81dfeb39043b456a44c5")
}

Jobs> show dbs
Jobs      8.00 KiB
admin    40.00 KiB
config  108.00 KiB
local    40.00 KiB
```

#### 3.3.2、查询（Read）名为`Jobs`的数据库

*`pretty() `方法以格式化的方式来显示所有文档*

```bash
Jobs> db.Jobs.find().pretty()
[
  { _id: ObjectId("645aa87e198b4fc57b6424f0"), name: '4' },
  { _id: ObjectId("645aa883198b4fc57b6424f1"), name: '4' },
  { _id: ObjectId("645aa889198b4fc57b6424f2"), name: 4 }
]
```

#### 3.3.3、删除（Delete）名为`Jobs`的数据库

```bash
Jobs> show dbs
Jobs      8.00 KiB
admin    40.00 KiB
config  108.00 KiB
local    40.00 KiB
Jobs>  db.dropDatabase()
{ ok: 1, dropped: 'Jobs' }

Jobs> show dbs
admin    40.00 KiB
config  108.00 KiB
local    40.00 KiB
Jobs> 
```

#### 3.3.4、更新（Update）名为`Jobs`的数据库

*语法*

```bash
db.collection.update(
   <query>,
   <update>,
   {
     upsert: <boolean>,
     multi: <boolean>,
     writeConcern: <document>
   }
)

参数说明：
query : update的查询条件，类似sql update查询的where子句。
update : update的对象和一些更新的操作符（如$,$inc...）等，也可以理解为 sql update查询的set子句
upsert : 可选，这个参数的意思是，如果不存在update的记录，是否插入objNew,true为插入，默认是false，不插入。
multi : 可选，mongodb 默认是false,只更新找到的第一条记录，如果这个参数为true,就把按条件查出来多条记录全部更新。
writeConcern :可选，抛出异常的级别。
```

*举例*

```bash
Jobs>  db.Jobs.find().pretty()
[ { _id: ObjectId("645a9f0cc23a619de7989dac"), name: 'W3Cschool教程' } ]
Jobs> 

Jobs> db.Jobs.update({'name':'W3Cschool教程'},{$set:{'name':'哈哈'}})
{
  acknowledged: true,
  insertedId: null,
  matchedCount: 1,
  modifiedCount: 1,
  upsertedCount: 0
}

Jobs> db.Jobs.find().pretty()
[ { _id: ObjectId("645a9f0cc23a619de7989dac"), name: '哈哈' } ]
Jobs> 
```







































