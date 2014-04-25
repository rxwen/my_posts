[dash](http://kapeli.com/dash) is an excellent API documentation browser on OSX. It supports offline documentation sets for lots of programming language, and search in dash is a lot faster than search on web. You can have access to documentation instantly, even if you don't have network access. Fortunately, programmers working on windows, linux platform, can use [zeal](http://zealdocs.org/), which is a opensource clone of dash.



![zeal](https://github-camo.global.ssl.fastly.net/5d20d0ff77698b1acfe49939a209246f4ccb239e/687474703a2f2f692e696d6775722e636f6d2f53694c76707a382e706e67)



The easy way to install zeal on Ubuntu is to [install from the PPA ](http://zealdocs.org/download.html). But we can't use this option, because zeal depends on Qt5, but we can't install Qt5 on system standard location to avoid confication with Qt4, which is used for our product development. So, we choose to install Qt5 in /opt directory and build zeal ourselves.


A problem with build zeal is it requires c++11 support, which isn't supported by gcc v4.6. But we can't upgrade to newer version. So, we choose to use [clang v3.3 (or newer version)](http://clang.llvm.org/cxx_status.html) to build zeal.


1. Download qt5 installer from https://qt-project.org/downloads and install to /opt
2. Install required packages and clang: 

        sudo apt-get install libgstreamer-plugins-base0.10-dev libxslt-dev libxml2-dev libxcb-keysyms1-dev libgl1-mesa-dev zlib1g-dev bsdtar clang-3.3 libclang1-3.3

3. Download zeal source code: 

        git clone https://github.com/jkozera/zeal.git

4. Run 

        /opt/Qt5.2.1/5.2.1/gcc_64/bin/qmake -spec linux-clang && make && sudo make install
