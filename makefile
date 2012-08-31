all:
	markdown_py -f out.html < debug_linux_kernel_with_kgdb.markdown
	firefox out.html
