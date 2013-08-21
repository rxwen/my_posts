In China mainland, you never know for what reason a website gets blocked by the fucking [GFW](http://en.wikipedia.org/wiki/Golden_Shield_Project). Even if the site has nothing to do with politics.  [github](http://github.com) is a example, many developers in China are victims.  This post is about how to access github via a proxy, such as goagent.


The git pull/push command can be instructed to access remote server via proxy by setting https_proxy environment variable. So, we can run commands below use proxy.

    https_proxy=http://127.0.0.1:8087 git pull

or

    export https_proxy=http://127.0.0.1:8087
    git push


But we may get below error because the goagent ssl certificate can't be verified.

    error: SSL certificate problem: unable to get local issuer certificate while accessing https://github.com/xxxxxxxxxxx
    fatal: HTTP request failed


To resolve this problem, we can force git not to verify ssl ceritificate by setting GIT_SSL_NO_VERIFY environment variable.

    export GIT_SSL_NO_VERIFY=true
    git pull


To make these settings perminately for a git project or globally. We can write them to [git config](http://linux.die.net/man/1/git-config) file.

    git config http.proxy http://127.0.0.1:8087
    git config http.sslVerify false


The resulting .git/config file is like this:

    [core]
        repositoryformatversion = 0
        filemode = true
        bare = false
        logallrefupdates = true
        ignorecase = true
    [remote "origin"]
        url = https://github.com/rxwen/my_posts.git
        fetch = +refs/heads/*:refs/remotes/origin/*
    [branch "master"]
        remote = origin
        merge = refs/heads/master
    [http]
        proxy = http://127.0.0.1:8087
        sslVerify = false


BTW, there is a rumour that [Fang BingXing](http://en.wikipedia.org/wiki/Fang_Binxing) gets sill badly recently. Wish Death can conquer him as soon as possible, amen.
