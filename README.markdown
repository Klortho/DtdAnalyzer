<h1>Context Model</h1>

<h2>Development environment</h2>

The development environment for this project is very rudimentary at present,
and uses make.  Here are the contents:

  - Makefile - targets are:
        all - default target, everything below.
        clean - deletes intermediat files
        build - compiles all .java → .class; results go into 'class' directory
        doc - builds javadocs; puts results into 'doc'
        t - runs the script over the test file in the 'test' directory
  - setenv.sh - sets up PATH and CLASSPATH to point to the (hard-coded) development
    directories
  - bin - directory containing the script contextmodel.sh
  - src/pmctools/*.java - the Java source files
  - test/*.xml - a few samples files

