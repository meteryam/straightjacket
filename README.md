# straightjacket
git repo for the straightjacket compiler

This is the 2020 rewrite of the straightjacket compiler.  I'm writing it in Python, and it will output c code rather than creating executables.  The plan is to implement these features last:

- lists
- pattern matching for lists within conditionals
- floating point numbers
- literate programming
- small standard library (strings, i/o, etc)
- extended standard library

Thus far, only tokenization and single-line comments work.
