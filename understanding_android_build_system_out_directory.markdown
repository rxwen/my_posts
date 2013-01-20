The android build system keeps a clean seperation of source and output. All intermediates and final output are placed in the directory named out. So, the simple way to fully clean a build is deleting the out directory.

The hierarchy of the out directory is shown below:

    out/
    |-- host/                           # the directory containing all tools and libraries of build system
     -- target/product/generic/         # the root of this product's out directory
        |-- data                        # the directory for creating data file system image
        |-- obj                         # the root directory of build process
        |   |-- APPS                    # android application 
        |   |-- ETC
        |   |-- EXECUTABLES             # the root directory containing all native executable build output
        |   |-- include
        |   |-- JAVA_LIBRARIES
        |   |-- lib                     # the directory containing copies of stripped shared libraries,
        |   |                           # other modules will search this directory for libraries to resolve linkage
        |   |-- PACKAGING
        |   |-- SHARED_LIBRARIES        # the root directory containing all native shared library build output
        |   |   |-- {LOCAL_MODULE_NAME}_intermediates    # the direcotry containing all build output for {LOCAL_MODULE_NAME} module
        |   |       |                                    # this naming convention is followed by all subdirectories of module
        |   |        -- LINKED          # the directory containing the linked binary file, e.g, .so file
        |    -- STATIC_LIBRARIES        # the root directory containing all native static library build output
        |-- root                        # the directory for creating root file system, ramdisk image
        |   |-- data
        |   |-- dev
        |   |-- proc
        |   |-- sbin
        |   |-- sys
        |    -- system
        |-- symbols                     # the directory contains all binary images that has debugging symbols
        |   |-- data
        |   |-- sbin
        |    -- system
         -- system                      # the directory for creating system.img, where most of appications and libraries reside
            |-- app
            |-- bin
            |-- etc
            |-- fonts
            |-- framework
            |-- lib
            |-- media
            |-- tts
            |-- usr
             -- xbin

Under the out/target/product/generic/obj directory, there are several subdirectories, APPS, EXECUTABLES, SHARED_LIBRARIES, STATIC_LIBRARIES. They contain build output for modules of different type, java application, native executable, shared libraries and static libraries, respectively. Under the module type's directory, there is a directory for each module of corresponding type, named with the module's name catenating _intermediates. So, when we need to clean a specific module, we can simply delete the intermediate directory for the module.

For example, in the Android.mk for stlport, there is a LOCAL_MODULE defined as libstlport, which is a shared library (by including $(BUILD_SHARED_LIBRARY)). The output of this module will be placed in SHARED_LIBRARIES/libstlport_intermediates directory. The linker will generate the final shared library in the SHARED_LIBRARIES/libstlport_intermediates/LINKED directory.

After a module has been compiled the linked, it's to be stripped and copied to directory for creating file system image. The build system doesn't perform stripping in place. Instead, it will first copy the file with debugging symbol information (the file under LINKED directory) to correct place in symbols directory. Then strip the file and save in intermediate directory (for executable) or obj/lib directory (for shared library), meanwhile, the file without symbol and the file with symbol are associated with '[objcopy --add-gnu-debuglink](http://sourceware.org/gdb/onlinedocs/gdb/Separate-Debug-Files.html)' command. Finally, the stripped file will be copied to system directory.

Once all modules are built, the system directory should have been populated with necessary files. The build system will create three file system images, ramdisk.img, userdata.img, and system.img with system, root and data as source directories respectively. The default choice of file system is [yaffs2](http://en.wikipedia.org/wiki/YAFFS).
