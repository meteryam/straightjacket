# Straightjacket

## Summary

This is the 2020 rewrite of the straightjacket compiler.  I'm writing it in Python, and it will output c code rather than creating executables.  The plan is to implement these features last:

- lists
- pattern matching within conditionals
- floating point numbers
- literate programming
- foreign function interface
- small standard library (strings, i/o, etc)
- extended standard library

These features have been implemented so far:

- modules


## Design Notes

This program implements the reference version of the Straightjacket compiler.  I designed Straightjacket to fit my own programming needs in ways that existing languages can't.  Fair warning; I am not a programmer by trade, and it probably shows (in a bad way).  Nevertheless, I intend to press on, partly for the fun of it and partly for its expected personal utility.

Straightjacket is a minimalist, modular, procedural compiled language with primitive lists, conditional pattern matching and generics.  Its syntax was inspired by multiple languages, and that eclecticism of inspiration shows (perhaps painfully).  My design philosophy hinges on two ideas:

1.  simplicity is better than complexity
2.  clarity is better than consistency

The first principle is exemplified by the work of such luminaries as C. A. R. Hoare, Edsgar Djikstra, Niklaus Wirth and others.  If you haven't read Hoare's quotes, Djikstra's EWD manuscripts or Wirth's documentation for Oberon, then you're missing out on several gold mines of wisdom.

The second principle appears everywhere, but is best illustrated with fonts.  Let us say that, for some reason, you are compelled to name your variable "ill".  Let us also say that your organization's coding standard specifies that variable names should use upper camel case (i.e. a capital first letter, followed by lowercase letters).  That gives us "Ill".  That can be easy to misread under the best of circumstances, and with the wrong choice of fonts all three of those characters will look identical.  I have seen technical support calls escalated to paid vendors that involved this issue.  Yet, most IT people I've met would insist that this source of problems is preferrable to inconsistent style.

Suppose instead that you choose to capitalise your variable as "iLL".  This is much easier to read, despite being as inconsistent with the standard as it is possible to be.  I believe that consistency is useful whenever one can make things consistently better, but harmful when it causes harm.  Therefore, I choose (what I consider to be) clarity rather than consistency whenever those two ideals are at odds.  As I said, this principle appears everywhere, so you will find multiple features of this language that come from different language families.  If this displeases you, you are free to use other languages.

The name "Straightjacket" is a (hopefully humorous) reference to the foldoc article "bondage-and-discipline language", which is perjoratively describes programming languages that many programmers consider to be too safe for personal comfort (including Ada and Pascal, both of which were Straightjacket inspirations).  Straightjacket uses strong, static type checking with type extension, but no escapes.  Various kinds of bounds checks are automatically inserted by the compiler.   There is no explicit reference type or programmatic manipulation of references.  Memory is automatically managed in a primitive way, but automatically freeing heap variables as they pass out of scope.  Nullable types (i.e. list nodes) must be checked for null explicitly.

## Detailed Description

Each Straightjacket program is composed of one or more modules, the first of which must be named "main".  The main module has this structure (where optional items are enclosed in square brackets):

[import statements]
module main
	[declarations]
begin
	[control flow statements, expressions, procedure calls]
definitions begin
	[function definitions, procedure definitions, exception catches, type definitions]
end module main

Other modules have a simpler structure:

[import statements]
module modulename definitions begin
	[function definitions, procedure definitions, exceptions, type definitions]
end module main

The reason modules other than the main module have a simpler structure is that they exist simply to provide access to new subroutines, variables and types.  To include a body section would mean compiling code that would never be called.

Import statements tell the compiler to include additional modules.  They look like this:

	import `filename` as aliasname
	limport `filename` as aliasname
	cimport `filename` as aliasname
	
The keyword "import" indicates that the module can be treated as simple Straightjacket code.  The keyword "limport" indicates that the module was written in a literate programming style, and that the Straightjacket code must be extracted from it before being processed.  The keyword "cimport" indicates that the module was written in c, and that its contents should be imported without being processed by the compiler.

### Literate Programming

Straightjacket natively supports a primitive form of literate programming.  If the main file is a literate file, then the compiler needs to process it accordingly.  The compiler first looks for a list of tags (without brackets) surrounded by `<<def>>` and `<</def>>` tags.  The final output will contain text from each declared tag, in the order given by the tag list within the `<<def>>` section.  Then the compiler looks for text located between tags formatted like this:  `<<tagName>>`

The final output will contain text from each declared tag, in the order given by the tag list within the <<def>> section.  The compiler will print an error and abort if a tag is not used, if an undeclared tag is used, if a tag is misspelled or if a section of text begins with one tag but is ended by another tag.  Tags are case-insensitive, they may not contain spaces and they may not be indented by tabs.

### Declarations

(type system)

Straightjacket's built-in data types are arranged in a conceptual hierarchy:

- list
- struct
- array
- primitive
- number
- float
- int

Lists generalize structs, which generalize arrays, which generalize primitives, which generalize numbers, which generalize floats, which generalize ints.

"Primitive" is a property of custom types that tells the compiler that the usual arithmetic operators do not apply to those types.  The type "number" can only be used in functions, which allows them to handle different numeric types.  Floats and ints can be mixed to produce floats, but arithmetic between ints can only produce ints.

Lists are stored on the heap, and are automatically reclaimed when they go out of scope.  A function's local variables only go out of scope when it returns a value.  Structs always go onto the stack.  These choices ensure that all variables are eliminated when they go out of scope, thus preventing many types of memory leaks.

(declaring variables)

(declaring functions)

(declaring procedures)

Each module may contain zero or more functions (which must not have side effects) or procedures (which should have side effects).  Functions and procedures may be private (the default) or they may be exported for use by other modules.  Exported resources must be imported explicitly in order to be used by other modules, and they must always explicitly refer to the module from whence they came.

(declaring and defining subroutines...)

declare returnType function : [argType] [argType]
declare procedure : [argType] [argType]

foreign functions and procedures:

declare foreign returnType #function : [argType] [argType]

declare foreign returnType #procedure : [argType] [argType]

(generics...)

(type declarations)

declare type (export) structName as int [7] (= 5)

	declare type (export) struct structName
		operator + is myfunC(structName,structName)
		operator ++ is myfunD(structName)
		myfunA(structName -> structNameA)	# defines a type conversion function
		primitive	# prohibits the use of built-in arithmetic operators
	begin
		int = 0	# extends type "int"
		int [10] = 0		# 10-cell integer array
		myfloat :i = 1.2	# creates suffix "i"
		myint = 0 enum ( FALSE = 0, TRUE = 1 )	# enum section creates values
		int = 0 : [0..1] enum ( FALSE = 0, TRUE = 1 )	# range braces
		const int : a = 97, quoted_enum ( a = `a` )	# quoted enumerations must be included within backticks; can be multi-byte
		myfunCmyInt : myInt2 = myfunC(0)	# uses a user-defined range function
	end type

declare type (export) (const) list listName (= { [listName] })

	declare type (export) list structName
		operator + is myfunC(structName,structName)
		operator ++ is myfunD(structName)
		myfunA(structName -> structNameA)	# defines a type conversion function
		primitive	# prohibits the use of built-in arithmetic operators
	begin
		{ 1, 1.0, 42 }
	end type

### Body

(control flow statements)

Control flow structures include:

loop begin [blockname]
	...
	break
	...
end loop  [blockname]


loop each [range or list] begin [blockname]
	...
end loop [blockname]


if (condition) begin [blockname]
	...
else (condition)
	...
else
	...
[end if [blockname]] or [else abort [blockname]]

(logical operators, pattern-matching conditionals)

(optional block names...)

The "else abort" option more directly supports Dijkstra's structured programming paradigm.  The end if option is offered because that approach might not fit every problem.

(expressions)

- right-hand equations
- operators
- order of precedence

(procedure calls)

(raise)

(abort)

### Definitions

(function definitions)

(procedure definitions)

(exceptions)

The main module can also catch exceptions that aren't caught by the subroutines from which they've arisen.  Subroutines defined within the main module and called from it must use forward declarations.




### Other Details

- Most tokens share the same namespace.  Modules, subroutines, operators, variables, constants, block labels, type names.  Struct fields can use types from this shared namespace, but they don't have to.
- Most tokens have a rather liberal format:  `[$|@|#]` + `[_|-|:alpha:|:num:]` + `[_|:alpha:|:num:]`
- Tokens must be separated from everything else by whitespace.
- The equal sign must appear on the right-hand side of expressions.
- The equal sign is used for both equality and assignment.  This eliminates a common source of errors when programmers accidentally use the assignment operator in a comparison context.
- Straightjacket is case-insensitive.  These strings represent the same tokens:  hello HeLlo hELLo
- The logical operators are:  AND, OR, XOR, NOT
- To facilitate pattern matching, list literals in if conditions may include logical operators, with the exception of the AND operator.
- The custom data type syntax is extremely flexible.  This is intended to facilitate (among other things) easier construction of strings, complex numbers, booleans and matrices.
- References to specific list positions (except for constant lists) must be wrapped in explicit null checks.
- The compiler inserts automatic checks for range overflows, zero division of integers, infinities, NaNs, list ranges, etc.  These may be caught either by the subroutine within which they arise, or by the main module.
- Functions are pure (i.e. they cannot have side effects).  However, procedures can have side effects.  This makes both correct coding and troubleshooting easier.
- Software transactional memory must be used to update lists when subroutines are marked "atomic".  This can be done at either definition time or at call time.  This facilitates multi-threaded programming without unduly burdening single-threaded programs.
- Type checking is both strict and static.  Two structs have the same type if their fields have the same names, same underlying types and are in the same order.


