# PAR2

PAR2 is a monitoring library to be used with a par2cmdline executable.

## Dependencies
* [par2cmdline](http://sourceforge.net/projects/parchive/files/par2cmdline/0.4/)
  
  The source code as well as a patch for gcc4 compatibility is included in the 
  _par2cmdline_ subdirectory. This can be built using the `make par2` command.
  
  See _par2cmdline/COPYING_ for copyright/license details.

## Status
Work in progress...

## FAQ
* _Why is **par2cmdline** used instead of **libpar2**?_
  
  Using **libpar2** would have required that this library also be licensed as 
  GPLv2. By compiling the binary from **par2cmdline** sources and 
  communicating with the binary via input/output streams, this library can be 
  released under a different license (in this case, the MIT license).

## Copyright

Copyright (c) 2011 Andy Kant. See LICENSE for details.


