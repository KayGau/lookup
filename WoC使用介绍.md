# WoC使用介绍

## WoC介绍

--------------------

WoC包含了互联网上所有可获得的使用Git的公开仓库的[Git对象](https://git-scm.com/book/zh/v1/Git-内部原理-Git-对象)：包含commit, tree, blob和tag四种类型的Git对象数据。关于WoC的详细介绍请见[MSR 19](https://dl.acm.org/citation.cfm?id=3341908)。

### WoC数据介绍

WoC中保存了两种形式的数据：

- Git对象的原始内容。

- 根据Git对象间的关系建立的一系列的map(table)。这些map有两种形式：

  - 按照第一列排序后用gzip压缩的文本文件。后面以`.s文件`表示
  - 随机访问的数据库。（基于`TokyoCabinet`数据库，详见[TC](https://fallabs.com/tokyocabinet/)）。后面以`.tch文件`表示

  这些table的命名中包含：

  - 前缀描述数据的类型。比如c2p表明是从commit到project的映射
  - 接着是完整性。Full表明表的数据是完整的，absence表明表中只包含更新的数据
  - 最后一个字母表示版本（用字母表顺序）。当前版本是P
  - 最后是数字(0-31或者0-127)。因为数据量太大，所以WoC根据第一列的哈希值来将数据分开存储。详见论文

  数据类型的说明：

  ```
  a   - author
  b   - blob
  c   - commit
  cc  - child commit
  f   - filename
  h   - Head Commit
  m   - module
  p   - project
  P   - project after fork normalization
  pc  - parent commit
  t   - time
  trp - Torvald Path
  ```

-------------------

## 初步设置

### 获取访问WoC服务器的权限

这里以Linux操作系统为例。为了访问WoC服务器，需要先通过`ssh-keygen`命令生成一对私钥和秘钥。`ssh-keygen`命令的用法见：[ssh-keygen](https://www.ssh.com/ssh/keygen/)。ssh-keygen命令生成的公钥和私钥的名字默认是`id_rsa.pub`和`id_rsa`，将这两个文件放入home文件夹内的.ssh文件夹内，然后将公钥如`id_rsa.pub`发送给Dr.Mockus。然后他会给你访问WoC服务器的权限，以邮件的形式通知你。比如，我的是：`ssh -p 443 kgao@da4.utk.edu.cn`。

如果你觉得每次在命令行输入这么长的命令很麻烦，你可以在你电脑的home文件夹内的.ssh文件夹内设置config文件。通过设置`.ssh/config`文件，你就可以用一个昵称来代替要连接的服务器。具体格式如下：

```
Host woc
	Hostname da4.eecs.utk.edu
	Port 443
	User kgao
```

你可以将woc替换成你想要的昵称，将kgao替换成你的用户名，填写你的Hostname

配置好`.ssh/config`后，你可以以`ssh woc`的形式来登录WoC服务器。

登录到WoC服务器后，你可以在`/home/username`文件夹下存放你的程序和文件。

------------------------

## 相关文件夹的介绍 

登录到WoC服务器后，通过`cd /`进入到根目录，并通过`ls`命令查看根目录内的文件：

```
bin       da2_data  dev    fast2  localhome  net   run   tmp
boot      da3_data  etc    home   media      opt   sbin  usr
da0_data  da4_data  fast   lib    misc       proc  srv   var
da1_data  data      fast1  lib64  mnt        root  sys
```

这里的data，fast，da0_data，da3_data，da4_data文件夹中保存了WoC的数据。

### /data文件夹

- 原始的Git对象内容存储在`/data/All.blobs`文件夹中。依据Git对象的类型，分别命名为`{commit,tree,tag,blob}_Num.{idx,bin}`，其中，Num范围是{0...127}。随着新的Git对象被发现和提取出来，会将这些Git对象定期添加到上述文件内。`.bin`文件存储的是对象的原始内容，`.idx`存储的是每个Git对象在对应的`.bin`文件中的索引。

------------------------------

### /fast文件夹

/fast文件夹是挂载在SSD上的，读取速度很快，它里面包含四部分的内容

- `.tch`map。
- `All.sha1`文件夹。这个文件夹中包含`sha1.{commit,tree,tag,blob}_Num.tch`文件。这些文件记录了Git对象的内容在`/data/All.blobs`中保存的原始文件中的偏移（以Git对象的SHA1值为索引）。同时这些文件也可以用来检查一个Git对象是否被记录在WoC中。
- `All.sha1c`文件夹。这个文件夹中包含`{commit,tree}_Num.tch`文件。这些文件将commit和tree对象的SHA1值映射到对象的内容
- `All.sha1o`文件夹。这个文件夹中包含`blob_Num.tch`文件。这些文件将blob对象的SHA1值映射到对应blob对象在`/data/All.blobs/blob_Num.bin`文件中的偏移，进而通过偏移读出blob对象的内容。

----------------------------

### /da0_data文件夹

da0_data中保存WoC数据的文件夹有：basemaps和play

#### /da0_data/basemaps

这个文件夹包含两部分内容

- `.tch`map
- `gz/`文件夹。这个文件夹内保存着`.s`和`.gz`文件。这些文件保存着上述的`.tch`文件的压缩版本。可以用Python的gzip模块或者Unix的zcat命令打开。

```bash
kgao@da4:/da0_data/basemaps/gz
$ zcat b2fFullP10.s | head -3
0a0000007714498dd71c0a99b0a5abd454b8925d;Silownia/Silownia/Silownia.csproj
0a000000a01950569b81fa3b036da13e332ebc38;databases/cache/epub/22624/pg22624.rdf
0a000000a221983e35b620c3cfcfea5859a66ea2;src/com/example/cricflex/ActivityMain.java
```

#### /da0_data/play

这个文件夹中包含了两部分内容：

- 一部分是WoC的用户创建的文件夹，用以存放数据和程序（文件夹名一般是用户名）。
- `$LANGthruMaps/`文件夹，其中`$LANG`可以是PY, rb, java, ipy, JS等语言。这些thruMaps文件夹包含`c2bPtaPkgO{$LANG}.{0...31}.gz`文件。这些文件包含WoC中包含的仓库的每一个commit中依赖的模块。这些文件的格式是：`commit;repo_name;timestamp;author;blob;module1;module2;...` 。这里
- 

```bash
$ zcat c2bPtaPkgOPY.24.gz | head -1
180000145f49a0ac40c62d955c8ab9accfe999ef;bb_binanova_milos_academico;1477249556;luisrene88 <luisd162000@yahoo.com.mx>;23218aba688e93216339b824efea843b6b6f8c22;django;wkhtmltopdf;academico
```

每个thruMaps文件夹对应一个不同的语言($LANG)，包含于这个语言相关的模块。这里的模块一般是用相同语言写的库(如scikit-learn)，并通过一个仓库管理器(如pip)自动安装的。

----------------------

### /da3_data文件夹

#### /da3_data/All.blobs

这个文件夹里是对`/data/All.blobs`文件夹中的commit和tree数据的备份

------------------------------

### /da4_data文件夹

#### /da4_data/All.blobs

这个文件夹是对`/data/All/blobs`文件夹的备份

### WoC服务器上的临时空间：play文件夹

除了在你的`home`文件夹创建文件外，你也可以在`/$data/play`文件夹下创建以你的username命名的文件夹，在里面存储程序和文件，这里的`$data`可以是`da0_data, da1_data, da2_data, da3_data, da4_data, data`。这么做的一个显著的优点是：在home文件夹下进行高吞吐量的读写时，可能会由于nfs的限制而失败，但是在play文件夹下则不会。除此外，你最好在你要读取的数据所在的机器上（根目录下对应的文件夹）创建你的文件，这样可以避免网络延迟和读取错误。

--------------------

## 使用oscar接口和lookup的脚本

### 克隆oscar.py和swsc/lookup仓库

oscar.py仓库是访问WoC数据的Python接口，你可以在Python中使用。swsc/lookup仓库提供了访问WoC数据的Perl脚本，你可以在命令行使用它。

oscar.py的链接为：https://github.com/ssc-oscar/oscar.py

swsc/lookup的链接为：https://bitbucket.org/swsc/lookup

在命令行输入`git clone <link>`(将`<link>`替换成上面两个链接)将上面两个仓库克隆到你的文件夹内使用

```bash
kgao@da4:~
$ ls
AIWorldExploration  build     head    lookup  nohup.out  query      tokyopipe
atp                 db.alias  head.c  memory  oscar.py   tf_readme
```

### oscar.py介绍

oscar.py中封装了一些Python的类，可以方便地查找`.tch`中单个的Git对象和blob文件。oscar.py中的类及其一些重要的属性（调用时不用加()）在下面列出。详细请见[Reference。](https://ssc-oscar.github.io/oscar.py/)

1. `Author`类 - 根据开发者的名字和邮箱组合初始化，如`Author("Albert Krawczyk" <pro-logic@optusnet.com.au>)`

   - `commit_shas`：返回这个Author对象所有commit的SHA1值，为一个元组
   - `commits`：返回这个Author对象的所有commit对象，是一个`generator`
   - `project_names`：返回这个Author对象贡献的所有仓库，返回一个元组
   - `torvald`：返回这个Author对象的torvald path，即与这个Author对象向同一个仓库贡献，同时与Linus Torvald贡献过相同仓库的开发者。格式是

   ```python
   kgao@da4:~/oscar.py
   $ python
   >>> from oscar import Author
   >>> author = Author('"Albert Krawczyk" <pro-logic@optusnet.com.au>')
   >>> print(author.commit_shas)
   ('17abdbdc90195016442a6a8dd8e38dea825292ae', '9cdc918bfba1010de15d0c968af8ee37c9c300ff', 'd9fc680a69198300d34bc7e31bbafe36e7185c76')
   >>> print(author.commits)
   <generator object <genexpr> at 0x7fdf4e809f00>
   >>> for commit in author.commits:
   ...     print(commit)
   ...
   tree 475e2fd8c608808d2fcabcf759682970a597e94f
   parent d94c406a677f4986fd6499e6169c28658e09f63c
   author "Albert Krawczyk" <pro-logic@optusnet.com.au> 1292274508 +1100
   ......
   >>> print(author.project_names)
   ('git.kernel.org_public-inbox_vger.kernel.org/git',)
   >>> print(author.torvald)
   ('git.kernel.org_public-inbox_vger.kernel.org/git', 'Linus Torvalds <torvalds@linux-foundation.org>')
   ```

2. `Blob`类 - 用一个blob对象的SHA1值初始化， 如`Blob('0629a6caa45ded5f4a2774ff7a72738460b399d4')`

   - `commit_shas`：返回创建或修改（不包括删除）这个blob对象的所有commit的SHA1值，为一个元组
   - `commit`：返回创建或修改（不包括删除）这个blob对象的所有commit对象，是一个generator`

   ```python
   kgao@da4:~/oscar.py
   $ python
   >>> from oscar import Blob
   >>> blob = Blob('0629a6caa45ded5f4a2774ff7a72738460b399d4')
   >>> print(blob.commit_shas)
   ('000034db68f89d3d2061b763deb7f9e5f81fef27',)
   >>> print(blob.commits)
   <generator object <genexpr> at 0x7f69dd66acd0>
   >>> for commit in blob.commits:
   ...     print(commit)
   ...
   tree 6ad498c9a9efb005c2d2d747695d15bbc8b8c47d
   parent ed3519f6db922c8779bf337d75d18218650fefef
   author Lucas Kjaero <lucas@lucaskjaero.com> 1497547797 -0700
   committer Lucas Kjaero <lucas@lucaskjaero.com> 1497547797 -0700
   
   Bug fixes
   
   Proper input dimensions for a one-channel image.
   ```

3. `Commit`类 - 用一个commit对象的SHA1值初始化，如`Commit('1e971a073f40d74a1e72e07c682e1cba0bae159b')`

   - `blob_shas`：返回这个commit对象包含的所有blob的SHA1值，是一个元组
   - `blob`：返回这个commit对象包含的所有blob对象，是一个`generator`
   - `child_shas`：返回这个commit对象的所有子commit的SHA1值，是一个元组
   - `children`：返回这个commit对象的所有子commit对象，是一个`generator`。
   - `changed_file_names`：返回这个commit对象修改（不包括删除）或增加的所有文件的名字，是一个元组
   - `parent_shas`：返回这个commit对象的所有父commit的SHA1值，是一个元组
   - `parents`：返回这个commit对象的所有子commit对象，是一个`generator`
   - `project_names`：返回包含这个commit对象的所有project的名字，是一个元组
   - `projects`：返回包含这个commit对象的所有Project类，是一个`generator`

   ```python
   >>> from oscar import Commit
   >>> commit = Commit('1e971a073f40d74a1e72e07c682e1cba0bae159b')
   >>> print(commit.blob_shas)
   ('2bdf5d686c6cd488b706be5c99c3bb1e166cf2f6', '2060f551336795224535caa172703b6c0e660510', 'e69de29bb2d1d6434b8b29ae775ad8c2e48c5391', '7e2a34e2ec9bfdccfa01fff7762592d9458866eb', '1e0eaec8f6164cb5e15031fee8702a05dec6a1cf', 'e0ac96cefe3d230553931c54a79fa164a8fa11da', 'c006bef767d08b41633b380058a171b7786b71ab')
   >>> print(commit.blobs)
   <generator object <genexpr> at 0x7f69dd75d730>
   >>> for blob in commit.blobs:
   ...     print(blob)
   ...
   # encoding: utf-8
   
   from django.contrib import admin
   from minicms.models import Page
   from django import forms
   from django_markdown.widgets import MarkdownWidget
   ......
   >>> print(commit.child_shas)
   ('9bd02434b834979bb69d0b752a403228f2e385e8',)
   >>> print(commit.children)
   <generator object <genexpr> at 0x7f69dd75d730>
   >>> for child in commit.children:
   ...     print(child)
   ...
   tree bbc29c8802229f735bf993ac7f8fedafe3624984
   parent 1e971a073f40d74a1e72e07c682e1cba0bae159b
   author Pavel Puchkin <neoascetic@gmail.com> 1336390606 +1100
   committer Pavel Puchkin <neoascetic@gmail.com> 1336390757 +1100
   
   `get_page` produces `menu` context variable
   >>> print(commit.changed_file_names)
   ('MANIFEST.in', 'minicms/__init__.py', 'minicms/admin.py', 'minicms/models.py', 'minicms/urls.py', 'minicms/views.py', 'setup.py')
   >>> print(commit.parent_shas) ##这个commit对象没有父commit，因为它是该仓库第一个commit
   ()
   >>> commit = Commit('e38126dbca6572912013621d2aa9e6f7c50f36bc')
   >>> print(commit.parent_shas)
   ('ab124ab4baa42cd9f554b7bb038e19d4e3647957',)
   >>> print(commit.project_names)
   ('user2589_minicms',)
   >>> print(commit.projects)
   <generator object <genexpr> at 0x7fa70f0fa0f0>
   >>> for project in commit.projects:
   ...     print(project)
   ...
   user2589_minicms
   ```

4. `Commit_info`类 - 用一个commit对象的SHA1值初始化，如`Commit_info(8caff1690253f8a9596c9918819f24c9f79140ce)`

   - `head`：返回这个commit对象所在分支(branch)的`head`的commit对象的SHA值，以及其到head的最短距离，是一个元组，第一个是SHA值，第二个距离
   - `time_author`：返回这个commit对象的产生时间戳及作者author（不是committer)，是一个元组，第一个是时间戳，第二个是作者

   ```python
   >>> from oscar import Commit_info
   >>> cf = Commit_info('995e6a997e3f841235487dac9c50f903d855aaa2')
   >>> print(cf.head)
   ('f2a7fcdc51450ab03cb364415f14e634fa69b62c', '03')
   >>> print(cf.time_author)
   ('1346920650', 'Pavel Puchkin <neoascetic@gmail.com>')
   ```

5. `File`类 - 用路径（从仓库的顶层目录开始）初始化。路径仅表示一个文件名，与文件内容或仓库无关。比如`File('.gitignore')`表示WoC中所有仓库中的`.gitignore`文件

   - `commit_shas`：返回所有改变这个文件的commit对象的SHA值，为一个元组。**
   - `commits`：返回所有改变这个文件的commit对象，为一个`generator`

6. `Project`类 - 用仓库的名字或者URL初始化，如`Project('user2589_minicms')`。WoC中仓库名的命名规则如下：

   ```
   Github: {user}_{repo}, e.g. user2589_minicms
   Gitlab: gl_{user}_{repo}
   Bitbucket: bb_{user}_{repo}
   Bioconductor: bioconductor.org_{user}_{repo}
   kde: kde.org_{user}_{repo}
   drupal: drupal.org_{user}_{repo}
   Googlesouce: android.googlesource.com_{repo}_{user}
   Linux kernel: git.kernel.org_{user}_{repo}
   PostgreSQL: git.postgresql.org_{user}_{repo}
   GNU Savannah: git.savannah.gnu.org_{user}_{repo}
   ZX2C4: git.zx2c4.com_{user}_{repo}
   GNOME: gitlab.gnome.org_{user}_{repo}
   repo.or.cz: repo.or.cz_{user}_{repo}
   Salsa: salsa.debian.org_{user}_{repo}
   SourceForge: sourceforge.net_{user}_{repo}
   ```

   - `author_names`：返回向这个仓库提交commit的author
   - `commit_shas`：返回这个仓库所有的commit对象的SHA1值，为一个元组
   - `commits:`：返回这个仓库所有的commit对象，为一个`generator`
   - `toURL()`：返回这个仓库的URL

   ```python
   >>> from oscar import Project
   >>> p = Project('user2589_minicms')
   >>> print(p.author_names)
   ('Marat Valiev <valiev.m@gmail.com>', 'Pavel Puchkin <neoascetic@gmail.com>')
   >>> print(p.commit_shas)
   ('05cf84081b63cda822ee407e688269b494a642de', '086a622f0e24feb7853c520f965f04c7fc7e4861',
   ......)
   >>> print(p.commits)
   <generator object commits at 0x7f66da7bb410>
   >>> for commit in p.commits:
   ...     print(commit)
   ...     break
   ...
   tree 85575a7546aef8dfbee6fff30d83c24d24a5454a
   parent 4dffda766eba4f4edc31eb0b7691cc75d7775de0
   author Pavel Puchkin <neoascetic@gmail.com> 1337338456 +1100
   committer Pavel Puchkin <neoascetic@gmail.com> 1337338456 +1100
   
   Markdown editor integrated
   >>> print(p.toURL())
   https://github.com/user2589/minicms
   ```

   ### lookup介绍

   Lookup仓库中有很多读取WoC数据的Perl脚本，你可以在命令行中使用它们，下面展示了一些它的常用的用法，关于详细的教程，请见[Analytics](https://github.com/ssc-oscar/Analytics/blob/master/README.md)，[lookup](https://bitbucket.org/swsc/lookup/src/master/README.md)。

   1. 获取一个author的所有仓库

   ```bash
   $ echo "KayGau <topgaokai@gmail.com>" | /da3_data/lookup/Prj2FileShow.perl /da0_data/basemaps/a2pFullP 1 32
   KayGau <topgaokai@gmail.com>;4;KayGau_libgit2;KayGau_my_test;KayGau_test;ghtorrent_ghtorrent.org
   ```

   2. 获取一个author的所有commit

   ```bash
   $ echo "KayGau <topgaokai@gmail.com>" | /da3_data/lookup/Prj2CmtShow.perl /da0_data/basemaps/a2cFullP 1 32
   KayGau <topgaokai@gmail.com>;34;16a3c3950696f645f5f731257b1b5060a7a34b2c;1f84830c6a6170454fe25c92e82907655701e30c;24da4efc27bfd2d9a5142d74ecc4ef0b338c9ef7;
   ```

   3. 获取一个commit的属性，输出格式为：commit;tree;parent commits;author;committer;author time;commit time

   ```bash
   $ echo af36164b147909db1c10e9fa036482dd3e885d86 | /da3_data/lookup/showCmt.perl
   af36164b147909db1c10e9fa036482dd3e885d86;327fc9abe68a2e7a2c3c0e57aa24acac483d1df5;dc20c7c4e92aea6af318a611e2669d5b9c6cbfaf:233a171bffda06c3dc4d11548160b24b8ed2f6e4;Roger D. Peng <rdpeng@gmail.com>;Roger D. Peng <rdpeng@gmail.com>;1409068558 -0400;1409068558 -0400
   ```

   4. 获取blob对象的内容 (只能用da4登陆，即username@da4.eecs.utk.edu)

   ```bash
   $ echo 05fe634ca4c8386349ac519f899145c75fff4169 | /da3_data/lookup/showBlob.perl
   blob;5;8529;54537521775;54537521775;8529;05fe634ca4c8386349ac519f899145c75fff4169
   # Syllabus for "Fundamentals of Digital Archeology"
   ......
   ```

   5. 获取一个tree对象的内容 (只能用da4登陆，即username@da4.eecs.utk.edu)

   ```bash
   $ echo f1b66dcca490b5c4455af319bc961a34f69c72c2 | perl ~audris/bin/showTree.perl
   100644;05fe634ca4c8386349ac519f899145c75fff4169;README.md
   100644;dfcd0359bfb5140b096f69d5fad3c7066f101389;course.pdf
   ```

   ## 一些实践

   ### 获取所有使用TensorFlow的项目

   ```bash
   for j in {0..31}
   do
   	zcat /da0_data/play/PYthruMaps/c2bPtaPkgOPY.$j.gz | grep tensorflow | awk -F ';' '{print $2}' >> tf_project
   	sort tf_project | uniq > tf_project_sort
   done
   ```

   ### 找到仓库第一次import AI模块的时间

   关于这个实践的代码在[popmods.py](https://github.com/ssc-oscar/aiframeworks/blob/master/popmods.py)。首先指定一个编程语言`$LANG`，遍历32个`c2bPtaPkgO$LANG.{0-31}.gz`文件，然后找到所有import该模块的仓库第一次import它的时间。`popmods.py`的运行方式为：

   ```bash
   $ python popmods.py language_file_extension module_name
   ```

   它会生成一个<module_name>.first文件，该文件每一行的格式是`repo_name;UNIX_timestam`。

   下面看一下它的实现细节。它也是依赖`c2bPtaPkgO$LANG.{0-31}.gz`文件。我们来回忆一下这个文件的格式:

   ```bash
   $ zcat /da0_data/play/PYthruMaps/c2bPtaPkgOPY.0.gz | head -1
   000000004e98f7ef31ab0e7f16b6fd981b43c78e;dj-shin_gitchain;1531386645;hoonga <oh.hoonga@gmail.com>;6fb813dcf21d4069bb21f7444c872ce770fee728;itertools;string;time;mp;argparse;datetime;subprocess;re;hashlib
   ```

   其格式为：`commit;repo_name;timestamp;author;blob;module1;module2;...`。我们可以通过module来判断一个仓库是否import指定的AI模块，同时记录下timestamp以便找到第一次import的时间。如何通过Python来读取这些文件呢？Python提供了gzip模块用以读取gz压缩文件：

   ```python
   import gzip
   ...
   for i in range(32):
     file = gzip.open("/data/play/PYthruMaps/c2bPtaPkgOPY." + str(i) + ".gz")
   ```

   然后读取每一行，根据分号(;)将每一行转化成列表：`[commit, repo_name,timestamp,author,blob,module...]`。

   ```python\
   ...
   repo_dict = []
   for line in file.readlines():
     entry = str(line).split(';')
     repo, time = entry[1], entry[2]
   ...
   ```

   这里有一点要注意，我们要只对每一个timestamp计数一次。这是因为由于会有fork仓库的情况出现，会导致相同的commit出现多次。一般来说，不同的commit的timestamp是不一样的（SHA1算法对字符敏感）。所以这么做，我们可以避免对同一个commit计数多次：

   ```
   ...
   if time in times:
   	continue
   else:
   	times.append(time)
   ...
   ```

   然后找到一个仓库import AI模块的最早时间：

   ```python
   ...
   if repo not in dict.keys() or time < dict[repo]:
     for word in entry[5:]:
       if module in word:
         dict[repo] = time
         break
   ...
   ```

   最后将dict字典写入到文件中，得到<module_name>.first文件。

   我们可以用`popmods.py`得到多个AI模块的<module_name>.first文件。除此外，我们还可以更进一步，画出一个AI模块第一次被import的数量随时间的变化，甚至比较多个模块的情况。[modtrends.py](https://github.com/ssc-oscar/aiframeworks/blob/master/modtrends.py)文件可以做到这些，具体说来，它：

   - 读取1个或多个.first文件
   - 将.first文件中每个仓库的timestamp转换成datetime
   - 将得到的datetime按月计数
   - 画出时间和频率

   用法示例：比较tensorflow和Keras每月被第一次import的数量

   ```bash
   $ python modtrends.py tensorflow.first keras.first
   ```

   ### 统计每个author各编程语言使用比例及随时间的变化

   为了完成这个任务，我们需要修改`swsc/lookup`仓库里的[a2fBinSorted.perl](https://bitbucket.org/swsc/lookup/src/master/a2fBinSorted.perl)文件，然后创建一个[a2L.py](https://bitbucket.org/swsc/lookup/src/master/a2L.py)文件以获取每个author每年使用的编程语言计数

   #### Part 1 -- 修改a2fBinSorted.perl文件

   

   
