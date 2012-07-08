[clang-complete](https://github.com/Rip-Rip/clang_complete) is a powerful vim autocomplete plugin for c/c++ developers. Unlike the famous [OmniCppComplete](http://www.vim.org/scripts/script.php?script_id=1520) plugin, which makes use of ctag database to implement completion, the clang-complete plugin take advantage of the [clang](http://clang.llvm.org/) compiler. With the help of compiler, far more knowledge can be gained than the tag matching method. So the plugin can achieve a very precise completion, just like how visual studio does.

# clang-complete mode

## 1. executable mode
In this mode, each time we trigger a completion ([Ctrl_X Ctrl_U](http://vimdoc.sourceforge.net/htmldoc/insert.html#i_CTRL-X_CTRL-U)) in vim, the plugin will invoke the clang executable on the specified position in source code, then read and parse the executable's output to use as the candidates list.

## 2. library mode
In this mode, the plugin will run a python script to invoke the libclang library to get the candidates list. As [the author indicates](https://github.com/Rip-Rip/clang_complete/wiki), the libclang library employs cache mechanism and runs much faster than the executable mode. So, it's the recommended way to use.

# how to use it

## Ubuntu
By following instructions in this [wiki page](https://github.com/Rip-Rip/clang_complete/wiki), the plugin works very well on ubuntu. The only thing wasn't mentioned in the documenataion is that in order to use library mode, we must install the libclang-dev package.

## Windows
The experience of using the plugin of windows is much more difficult. 

### 1. Get a windows version clang
Since new version (v3.1) of clang can be compiled with visual studio, it's not difficult to compile the clang.exe and libclang.dll myself. Just note that though the clang can run on windows and can compile our c++ code, it can't performing linking. That's fair enough to simply use clang for our purpose. 

And you can get the binaries I compiled [here](https://code.google.com/p/rxwen-blog-stuff/downloads/list), for free :).
### 2. Get right output in executable mode
The clang.exe on windows outputs a lot of message to stderr, which are not interested by the plugin at all. Because the plugin uses [system()](http://vimdoc.sourceforge.net/htmldoc/eval.html#system\(\)) function to invoke clang.exe, and the function will automatically redirect stderr to stdout by default.
The author of the plugin suggests we can use let g:clang_user_options = '2> NUL || exit 0"' to get rid of stderr output. But it doesn't work for me. And I finally come up with this patch to fix the problem.

    diff --git a/plugin/clang_complete.vim b/plugin/clang_complete.vim
    old mode 100644
    new mode 100755
    index 7cb0fe0..6db164d
    --- a/plugin/clang_complete.vim
    +++ b/plugin/clang_complete.vim
    @@ -421,6 +421,8 @@ function! s:ClangCompleteBinary(base)
         return {}
       endtry
       let l:escaped_tempfile = shellescape(l:tempfile)
    +  let l:shellredir_orig = &shellredir
    +  let &shellredir ='>%s 2>NUL'
    
       let l:command = g:clang_exec . ' -cc1 -fsyntax-only'
             \ . ' -fno-caret-diagnostics -fdiagnostics-print-source-range-info'
    @@ -429,6 +431,8 @@ function! s:ClangCompleteBinary(base)
             \ . ' ' . b:clang_parameters . ' ' . b:clang_user_options . ' ' . g:clang_user_options
       let l:clang_output = split(system(l:command), "\n")
       call delete(l:tempfile)
    +  " restore original shellredir
    +  let &shellredir = l:shellredir_orig
    
       call s:ClangQuickFix(l:clang_output, l:tempfile)
       if v:shell_error

### 3. Make python ctypes module to work in library mode
The plugin uses ctypes module to invoke the libclang.dll. Due to a mysterious reason, the ctypes module can't be loaded successfully when run from embedded python in vim. I got the the "ImportError: No module named _ctypes" error and the plugin failed to work. But when I tested from a standalone python instance, the ctypes module worked well. After some debugging, it seems the embedded python doesn't search {python_root}/dlls directory to load _ctypes.pyd file, but the standalone python does. 
So I take a nasty method to solve the problem by copying the _ctypes.pyd to the clang_complete's plugin directory, right besides libclang.py file.
