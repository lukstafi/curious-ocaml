<TeXmacs|1.0.7.16>

<style|<tuple|beamer|highlight|beamer-metal-lighter|smileys>>

<\body>
  <doc-data|<doc-title|Functional Programming>|<\doc-author-data|<author-name|Šukasz
  Stafiniak>>
    \;
  </doc-author-data|<author-email|lukstafi@gmail.com,
  lukstafi@ii.uni.wroc.pl>|<\author-homepage>
    www.ii.uni.wroc.pl/~lukstafi
  </author-homepage>>>

  <doc-data|<doc-title|Lecture 9: Compiler>|<\doc-subtitle>
    Compilation. Runtime. Optimization. Parsing.

    <\small>
      Andrew W. Appel <em|``Modern Compiler Implementation in
      ML''><next-line>E. Chailloux, P. Manoury, B. Pagano <em|``Developing
      Applications with OCaml''><next-line>Jon D. Harrop <em|``OCaml for
      Scientists''><next-line>Francois Pottier, Yann Regis-Gianas
      ``<em|Menhir Reference Manual>''
    </small>
  </doc-subtitle>|>

  <center|If you see any error on the slides, let me know!>

  <section|<new-page*>OCaml Compilers>

  <\itemize>
    <item>OCaml has two <very-small|primary> compilers: the bytecode compiler
    <verbatim|ocamlc> and the native code compiler <verbatim|ocamlopt>.

    <\itemize>
      <item>Natively compiled code runs about 10 times faster than bytecode
      -- depending on program.
    </itemize>

    <item>OCaml has an interactive shell called <em|toplevel> (in other
    languages, <em|repl>): <verbatim|ocaml> which is based on the bytecode
    compiler.

    <\itemize>
      <item>There is a toplevel <verbatim|ocamlnat> based on the native code
      compiler but currently not part of the binary distribution.
    </itemize>

    <item>There are ``third-party'' compilers, most notably
    <verbatim|js_of_ocaml> which translates OCaml bytecode into JavaScript
    source.

    <\itemize>
      <item>On modern JS virtual machines like V8 the result can be 2-3x
      faster than on OCaml virtual machine (but can also be slower).
    </itemize>

    <new-page*><item>Stages of compilation:

    <tabular|<tformat|<table|<row|<cell|<block|<tformat|<table|<row|<cell|preprocessing>>|<row|<cell|compiling>>|<row|<cell|assembling>>|<row|<cell|linking>>>>>>|<cell|<block|<tformat|<table|<row|<cell|Source
    program>>|<row|<cell|Source or abstract syntax tree
    program>>|<row|<cell|Assembly program>>|<row|<cell|Machine
    instrucitons>>|<row|<cell|Executable code>>>>>>>>>>

    <item>Programs:

    <block|<tformat|<table|<row|<cell|<verbatim|ocaml>>|<cell|toplevel
    loop>>|<row|<cell|<verbatim|ocamlrun>>|<cell|bytecode interpreter
    (VM)>>|<row|<cell|<verbatim|camlp4>>|<cell|preprocessor (syntax
    extensions)>>|<row|<cell|<verbatim|ocamlc>>|<cell|bytecode
    compiler>>|<row|<cell|<verbatim|ocamlopt>>|<cell|native code
    compiler>>|<row|<cell|<verbatim|ocamlmktop>>|<cell|new toplevel
    constructor>>|<row|<cell|<verbatim|ocamldep>>|<cell|dependencies between
    modules>>|<row|<cell|<verbatim|ocamlbuild>>|<cell|building projects
    tool>>|<row|<cell|<verbatim|ocamlbrowser>>|<cell|graphical browsing of
    sources>>>>>

    <new-page*><item>File extensions:

    <block|<tformat|<table|<row|<cell|<verbatim|.ml>>|<cell|OCaml source
    file>>|<row|<cell|<verbatim|.mli>>|<cell|OCaml interface source
    file>>|<row|<cell|<verbatim|.cmi>>|<cell|compiled
    interface>>|<row|<cell|<verbatim|.cmo>>|<cell|bytecode-compiled
    file>>|<row|<cell|<verbatim|.cmx>>|<cell|native-code-compiled
    file>>|<row|<cell|<verbatim|.cma>>|<cell|bytecode-compiled library
    (several source files)>>|<row|<cell|<verbatim|.cmxa>>|<cell|native-code-compiled
    library>>|<row|<cell|<verbatim|.cmt>/<verbatim|.cmti>/<verbatim|.annot>>|<cell|type
    information for editors>>|<row|<cell|<verbatim|.c>>|<cell|C source
    file>>|<row|<cell|<verbatim|.o>>|<cell|C native-code-compiled
    file>>|<row|<cell|<verbatim|.a>>|<cell|C native-code-compiled
    library>>>>>

    <new-page*><item>Both compilers commands:

    <block|<tformat|<table|<row|<cell|<verbatim|-a>>|<cell|construct a
    runtime library >>|<row|<cell|<verbatim|-c>>|<cell|compile without
    linking >>|<row|<cell|<verbatim|-o>>|<cell|name_of_executable specify the
    name of the executable >>|<row|<cell|<verbatim|-linkall>>|<cell|link with
    all libraries used >>|<row|<cell|<verbatim|-i>>|<cell|display all
    compiled global declarations >>|<row|<cell|<verbatim|-pp>>|<cell|command
    uses command as preprocessor >>|<row|<cell|<verbatim|-unsafe>>|<cell|turn
    off index checking for arrays>>|<row|<cell|<verbatim|-v>>|<cell|display
    the version of the compiler >>|<row|<cell|<verbatim|-w>
    list>|<cell|choose among the list the level of warning message
    >>|<row|<cell|<verbatim|-impl> file>|<cell|indicate that file is a Caml
    source (.ml) >>|<row|<cell|<verbatim|-intf> file>|<cell|indicate that
    file is a Caml interface (.mli) >>|<row|<cell|<verbatim|-I>
    directory>|<cell|add directory in the list of directories; prefix
    <verbatim|+> for relative>>|<row|<cell|<verbatim|-g>>|<cell|generate
    debugging information>>>>>

    <new-page*><item>Warning levels:

    <block|<tformat|<cwith|6|6|2|2|cell-halign|l>|<table|<row|<cell|<verbatim|A>/<verbatim|a>>|<cell|enable/disable
    all messages>>|<row|<cell|<verbatim|F>/<verbatim|f>>|<cell|partial
    application in a sequence >>|<row|<cell|<verbatim|P>/<verbatim|p>>|<cell|for
    incomplete pattern matching>>|<row|<cell|<verbatim|U>/<verbatim|u>>|<cell|for
    missing cases in pattern matching>>|<row|<cell|<verbatim|X>/<verbatim|x>>|<cell|enable/disable
    all other messages for hidden object>>|<row|<cell|<verbatim|M>/<verbatim|m>,
    <verbatim|V>/<verbatim|v>>|<cell|object-oriented related warnings>>>>>

    <item>Native compiler commands:

    <block|<tformat|<table|<row|<cell|<verbatim|-compact>>|<cell|optimize the
    produced code for space>>|<row|<cell|<verbatim|-S>>|<cell|keeps the
    assembly code in a file>>|<row|<cell|<verbatim|-inline>>|<cell|level set
    the aggressiveness of inlining>>>>>

    <new-page*><item>Environment variable <verbatim|OCAMLRUNPARAM>:

    <block|<tformat|<table|<row|<cell|<verbatim|b>>|<cell|print detailed
    stack backtrace of runtime exceptions>>|<row|<cell|<verbatim|s>/<verbatim|h>/<verbatim|i>>|<cell|size
    of the minor heap/major heap/size increment>>|<row|<cell|<verbatim|o>/<verbatim|O>>|<cell|major
    GC speed setting / heap compaction trigger setting>>>>>

    Typical use, running <verbatim|prog>: <verbatim|export OCAMLRUNPARAM='b';
    ./prog>

    To have stack backtraces, compile with option <verbatim|-g>.

    <item>Toplevel loop directives:

    <block|<tformat|<cwith|1|1|1|1|cell-halign|l>|<table|<row|<cell|<verbatim|#quit;;>>|<cell|exit>>|<row|<cell|<verbatim|#directory
    "dir";;>>|<cell|add <verbatim|dir> to the ``search path''; <verbatim|+>
    for rel.>>|<row|<cell|<verbatim|#cd "dir-name";;>>|<cell|change
    directory>>|<row|<cell|<verbatim|#load "file-name";;>>|<cell|load a
    bytecode <verbatim|.cmo>/<verbatim|.cma>
    file>>|<row|<cell|<verbatim|#load_rec "file-name";;>>|<cell|load the
    files <verbatim|file-name> depends on too>>|<row|<cell|<verbatim|#use
    "file-name";;>>|<cell|read, compile and execute source
    phrases>>|<row|<cell|<verbatim|#instal_printer pr_nm;;>>|<cell|register
    <verbatim|pr_nm> to print values of a
    type>>|<row|<cell|<verbatim|#print_depth num;;>>|<cell|how many nestings
    to print>>|<row|<cell|<verbatim|#print_length num;;>>|<cell|how many
    nodes to print -- the rest <verbatim|...>>>|<row|<cell|<verbatim|#trace
    func;;>/<verbatim|#untrace>>|<cell|trace calls to <verbatim|func>/stop
    tracing>>>>>
  </itemize>

  <subsection|<new-page*>Compiling multiple-file projects>

  <\itemize>
    <item>Traditionally the file containing a module would have a lowercase
    name, although the module name is always uppercase.

    <\itemize>
      <item>Some people think it is more elegant to use uppercase for file
      names, to reflect module names, i.e. for <hlkwc|MyModule>, use
      <verbatim|MyModule.ml> rather than <verbatim|myModule.ml>.
    </itemize>

    <item>We have a project with main module <verbatim|main.ml> and helper
    modules <verbatim|sub1.ml> and <verbatim|sub2.ml> with corresponding
    interfaces.

    <new-page*><item>Native compilation by hand:

    <verbatim|...:.../Lec9$ ocamlopt sub1.mli<next-line>...:.../Lec9$
    ocamlopt sub2.mli<next-line>...:.../Lec9$ ocamlopt -c
    sub1.ml<next-line>...:.../Lec9$ ocamlopt -c
    sub2.ml<next-line>...:.../Lec9$ ocamlopt -c
    main.ml<next-line>...:.../Lec9$ ocamlopt unix.cmxa sub1.cmx sub2.cmx
    main.cmx -o prog<next-line>...:.../Lec9$ ./prog<next-line>>

    <new-page*><item>Native compilation using <verbatim|make>:

    <\code>
      PROG := prog

      LIBS := unix

      SOURCES := sub1.ml sub2.ml main.ml

      INTERFACES := $(wildcard *.mli)

      OBJS := $(patsubst %.ml,%.cmx,$(SOURCES))

      LIBS := $(patsubst %,%.cmxa,$(LIBS))

      $(PROG): $(OBJS)

      <tabulator>ocamlopt -o $@ $(LIBS) $(OBJS)

      clean: rm -rf $(PROG) *.o *.cmx *.cmi *~

      %.cmx: %.ml

      <tabulator>ocamlopt -c $*.ml

      %.cmi: %.mli

      <tabulator>ocamlopt -c $*.mli

      depend: $(SOURCES) $(INTERFACES)

      <tabulator>ocamldep -native $(SOURCES) $(INTERFACES)
    </code>

    <\itemize>
      <item>First use command: <verbatim|touch .depend; make depend; make>

      <item>Later just <verbatim|make>, after creating new source files
      <verbatim|make depend>
    </itemize>

    <item>Using <verbatim|ocamlbuild>

    <\itemize>
      <item>files with compiled code are created in <verbatim|_build>
      directory

      <item>Command: <verbatim|ocamlbuild -libs unix main.native>

      <item>Resulting program is called <verbatim|main.native> (in directory
      <verbatim|_build>, but with a link in the project directory)

      <item>More arguments passed after comma, e.g.

      <verbatim|ocamlbuild -libs nums,unix,graphics main.native>

      <item>Passing parameters to the compiler with <verbatim|-cflags>, e.g.:

      <verbatim|ocamlbuild -cflags -I,+lablgtk,-rectypes hello.native>

      <item>Adding a <verbatim|--> at the end (followed with command-line
      arguments for the program) will compile and run the program:

      <verbatim|ocamlbuild -libs unix main.native -->
    </itemize>
  </itemize>

  <subsection|<new-page*>Editors>

  <\itemize>
    <item>Emacs

    <\itemize>
      <item><verbatim|ocaml-mode> from the standard distribution

      <item><small|alternative> <verbatim|tuareg-mode>
      <hlink|https://forge.ocamlcore.org/projects/tuareg/|https://forge.ocamlcore.org/projects/tuareg/>

      <\itemize>
        <item>cheat-sheet: <hlink|http://www.ocamlpro.com/files/tuareg-mode.pdf|http://www.ocamlpro.com/files/tuareg-mode.pdf>
      </itemize>

      <item><verbatim|camldebug> intergration with debugger

      <item>type feedback with <verbatim|C-c C-t> key shortcut, needs
      <verbatim|.annot> files
    </itemize>

    <item>Vim

    <\itemize>
      <item>OMLet plugin <next-line><hlink|http://www.lix.polytechnique.fr/~dbaelde/productions/omlet.html|http://www.lix.polytechnique.fr/~dbaelde/productions/omlet.html>

      <item>For type lookup: either <hlink|https://github.com/avsm/ocaml-annot|https://github.com/avsm/ocaml-annot>

      <\itemize>
        <item>or <hlink|http://www.vim.org/scripts/script.php?script_id=2025|http://www.vim.org/scripts/script.php?script_id=2025>

        <item>also? <hlink|http://www.vim.org/scripts/script.php?script_id=1197|http://www.vim.org/scripts/script.php?script_id=1197>
      </itemize>
    </itemize>

    <item>Eclipse

    <\itemize>
      <item><em|OCaml Development Tools> <hlink|http://ocamldt.free.fr/|http://ocamldt.free.fr/>

      <item>an old plugin OcaIDE <hlink|http://www.algo-prog.info/ocaide/|http://www.algo-prog.info/ocaide/>
    </itemize>

    <item>TypeRex <hlink|http://www.typerex.org/|http://www.typerex.org/>

    <\itemize>
      <item>currently mostly as <verbatim|typerex-mode> for Emacs but
      integration with other editors will become better

      <item>Auto-completion of identifiers (experimental)

      <item>Browsing of identifiers: show type and comment, go to definition

      <item>local and whole-program refactoring: renaming identifiers and
      compilation units, <hlkwa|open> elimination
    </itemize>

    <item>Indentation tool <verbatim|ocp-ident>
    <hlink|https://github.com/OCamlPro/ocp-indent|https://github.com/OCamlPro/ocp-indent>

    <\itemize>
      <item>Installation instructions for Emacs and Vim

      <item>Can be used with other editors.
    </itemize>

    <new-page*><item>Some dedicated editors

    <\itemize>
      <item>OCamlEditor <hlink|http://ocamleditor.forge.ocamlcore.org/|http://ocamleditor.forge.ocamlcore.org/>

      <item><verbatim|ocamlbrowser> inspects libraries and programs

      <\itemize>
        <item>browsing contents of modules

        <item>search by name and by type

        <item>basic editing, with syntax highlighting
      </itemize>

      <item>Cameleon <hlink|http://home.gna.org/cameleon/|http://home.gna.org/cameleon/>
      (older)

      <item>Camelia <hlink|http://camelia.sourceforge.net/|http://camelia.sourceforge.net/>
      (even older)
    </itemize>
  </itemize>

  <section|<new-page*>Imperative features in OCaml>

  OCaml is <strong|not> a <em|purely functional> language, it has built-in:

  <\itemize>
    <item>Mutable arrays.

    <hlkwa|let ><hlstd|a ><hlopt|= ><hlkwc|Array><hlopt|.><hlstd|make
    ><hlnum|5 0 ><hlkwa|in><hlendline|><next-line><hlstd|a><hlopt|.(><hlnum|3><hlopt|)
    \<less\>- ><hlnum|7><hlopt|; ><hlstd|a><hlopt|.(><hlnum|2><hlopt|),
    ><hlstd|a><hlopt|.(><hlnum|3><hlopt|)><hlendline|>

    <\itemize>
      <item>Hashtables in the standard distribution (based on arrays).

      <hlkwa|let ><hlstd|h ><hlopt|= ><hlkwc|Hashtbl><hlopt|.><hlstd|create
      ><hlnum|11 ><hlkwa|in><hlendline|Takes initial size of the
      array.><next-line><hlkwc|Hashtbl><hlopt|.><hlstd|add h
      ><hlstr|"Alpha"><hlstd| ><hlnum|5><hlopt|;
      ><hlkwc|Hashtbl><hlopt|.><hlstd|find h ><hlstr|"Alpha"><hlendline|>
    </itemize>

    <item>Mutable strings. (Historical reasons...)

    <hlkwa|let ><hlstd|a ><hlopt|= ><hlkwc|String><hlopt|.><hlstd|make
    ><hlnum|4 ><hlstd|'a' ><hlkwa|in><hlendline|><next-line><hlstd|a><hlopt|.[><hlnum|2><hlopt|]
    \<less\>- ><hlstd|'b'><hlopt|; ><hlstd|a><hlopt|.[><hlnum|2><hlopt|],
    ><hlstd|a><hlopt|.[><hlnum|3><hlopt|]><hlendline|>

    <\itemize>
      <item>Extensible mutable strings <hlkwc|Buffer><hlopt|.><hlstd|t> in
      standard distribution.
    </itemize>

    <item>Loops:

    <\itemize>
      <item><hlkwa|for> i <hlopt|=> a <hlkwa|to>/<hlkwa|downto> b <hlkwa|do>
      body <hlkwa|done>

      <item><hlkwa|while> condition <hlkwa|do> body <hlkwa|done>
    </itemize>

    <new-page*><item>Mutable record fields, for example:

    <hlkwa|type ><hlstd|'a ><hlkwb|ref ><hlopt|= { ><hlkwa|mutable
    ><hlstd|contents ><hlopt|: ><hlstd|'a ><hlopt|}><hlendline|Single,
    mutable field.>

    A record can have both mutable and immutable fields.

    <\itemize>
      <item>Modifying the field: <hlstd|record><hlopt|.><hlstd|field
      ><hlopt|\<less\>- ><hlstd|new_value>

      <item>The <hlkwb|ref >type has operations:

      <hlkwa|let ><hlopt|(:=) ><hlstd|r v ><hlopt|=
      ><hlstd|r><hlopt|.><hlstd|contents ><hlopt|\<less\>-
      ><hlstd|v><hlendline|><next-line><hlkwa|let ><hlopt|(!) ><hlstd|r
      ><hlopt|= ><hlstd|r><hlopt|.><hlstd|contents><hlendline|>
    </itemize>

    <item>Exceptions, defined by <hlkwa|exception>, raised by <hlkwa|raise>
    and caught by <hlkwa|try>-<hlkwa|with> clauses.

    <\itemize>
      <item>An exception is a variant of type <hlkwa|exception>, which is the
      only open algebraic datatype -- new variants can be added to it.
    </itemize>

    <item>Input-output functions have no ``type safeguards'' (no <em|IO
    monad>).
  </itemize>

  Using <strong|global> state e.g. reference cells makes code <em|non
  re-entrant>: finish one task before starting another -- any form of
  concurrency is excluded.

  <subsection|<new-page*>Parsing command-line arguments>

  To go beyond <hlkwc|Sys><hlopt|.><hlstd|argv> array, see <hlkwc|Arg>
  module:<next-line><hlink|http://caml.inria.fr/pub/docs/manual-ocaml/libref/Arg.html|http://caml.inria.fr/pub/docs/manual-ocaml/libref/Arg.html>

  <hlkwa|type ><hlstd|config ><hlopt|= { ><hlendline|Example: configuring a
  <em|Mine Sweeper> game.><next-line><hlstd| \ \ nbcols \ ><hlopt|:
  ><hlkwb|int ><hlopt|; ><hlstd|nbrows ><hlopt|: ><hlkwb|int ><hlopt|;
  ><hlstd|nbmines ><hlopt|: ><hlkwb|int ><hlopt|}><hlendline|><next-line><hlkwa|let
  ><hlstd|default<textunderscore>config ><hlopt|= {
  ><hlstd|nbcols><hlopt|=><hlnum|10><hlopt|;
  ><hlstd|nbrows><hlopt|=><hlnum|10><hlopt|;
  ><hlstd|nbmines><hlopt|=><hlnum|15 ><hlopt|}><hlendline|><next-line><hlkwa|let
  ><hlstd|set<textunderscore>nbcols cf n ><hlopt|= ><hlstd|cf ><hlopt|:=
  {!><hlstd|cf ><hlkwa|with ><hlstd|nbcols ><hlopt|=
  ><hlstd|n><hlopt|}><hlendline|><next-line><hlkwa|let
  ><hlstd|set<textunderscore>nbrows cf n ><hlopt|= ><hlstd|cf ><hlopt|:=
  {!><hlstd|cf ><hlkwa|with ><hlstd|nbrows ><hlopt|=
  ><hlstd|n><hlopt|}><hlendline|><next-line><hlkwa|let
  ><hlstd|set<textunderscore>nbmines cf n ><hlopt|= ><hlstd|cf ><hlopt|:=
  {!><hlstd|cf ><hlkwa|with ><hlstd|nbmines ><hlopt|=
  ><hlstd|n><hlopt|}><hlendline|><next-line><hlkwa|let
  ><hlstd|read<textunderscore>args><hlopt|() =><hlendline|><next-line><hlstd|
  \ ><hlkwa|let ><hlstd|cf ><hlopt|= ><hlkwb|ref
  ><hlstd|default<textunderscore>config ><hlkwa|in><hlendline|State of
  configuration><next-line><hlstd| \ ><hlkwa|let ><hlstd|speclist ><hlopt|=
  ><hlendline|will be updated by given functions.><next-line><hlstd|
  \ \ ><hlopt|[(><hlstr|"-col"><hlopt|, ><hlkwc|Arg><hlopt|.><hlkwd|Int
  ><hlopt|(><hlstd|set<textunderscore>nbcols cf><hlopt|), ><hlstr|"number of
  columns"><hlopt|);><hlendline|><next-line><hlstd|
  \ \ \ ><hlopt|(><hlstr|"-lin"><hlopt|, ><hlkwc|Arg><hlopt|.><hlkwd|Int
  ><hlopt|(><hlstd|set<textunderscore>nbrows cf><hlopt|), ><hlstr|"number of
  lines"><hlopt|);><hlendline|><next-line><hlstd|
  \ \ \ ><hlopt|(><hlstr|"-min"><hlopt|, ><hlkwc|Arg><hlopt|.><hlkwd|Int
  ><hlopt|(><hlstd|set<textunderscore>nbmines cf><hlopt|), ><hlstr|"number of
  mines"><hlopt|)] ><hlkwa|in><hlstd|><next-line><hlstd| \ ><hlkwa|let
  ><hlstd|usage<textunderscore>msg ><hlopt|=><hlendline|><next-line><hlstd|
  \ \ \ ><hlstr|"usage : minesweep [-col n] [-lin n] [-min n]"><hlstd|
  ><hlkwa|in><hlendline|><next-line><hlstd|
  \ \ ><hlkwc|Arg><hlopt|.><hlstd|parse speclist ><hlopt|(><hlkwa|fun
  ><hlstd|s ><hlopt|-\<gtr\> ()) ><hlstd|usage<textunderscore>msg><hlopt|;
  !><hlstd|cf><hlendline|>

  <section|<new-page*>OCaml Garbage Collection>

  <subsection|Representation of values>

  <\itemize>
    <item>Pointers always end with <verbatim|00> in binary (addresses are in
    number of bytes).

    <item>Integers are represented by shifting them 1 bit, setting the last
    bit to <verbatim|1>.

    <item>Constant constructors (i.e. variants without parameters) like
    <verbatim|None>, <verbatim|[]> and <verbatim|()>, and other integer-like
    types (<verbatim|char>, <verbatim|bool>) are represented in the same way
    as integers.

    <item>Pointers are always to OCaml <em|blocks>. Variants with parameters,
    strings and OCaml arrays are stored as blocks.

    <item>A block starts with a header, followed by an array of values of
    size 1 word: either integer-like, or pointers.

    <item>The header stores the size of the block, the 2-bit color used for
    garbage collection, and 8-bit <em|tag> -- which variant it is.

    <\itemize>
      <item>Therefore there can be at most about 240 variants with parameters
      in a variant type (some tag numbers are reserved).

      <item><em|Polymorphic variants> are a different story.
    </itemize>
  </itemize>

  <subsection|<new-page*>Generational Garbage Collection>

  <\itemize>
    <item>OCaml has two heaps to store blocks: a small, continuous <em|minor
    heap> and a growing-as-necessary <em|major heap>.

    <item>Allocation simply moves the minor heap pointer (aka. the <em|young
    pointer>) and returns the pointed address.

    <\itemize>
      <item>Allocation of very large blocks uses the major heap instead.
    </itemize>

    <item>When the minor heap runs out of space, it triggers the <em|minor
    (garbage) collection>, which uses the <em|Stop & Copy> algorithm.

    <item>Together with the minor collection, a slice of <em|major (garbage)
    collection> is performed to cleanup the major heap a bit.

    <\itemize>
      <item>The major heap is not cleaned all at once because it might stop
      the main program (i.e. our application) for too long.

      <item>Major collection uses the <em|Mark & Sweep> algorithm.
    </itemize>

    <item>Great if most minor heap blocks are already not needed when
    collection starts -- garbage does <strong|not> slow down collection.
  </itemize>

  <subsection|<new-page*>Stop & Copy GC>

  <\itemize>
    <item>Minor collection starts from a set of <em|roots> -- young blocks
    that definitely are not garbage.

    <item>Besides the root set, OCaml also maintains the <em|remembered set>
    of minor heap blocks pointed at from the major heap.

    <\itemize>
      <item>Most mutations must check whether they assign a minor heap block
      to a major heap block field. This is called <em|write barrier>.

      <item>Immutable blocks cannot contain pointers from major to minor
      heap.

      <\itemize>
        <item>Unless they are <hlkwa|lazy> blocks.
      </itemize>
    </itemize>

    <item>Collection follows pointers in the root set and remembered set to
    find other used blocks.

    <item>Every found block is copied to the major heap.

    <item>At the end of collection, the young pointer is reset so that the
    minor heap is empty again.
  </itemize>

  <subsection|<new-page*>Mark & Sweep GC>

  <\itemize>
    <item>Major collection starts from a separate root set -- old blocks that
    definitely are not garbage.

    <item>Major garbage collection consists of a <em|mark> phase which colors
    blocks that are still in use and a <em|sweep> phase that searches for
    stretches of unused memory.

    <\itemize>
      <item>Slices of the mark phase are performed by-after each minor
      collection.

      <item>Unused memory is stored in a <em|free list>.
    </itemize>

    <item>The ``proper'' major collection is started when a minor collection
    consumes the remaining free list. The mark phase is finished and sweep
    phase performed.

    <item>Colors:

    <\itemize>
      <item><strong|gray>: marked cells whose descendents are not yet marked;

      <item><strong|black>: marked cells whose descendents are also marked;

      <item><strong|hatched>: free list element;

      <item><strong|white>: elements previously being in use.
    </itemize>

    <new-page*><item><verbatim|# let u = let l = ['c'; 'a'; 'm'] in List.tl l
    ;;<next-line>><verbatim|val u : char list = ['a';
    'm']><next-line><small|<verbatim|# let v = let r = ( ['z'] , u ) in match
    r with p -\<gtr\> (fst p) @ (snd p) ;;>><next-line><verbatim|val v : char
    list = ['z'; 'a'; 'm']>

    <item><image|book-ora034-GC_Marking_phase.gif|900.0px|250px||>

    <item><image|book-ora035-GC_Sweep_phase.gif|900px|300px||>
  </itemize>

  <section|<new-page*>Stack Frames and Closures>

  <\itemize>
    <item>The nesting of procedure calls is reflected in the <em|stack> of
    procedure data.

    <item>The stretch of stack dedicated to a single function is <em|stack
    frame> aka. <em|activation record>.

    <item><em|Stack pointer> is where we create new frames, stored in a
    special register.

    <item><em|Frame pointer> allows to refer to function data by offset --
    data known early in compilation is close to the frame pointer.

    <item>Local variables are stored in the stack frame or in registers --
    some regis<no-break>ters need to be saved prior to function call
    (<em|caller-save>) or at entry to a function (<em|callee-save>). OCaml
    avoids callee-save registers.

    <item>Up to 4-6 arguments can be passed in registers, remaining ones on
    stack.

    <\itemize>
      <item>Note that <em|x86> architecture has a small number of registers.
    </itemize>

    <item>Using registers, tail call optimization and function inlining can
    eliminate the use of stack entirely. OCaml compiler can also use stack
    more efficiently than by creating full stack frames as depicted below.

    <new-page*><item><small|<tabular|<tformat|<table|<row|<cell|<tabular|<tformat|<table|<row|<cell|>>|<row|<cell|incoming>>|<row|<cell|arguments>>|<row|<cell|>>|<row|<cell|>>|<row|<cell|frame
    pointer<math|\<rightarrow\>>>>|<row|<cell|>>|<row|<cell|>>|<row|<cell|>>|<row|<cell|>>|<row|<cell|>>|<row|<cell|>>|<row|<cell|>>|<row|<cell|>>|<row|<cell|>>|<row|<cell|>>|<row|<cell|outgoing>>|<row|<cell|arguments>>|<row|<cell|>>|<row|<cell|>>|<row|<cell|stack
    pointer<math|\<rightarrow\>>>>|<row|<cell|>>|<row|<cell|>>|<row|<cell|>>>>>>|<cell|<block|<tformat|<cwith|1|1|1|1|cell-tborder|>|<cwith|8|8|1|1|cell-bborder|>|<cwith|8|8|2|2|cell-bborder|>|<cwith|1|1|2|2|cell-tborder|>|<cwith|1|1|2|2|cell-row-span|2>|<cwith|3|3|2|2|cell-row-span|5>|<cwith|1|1|2|2|cell-valign|b>|<cwith|3|3|2|2|cell-valign|c>|<cwith|3|3|2|2|cell-halign|c>|<table|<row|<cell|>|<cell|<tabular|<tformat|<cwith|3|3|1|1|cell-valign|c>|<table|<row|<cell|<math|\<uparrow\>>higher
    addresses>>|<row|<cell|>>|<row|<cell|previous
    frame>>|<row|<cell|>>>>>>>|<row|<cell|<tabular|<tformat|<cwith|2|2|1|1|cell-halign|c>|<cwith|3|3|1|1|cell-halign|c>|<table|<row|<cell|argument
    <math|n>>>|<row|<cell|<math|\<vdots\>>>>|<row|<cell|argument
    <math|2>>>|<row|<cell|argument <math|1>>>|<row|<cell|static
    link>>>>>>|<cell|>>|<row|<cell|<tabular|<tformat|<cwith|1|1|1|1|cell-halign|c>|<table|<row|<cell|>>|<row|<cell|local
    variables>>|<row|<cell|>>>>>>|<cell|current frame>>|<row|<cell|return
    address>|<cell|>>|<row|<cell|<tabular|<tformat|<table|<row|<cell|>>|<row|<cell|temporaries>>|<row|<cell|>>>>>>|<cell|>>|<row|<cell|<tabular|<tformat|<table|<row|<cell|saved>>|<row|<cell|registers>>>>>>|<cell|>>|<row|<cell|<tabular|<tformat|<cwith|2|2|1|1|cell-halign|c>|<cwith|3|3|1|1|cell-halign|c>|<table|<row|<cell|argument
    <math|m>>>|<row|<cell|<math|\<vdots\>>>>|<row|<cell|argument
    <math|2>>>|<row|<cell|argument <math|1>>>|<row|<cell|static
    link>>>>>>|<cell|>>|<row|<cell|>|<cell|<tabular|<tformat|<cwith|3|3|1|1|cell-valign|c>|<table|<row|<cell|>>|<row|<cell|next
    frame>>|<row|<cell|>>|<row|<cell|<math|\<downarrow\>>lower
    addresses>>>>>>>>>>>>>>>>

    <new-page*><item><em|Static links> point to stack frames of parent
    functions, so we can access stack-based data, e.g. arguments of a main
    function from inside <verbatim|aux>.

    <item>A <em|<strong|closure>> represents a function: it is a block that
    contains address of the function: either another closure or a
    machine-code pointer, and a way to access non-local variables of the
    function.

    <\itemize>
      <item>For partially applied functions, it contains the values of
      arguments and the address of the original function.
    </itemize>

    <item><em|Escaping variables> are the variables of a function
    <verbatim|f> -- arguments and local definitions -- which are accessed
    from a nested function which is part of the returned value of
    <verbatim|f> (or assigned to a mutable field).

    <\itemize>
      <item>Escaping variables must be either part of the closures
      representing the nested functions, or of a closure representing the
      function <verbatim|f> -- in the latter case, the nested functions must
      also be represented by closures that have a link to the closure of
      <verbatim|f>.
    </itemize>
  </itemize>

  <subsection|<new-page*>Tail Recursion>

  <\itemize>
    <item>A function call <verbatim|f x> within the body of another function
    <verbatim|g> is in <em|tail position> if, roughly ``calling <verbatim|f>
    is the last thing that <verbatim|g> will do before returning''.

    <item>Call inside <hlkwa|try ><hlopt|... ><hlkwa|with> clause is not in
    tail position!

    <\itemize>
      <item>For efficient exceptions, OCaml stores <em|traps> for
      <hlkwa|try>-<hlkwa|with> on the stack with topmost trap in a register,
      after <hlkwa|raise> unwinding directly to the trap.
    </itemize>

    <item>The steps for a tail call are:

    <\enumerate>
      <item>Move actual parameters into argument registers (if they aren't
      already there).

      <item>Restore callee-save registers (if needed).

      <item>Pop the stack frame of the calling function (if it has one).

      <item>Jump to the callee.
    </enumerate>

    <item>Bytecode always throws <verbatim|Stack_overflow> exception on too
    deep recursion, native code will sometimes cause <em|segmentation fault>!

    <item><hlkwc|List><verbatim|.map> from the standard distribution is
    <strong|not> tail-recursive.
  </itemize>

  <subsection|<new-page*>Generated assembly>

  <\itemize>
    <item>Let us look at examples from<next-line>
    <hlink|http://ocaml.org/tutorials/performance_and_profiling.html|http://ocaml.org/tutorials/performance_and_profiling.html>
  </itemize>

  <section|<new-page*>Profiling and Optimization>

  <\itemize>
    <item>Steps of optimizing a program:

    <\enumerate>
      <item>Profile the program to find bottlenecks: where the time is spent.

      <item>If possible, modify the algorithm used by the bottleneck to an
      algorithm with better asymptotic complexity.

      <item>If possible, modify the bottleneck algorithm to access data less
      randomly, to increase <em|cache locality>.

      <\itemize>
        <item>Additionally, <em|realtime> systems may require avoiding use of
        huge arrays, traversed by the garbage collector in one go.
      </itemize>

      <item>Experiment with various implementations of data structures used
      <small|(related to step 3).>

      <item>Avoid <em|boxing> and polymorphic functions. Especially for
      numerical processing. (OCaml specific.)

      <item><em|Deforestation>.

      <item><em|Defunctorization>.
    </enumerate>
  </itemize>

  <subsection|<new-page*>Profiling>

  <\itemize>
    <item>We cover native code profiling because it is more useful.

    <\itemize>
      <item>It relies on the ``Unix'' profiling program <verbatim|gprof>.
    </itemize>

    <item>First we need to compile the sources in profiling mode:
    <verbatim|ocamlopt -p >...

    <\itemize>
      <item>or using <verbatim|ocamlbuild> when program source is in
      <verbatim|prog.ml>:

      <verbatim|ocamlbuild prog.p.native -->
    </itemize>

    <item>The execution of program <verbatim|./prog> produces a file
    <verbatim|gmon.out>

    <item>We call <verbatim|gprof prog \<gtr\> profile.txt>

    <\itemize>
      <item>or when we used <verbatim|ocamlbuild> as above:

      <verbatim|gprof prog.p.native \<gtr\> profile.txt>

      <item>This redirects profiling analysis to <verbatim|profile.txt> file.
    </itemize>

    <new-page*><item>The result <verbatim|profile.txt> has three parts:

    <\enumerate>
      <item>List of functions in the program in descending order of the time
      which was spent within the body of the function, excluding time spent
      in the bodies of any other functions.

      <item>A hierarchical representation of the time taken by each function,
      and the total time spent in it, including time spent in functions it
      called.

      <item>A bibliography of function references.
    </enumerate>

    <item>It contains C/assembly function names like
    <verbatim|camlList__assoc_1169>:

    <\itemize>
      <item>Prefix <verbatim|caml> means function comes from OCaml source.

      <item><verbatim|List__> means it belongs to a <hlkwc|List> module.

      <item><verbatim|assoc> is the name of the function in source.

      <item>Postfix <verbatim|_1169> is used to avoid name clashes, as in
      OCaml different functions often have the same names.
    </itemize>

    <item>Example: computing words histogram for a large file,
    <verbatim|Optim0.ml>.
  </itemize>

  <new-page*><hlkwa|let ><hlstd|read<textunderscore>words file
  ><hlopt|=><hlendline|Imperative programming example.><next-line><hlstd|
  \ ><hlkwa|let ><hlstd|input ><hlopt|= ><hlstd|open<textunderscore>in file
  ><hlkwa|in><hlendline|><next-line><hlstd| \ ><hlkwa|let ><hlstd|words
  ><hlopt|= ><hlkwb|ref ><hlopt|[] ><hlkwa|and ><hlstd|more ><hlopt|=
  ><hlkwb|ref ><hlkwa|true in><hlendline|><next-line><hlstd|
  \ ><hlkwa|try><hlendline|Lecture 6 <verbatim|read_lines> function would
  stack-overflow><next-line><hlstd| \ \ \ ><hlkwa|while ><hlopt|!><hlstd|more
  ><hlkwa|do><hlendline|because of the <hlkwa|try>-<hlkwa|with>
  clause.><next-line><hlstd| \ \ \ \ \ ><hlkwc|Scanf><hlopt|.><hlstd|fscanf
  input ><hlstr|"%[<textasciicircum>a-zA-Z0-9']%[a-zA-Z0-9']"><hlstd|<hlendline|><next-line>
  \ \ \ \ \ \ \ ><hlopt|(><hlkwa|fun ><hlstd|b x ><hlopt|-\<gtr\>
  ><hlstd|words ><hlopt|:= ><hlstd|x ><hlopt|:: !><hlstd|words><hlopt|;
  ><hlstd|more ><hlopt|:= ><hlstd|x ><hlopt|\<less\>\<gtr\>
  ><hlstr|""><hlopt|)><hlendline|><next-line><hlstd|
  \ \ \ ><hlkwa|done><hlopt|;><hlendline|><next-line><hlstd|
  \ \ \ ><hlkwc|List><hlopt|.><hlstd|rev ><hlopt|(><hlkwc|List><hlopt|.><hlstd|tl
  ><hlopt|!><hlstd|words><hlopt|)><hlendline|><next-line><hlstd|
  \ ><hlkwa|with ><hlkwd|End<textunderscore>of<textunderscore>file
  ><hlopt|-\<gtr\> ><hlkwc|List><hlopt|.><hlstd|rev
  ><hlopt|!><hlstd|words><hlendline|><next-line><hlendline|><next-line><hlkwa|let
  ><hlstd|empty ><hlopt|() = []><hlendline|><next-line><hlkwa|let
  ><hlstd|increment h w ><hlopt|=><hlendline|Inefficient map
  update.><next-line><hlstd| \ ><hlkwa|try><hlendline|><next-line><hlstd|
  \ \ \ ><hlkwa|let ><hlstd|c ><hlopt|= ><hlkwc|List><hlopt|.><hlstd|assoc w
  h ><hlkwa|in><hlendline|><next-line><hlstd|
  \ \ \ ><hlopt|(><hlstd|w><hlopt|, ><hlstd|c><hlopt|+><hlnum|1><hlopt|) ::
  ><hlkwc|List><hlopt|.><hlstd|remove<textunderscore>assoc w
  h<hlendline|><next-line> \ ><hlkwa|with ><hlkwd|Not<textunderscore>found
  ><hlopt|-\<gtr\> (><hlstd|w><hlopt|, ><hlnum|1><hlopt|)::><hlstd|h><hlendline|><next-line><hlkwa|let
  ><hlstd|iterate f h ><hlopt|=><hlendline|><next-line><hlstd|
  \ ><hlkwc|List><hlopt|.><hlstd|iter ><hlopt|(><hlkwa|fun
  ><hlopt|(><hlstd|k><hlopt|,><hlstd|v><hlopt|)-\<gtr\>><hlstd|f k v><hlopt|)
  ><hlstd|h><hlendline|><next-line><hlendline|><next-line><hlkwa|let
  ><hlstd|histogram words ><hlopt|=><hlendline|><next-line><hlstd|
  \ ><hlkwc|List><hlopt|.><hlstd|fold<textunderscore>left increment
  ><hlopt|(><hlstd|empty ><hlopt|()) ><hlstd|words><hlendline|><next-line><hlendline|><next-line><hlkwa|let
  ><hlstd|<textunderscore> ><hlopt|=><hlendline|><next-line><hlstd|
  \ ><hlkwa|let ><hlstd|words ><hlopt|= ><hlstd|read<textunderscore>words
  ><hlstr|"./shakespeare.xml"><hlstd| ><hlkwa|in><hlendline|><next-line><hlstd|
  \ ><hlkwa|let ><hlstd|words ><hlopt|= ><hlkwc|List><hlopt|.><hlstd|rev<textunderscore>map
  ><hlkwc|String><hlopt|.><hlstd|lowercase words
  ><hlkwa|in><hlendline|><next-line><hlstd| \ ><hlkwa|let ><hlstd|h ><hlopt|=
  ><hlstd|histogram words ><hlkwa|in><hlendline|><next-line><hlstd|
  \ ><hlkwa|let ><hlstd|output ><hlopt|= ><hlstd|open<textunderscore>out
  ><hlstr|"histogram.txt"><hlstd| ><hlkwa|in><hlendline|><next-line><hlstd|
  \ iterate ><hlopt|(><hlkwc|Printf><hlopt|.><hlstd|fprintf output
  ><hlstr|"%s: %d><hlesc|<math|>n><hlstr|"><hlopt|)
  ><hlstd|h><hlopt|;><hlendline|><next-line><hlstd|
  \ close<textunderscore>out output><hlendline|>

  <\itemize>
    <new-page*><item>Now we look at the profiling analysis, first part begins
    with:
  </itemize>

  <\small>
    <\code>
      \ \ % \ \ cumulative \ \ self \ \ \ \ \ \ \ \ \ \ \ \ \ self
      \ \ \ \ total \ \ \ \ \ \ \ \ \ \ 

      \ time \ \ seconds \ \ seconds \ \ \ calls \ \ s/call \ \ s/call \ name
      \ \ \ 

      \ 37.88 \ \ \ \ \ 8.54 \ \ \ \ 8.54 306656698 \ \ \ 0.00 \ \ \ \ 0.00
      \ compare_val

      \ 19.97 \ \ \ \ 13.04 \ \ \ \ 4.50 \ \ 273169 \ \ \ \ 0.00 \ \ \ \ 0.00
      \ camlList__assoc_1169

      \ \ 9.17 \ \ \ \ 15.10 \ \ \ \ 2.07 633527269 \ \ \ 0.00 \ \ \ \ 0.00
      \ caml_page_table_lookup

      \ \ 8.72 \ \ \ \ 17.07 \ \ \ \ 1.97 \ \ 260756 \ \ \ 0.00 \ 0.00
      camlList__remove_assoc_1189

      \ \ 7.10 \ \ \ \ 18.67 \ \ \ \ 1.60 612779467 \ \ \ 0.00 \ \ \ \ 0.00
      \ caml_string_length

      \ \ 4.97 \ \ \ \ 19.79 \ \ \ \ 1.12 306656692 \ \ \ \ 0.00 \ \ \ 0.00
      \ caml_compare

      \ \ 2.84 \ \ \ \ 20.43 \ \ \ \ 0.64
      \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ caml_c_call

      \ \ 1.53 \ \ \ \ 20.77 \ \ \ \ 0.35 \ \ \ 14417 \ \ \ \ 0.00
      \ \ \ \ 0.00 \ caml_page_table_modify

      \ \ 1.07 \ \ \ \ 21.01 \ \ \ \ 0.24 \ \ \ \ 1115 \ \ \ \ 0.00
      \ \ \ \ 0.00 \ sweep_slice

      \ \ 0.89 \ \ \ \ 21.21 \ \ \ \ 0.20 \ \ \ \ \ 484 \ \ \ \ 0.00
      \ \ \ \ 0.00 \ mark_slice
    </code>
  </small>

  <\itemize>
    <item><hlkwc|List><hlopt|.><hlstd|assoc> and
    <hlkwc|List><hlopt|.><hlstd|remove<textunderscore>assoc> high in the
    ranking suggests to us that <verbatim|increment> could be the bottleneck.

    <\itemize>
      <item>They both use comparison which could explain why
      <verbatim|compare_val> consumes the most of time.
    </itemize>

    <new-page*><item>Next we look at the interesting pieces of the second
    part: data about the <verbatim|increment> function.

    <\itemize>
      <item>Each block, separated by <verbatim|------> lines, describes the
      function whose line starts with an index in brackets.

      <item>The functions that called it are above, the functions it calls
      below.
    </itemize>
  </itemize>

  <\small>
    <\code>
      index % time \ \ \ self \ children \ \ \ called \ \ \ \ name

      -----------------------------------------------

      \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ 0.00 \ \ \ 6.47 \ 273169/273169
      \ camlList__fold_left_1078 [7]

      [8] \ \ \ \ 28.7 \ \ \ 0.00 \ \ \ 6.47 \ 273169
      \ \ \ \ \ \ \ \ camlOptim0__increment_1038 [8]

      \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ 4.50 \ \ \ 0.00 \ 273169/273169
      \ camlList__assoc_1169 [9]

      \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ 1.97 \ \ \ 0.00 \ 260756/260756
      \ camlList__remove_assoc_1189 [11]
    </code>
  </small>

  <\itemize>
    <item>As expected, <verbatim|increment> is only called by
    <hlkwc|List><hlopt|.><hlstd|fold_left>. But it seems to account for only
    29% of time. It is because <verbatim|compare> is not analysed correctly,
    thus not included in time for <verbatim|increment>:
  </itemize>

  <\small>
    <\code>
      -----------------------------------------------

      \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ 1.12 \ \ 12.13 306656692/306656692
      \ \ \ \ caml_c_call [1]

      [2] \ \ \ \ 58.8 \ \ \ 1.12 \ \ 12.13 306656692
      \ \ \ \ \ \ \ \ caml_compare [2]

      \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ 8.54 \ \ \ 3.60 306656692/306656698
      \ \ \ \ compare_val [3]
    </code>
  </small>

  <subsection|<new-page*>Algorithmic optimizations>

  <\itemize>
    <item>(All times measured with profiling turned on.)

    <item><verbatim|Optim0.ml> asymptotic time complexity:
    <math|\<cal-O\><around*|(|n<rsup|2>|)>>, time: 22.53s.

    <\itemize>
      <item>Garbage collection takes 6% of time.

      <\itemize>
        <item>So little because data access wastes a lot of time.
      </itemize>
    </itemize>

    <item>Optimize the data structure, keep the algorithm.

    <hlkwa|let ><hlstd|empty ><hlopt|() =
    ><hlkwc|Hashtbl><hlopt|.><hlstd|create
    ><hlnum|511><hlendline|><next-line><hlkwa|let ><hlstd|increment h w
    ><hlopt|=><hlendline|><next-line><hlstd|
    \ ><hlkwa|try><hlendline|><next-line><hlstd| \ \ \ ><hlkwa|let ><hlstd|c
    ><hlopt|= ><hlkwc|Hashtbl><hlopt|.><hlstd|find h w
    ><hlkwa|in><hlendline|><next-line><hlstd|
    \ \ \ ><hlkwc|Hashtbl><hlopt|.><hlstd|replace h w
    ><hlopt|(><hlstd|c><hlopt|+><hlnum|1><hlopt|);
    ><hlstd|h<hlendline|><next-line> \ ><hlkwa|with
    ><hlkwd|Not<textunderscore>found ><hlopt|-\<gtr\>
    ><hlkwc|Hashtbl><hlopt|.><hlstd|add h w ><hlnum|1><hlopt|;
    ><hlstd|h><hlendline|><next-line><hlkwa|let ><hlstd|iterate f h ><hlopt|=
    ><hlkwc|Hashtbl><hlopt|.><hlstd|iter f h><hlendline|>

    <verbatim|Optim1.ml> asymptotic time complexity:
    <math|\<cal-O\><around*|(|n|)>>, time: 0.63s.

    <\itemize>
      <item>Garbage collection takes 17% of time.
    </itemize>

    <new-page*><item>Optimize the algorithm, keep the data structure.

    <hlkwa|let ><hlstd|histogram words ><hlopt|=><hlendline|><next-line><hlstd|
    \ ><hlkwa|let ><hlstd|words ><hlopt|= ><hlkwc|List><hlopt|.><hlstd|sort
    ><hlkwc|String><hlopt|.><hlstd|compare words
    ><hlkwa|in><hlendline|><next-line><hlstd| \ ><hlkwa|let
    ><hlstd|k><hlopt|,><hlstd|c><hlopt|,><hlstd|h ><hlopt|=
    ><hlkwc|List><hlopt|.><hlstd|fold<textunderscore>left<hlendline|><next-line>
    \ \ \ ><hlopt|(><hlkwa|fun ><hlopt|(><hlstd|k><hlopt|,><hlstd|c><hlopt|,><hlstd|h><hlopt|)
    ><hlstd|w ><hlopt|-\<gtr\>><hlendline|><next-line><hlstd|
    \ \ \ \ \ ><hlkwa|if ><hlstd|k ><hlopt|= ><hlstd|w ><hlkwa|then
    ><hlstd|k><hlopt|, ><hlstd|c><hlopt|+><hlnum|1><hlopt|, ><hlstd|h
    ><hlkwa|else ><hlstd|w><hlopt|, ><hlnum|1><hlopt|,
    ((><hlstd|k><hlopt|,><hlstd|c><hlopt|)::><hlstd|h><hlopt|))><hlendline|><next-line><hlstd|
    \ \ \ ><hlopt|(><hlstr|""><hlopt|, ><hlnum|0><hlopt|, []) ><hlstd|words
    ><hlkwa|in><hlendline|><next-line><hlstd|
    \ ><hlopt|(><hlstd|k><hlopt|,><hlstd|c><hlopt|)::><hlstd|h><hlendline|>

    <verbatim|Optim2.ml> asymptotic time complexity:
    <math|\<cal-O\><around*|(|n*log n|)>>, time: 1s.

    <\itemize>
      <item>Garbage collection takes 40% of time.\ 
    </itemize>

    <item>Optimizing for cache efficiency is more advanced, we will not
    attempt it.

    <item>With algorithmic optimizations we should be concerned with
    <strong|asymptotic complexity> in terms of the
    <math|\<cal-O\><around*|(|\<cdot\>|)>> notation, but we will not pursue
    complexity analysis in the remainder of the lecture.
  </itemize>

  <subsection|<new-page*>Low-level optimizations>

  <\itemize>
    <item>Optimizations below have been made <em|for educational purposes
    only>.

    <item>Avoid polymorphism in generic comparison function <hlopt|(=)>.

    <small|<hlkwa|let rec ><hlstd|assoc x ><hlopt|=
    ><hlkwa|function><hlendline|><next-line><hlstd| \ \ \ ><hlopt|[] -\<gtr\>
    ><hlstd|raise ><hlkwd|Not<textunderscore>found><hlendline|><next-line><hlstd|
    \ ><hlopt|\| (><hlstd|a><hlopt|,><hlstd|b><hlopt|)::><hlstd|l
    ><hlopt|-\<gtr\> ><hlkwa|if ><hlkwc|String><hlopt|.><hlstd|compare a x
    ><hlopt|= ><hlnum|0 ><hlkwa|then ><hlstd|b ><hlkwa|else ><hlstd|assoc x
    l><hlendline|><next-line><hlkwa|let rec
    ><hlstd|remove<textunderscore>assoc x ><hlopt|=
    ><hlkwa|function><hlendline|><next-line><hlstd| \ ><hlopt|\| [] -\<gtr\>
    []><hlendline|><next-line><hlstd| \ ><hlopt|\| (><hlstd|a><hlopt|,
    ><hlstd|b ><hlkwa|as ><hlstd|pair><hlopt|) :: ><hlstd|l
    ><hlopt|-\<gtr\>><hlendline|><next-line><hlstd| \ \ \ \ \ ><hlkwa|if
    ><hlkwc|String><hlopt|.><hlstd|compare a x ><hlopt|= ><hlnum|0
    ><hlkwa|then ><hlstd|l ><hlkwa|else ><hlstd|pair ><hlopt|::
    ><hlstd|remove<textunderscore>assoc x l><hlendline|>>

    <verbatim|Optim3.ml> (based on <verbatim|Optim0.ml>) time: 19s.

    <\itemize>
      <item>Despite implementation-wise the code is the same, as
      <hlkwc|String><hlopt|.><hlstd|compare> =
      <hlkwc|Pervasives><hlopt|.><hlstd|compare> inside module
      <hlkwc|String>, and <hlkwc|List><hlopt|.><verbatim|assoc> is like above
      but uses <hlkwc|Pervasives><hlopt|.><hlstd|compare>!

      <item>We removed polymorphism, no longer <verbatim|caml_compare_val>
      function.

      <item>Usually, adding type annotations would be enough. (Useful
      especially for numeric types <hlkwb|int>, <hlkwb|float>.)
    </itemize>

    <new-page*><item><strong|Deforestation> means removing intermediate data
    structures.

    <hlkwa|let ><hlstd|read<textunderscore>to<textunderscore>histogram file
    ><hlopt|=><hlendline|><next-line><hlstd| \ ><hlkwa|let ><hlstd|input
    ><hlopt|= ><hlstd|open<textunderscore>in file
    ><hlkwa|in><hlendline|><next-line><hlstd| \ ><hlkwa|let ><hlstd|h
    ><hlopt|= ><hlstd|empty ><hlopt|() ><hlkwa|and ><hlstd|more ><hlopt|=
    ><hlkwb|ref ><hlkwa|true in><hlendline|><next-line><hlstd|
    \ ><hlkwa|try><hlendline|><next-line><hlstd| \ \ \ ><hlkwa|while
    ><hlopt|!><hlstd|more ><hlkwa|do><hlendline|><next-line><hlstd|
    \ \ \ \ \ ><hlkwc|Scanf><hlopt|.><hlstd|fscanf input
    ><hlstr|"%[<textasciicircum>a-zA-Z0-9']%[a-zA-Z0-9']"><hlstd|<hlendline|><next-line>
    \ \ \ \ \ \ \ ><hlopt|(><hlkwa|fun ><hlstd|b w
    ><hlopt|-\<gtr\>><hlendline|><next-line><hlstd|
    \ \ \ \ \ \ \ \ \ ><hlkwa|let ><hlstd|w ><hlopt|=
    ><hlkwc|String><hlopt|.><hlstd|lowercase w
    ><hlkwa|in><hlendline|><next-line><hlstd| \ \ \ \ \ \ \ \ \ increment h
    w><hlopt|; ><hlstd|more ><hlopt|:= ><hlstd|w ><hlopt|\<less\>\<gtr\>
    ><hlstr|""><hlopt|)><hlendline|><next-line><hlstd|
    \ \ \ ><hlkwa|done><hlopt|; ><hlstd|h<hlendline|><next-line>
    \ ><hlkwa|with ><hlkwd|End<textunderscore>of<textunderscore>file
    ><hlopt|-\<gtr\> ><hlstd|h><hlendline|>

    <verbatim|Optim4.ml> (based on <verbatim|Optim1.ml>) time: 0.51s.

    <\itemize>
      <item>Garbage collection takes 8% of time.

      <\itemize>
        <item>So little because we have eliminated garbage.
      </itemize>
    </itemize>

    <new-page*><item><strong|Defunctorization> means computing functor
    applications by hand.

    <\itemize>
      <item>There was a tool <verbatim|ocamldefun> but it is out of date.

      <item>The slight speedup comes from the fact that functor arguments are
      implemented as records of functions.
    </itemize>
  </itemize>

  <subsection|<new-page*>Comparison of data structure implementations>

  <\itemize>
    <item>We perform a rough comparison of association lists, tree-based maps
    and hashtables. Sets would give the same results.

    <item>We always create hashtables with initial size 511.

    <item><math|10<rsup|7>> operations of: adding an association (creation),
    finding a key that is in the map, finding a key out of a small number of
    keys not in the map.

    <item>First row gives sizes of maps. Time in seconds, to two significant
    digits.
  </itemize>

  <block|<tformat|<cwith|4|4|1|1|cell-halign|l>|<table|<row|<cell|create:>|<cell|<math|2<rsup|1>>>|<cell|<math|2<rsup|2>>>|<cell|<math|2<rsup|3>>>|<cell|<math|2<rsup|4>>>|<cell|<math|2<rsup|5>>>|<cell|<math|2<rsup|6>>>|<cell|<math|2<rsup|7>>>|<cell|<math|2<rsup|8>>>|<cell|<math|2<rsup|9>>>|<cell|<math|2<rsup|10>>>>|<row|<cell|assoc
  list>|<cell|0.25>|<cell|0.25>|<cell|0.18>|<cell|0.19>|<cell|0.17>|<cell|0.22>|<cell|0.19>|<cell|0.19>|<cell|0.19>|<cell|>>|<row|<cell|tree
  map>|<cell|0.48>|<cell|0.81>|<cell|0.82>|<cell|1.2>|<cell|1.6>|<cell|2.3>|<cell|2.7>|<cell|3.6>|<cell|4.1>|<cell|5.1>>|<row|<cell|hashtable>|<cell|27>|<cell|9.1>|<cell|5.5>|<cell|4>|<cell|2.9>|<cell|2.4>|<cell|2.1>|<cell|1.9>|<cell|1.8>|<cell|3.7>>>>>

  <block|<tformat|<cwith|3|3|1|1|cell-halign|l>|<table|<row|<cell|create:>|<cell|<math|2<rsup|11>>>|<cell|<math|2<rsup|12>>>|<cell|<math|2<rsup|13>>>|<cell|<math|2<rsup|14>>>|<cell|<math|2<rsup|15>>>|<cell|<math|2<rsup|16>>>|<cell|<math|2<rsup|17>>>|<cell|<math|2<rsup|18>>>|<cell|<math|2<rsup|19>>>|<cell|<math|2<rsup|20>>>|<cell|<math|2<rsup|21>>>|<cell|<math|2<rsup|22>>>>|<row|<cell|tree
  map>|<cell|6.5>|<cell|8>|<cell|9.8>|<cell|15>|<cell|19>|<cell|26>|<cell|34>|<cell|41>|<cell|51>|<cell|67>|<cell|80>|<cell|130>>|<row|<cell|hashtable>|<cell|4.8>|<cell|5.6>|<cell|6.4>|<cell|8.4>|<cell|12>|<cell|15>|<cell|19>|<cell|20>|<cell|22>|<cell|24>|<cell|23>|<cell|33>>>>>

  <block|<tformat|<cwith|4|4|1|1|cell-halign|l>|<table|<row|<cell|found:>|<cell|<math|2<rsup|1>>>|<cell|<math|2<rsup|2>>>|<cell|<math|2<rsup|3>>>|<cell|<math|2<rsup|4>>>|<cell|<math|2<rsup|5>>>|<cell|<math|2<rsup|6>>>|<cell|<math|2<rsup|7>>>|<cell|<math|2<rsup|8>>>|<cell|<math|2<rsup|9>>>|<cell|<math|2<rsup|10>>>>|<row|<cell|assoc
  list>|<cell|1.1>|<cell|1.5>|<cell|2.5>|<cell|4.2>|<cell|8.1>|<cell|17>|<cell|30>|<cell|60>|<cell|120>|<cell|>>|<row|<cell|tree
  map>|<cell|1>|<cell|1.1>|<cell|1.3>|<cell|1.5>|<cell|1.9>|<cell|2.1>|<cell|2.5>|<cell|2.8>|<cell|3.1>|<cell|3.6>>|<row|<cell|hashtable>|<cell|1.4>|<cell|1.5>|<cell|1.4>|<cell|1.4>|<cell|1.5>|<cell|1.5>|<cell|1.6>|<cell|1.6>|<cell|1.8>|<cell|1.8>>>>>

  <block|<tformat|<cwith|3|3|1|1|cell-halign|l>|<table|<row|<cell|found:>|<cell|<math|2<rsup|11>>>|<cell|<math|2<rsup|12>>>|<cell|<math|2<rsup|13>>>|<cell|<math|2<rsup|14>>>|<cell|<math|2<rsup|15>>>|<cell|<math|2<rsup|16>>>|<cell|<math|2<rsup|17>>>|<cell|<math|2<rsup|18>>>|<cell|<math|2<rsup|19>>>|<cell|<math|2<rsup|20>>>|<cell|<math|2<rsup|21>>>|<cell|<math|2<rsup|22>>>>|<row|<cell|tree
  map>|<cell|4.3>|<cell|5.2>|<cell|6>|<cell|7.6>|<cell|9.4>|<cell|12>|<cell|15>|<cell|17>|<cell|19>|<cell|24>|<cell|28>|<cell|32>>|<row|<cell|hashtable>|<cell|1.8>|<cell|2>|<cell|2.5>|<cell|3.1>|<cell|4>|<cell|5.1>|<cell|5.9>|<cell|6.4>|<cell|6.8>|<cell|7.6>|<cell|6.7>|<cell|7.5>>>>>

  <\small>
    <block|<tformat|<cwith|4|4|1|1|cell-halign|l>|<table|<row|<cell|not
    found:>|<cell|<math|2<rsup|1>>>|<cell|<math|2<rsup|2>>>|<cell|<math|2<rsup|3>>>|<cell|<math|2<rsup|4>>>|<cell|<math|2<rsup|5>>>|<cell|<math|2<rsup|6>>>|<cell|<math|2<rsup|7>>>|<cell|<math|2<rsup|8>>>|<cell|<math|2<rsup|9>>>|<cell|<math|2<rsup|10>>>>|<row|<cell|assoc
    list>|<cell|1.8>|<cell|2.6>|<cell|4.6>|<cell|8>|<cell|16>|<cell|32>|<cell|60>|<cell|120>|<cell|240>|<cell|>>|<row|<cell|tree
    map>|<cell|1.5>|<cell|1.5>|<cell|1.8>|<cell|2.1>|<cell|2.4>|<cell|2.7>|<cell|3>|<cell|3.2>|<cell|3.5>|<cell|3.8>>|<row|<cell|hashtable>|<cell|1.4>|<cell|1.4>|<cell|1.5>|<cell|1.5>|<cell|1.6>|<cell|1.5>|<cell|1.7>|<cell|1.9>|<cell|2>|<cell|2.1>>>>>

    <block|<tformat|<cwith|3|3|1|1|cell-halign|l>|<table|<row|<cell|not
    found:>|<cell|<math|2<rsup|11>>>|<cell|<math|2<rsup|12>>>|<cell|<math|2<rsup|13>>>|<cell|<math|2<rsup|14>>>|<cell|<math|2<rsup|15>>>|<cell|<math|2<rsup|16>>>|<cell|<math|2<rsup|17>>>|<cell|<math|2<rsup|18>>>|<cell|<math|2<rsup|19>>>|<cell|<math|2<rsup|20>>>|<cell|<math|2<rsup|21>>>|<cell|<math|2<rsup|22>>>>|<row|<cell|tree
    map>|<cell|4.2>|<cell|4.3>|<cell|4.7>|<cell|4.9>|<cell|5.3>|<cell|5.5>|<cell|6.1>|<cell|6.3>|<cell|6.6>|<cell|7.2>|<cell|7.5>|<cell|7.3>>|<row|<cell|hashtable>|<cell|1.8>|<cell|1.9>|<cell|2>|<cell|1.9>|<cell|1.9>|<cell|1.9>|<cell|2>|<cell|2>|<cell|2.2>|<cell|2>|<cell|2>|<cell|1.9>>>>>
  </small>

  <\itemize>
    <item>Using lists makes sense for up to about 15 elements.

    <item>Unfortunately OCaml and Haskell do not encourage the use of
    efficient maps, the way Scala and Python have built-in syntax for them.
  </itemize>

  <section|<new-page*>Parsing: ocamllex and Menhir>

  <\itemize>
    <item><em|Parsing> means transforming text, i.e. a string of characters,
    into a data structure that is well fitted for a given task, or generally
    makes information in the text more explicit.

    <item>Parsing is usually done in stages:

    <\enumerate>
      <item><em|Lexing> or <em|tokenizing>, dividing the text into smallest
      meaningful pieces called <em|lexemes> or <em|tokens>,

      <item>composing bigger structures out of lexemes/tokens (and smaller
      structures) according to a <em|grammar>.

      <\itemize>
        <item>Alternatively to building such hierarchical structure,
        sometimes we build relational structure over the tokens, e.g.
        <em|dependency gram<no-break>mars>.
      </itemize>
    </enumerate>

    <item>We will use <verbatim|ocamllex> for lexing, whose rules are like
    pattern matching functions, but with patterns being <em|regular
    expressions>.

    <item>We will either consume the results from lexer directly, or use
    <em|Menhir> for parsing, a successor of <verbatim|ocamlyacc>, belonging
    to the <em|yacc>/<em|bison> family of parsers.
  </itemize>

  <subsection|<new-page*>Lexing with <em|ocamllex>>

  <\itemize>
    <item>The format of lexer definitions is as follows: file with extension
    <verbatim|.mll>

    <hlopt|{ >header<hlopt| }><hlendline|><next-line><hlkwa|let
    ><hlstd|ident1 ><hlopt|= >regexp ...<hlendline|><next-line><hlkwa|rule><verbatim|
    entrypoint1 >[<verbatim|arg1>...<verbatim| argN>]<hlopt|
    =><hlendline|><next-line><hlkwa| \ parse >regexp<hlopt| { >action1<hlopt|
    }><hlendline|><next-line><verbatim| \ \ \ \ \ ><hlopt|\|>
    ...<hlendline|><next-line><verbatim| \ \ \ \ \ ><hlopt|\|> regexp
    <hlopt|{ >actionN<hlopt| }><hlendline|><next-line><hlkwa|and
    ><hlstd|entrypointN ><hlopt|[><hlstd|arg1? argN><hlopt|]
    =><hlendline|><next-line><hlkwa| \ parse
    >...<hlendline|><next-line><hlkwa|and >...<hlendline|><next-line><hlopt|{
    >trailer<hlopt| }><hlendline|>

    <\itemize>
      <item>Comments are delimited by <hlcom|(* and *)>, as in OCaml.

      <item>The <hlkwa|parse> keyword can be replaced by the <hlkwa|shortest>
      keyword.

      <item>''Header'', ``trailer'', ``action1'', ... ``actionN'' are
      arbitrary OCaml code.

      <item>There can be multiple let-clauses and rule-clauses.
    </itemize>

    <new-page*><item>Let-clauses are shorthands for regular expressions.

    <item>Each rule-clause <verbatim|entrypoint> defines function(s) that as
    the last argument (after <verbatim|arg1>...<verbatim| argN> if
    <verbatim|N>\<gtr\>0) takes argument <verbatim|lexbuf> of type
    <hlkwc|Lexing><hlopt|.><hlstd|lexbuf>.

    <\itemize>
      <item><verbatim|lexbuf> is also visible in actions, just as a regular
      argument.

      <item><verbatim|entrypoint1>...<verbatim| entrypointN> can be mutually
      recursive if we need to read more before we can return output.

      <item>It seems <hlkwa|rule> keyword can be used only once.
    </itemize>

    <item>We can use <verbatim|lexbuf> in actions:

    <\itemize>
      <item><hlkwc|Lexing><hlopt|.><hlstd|lexeme lexbuf> -- Return the
      matched string.

      <item><hlkwc|Lexing><hlopt|.><hlstd|lexeme<textunderscore>char lexbuf
      n> -- Return the nth character in the matched string. The first
      character corresponds to n = 0.

      <item><hlkwc|Lexing><hlopt|.><hlstd|lexeme<textunderscore>start>/<hlstd|lexeme<textunderscore>end
      lexbuf> -- Return the absolute position in the input text of the
      beginning/end of the matched string (i.e. the offset of the first
      character of the matched string). The first character read from the
      input text has offset 0.
    </itemize>

    <item>The parser will call an <verbatim|entrypoint> when it needs another
    lexeme/token.

    <new-page*><item>The syntax of <strong|regular expressions>

    <\itemize>
      <item><hlstr|'c'> -- match the character <hlstr|'c'>

      <item><verbatim|_> -- match a <strong|single> character

      <item><verbatim|eof> -- match end of lexer input

      <item><hlstr|"string"> -- match the corresponding sequence of
      characters

      <item><hlopt|[>character set<hlopt|]> -- match the character set,
      characters <hlstr|'c'> and ranges of characters
      <hlstr|'c'><hlopt|-><hlstr|'d'> separated by space

      <item><hlopt|[^>character set<hlopt|]> -- match characters outside the
      character set

      <item><hlopt|[>character set 1<hlopt|] # ><hlopt|[>character set
      2<hlopt|]> -- match the difference, i.e. only characters in set 1 that
      are not in set 2

      <item>regexp<hlopt|*> -- (repetition) match the concatenation of zero
      or more strings that match regexp

      <item>regexp<hlopt|+> -- (strict repetition) match the concatenation of
      one or more strings that match regexp

      <item>regexp<hlopt|?> -- (option) match the empty string, or a string
      matching regexp.

      <item>regexp1<hlopt| \| >regexp2 -- (alternative) match any string that
      matches regexp1 or regexp2

      <item>regexp1 regexp2 -- (concatenation) match the concatenation of two
      strings, the first matching regexp1, the second matching regexp2.

      <item><hlopt|(> regexp <hlopt|)> -- match the same strings as regexp

      <item><verbatim|ident> -- reference the regular expression bound to
      ident by an earlier <hlkwa|let ><verbatim|ident ><hlopt|= >regexp
      definition

      <item>regexp<hlkwa| as ><verbatim|ident> -- bind the substring matched
      by regexp to identifier <verbatim|ident>.
    </itemize>

    The precedences are: <hlopt|#> highest, followed by <hlopt|*>, <hlopt|+>,
    <hlopt|?>, concatenation, <hlopt|\|>, <hlkwa|as>.

    <new-page*><item>The type of<hlkwa| as ><verbatim|ident> variables can be
    <hlkwb|string>, <hlkwb|char>, <hlkwb|string option >or <hlkwb|char
    option>

    <\itemize>
      <item><hlkwb|char> means obviously a single character pattern

      <item><hlkwb|option> means situations like <hlopt|(>regexp <hlkwa|as
      ><verbatim|ident><hlopt|)?> or regexp1<hlopt|\|(>regexp2 <hlkwa|as
      ><verbatim|ident><hlopt|)>

      <item>The variables can repeat in the pattern (<strong|unlike> in
      normal paterns) -- meaning both regexpes match the same substrings.
    </itemize>

    <item><verbatim|ocamllex Lexer.mll> produces the lexer code in
    <verbatim|Lexer.ml>

    <\itemize>
      <item><verbatim|ocamlbuild> will call <verbatim|ocamllex> and
      <verbatim|ocamlyacc>/<verbatim|menhir> if needed
    </itemize>

    <item>Unfortunately if the lexer patterns are big we get an error:

    <em|transition table overflow, automaton is too big>
  </itemize>

  <subsubsection|<new-page*>Example: Finding email addresses>

  <\itemize>
    <item>We mine a text file for email addresses, that could have been
    obfuscated to hinder our job...

    <item>To compile and run <verbatim|Emails.mll>, processing a file
    <verbatim|email_corpus.xml>:

    <verbatim|ocamlbuild Emails.native -- email_corpus.xml>
  </itemize>

  <hlopt|{><hlendline|The header with OCaml code.><next-line><hlstd|
  \ ><hlkwa|open ><hlkwc|Lexing><hlendline|Make accessing <hlkwc|Lexing>
  easier.><next-line><hlstd| \ ><hlkwa|let ><hlstd|nextline lexbuf
  ><hlopt|=><hlendline|Typical lexer function: move position to next
  line.><next-line><hlstd| \ \ \ ><hlkwa|let ><hlstd|pos ><hlopt|=
  ><hlstd|lexbuf><hlopt|.><hlstd|lex<textunderscore>curr<textunderscore>p
  ><hlkwa|in><hlendline|><next-line><hlstd|
  \ \ \ lexbuf><hlopt|.><hlstd|lex<textunderscore>curr<textunderscore>p
  ><hlopt|\<less\>- { ><hlstd|pos ><hlkwa|with><hlendline|><next-line><hlstd|
  \ \ \ \ \ pos<textunderscore>lnum ><hlopt|=
  ><hlstd|pos><hlopt|.><hlstd|pos<textunderscore>lnum ><hlopt|+
  ><hlnum|1><hlopt|;><hlendline|><next-line><hlstd|
  \ \ \ \ \ pos<textunderscore>bol ><hlopt|=
  ><hlstd|pos><hlopt|.><hlstd|pos<textunderscore>cnum><hlopt|;><hlendline|><next-line><hlstd|
  \ \ \ ><hlopt|}><hlendline|><next-line><hlstd| \ ><hlkwa|type ><hlstd|state
  ><hlopt|=><hlendline|Which step of searching for address we're
  at:><next-line><hlstd| \ ><hlopt|\| ><hlkwd|Seek><hlendline|<hlkwd|Seek>:
  still seeking, <hlkwd|Addr ><hlopt|(><hlkwa|true>...<hlopt|)>: possibly
  finished,><next-line><hlstd| \ ><hlopt|\| ><hlkwd|Addr ><hlkwa|of
  ><hlkwb|bool ><hlopt|* ><hlkwb|string ><hlopt|* ><hlkwb|string
  ><verbatim|list><hlendline|<hlkwd|Addr ><hlopt|(><hlkwa|false>...<hlopt|)>:
  no domain.>

  <new-page*><verbatim| \ ><hlkwa|let ><hlstd|report state lexbuf
  ><hlopt|=><hlendline|Report the found address, if any.><next-line><hlstd|
  \ \ \ ><hlkwa|match ><hlstd|state ><hlkwa|with><hlendline|><next-line><hlstd|
  \ \ \ ><hlopt|\| ><hlkwd|Seek ><hlopt|-\<gtr\>
  ()><hlendline|><next-line><hlstd| \ \ \ ><hlopt|\| ><hlkwd|Addr
  ><hlopt|(><hlkwa|false><hlopt|, ><hlstd|<textunderscore>><hlopt|,
  ><hlstd|<textunderscore>><hlopt|) -\<gtr\>
  ()><hlendline|><next-line><hlstd| \ \ \ ><hlopt|\| ><hlkwd|Addr
  ><hlopt|(><hlkwa|true><hlopt|, ><hlstd|name><hlopt|, ><hlstd|addr><hlopt|)
  -\<gtr\>><hlendline|With line at which it is found.><next-line><hlstd|
  \ \ \ \ \ ><hlkwc|Printf><hlopt|.><hlstd|printf ><hlstr|"%d:
  %s@%s><hlesc|<math|>n><hlstr|"><hlstd| lexbuf><hlopt|.><hlstd|lex<textunderscore>curr<textunderscore>p><hlopt|.><hlstd|pos<textunderscore>lnum<hlendline|><next-line>
  \ \ \ \ \ \ \ name ><hlopt|(><hlkwc|String><hlopt|.><hlstd|concat
  ><hlstr|"."><hlstd| ><hlopt|(><hlkwc|List><hlopt|.><hlstd|rev
  addr><hlopt|))><hlendline|><next-line><hlopt|}><hlendline|><next-line><hlendline|><next-line><hlkwa|let
  ><hlstd|newline ><hlopt|= (><hlesc|'<math|>\\n'><hlstd| <hlopt|\|>
  ><hlstr|"><hlesc|<math|>\\r\\<math|>n><hlstr|"><hlopt|)><hlendline|Regexp
  for end of line.><next-line><hlkwa|let ><hlstd|addr<textunderscore>char
  ><hlopt|= [><hlstr|'a'><hlopt|-><hlstr|'z'><verbatim|
  ><hlstr|'A'><hlopt|-><hlstr|'Z'><verbatim|
  ><hlstr|'0'><hlopt|-><hlstr|'9'><verbatim| ><hlstr|'-'><verbatim|
  ><hlstr|'<textunderscore>'><hlopt|]><hlendline|><next-line><hlkwa|let
  ><hlstd|at<textunderscore>w<textunderscore>symb ><hlopt|=
  ><hlstr|"where"><hlstd| <hlopt|\|> ><hlstr|"WHERE"><hlstd| <hlopt|\|>
  ><hlstr|"at"><hlstd| <hlopt|\|> ><hlstr|"At"><hlstd| <hlopt|\|>
  ><hlstr|"AT"><hlendline|><next-line><hlkwa|let
  ><hlstd|at<textunderscore>nw<textunderscore>symb ><hlopt|=
  ><hlstd|<hlstr|'@'> <hlopt|\|> ><hlstr|"&#x40;"><hlstd| <hlopt|\|>
  ><hlstr|"&#64;"><hlendline|><next-line><hlkwa|let
  ><hlstd|open<textunderscore>symb ><hlopt|= ><hlstr|' '><hlopt|*
  ><hlstr|'('> <hlstr|' '><hlopt|* ><hlopt|\| ><hlstr|'
  '><hlopt|+><hlendline|Demarcate a possible @><next-line><hlkwa|let
  ><hlstd|close<textunderscore>symb ><hlopt|= ><hlstr|' '><hlopt|*
  ><hlstr|')'><verbatim| ><hlstr|' '><hlopt|* ><hlopt|\| ><hlstr|'
  '><hlopt|+><hlendline|or . symbol.><next-line><hlkwa|let
  ><hlstd|at<textunderscore>sep<textunderscore>symb
  ><hlopt|=><hlendline|><next-line><hlstd| \ open<textunderscore>symb?
  at<textunderscore>nw<textunderscore>symb close<textunderscore>symb?
  <hlopt|\|><hlendline|><next-line> \ open<textunderscore>symb
  at<textunderscore>w<textunderscore>symb
  close<textunderscore>symb><hlendline|>

  <new-page*><hlkwa|let ><hlstd|dot<textunderscore>w<textunderscore>symb
  ><hlopt|= ><hlstr|"dot"><hlstd| <hlopt|\|> ><hlstr|"DOT"><hlstd| <hlopt|\|>
  ><hlstr|"dt"><hlstd| <hlopt|\|> ><hlstr|"DT"><hlendline|><next-line><hlkwa|let
  ><hlstd|dom<textunderscore>w<textunderscore>symb ><hlopt|=
  ><hlstd|dot<textunderscore>w<textunderscore>symb <hlopt|\|>
  ><hlstr|"dom"><hlstd| <hlopt|\|> ><hlstr|"DOM"><hlendline|Obfuscation for
  last dot.><next-line><hlkwa|let ><hlstd|dot<textunderscore>sep<textunderscore>symb
  ><hlopt|=><hlendline|><next-line><hlstd| \ open<textunderscore>symb
  dot<textunderscore>w<textunderscore>symb close<textunderscore>symb
  <hlopt|\|><hlendline|><next-line> \ open<textunderscore>symb?
  ><hlstr|'.'><hlstd| close<textunderscore>symb?><hlendline|><next-line><hlkwa|let
  ><hlstd|dom<textunderscore>sep<textunderscore>symb
  ><hlopt|=><hlendline|><next-line><hlstd| \ open<textunderscore>symb
  dom<textunderscore>w<textunderscore>symb close<textunderscore>symb
  <hlopt|\|><hlendline|><next-line> \ open<textunderscore>symb?
  ><hlstr|'.'><hlstd| close<textunderscore>symb?><hlendline|><next-line><hlkwa|let
  ><hlstd|addr<textunderscore>dom ><hlopt|=
  ><verbatim|addr<textunderscore>char addr<textunderscore>char><hlendline|Restricted
  form of last part><next-line><verbatim| \ ><hlopt|\| ><hlstr|"edu"><hlstd|
  <hlopt|\|> ><hlstr|"EDU"><hlstd| <hlopt|\|> ><hlstr|"org"><hlstd|
  <hlopt|\|> ><hlstr|"ORG"><hlstd| <hlopt|\|> ><hlstr|"com"><hlstd|
  <hlopt|\|> ><hlstr|"COM"><hlendline|of address.><next-line><hlendline|><next-line><hlkwa|rule
  ><verbatim|email state ><hlopt|= >parse<hlendline|><next-line><hlopt|\|>
  <verbatim|newline><hlendline|Check state before moving
  on.><verbatim|<next-line> \ \ \ ><hlopt|{ ><hlstd|report state
  lexbuf><hlopt|; ><hlstd|nextline lexbuf><hlopt|;><hlendline|><next-line><hlstd|
  \ \ \ \ \ email ><hlkwd|Seek ><hlstd|lexbuf
  ><hlopt|}><hlendline|<math|\<swarrow\>>Detected possible start of
  address.><next-line><hlopt|\| (><hlstd|addr<textunderscore>char><hlopt|+
  ><hlkwa|as ><hlstd|name><hlopt|) ><hlstd|at<textunderscore>sep<textunderscore>symb
  ><hlopt|(><hlstd|addr<textunderscore>char><hlopt|+ ><hlkwa|as
  ><hlstd|addr><hlopt|)><hlendline|><next-line><hlstd| \ \ \ ><hlopt|{
  ><hlstd|email ><hlopt|(><hlkwd|Addr ><hlopt|(><hlkwa|false><hlopt|,
  ><hlstd|name><hlopt|, [><hlstd|addr><hlopt|])) ><hlstd|lexbuf
  ><hlopt|}><hlendline|>

  <new-page*><hlstd|<hlopt|\|> dom<textunderscore>sep<textunderscore>symb
  ><hlopt|(><hlstd|addr<textunderscore>dom ><hlkwa|as
  ><hlstd|dom><hlopt|)><hlendline|Detected possible finish of
  address.><next-line><hlstd| \ \ \ ><hlopt|{ ><hlkwa|let ><hlstd|state
  ><hlopt|=><hlendline|><next-line><hlstd| \ \ \ \ \ \ \ ><hlkwa|match
  ><hlstd|state ><hlkwa|with><hlendline|><next-line><hlstd|
  \ \ \ \ \ \ \ ><hlopt|\| ><hlkwd|Seek ><hlopt|-\<gtr\>
  ><hlkwd|Seek><hlendline|We weren't looking at an
  address.><next-line><hlstd| \ \ \ \ \ \ \ ><hlopt|\| ><hlkwd|Addr
  ><hlopt|(><hlstd|<textunderscore>><hlopt|, ><hlstd|name><hlopt|,
  ><hlstd|addrs><hlopt|) -\<gtr\>><hlendline|Bingo.><next-line><hlstd|
  \ \ \ \ \ \ \ \ \ ><hlkwd|Addr ><hlopt|(><hlkwa|true><hlopt|,
  ><hlstd|name><hlopt|, ><hlstd|dom><hlopt|::><hlstd|addrs><hlopt|)
  ><hlkwa|in><hlendline|><next-line><hlstd| \ \ \ \ \ email state lexbuf
  ><hlopt|}><hlendline|><next-line><hlstd|<hlopt|\|>
  dot<textunderscore>sep<textunderscore>symb
  ><hlopt|(><hlstd|addr<textunderscore>char><hlopt|+ ><hlkwa|as
  ><hlstd|addr><hlopt|)><hlendline|Next part of address --><next-line><hlstd|
  \ \ \ ><hlopt|{ ><hlkwa|let ><hlstd|state ><hlopt|=><hlendline|must be
  continued.><next-line><hlstd| \ \ \ \ \ \ \ ><hlkwa|match ><hlstd|state
  ><hlkwa|with><hlendline|><next-line><hlstd| \ \ \ \ \ \ \ ><hlopt|\|
  ><hlkwd|Seek ><hlopt|-\<gtr\> ><hlkwd|Seek><hlendline|><next-line><hlstd|
  \ \ \ \ \ \ \ ><hlopt|\| ><hlkwd|Addr ><hlopt|(><hlstd|<textunderscore>><hlopt|,
  ><hlstd|name><hlopt|, ><hlstd|addrs><hlopt|)
  -\<gtr\>><hlendline|><next-line><hlstd| \ \ \ \ \ \ \ \ \ ><hlkwd|Addr
  ><hlopt|(><hlkwa|false><hlopt|, ><hlstd|name><hlopt|,
  ><hlstd|addr><hlopt|::><hlstd|addrs><hlopt|)
  ><hlkwa|in><hlendline|><next-line><hlstd| \ \ \ \ \ email state lexbuf
  ><hlopt|}><hlendline|><next-line><hlopt|\|> <verbatim|eof><hlendline|End of
  file -- end loop.><next-line><verbatim| \ \ \ \ ><hlopt|{ ><hlstd|report
  state lexbuf ><hlopt|}><hlendline|><next-line><hlopt|\|><verbatim|
  <textunderscore>><hlendline|Some boring character -- not looking at an
  address yet.><next-line><verbatim| \ \ \ \ ><hlopt|{ ><hlstd|report state
  lexbuf><hlopt|; ><hlstd|email ><hlkwd|Seek ><hlstd|lexbuf
  ><hlopt|}><hlendline|><next-line><hlendline|><next-line><hlopt|{><hlendline|The
  trailer with OCaml code.><next-line><hlstd| \ ><hlkwa|let
  ><hlstd|<textunderscore> ><hlopt|=><hlendline|Open a file and start mining
  for email addresses.><next-line><hlstd| \ \ \ ><hlkwa|let ><hlstd|ch
  ><hlopt|= ><hlstd|open<textunderscore>in
  ><hlkwc|Sys><hlopt|.><hlstd|argv><hlopt|.(><hlnum|1><hlopt|)
  ><hlkwa|in><hlendline|><next-line><hlstd| \ \ \ email ><hlkwd|Seek
  ><hlopt|(><hlkwc|Lexing><hlopt|.><hlstd|from<textunderscore>channel
  ch><hlopt|);><hlendline|><next-line><hlstd| \ \ \ close<textunderscore>in
  ch><hlendline|Close the file at the end.><next-line><hlopt|}><hlendline|><next-line>

  <subsection|<new-page*>Parsing with Menhir>

  <\itemize>
    <item>The format of parser definitions is as follows: file with extension
    <verbatim|.mly>

    <hlopt|%{ >header <hlopt|%}><hlendline|OCaml code put in
    front.><next-line><hlopt|%><hlstd|parameter ><hlopt|\<less\> ><hlkwd|M
    ><hlopt|: >signature <hlopt|\<gtr\>><hlendline|Parameters make a
    functor.><next-line><hlopt|%><hlstd|token ><hlopt|\<less\> >type1
    <hlopt|\<gtr\> ><hlkwd|Token1 Token2><hlendline|Terminal productions,
    variants><next-line><hlopt|%><hlstd|token ><hlopt|\<less\> >type3
    <hlopt|\<gtr\> ><hlkwd|Token3><hlendline|returned from
    lexer.><next-line><hlopt|%><hlstd|token
    ><hlkwd|NoArgToken><hlendline|Without an argument, e.g. keywords or
    symbols.><next-line><hlopt|%><hlstd|nonassoc
    ><hlkwd|Token1><hlendline|This token cannot be stacked without
    parentheses.><next-line><hlopt|%><hlstd|left
    ><hlkwd|Token3><hlendline|Associates to
    left,><next-line><hlopt|%><hlstd|right ><hlkwd|Token2><hlendline|to
    right.><next-line><hlopt|%><hlkwa|type ><hlopt|\<less\> >type4
    <hlopt|\<gtr\> ><hlstd|rule1><hlendline|Type of the action of the
    rule.><next-line><hlopt|%><hlstd|start ><hlopt|\<less\> >type5
    <hlopt|\<gtr\> ><hlstd|rule2><hlendline|The entry point of the
    grammar.><next-line><hlopt|%%><hlendline|Separate out the rules
    part.><next-line><hlopt|%><hlstd|inline rule1
    ><hlopt|(><hlstd|id1><hlopt|, ..., ><hlstd|inN><hlopt|)
    :><hlendline|Inlined rules can propagate
    priorities.><next-line><verbatim| ><hlopt|\|><verbatim| >production1
    <hlopt|{ ><hlstd|action1 ><hlopt|}><hlendline|If production matches,
    perform action.><verbatim|<next-line> ><hlopt|\|><verbatim| >production2
    <hlopt|\|><verbatim| >production3<hlendline|Several
    productions><verbatim|<next-line> \ \ \ \ ><hlopt|{ >action2<hlopt|
    }><hlendline|with the same action.>

    <new-page*><hlopt|%><hlstd|public rule2 ><hlopt|:><hlendline|Visible in
    other files of the grammar.><next-line><hlopt| \| >production4<hlopt| {
    >action4<hlopt| }><hlendline|><next-line><hlopt|%><hlstd|public rule3
    ><hlopt|:><hlendline|Override precedence of production5 to that of
    productions><next-line><hlopt| \| >production5<hlopt| { >action5<hlopt|
    }><hlstd| ><hlopt|%><hlstd|prec ><hlkwd|Token1><hlendline|ending with
    <hlkwd|Token1>><next-line><hlopt|%%><hlendline|The separations are needed
    even if the sections are empty.><next-line>trailer<hlendline|OCaml code
    put at the end of generated source.>

    <item>Header, actions and trailer are OCaml code.

    <item>Comments are <hlcom|(* ... *)> in OCaml code, <hlcom|/* ... */> or
    <hlcom|// ...> outisde

    <item>Rules can optionally be separated by <hlopt|;>

    <item><hlopt|%><hlstd|parameter >turns the <strong|whole> resulting
    grammar into a functor, multiple parameters are allowed. The parameters
    are visible in <hlopt|%{>...<hlopt|%}>.

    <item>Terminal symbols <hlkwd|Token1> and <hlkwd|Token2> are both
    variants with argument of type type1, called their <em|semantic value>.

    <item><verbatim|rule1>... <verbatim|ruleN> must be lower-case
    identifiers.

    <item>Parameters <verbatim|id1>... <verbatim|idN> can be lower- or
    upper-case.

    <new-page*><item>Priorities, i.e. precedence, are declared implicitly:
    <hlopt|%><hlstd|nonassoc>, <hlopt|%><hlstd|left>, <hlopt|%><hlstd|right>
    list tokens in increasing priority (<hlkwd|Token2> has highest
    precedence).

    <\itemize>
      <item>Higher precedence = a rule is applied even when tokens so far
      could be part of the other rule.

      <item>Precedence of a production comes from its rightmost terminal.

      <item><hlopt|%><hlstd|left>/<hlopt|%><hlstd|right> means left/right
      associativity: the rule will/won't be applied if the ``other'' rule is
      the same production.
    </itemize>

    <item><hlopt|%><hlstd|start> symbols become names of functions exported
    in the <verbatim|.mli> file to invoke the parser. They are automatically
    <hlopt|%><hlstd|public>.

    <item><hlopt|%><hlstd|public> rules can even be defined over multiple
    files, with productions joined by <hlopt|\|>.

    <new-page*><item>The syntax of productions, i.e. patterns, each line
    shows one aspect, they can be combined:

    <verbatim|rule2><hlkwd| Token1 ><verbatim|rule3><hlendline|Match tokens
    in sequence with <hlkwd|Token1> in the
    middle.><next-line>a<hlopt|=><hlstd|rule2
    t><hlopt|=><hlkwd|Token3><hlendline|Name semantic values produced by
    rules/tokens.><next-line><hlstd|rule2><hlopt|;
    ><hlkwd|Token3><hlendline|Parts of pattern can be separated by
    semicolon.><next-line><hlstd|rule1><hlopt|(><hlstd|arg1><hlopt|,...,><hlstd|argN><hlopt|)><hlendline|Use
    a rule that takes arguments.><next-line><verbatim|rule2><hlopt|?><hlendline|Shorthand
    for <hlkwb|option><hlopt|(><hlstd|rule2><hlopt|)>><next-line><verbatim|rule2><hlopt|+><hlendline|Shorthand
    for <hlstd|nonempty<textunderscore>list><hlopt|(><hlstd|rule2><hlopt|)>><next-line><hlstd|rule2><hlopt|*><hlendline|Shorthand
    for <hlstd|list><hlopt|(><hlstd|rule2><hlopt|)>>

    <item>Always-visible ``standard library'' -- most of rules copied below:

    <hlopt|%><hlstd|public ><hlkwb|option><hlopt|(><hlkwd|X><hlopt|):><hlendline|><next-line><hlstd|
    \ ><hlopt|/* ><hlstd|nothing ><hlopt|*/><hlendline|><next-line><hlstd|
    \ \ \ ><hlopt|{ ><hlkwd|None ><hlopt|}><hlendline|><next-line><hlstd|<hlopt|\|>
    x ><hlopt|= ><hlkwd|X><hlendline|><next-line><hlstd| \ \ \ ><hlopt|{
    ><hlkwd|Some ><hlstd|x ><hlopt|}><hlendline|><next-line><hlopt|%><hlstd|public
    ><hlopt|%><hlstd|inline pair><hlopt|(><hlkwd|X><hlopt|,
    ><hlkwd|Y><hlopt|):><hlendline|><next-line><hlstd| \ x ><hlopt|=
    ><hlkwd|X><hlopt|; ><hlstd|y ><hlopt|=
    ><hlkwd|Y><hlendline|><next-line><hlstd| \ \ \ ><hlopt|{
    (><hlstd|x><hlopt|, ><hlstd|y><hlopt|) }><hlendline|>

    <new-page*><hlopt|%><hlstd|public ><hlopt|%><hlstd|inline
    separated<textunderscore>pair><hlopt|(><hlkwd|X><hlopt|,
    ><hlstd|sep><hlopt|, ><hlkwd|Y><hlopt|):><hlendline|><next-line><hlstd|
    \ x ><hlopt|= ><hlkwd|X><hlopt|; ><hlstd|sep><hlopt|; ><hlstd|y ><hlopt|=
    ><hlkwd|Y><hlendline|><next-line><hlstd| \ \ \ ><hlopt|{
    (><hlstd|x><hlopt|, ><hlstd|y><hlopt|)
    }><hlendline|><next-line><hlopt|%><hlstd|public ><hlopt|%><hlstd|inline
    delimited><hlopt|(><hlstd|opening><hlopt|, ><hlkwd|X><hlopt|,
    ><hlstd|closing><hlopt|):><hlendline|><next-line><hlstd|
    \ opening><hlopt|; ><hlstd|x ><hlopt|= ><hlkwd|X><hlopt|;
    ><hlstd|closing<hlendline|><next-line> \ \ \ ><hlopt|{ ><hlstd|x
    ><hlopt|}><hlendline|><next-line><hlopt|%><hlstd|public
    list><hlopt|(><hlkwd|X><hlopt|):><hlendline|><next-line><hlstd|
    \ ><hlopt|/* ><hlstd|nothing ><hlopt|*/><hlendline|><next-line><hlstd|
    \ \ \ ><hlopt|{ [] }><hlendline|><next-line><hlstd|<hlopt|\|> x ><hlopt|=
    ><hlkwd|X><hlopt|; ><hlstd|xs ><hlopt|=
    ><hlstd|list><hlopt|(><hlkwd|X><hlopt|)><hlendline|><next-line><hlstd|
    \ \ \ ><hlopt|{ ><hlstd|x ><hlopt|:: ><hlstd|xs
    ><hlopt|}><hlendline|><next-line><hlopt|%><hlstd|public
    nonempty<textunderscore>list><hlopt|(><hlkwd|X><hlopt|):><hlendline|><next-line><hlstd|
    \ x ><hlopt|= ><hlkwd|X><hlendline|><next-line><hlstd| \ \ \ ><hlopt|{ [
    ><hlstd|x ><hlopt|] }><hlendline|><next-line><hlstd|<hlopt|\|> x
    ><hlopt|= ><hlkwd|X><hlopt|; ><hlstd|xs ><hlopt|=
    ><hlstd|nonempty<textunderscore>list><hlopt|(><hlkwd|X><hlopt|)><hlendline|><next-line><hlstd|
    \ \ \ ><hlopt|{ ><hlstd|x ><hlopt|:: ><hlstd|xs
    ><hlopt|}><hlendline|><next-line><hlopt|%><hlstd|public
    ><hlopt|%><hlstd|inline separated<textunderscore>list><hlopt|(><hlstd|separator><hlopt|,
    ><hlkwd|X><hlopt|):><hlendline|><next-line><hlstd| \ xs ><hlopt|=
    ><hlstd|loption><hlopt|(><hlstd|separated<textunderscore>nonempty<textunderscore>list><hlopt|(><hlstd|separator><hlopt|,
    ><hlkwd|X><hlopt|))><hlendline|><next-line><hlstd| \ \ \ ><hlopt|{
    ><hlstd|xs ><hlopt|}><hlendline|>

    <new-page*><hlopt|%><hlstd|public separated<textunderscore>nonempty<textunderscore>list><hlopt|(><hlstd|separator><hlopt|,
    ><hlkwd|X><hlopt|):><hlendline|><next-line><hlstd| \ x ><hlopt|=
    ><hlkwd|X><hlendline|><next-line><hlstd| \ \ \ ><hlopt|{ [ ><hlstd|x
    ><hlopt|] }><hlendline|><next-line><hlstd|<hlopt|\|> x ><hlopt|=
    ><hlkwd|X><hlopt|; ><hlstd|separator><hlopt|; ><hlstd|xs ><hlopt|=
    ><hlstd|separated<textunderscore>nonempty<textunderscore>list><hlopt|(><hlstd|separator><hlopt|,
    ><hlkwd|X><hlopt|)><hlendline|><next-line><hlstd| \ \ \ ><hlopt|{
    ><hlstd|x ><hlopt|:: ><hlstd|xs ><hlopt|}><hlendline|>

    <item>Only <em|left-recursive> rules are truly tail-recursive, as in:

    <hlstd|declarations><hlopt|:><hlendline|><next-line><hlopt|\| { []
    }><hlendline|><next-line><hlstd|<hlopt|\|> ds ><hlopt|=
    ><hlstd|declarations><hlopt|; ><hlkwb|option><hlopt|(><hlkwd|COMMA><hlopt|);><hlendline|><next-line><hlstd|
    \ d ><hlopt|= ><hlstd|declaration ><hlopt|{ ><hlstd|d ><hlopt|::
    ><hlstd|ds ><hlopt|}><hlendline|>

    <\itemize>
      <item>This is opposite to code expressions (or <em|recursive descent
      parsers>), i.e. if both OK, first rather than last invocation should be
      recursive.
    </itemize>

    <new-page*><item>Invocations can be nested in arguments, e.g.:

    <hlstd|plist><hlopt|(><hlkwd|X><hlopt|):><hlendline|><next-line><hlstd|<hlopt|\|>
    xs ><hlopt|= ><hlstd|loption><hlopt|(><hlendline|Like <verbatim|option>,
    but returns a list.><next-line><hlstd|
    \ delimited><hlopt|(><hlkwd|LPAREN><hlopt|,><hlendline|><next-line><hlstd|
    \ \ \ \ \ \ \ \ \ \ \ separated<textunderscore>nonempty<textunderscore>list><hlopt|(><hlkwd|COMMA><hlopt|,
    ><hlkwd|X><hlopt|),><hlendline|><next-line><hlstd|
    \ \ \ \ \ \ \ \ \ \ \ ><hlkwd|RPAREN><hlopt|)) { ><hlstd|xs
    ><hlopt|}><hlendline|>

    <item>Higher-order parameters are allowed.

    <hlstd|procedure><hlopt|(><hlstd|list><hlopt|):><hlendline|><next-line><hlopt|\|
    ><hlkwd|PROCEDURE ID ><hlstd|list><hlopt|(><hlstd|formal><hlopt|)
    ><hlkwd|SEMICOLON ><hlstd|block ><hlkwd|SEMICOLON ><hlopt|{>...<hlopt|}>

    <new-page*><item>Example where inlining is required (besides being an
    optimization)

    <hlopt|%><hlstd|token ><hlopt|\<less\> ><hlkwb|int ><hlopt|\<gtr\>
    ><hlkwd|INT><hlendline|><next-line><hlopt|%><hlstd|token ><hlkwd|PLUS
    TIMES><hlendline|><next-line><hlopt|%><hlstd|left
    ><hlkwd|PLUS><hlendline|><next-line><hlopt|%><hlstd|left
    ><hlkwd|TIMES><hlendline|Multiplication has higher
    priority.><next-line><hlopt|%%><hlendline|><next-line><hlstd|expression><hlopt|:><hlendline|><next-line><hlstd|<hlopt|\|>
    i ><hlopt|= ><hlkwd|INT ><hlopt|{ ><hlstd|i
    ><hlopt|}><hlendline|<math|\<swarrow\>> Without inlining, would not
    distinguish priorities.><next-line><hlstd|<hlopt|\|> e ><hlopt|=
    ><hlstd|expression><hlopt|; ><hlstd|o ><hlopt|= ><hlstd|op><hlopt|;
    ><hlstd|f ><hlopt|= ><hlstd|expression ><hlopt|{ ><hlstd|o e f
    ><hlopt|}><hlendline|><next-line><hlopt|%><hlstd|inline
    op><hlopt|:><hlendline|Inline operator -- generate corresponding
    rules.><next-line><hlopt|\| ><hlkwd|PLUS ><hlopt|{ ( + )
    }><hlendline|><next-line><hlopt|\| ><hlkwd|TIMES ><hlopt|{ ( * )
    }><hlendline|>

    <new-page*><item>Menhir is an <math|LR<around*|(|1|)>> parser generator,
    i.e. it fails for grammars where looking one token ahead, together with
    precedences, is insufficient to determine whether a rule applies.

    <\itemize>
      <item>In particular, only unambiguous grammars.
    </itemize>

    <item>Although <math|LR<around*|(|1|)>> grammars are a small subset of
    <em|context free grammars>, the semantic actions can depend on context:
    actions can be functions that take some form of context as input.

    <item>Positions are available in actions via keywords
    <hlopt|$><verbatim|startpos><hlopt|(><verbatim|x><hlopt|)> and
    <hlopt|$><verbatim|endpos><hlopt|(><verbatim|x><hlopt|)> where
    <verbatim|x> is name given to part of pattern.

    <\itemize>
      <item>Do not use the <hlkwc|Parsing> module from OCaml standard
      library.
    </itemize>
  </itemize>

  <subsubsection|<new-page*>Example: parsing arithmetic expressions>

  <\itemize>
    <item>Example based on a Menhir demo. Due to difficulties with
    <verbatim|ocamlbuild>, we use option <verbatim|--external-tokens> to
    provide <hlkwa|type ><hlstd|token> directly rather than having it
    generated.

    <item>File <verbatim|lexer.mll>:

    <hlopt|{><hlendline|><next-line><hlstd| \ ><hlkwa|type ><hlstd|token
    ><hlopt|= ><hlendline|><next-line><hlstd| \ \ \ ><hlopt|\|
    ><hlkwd|TIMES><hlendline|><next-line><hlstd| \ \ \ ><hlopt|\|
    ><hlkwd|RPAREN><hlendline|><next-line><hlstd| \ \ \ ><hlopt|\|
    ><hlkwd|PLUS><hlendline|><next-line><hlstd| \ \ \ ><hlopt|\|
    ><hlkwd|MINUS><hlendline|><next-line><hlstd| \ \ \ ><hlopt|\|
    ><hlkwd|LPAREN><hlendline|><next-line><hlstd| \ \ \ ><hlopt|\|
    ><hlkwd|INT ><hlkwa|of ><hlopt|(><hlkwb|int><hlopt|)><hlendline|><next-line><hlstd|
    \ \ \ ><hlopt|\| ><hlkwd|EOL><hlendline|><next-line><hlstd|
    \ \ \ ><hlopt|\| ><hlkwd|DIV><hlendline|><next-line><hlstd|
    \ ><hlkwa|exception ><hlkwd|Error ><hlkwa|of
    ><hlkwb|string><hlendline|><next-line><hlopt|}><hlendline|>

    <new-page*><hlstd|rule line ><hlopt|=
    ><hlstd|parse<hlendline|><next-line><hlopt|\|>
    ><hlopt|([><hlstd|<textasciicircum>'><hlesc|<math|>n><hlstd|'><hlopt|]*
    ><hlstd|'><hlesc|<math|>n><hlstd|'><hlopt|) ><hlkwa|as ><hlstd|line
    ><hlopt|{ ><hlstd|line ><hlopt|}><hlendline|><next-line><hlstd|<hlopt|\|>
    eof \ ><hlopt|{ ><hlstd|exit ><hlnum|0
    ><hlopt|}><hlendline|><next-line><hlkwa|and ><hlstd|token ><hlopt|=
    ><hlstd|parse<hlendline|><next-line><hlopt|\|> ><hlopt|[><hlstd|' '
    '><hlesc|<math|>t><hlstd|'><hlopt|]><hlstd| \ \ \ \ \ ><hlopt|{
    ><hlstd|token lexbuf ><hlopt|}><hlendline|><next-line><hlstd|<hlopt|\|>
    '><hlesc|<math|>n><hlstd|' ><hlopt|{ ><hlkwd|EOL
    ><hlopt|}><hlendline|><next-line><hlopt|\|
    [><hlstd|'><hlnum|0><hlstd|'><hlopt|-><hlstd|'><hlnum|9><hlstd|'><hlopt|]+
    ><hlkwa|as ><hlstd|i ><hlopt|{ ><hlkwd|INT
    ><hlopt|(><hlstd|int<textunderscore>of<textunderscore>string i><hlopt|)
    }><hlendline|><next-line><hlstd|<hlopt|\|> '><hlopt|+><hlstd|'
    \ ><hlopt|{ ><hlkwd|PLUS ><hlopt|}><hlendline|><next-line><hlstd|<hlopt|\|>
    '><hlopt|-><hlstd|' \ ><hlopt|{ ><hlkwd|MINUS
    ><hlopt|}><hlendline|><next-line><hlstd|<hlopt|\|> '><hlopt|*><hlstd|'
    \ ><hlopt|{ ><hlkwd|TIMES ><hlopt|}><hlendline|><next-line><hlstd|<hlopt|\|>
    '><hlopt|/><hlstd|' \ ><hlopt|{ ><hlkwd|DIV
    ><hlopt|}><hlendline|><next-line><hlstd|<hlopt|\|> '><hlopt|(><hlstd|'
    \ ><hlopt|{ ><hlkwd|LPAREN ><hlopt|}><hlendline|><next-line><hlstd|<hlopt|\|>
    '><hlopt|)><hlstd|' \ ><hlopt|{ ><hlkwd|RPAREN
    ><hlopt|}><hlendline|><next-line><hlstd|<hlopt|\|> eof \ ><hlopt|{
    ><hlstd|exit ><hlnum|0 ><hlopt|}><hlendline|><next-line><hlstd|<hlopt|\|>
    <textunderscore> \ \ \ ><hlopt|{ ><hlstd|raise ><hlopt|(><hlkwd|Error
    ><hlopt|(><hlkwc|Printf><hlopt|.><hlstd|sprintf ><hlstr|"At offset %d:
    unexpected character.><hlesc|<math|>n><hlstr|"><hlstd|
    ><hlopt|(><hlkwc|Lexing><hlopt|.><hlstd|lexeme<textunderscore>start
    lexbuf><hlopt|))) }><hlendline|>

    <new-page*><item>File <verbatim|parser.mly>:

    <hlopt|%><hlstd|token ><hlopt|\<less\>><hlkwb|int><hlopt|\<gtr\>
    ><hlkwd|INT><hlendline|We still need to define
    tokens,><next-line><hlopt|%><hlstd|token ><hlkwd|PLUS MINUS TIMES
    DIV><hlendline|Menhir does its own checks.><next-line><hlopt|%><hlstd|token
    ><hlkwd|LPAREN RPAREN><hlendline|><next-line><hlopt|%><hlstd|token
    ><hlkwd|EOL><hlendline|><next-line><hlopt|%><hlstd|left ><hlkwd|PLUS
    MINUS><hlstd| \ \ \ \ \ \ \ ><hlopt|/* ><hlstd|lowest precedence
    ><hlopt|*/><hlendline|><next-line><hlopt|%><hlstd|left ><hlkwd|TIMES
    DIV><hlstd| \ \ \ \ \ \ \ \ ><hlopt|/* ><hlstd|medium precedence
    ><hlopt|*/><hlendline|><next-line><hlopt|%><hlstd|nonassoc
    ><hlkwd|UMINUS><hlstd| \ \ \ \ \ \ \ ><hlopt|/* ><hlstd|highest
    precedence ><hlopt|*/><hlendline|><next-line><hlopt|%><hlstd|parameter><hlopt|\<less\>><hlkwd|Semantics
    ><hlopt|: ><hlkwa|sig><hlendline|><next-line><hlstd| \ ><hlkwa|type
    ><hlstd|number<hlendline|><next-line> \ ><hlkwa|val
    ><hlstd|inject><hlopt|: ><hlkwb|int ><hlopt|-\<gtr\>
    ><hlstd|number<hlendline|><next-line> \ ><hlkwa|val ><hlopt|( + ):
    ><hlstd|number ><hlopt|-\<gtr\> ><hlstd|number ><hlopt|-\<gtr\>
    ><hlstd|number<hlendline|><next-line> \ ><hlkwa|val ><hlopt|( - ):
    ><hlstd|number ><hlopt|-\<gtr\> ><hlstd|number ><hlopt|-\<gtr\>
    ><hlstd|number<hlendline|><next-line> \ ><hlkwa|val ><hlopt|( * ):
    ><hlstd|number ><hlopt|-\<gtr\> ><hlstd|number ><hlopt|-\<gtr\>
    ><hlstd|number<hlendline|><next-line> \ ><hlkwa|val ><hlopt|( / ):
    ><hlstd|number ><hlopt|-\<gtr\> ><hlstd|number ><hlopt|-\<gtr\>
    ><hlstd|number<hlendline|><next-line> \ ><hlkwa|val ><hlopt|(
    ><hlstd|<math|\<sim\>>><hlopt|-): ><hlstd|number ><hlopt|-\<gtr\>
    ><hlstd|number><hlendline|><next-line><hlkwa|end><hlopt|\<gtr\>><hlendline|><next-line><hlopt|%><hlstd|start
    ><hlopt|\<less\>><hlkwc|Semantics><hlopt|.><hlstd|number><hlopt|\<gtr\>
    ><hlstd|main><hlendline|><next-line><hlopt|%{ ><hlkwa|open
    ><hlkwd|Semantics ><hlopt|%}><hlendline|>

    <new-page*><hlopt|%%><hlendline|><next-line><hlstd|main><hlopt|:><hlendline|><next-line><hlstd|<hlopt|\|>
    e ><hlopt|= ><hlstd|expr ><hlkwd|EOL><hlstd| \ \ ><hlopt|{ ><hlstd|e
    ><hlopt|}><hlendline|><next-line><hlstd|expr><hlopt|:><hlendline|><next-line><hlstd|<hlopt|\|>
    i ><hlopt|= ><hlkwd|INT><hlstd| \ \ \ \ ><hlopt|{ ><hlstd|inject i
    ><hlopt|}><hlendline|><next-line><hlopt|\| ><hlkwd|LPAREN ><hlstd|e
    ><hlopt|= ><hlstd|expr ><hlkwd|RPAREN><hlstd| \ \ \ ><hlopt|{ ><hlstd|e
    ><hlopt|}><hlendline|><next-line><hlstd|<hlopt|\|> e1 ><hlopt|=
    ><hlstd|expr ><hlkwd|PLUS ><hlstd|e2 ><hlopt|= ><hlstd|expr \ ><hlopt|{
    ><hlstd|e1 ><hlopt|+ ><hlstd|e2 ><hlopt|}><hlendline|><next-line><hlstd|<hlopt|\|>
    e1 ><hlopt|= ><hlstd|expr ><hlkwd|MINUS ><hlstd|e2 ><hlopt|= ><hlstd|expr
    ><hlopt|{ ><hlstd|e1 ><hlopt|- ><hlstd|e2
    ><hlopt|}><hlendline|><next-line><hlstd|<hlopt|\|> e1 ><hlopt|=
    ><hlstd|expr ><hlkwd|TIMES ><hlstd|e2 ><hlopt|= ><hlstd|expr ><hlopt|{
    ><hlstd|e1 ><hlopt|* ><hlstd|e2 ><hlopt|}><hlendline|><next-line><hlstd|<hlopt|\|>
    e1 ><hlopt|= ><hlstd|expr ><hlkwd|DIV ><hlstd|e2 ><hlopt|= ><hlstd|expr
    \ \ ><hlopt|{ ><hlstd|e1 ><hlopt|/ ><hlstd|e2
    ><hlopt|}><hlendline|><next-line><hlopt|\| ><hlkwd|MINUS ><hlstd|e
    ><hlopt|= ><hlstd|expr ><hlopt|%><hlstd|prec ><hlkwd|UMINUS ><hlopt|{ -
    ><hlstd|e ><hlopt|}><hlendline|>

    <new-page*><item>File <verbatim|calc.ml>:

    <hlkwa|module ><hlkwd|FloatSemantics ><hlopt|=
    ><hlkwa|struct><hlendline|><next-line><hlstd| \ ><hlkwa|type
    ><hlstd|number ><hlopt|= ><hlkwb|float><hlendline|><next-line><hlstd|
    \ ><hlkwa|let ><hlstd|inject ><hlopt|=
    ><hlstd|float<textunderscore>of<textunderscore>int<hlendline|><next-line>
    \ ><hlkwa|let ><hlopt|( + ) = ( +. )><hlendline|><next-line><hlstd|
    \ ><hlkwa|let ><hlopt|( - ) = ( -. )><hlendline|><next-line><hlstd|
    \ ><hlkwa|let ><hlopt|( * ) = ( *. )><hlendline|><next-line><hlstd|
    \ ><hlkwa|let ><hlopt|( / ) = ( /. )><hlendline|><next-line><hlstd|
    \ ><hlkwa|let ><hlopt|(><hlstd|<math|\<sim\>>><hlopt|- ) =
    (><hlstd|<math|\<sim\>>><hlopt|-. )><hlendline|><next-line><hlkwa|end><hlendline|><next-line><hlkwa|module
    ><hlkwd|FloatParser ><hlopt|= ><hlkwc|Parser><hlopt|.><hlkwd|Make><hlopt|(><hlkwd|FloatSemantics><hlopt|)><hlendline|>

    <new-page*><hlkwa|let ><hlopt|() =><hlendline|><next-line><hlstd|
    \ ><hlkwa|let ><hlstd|stdinbuf ><hlopt|=
    ><hlkwc|Lexing><hlopt|.><hlstd|from<textunderscore>channel stdin
    ><hlkwa|in><hlendline|><next-line><hlstd| \ ><hlkwa|while true
    do><hlendline|><next-line><hlstd| \ \ \ ><hlkwa|let ><hlstd|linebuf
    ><hlopt|=><hlendline|><next-line><hlstd|
    \ \ \ \ \ ><hlkwc|Lexing><hlopt|.><hlstd|from<textunderscore>string
    ><hlopt|(><hlkwc|Lexer><hlopt|.><hlstd|line stdinbuf><hlopt|)
    ><hlkwa|in><hlendline|><next-line><hlstd|
    \ \ \ ><hlkwa|try><hlendline|><next-line><hlstd|
    \ \ \ \ \ ><hlkwc|Printf><hlopt|.><hlstd|printf
    ><hlstr|"%.1f><hlesc|<math|>n><hlstr|%!"><hlstd|<hlendline|><next-line>
    \ \ \ \ \ \ \ ><hlopt|(><hlkwc|FloatParser><hlopt|.><hlstd|main
    ><hlkwc|Lexer><hlopt|.><hlstd|token linebuf><hlopt|)><hlendline|><next-line><hlstd|
    \ \ \ ><hlkwa|with><hlendline|><next-line><hlstd| \ \ \ ><hlopt|\|
    ><hlkwc|Lexer><hlopt|.><hlkwd|Error ><hlstd|msg
    ><hlopt|-\<gtr\>><hlendline|><next-line><hlstd| ><hlkwc|
    \ \ \ \ Printf><hlopt|.><hlstd|fprintf stderr ><hlstr|"%s%!"><hlstd|
    msg<hlendline|><next-line> \ \ \ ><hlopt|\|
    ><hlkwc|FloatParser><hlopt|.><hlkwd|Error
    ><hlopt|-\<gtr\>><hlendline|><next-line><hlstd| ><hlkwc|
    \ \ \ \ Printf><hlopt|.><hlstd|fprintf stderr ><next-line><hlstr|
    \ \ \ \ \ \ \ "At offset %d: syntax error.><hlesc|<math|>n><hlstr|%!"><hlstd|<hlendline|><next-line>
    \ \ \ \ \ \ \ ><hlopt|(><hlkwc|Lexing><hlopt|.><hlstd|lexeme<textunderscore>start
    linebuf><hlopt|)><hlendline|><next-line><hlstd|
    \ ><hlkwa|done><hlendline|>

    <new-page*><item>Build and run command:

    <\verbatim>
      ocamlbuild calc.native -use-menhir -menhir "menhir parser.mly --base
      parser --external-tokens Lexer" --
    </verbatim>

    <\itemize>
      <item>Other grammar files can be provided besides <verbatim|parser.mly>

      <item><verbatim|--base> gives the file (without extension) which will
      become the module accessed from OCaml

      <item><verbatim|--external-tokens> provides the OCaml module which
      defines the <verbatim|token> type
    </itemize>
  </itemize>

  <subsubsection|<new-page*>Example: a toy sentence grammar>

  <\itemize>
    <item>Our lexer is a simple limited <em|part-of-speech tagger>. Not
    re-entrant.

    <item>For debugging, we log execution in file <verbatim|log.txt>.

    <item>File <verbatim|EngLexer.mll>:
  </itemize>

  <hlopt|{><hlendline|><next-line><hlstd| ><hlkwa|type ><hlstd|sentence
  ><hlopt|= {><hlendline|Could be in any module visible to
  <hlkwc|EngParser>.><next-line><hlstd| \ \ subject ><hlopt|:
  ><hlkwb|string><hlopt|;><hlendline|The actor/actors, i.e. subject
  noun.><next-line><hlstd| \ \ action ><hlopt|:
  ><hlkwb|string><hlopt|;><hlendline|The action, i.e.
  verb.><next-line><hlstd| \ \ plural ><hlopt|:
  ><hlkwb|bool><hlopt|;><hlendline|Whether one or multiple
  actors.><next-line><hlstd| \ \ adjs ><hlopt|: ><hlkwb|string
  ><hlstd|list><hlopt|;><hlendline|Characteristics of
  actor.><next-line><hlstd| \ \ advs ><hlopt|: ><hlkwb|string
  ><verbatim|list><hlendline|Characteristics of action.><next-line>
  <hlopt|}><hlendline|>

  <new-page*><hlstd| ><hlkwa|type ><hlstd|token
  ><hlopt|=><hlendline|><next-line><hlstd| <hlopt|\|> ><hlkwd|VERB ><hlkwa|of
  ><hlkwb|string><hlendline|><next-line><hlstd| <hlopt|\|> ><hlkwd|NOUN
  ><hlkwa|of ><hlkwb|string><hlendline|><next-line><hlstd| <hlopt|\|>
  ><hlkwd|ADJ ><hlkwa|of ><hlkwb|string><hlendline|><next-line><hlstd|
  <hlopt|\|> ><hlkwd|ADV ><hlkwa|of ><hlkwb|string><hlendline|><next-line><hlstd|
  <hlopt|\|> ><hlkwd|PLURAL ><hlopt|\| ><hlkwd|SINGULAR><hlendline|><next-line><hlstd|
  <hlopt|\|> ><hlkwd|A<textunderscore>DET ><hlopt|\|
  ><hlkwd|THE<textunderscore>DET ><hlopt|\| ><hlkwd|SOME<textunderscore>DET
  ><hlopt|\| ><hlkwd|THIS<textunderscore>DET ><hlopt|\|
  ><hlkwd|THAT<textunderscore>DET><hlendline|><next-line><hlstd| <hlopt|\|>
  ><hlkwd|THESE<textunderscore>DET ><hlopt|\|
  ><hlkwd|THOSE<textunderscore>DET><hlendline|><next-line><hlstd| <hlopt|\|>
  ><hlkwd|COMMA<textunderscore>CNJ ><hlopt|\| ><hlkwd|AND<textunderscore>CNJ
  ><hlopt|\| ><hlkwd|DOT<textunderscore>PUNCT><hlendline|><next-line><hlstd|
  ><hlkwa|let ><hlstd|tok<textunderscore>str ><hlopt|= ><hlkwa|function
  >...<hlendline|Print the token.><next-line><hlstd| ><hlkwa|let
  ><hlstd|adjectives ><hlopt|=><hlendline|Recognized
  adjectives.><next-line><hlstd| \ \ ><hlopt|[><hlstr|"smart"><hlopt|;
  ><hlstr|"extreme"><hlopt|; ><hlstr|"green"><hlopt|; ><hlstr|"slow"><hlopt|;
  ><hlstr|"old"><hlopt|; ><hlstr|"incredible"><hlopt|;><next-line><hlstd|
  \ \ \ ><hlstr|"quiet"><hlopt|; ><hlstr|"diligent"><hlopt|;
  ><hlstr|"mellow"><hlopt|; ><hlstr|"new"><hlopt|]><hlendline|><next-line><hlstd|
  ><hlkwa|let ><hlstd|log<textunderscore>file ><hlopt|=
  ><hlstd|open<textunderscore>out ><hlstr|"log.txt"><hlendline|File with
  debugging information.><next-line><verbatim| ><hlkwa|let ><hlstd|log s
  ><hlopt|= ><hlkwc|Printf><hlopt|.><hlstd|fprintf log<textunderscore>file
  ><hlstr|"%s><hlesc|<math|>n><hlstr|%!"><hlstd| s<hlendline|><next-line>
  ><hlkwa|let ><hlstd|last<textunderscore>tok ><hlopt|= ><hlkwb|ref
  ><hlkwd|DOT<textunderscore>PUNCT><hlendline|State for better tagging.>

  <new-page*><hlstd| ><hlkwa|let ><hlstd|tokbuf ><hlopt|=
  ><hlkwc|Queue><hlopt|.><hlstd|create ><hlopt|()><hlendline|Token buffer,
  since single word><next-line><hlstd| ><hlkwa|let ><hlstd|push w
  ><hlopt|=><hlendline|is sometimes two tokens.><next-line><hlstd| \ \ log
  ><hlopt|(><hlstr|"lex: "><hlstd|<textasciicircum>tok<textunderscore>str
  w><hlopt|);><hlendline|Log lexed token.><next-line><hlstd|
  \ \ last<textunderscore>tok ><hlopt|:= ><hlstd|w><hlopt|;
  ><hlkwc|Queue><hlopt|.><hlstd|push w tokbuf<hlendline|><next-line>
  ><hlkwa|exception ><hlkwd|LexError ><hlkwa|of
  ><hlkwb|string><hlendline|><next-line><hlopt|}><hlendline|><next-line><hlkwa|let
  ><hlstd|alphanum ><hlopt|= [><hlstd|'><hlnum|0><hlstd|'><hlopt|-><hlstd|'><hlnum|9><hlstd|'
  'a'><hlopt|-><hlstd|'z' '><hlkwd|A'><hlopt|-><hlstd|'><hlkwd|Z' ><hlstd|'''
  '><hlopt|-><hlstd|'><hlopt|]><hlendline|><next-line><hlstd|rule line
  ><hlopt|= ><hlkwa|parse><hlendline|For line-based
  interface.><next-line><hlopt|\|> <hlopt|([><hlstd|<textasciicircum>'><hlesc|<math|>\\n><hlstd|'><hlopt|]*
  ><hlstd|'><hlesc|\\<math|>n><hlstd|'><hlopt|) ><hlkwa|as ><hlstd|l
  ><hlopt|{ ><hlstd|l ><hlopt|}><hlendline|><next-line><hlstd|<hlopt|\|> eof
  ><hlopt|{ ><hlstd|exit ><hlnum|0 ><hlopt|}><hlendline|><next-line><hlkwa|and
  ><hlstd|lex<textunderscore>word ><hlopt|=
  ><hlstd|parse<hlendline|><next-line><hlopt|\|> ><hlopt|[><hlstd|' '
  '><hlesc|<math|>\\t><hlstd|'><hlopt|]><hlendline|Skip
  whitespace.><next-line><hlstd| \ \ \ ><hlopt|{
  ><hlstd|lex<textunderscore>word lexbuf ><hlopt|}><hlendline|><next-line><hlstd|<hlopt|\|>
  '><hlopt|.><hlstd|' ><hlopt|{ ><hlstd|push ><hlkwd|DOT<textunderscore>PUNCT
  ><hlopt|}><hlendline|End of sentence.><next-line><hlopt|\|
  ><hlstr|"a"><hlstd| ><hlopt|{ ><hlstd|push ><hlkwd|A<textunderscore>DET
  ><hlopt|} \| ><hlstr|"the"><hlstd| ><hlopt|{ ><hlstd|push
  ><hlkwd|THE<textunderscore>DET ><hlopt|}><hlendline|``Keywords''.><next-line><hlopt|\|
  ><hlstr|"some"><hlstd| ><hlopt|{ ><hlstd|push
  ><hlkwd|SOME<textunderscore>DET ><hlopt|}><hlendline|><next-line><hlopt|\|
  ><hlstr|"this"><hlstd| ><hlopt|{ ><hlstd|push
  ><hlkwd|THIS<textunderscore>DET ><hlopt|} \| ><hlstr|"that"><hlstd|
  ><hlopt|{ ><hlstd|push ><hlkwd|THAT<textunderscore>DET
  ><hlopt|}><hlendline|><next-line><hlopt|\| ><hlstr|"these"><hlstd|
  ><hlopt|{ ><hlstd|push ><hlkwd|THESE<textunderscore>DET ><hlopt|} \|
  ><hlstr|"those"><hlstd| ><hlopt|{ ><hlstd|push
  ><hlkwd|THOSE<textunderscore>DET ><hlopt|}><hlendline|><next-line><hlopt|\|
  ><hlstr|"A"><hlstd| ><hlopt|{ ><hlstd|push ><hlkwd|A<textunderscore>DET
  ><hlopt|} \| ><hlstr|"The"><hlstd| ><hlopt|{ ><hlstd|push
  ><hlkwd|THE<textunderscore>DET ><hlopt|}><hlendline|><next-line><hlopt|\|
  ><hlstr|"Some"><hlstd| ><hlopt|{ ><hlstd|push
  ><hlkwd|SOME<textunderscore>DET ><hlopt|}><hlendline|><next-line><hlopt|\|
  ><hlstr|"This"><hlstd| ><hlopt|{ ><hlstd|push
  ><hlkwd|THIS<textunderscore>DET ><hlopt|} \| ><hlstr|"That"><hlstd|
  ><hlopt|{ ><hlstd|push ><hlkwd|THAT<textunderscore>DET
  ><hlopt|}><hlendline|><next-line><hlopt|\| ><hlstr|"These"><hlstd|
  ><hlopt|{ ><hlstd|push ><hlkwd|THESE<textunderscore>DET ><hlopt|} \|
  ><hlstr|"Those"><hlstd| ><hlopt|{ ><hlstd|push
  ><hlkwd|THOSE<textunderscore>DET ><hlopt|}><hlendline|><next-line><hlopt|\|
  ><hlstr|"and"><hlstd| ><hlopt|{ ><hlstd|push ><hlkwd|AND<textunderscore>CNJ
  ><hlopt|}><hlendline|><next-line><hlstd|<hlopt|\|> '><hlopt|,><hlstd|'
  ><hlopt|{ ><hlstd|push ><hlkwd|COMMA<textunderscore>CNJ
  ><hlopt|}><hlendline|><next-line><hlopt|\| (><hlstd|alphanum><hlopt|+
  ><hlkwa|as ><hlstd|w><hlopt|) ><hlstr|"ly"><hlendline|Adverb is adjective
  that ends in ``ly''.><next-line><verbatim|
  \ \ \ ><hlopt|{><hlendline|><next-line><hlstd| \ \ \ \ \ ><hlkwa|if
  ><hlkwc|List><hlopt|.><hlstd|mem w adjectives<hlendline|><next-line>
  \ \ \ \ \ ><hlkwa|then ><hlstd|push ><hlopt|(><hlkwd|ADV
  ><hlstd|w><hlopt|)><hlendline|><next-line><hlstd| \ \ \ \ \ ><hlkwa|else if
  ><hlkwc|List><hlopt|.><hlstd|mem ><hlopt|(><hlstd|w<textasciicircum>><hlstr|"le"><hlopt|)
  ><hlstd|adjectives<hlendline|><next-line> \ \ \ \ \ ><hlkwa|then
  ><hlstd|push ><hlopt|(><hlkwd|ADV ><hlopt|(><hlstd|w<textasciicircum>><hlstr|"le"><hlopt|))><hlendline|><next-line><hlstd|
  \ \ \ \ \ ><hlkwa|else ><hlopt|(><hlstd|push ><hlopt|(><hlkwd|NOUN
  ><hlstd|w><hlopt|); ><hlstd|push ><hlkwd|SINGULAR><hlopt|)><hlendline|><next-line><hlstd|
  \ \ \ ><hlopt|}><hlendline|>

  <new-page*><hlopt|\| (><hlstd|alphanum><hlopt|+ ><hlkwa|as
  ><hlstd|w><hlopt|) ><hlstr|"s"><hlendline|Plural noun or singular
  verb.><next-line><verbatim| \ \ \ ><hlopt|{><hlendline|><next-line><hlstd|
  \ \ \ \ \ ><hlkwa|if ><hlkwc|List><hlopt|.><hlstd|mem w adjectives
  ><hlkwa|then ><hlstd|push ><hlopt|(><hlkwd|ADJ
  ><hlstd|w><hlopt|)><hlendline|><next-line><hlstd| \ \ \ \ \ ><hlkwa|else
  match ><hlopt|!><hlstd|last<textunderscore>tok
  ><hlkwa|with><hlendline|><next-line><hlstd| \ \ \ \ \ ><hlopt|\|
  ><hlkwd|THE<textunderscore>DET ><hlopt|\| ><hlkwd|SOME<textunderscore>DET
  ><hlopt|\| ><hlkwd|THESE<textunderscore>DET ><hlopt|\|
  ><hlkwd|THOSE<textunderscore>DET><hlendline|><next-line><hlstd|
  \ \ \ \ \ ><hlopt|\| ><hlkwd|DOT<textunderscore>PUNCT ><hlopt|\|
  ><hlkwd|ADJ ><hlstd|<textunderscore> ><hlopt|-\<gtr\>><hlendline|><next-line><hlstd|
  \ \ \ \ \ \ \ push ><hlopt|(><hlkwd|NOUN ><hlstd|w><hlopt|); ><hlstd|push
  ><hlkwd|PLURAL><hlendline|><next-line><hlstd| \ \ \ \ \ <hlopt|\|>
  <textunderscore> ><hlopt|-\<gtr\> ><hlstd|push ><hlopt|(><hlkwd|VERB
  ><hlstd|w><hlopt|); ><hlstd|push ><hlkwd|SINGULAR><hlendline|><next-line><hlstd|
  \ \ \ ><hlopt|}><hlendline|><next-line><hlstd|<hlopt|\|> alphanum><hlopt|+
  ><hlkwa|as ><verbatim|w><hlendline|Noun contexts vs. verb
  contexts.><next-line><verbatim| \ \ \ ><hlopt|{><hlendline|><next-line><hlstd|
  \ \ \ \ \ ><hlkwa|if ><hlkwc|List><hlopt|.><hlstd|mem w adjectives
  ><hlkwa|then ><hlstd|push ><hlopt|(><hlkwd|ADJ
  ><hlstd|w><hlopt|)><hlendline|><next-line><hlstd| \ \ \ \ \ ><hlkwa|else
  match ><hlopt|!><hlstd|last<textunderscore>tok
  ><hlkwa|with><hlendline|><next-line><hlstd| \ \ \ \ \ ><hlopt|\|
  ><hlkwd|A<textunderscore>DET ><hlopt|\| ><hlkwd|THE<textunderscore>DET
  ><hlopt|\| ><hlkwd|SOME<textunderscore>DET ><hlopt|\|
  ><hlkwd|THIS<textunderscore>DET ><hlopt|\|
  ><hlkwd|THAT<textunderscore>DET><hlendline|><next-line><hlstd|
  \ \ \ \ \ ><hlopt|\| ><hlkwd|DOT<textunderscore>PUNCT ><hlopt|\|
  ><hlkwd|ADJ ><hlstd|<textunderscore> ><hlopt|-\<gtr\>><hlendline|><next-line><hlstd|
  \ \ \ \ \ \ \ push ><hlopt|(><hlkwd|NOUN ><hlstd|w><hlopt|); ><hlstd|push
  ><hlkwd|SINGULAR><hlendline|><next-line><hlstd| \ \ \ \ \ <hlopt|\|>
  <textunderscore> ><hlopt|-\<gtr\> ><hlstd|push ><hlopt|(><hlkwd|VERB
  ><hlstd|w><hlopt|); ><hlstd|push ><hlkwd|PLURAL><hlendline|><next-line><hlstd|
  \ \ \ ><hlopt|}><hlendline|>

  <new-page*><hlstd|<hlopt|\|> <textunderscore> ><hlkwa|as
  ><hlstd|w<hlendline|><next-line> \ \ \ ><hlopt|{ ><hlstd|raise
  ><hlopt|(><hlkwd|LexError ><hlopt|(><hlstr|"Unrecognized character
  "><hlstd|<hlendline|><next-line> \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ <textasciicircum>><hlkwc|Char><hlopt|.><hlstd|escaped
  w><hlopt|)) }><hlendline|><next-line><hlopt|{><hlendline|><next-line><hlstd|
  \ ><hlkwa|let ><hlstd|lexeme lexbuf ><hlopt|=><hlendline|The proper
  interface reads from the token buffer.><next-line><hlstd| \ \ \ ><hlkwa|if
  ><hlkwc|Queue><hlopt|.><hlstd|is<textunderscore>empty tokbuf ><hlkwa|then
  ><hlstd|lex<textunderscore>word lexbuf><hlopt|;><hlendline|><next-line><hlstd|
  \ \ \ ><hlkwc|Queue><hlopt|.><hlstd|pop
  tokbuf><hlendline|><next-line><hlopt|}><hlendline|>

  <\itemize>
    <item>File <verbatim|EngParser.mly>:
  </itemize>

  <hlopt|%{><hlendline|><next-line><hlstd| \ ><hlkwa|open
  ><hlkwd|EngLexer><hlendline|Source of the token type and sentence
  type.><next-line><hlopt|%}><hlendline|><next-line><hlopt|%><hlstd|token
  ><hlopt|\<less\>><hlkwb|string><hlopt|\<gtr\> ><hlkwd|VERB NOUN ADJ
  ADV><hlendline|<em|Open word classes>.><next-line><hlopt|%><hlstd|token
  ><hlkwd|PLURAL SINGULAR><hlendline|Number
  marker.><next-line><hlopt|%><hlstd|token ><hlkwd|A<textunderscore>DET
  THE<textunderscore>DET SOME<textunderscore>DET THIS<textunderscore>DET
  THAT<textunderscore>DET><hlendline|``Keywords''.><next-line><hlopt|%><hlstd|token
  ><hlkwd|THESE<textunderscore>DET THOSE<textunderscore>DET><hlendline|><next-line><hlopt|%><hlstd|token
  ><hlkwd|COMMA<textunderscore>CNJ AND<textunderscore>CNJ
  DOT<textunderscore>PUNCT><hlendline|><next-line><hlopt|%><hlstd|start
  ><hlopt|\<less\>><hlkwc|EngLexer><hlopt|.><hlstd|sentence><hlopt|\<gtr\>
  ><hlstd|sentence><hlendline|Grammar entry.><next-line><hlopt|%%><hlendline|>

  <new-page*><hlopt|%><hlstd|public ><hlopt|%><hlstd|inline
  sep2<textunderscore>list><hlopt|(><hlstd|sep1><hlopt|,
  ><hlstd|sep2><hlopt|, ><hlkwd|X><hlopt|):><hlendline|General
  purpose.><next-line><hlstd|<hlopt|\|> xs ><hlopt|=
  ><hlstd|separated<textunderscore>nonempty<textunderscore>list><hlopt|(><hlstd|sep1><hlopt|,
  ><hlkwd|X><hlopt|) ><hlstd|sep2 x><hlopt|=><hlkwd|X><hlendline|><next-line><hlstd|
  \ \ \ ><hlopt|{ ><hlstd|xs @ ><hlopt|[><hlstd|x><hlopt|] }><hlendline|We
  use it for ``comma-and'' lists:><next-line><hlstd|<hlopt|\|>
  x><hlopt|=><hlkwb|option><hlopt|(><hlkwd|X><hlopt|)><hlendline|<em|smart<strong|,>
  quiet <strong|and> diligent.>><next-line><hlstd| \ \ \ ><hlopt|{
  ><hlkwa|match ><hlstd|x ><hlkwa|with ><hlkwd|None><hlopt|-\<gtr\>[] \|
  ><hlkwd|Some ><hlstd|x><hlopt|-\<gtr\>[><hlstd|x><hlopt|]
  }><hlendline|><next-line><hlstd|sing<textunderscore>only<textunderscore>det><hlopt|:><hlendline|How
  determiners relate to number.><next-line><hlopt|\|
  ><hlkwd|A<textunderscore>DET ><hlopt|\| ><hlkwd|THIS<textunderscore>DET
  ><hlopt|\| ><hlkwd|THAT<textunderscore>DET ><hlopt|{ ><hlstd|log
  ><hlstr|"prs: sing<textunderscore>only<textunderscore>det"><hlstd|
  ><hlopt|}><hlendline|><next-line><hlstd|plu<textunderscore>only<textunderscore>det><hlopt|:><hlendline|><next-line><hlopt|\|
  ><hlkwd|THESE<textunderscore>DET ><hlopt|\|
  ><hlkwd|THOSE<textunderscore>DET ><hlopt|{ ><hlstd|log ><hlstr|"prs:
  plu<textunderscore>only<textunderscore>det"><hlstd|
  ><hlopt|}><hlendline|><next-line><hlstd|other<textunderscore>det><hlopt|:><hlendline|><next-line><hlopt|\|
  ><hlkwd|THE<textunderscore>DET ><hlopt|\| ><hlkwd|SOME<textunderscore>DET
  ><hlopt|{ ><hlstd|log ><hlstr|"prs: other<textunderscore>det"><hlstd|
  ><hlopt|}><hlendline|><next-line><hlstd|np><hlopt|(><hlstd|det><hlopt|):><hlendline|><next-line><hlstd|<hlopt|\|>
  det adjs><hlopt|=><hlstd|list><hlopt|(><hlkwd|ADJ><hlopt|)
  ><hlstd|subject><hlopt|=><hlkwd|NOUN><hlendline|><next-line><hlstd|
  \ \ \ ><hlopt|{ ><hlstd|log ><hlstr|"prs: np"><hlopt|;
  ><hlstd|adjs><hlopt|, ><hlstd|subject ><hlopt|}><hlendline|><next-line><hlstd|vp><hlopt|(><hlkwd|NUM><hlopt|):><hlendline|><next-line><hlstd|<hlopt|\|>
  advs><hlopt|=><hlstd|separated<textunderscore>list><hlopt|(><hlkwd|AND<textunderscore>CNJ><hlopt|,><hlkwd|ADV><hlopt|)
  ><hlstd|action><hlopt|=><hlkwd|VERB NUM><hlendline|><next-line><hlstd|<hlopt|\|>
  action><hlopt|=><hlkwd|VERB NUM ><hlstd|advs><hlopt|=><hlstd|sep2<textunderscore>list><hlopt|(><hlkwd|COMMA<textunderscore>CNJ><hlopt|,><hlkwd|AND<textunderscore>CNJ><hlopt|,><hlkwd|ADV><hlopt|)><hlendline|><next-line><hlstd|
  \ \ \ ><hlopt|{ ><hlstd|log ><hlstr|"prs: vp"><hlopt|;
  ><hlstd|action><hlopt|, ><hlstd|advs ><hlopt|}><hlendline|>

  <new-page*><hlstd|sent><hlopt|(><hlstd|det><hlopt|,><hlkwd|NUM><hlopt|):><hlendline|Sentence
  parameterized by number.><next-line><hlstd|<hlopt|\|>
  adjsub><hlopt|=><hlstd|np><hlopt|(><hlstd|det><hlopt|) ><hlkwd|NUM
  ><hlstd|vbadv><hlopt|=><hlstd|vp><hlopt|(><hlkwd|NUM><hlopt|)><hlendline|><next-line><hlstd|
  \ \ \ ><hlopt|{ ><hlstd|log ><hlstr|"prs:
  sent"><hlopt|;><hlendline|><next-line><hlstd|
  \ \ \ \ \ ><hlopt|{><hlstd|subject><hlopt|=><hlstd|snd adjsub><hlopt|;
  ><hlstd|action><hlopt|=><hlstd|fst vbadv><hlopt|;
  ><hlstd|plural><hlopt|=><hlkwa|false><hlopt|;><hlendline|><next-line><hlstd|
  \ \ \ \ \ \ adjs><hlopt|=><hlstd|fst adjsub><hlopt|;
  ><hlstd|advs><hlopt|=><hlstd|snd vbadv><hlopt|}
  }><hlendline|><next-line><hlstd|vbsent><hlopt|(><hlkwd|NUM><hlopt|):><hlendline|Unfortunately,
  it doesn't always work...><next-line><hlopt|\| ><hlkwd|NUM
  ><hlstd|vbadv><hlopt|=><hlstd|vp><hlopt|(><hlkwd|NUM><hlopt|)><hlstd|
  \ \ \ ><hlopt|{ ><hlstd|log ><hlstr|"prs: vbsent"><hlopt|; ><hlstd|vbadv
  ><hlopt|}><hlendline|><next-line><hlstd|sentence><hlopt|:><hlendline|Sentence,
  either singular or plural number.><next-line><hlstd|<hlopt|\|>
  s><hlopt|=><hlstd|sent><hlopt|(><hlstd|sing<textunderscore>only<textunderscore>det><hlopt|,><hlkwd|SINGULAR><hlopt|)
  ><hlkwd|DOT<textunderscore>PUNCT><hlendline|><next-line><hlstd|
  \ \ \ ><hlopt|{ ><hlstd|log ><hlstr|"prs:
  sentence1"><hlopt|;><hlendline|><next-line><hlstd|
  \ \ \ \ \ ><hlopt|{><hlstd|s ><hlkwa|with ><hlstd|plural ><hlopt|=
  ><hlkwa|false><hlopt|} }><hlendline|><next-line><hlstd|<hlopt|\|>
  s><hlopt|=><hlstd|sent><hlopt|(><hlstd|plu<textunderscore>only<textunderscore>det><hlopt|,><hlkwd|PLURAL><hlopt|)
  ><hlkwd|DOT<textunderscore>PUNCT><hlendline|><next-line><hlstd|
  \ \ \ ><hlopt|{ ><hlstd|log ><hlstr|"prs:
  sentence2"><hlopt|;><hlendline|><next-line><hlstd|
  \ \ \ \ \ ><hlopt|{><hlstd|s ><hlkwa|with ><hlstd|plural ><hlopt|=
  ><hlkwa|true><hlopt|} }><hlendline|>

  <new-page*><hlstd|<hlopt|\|> adjsub><hlopt|=><hlstd|np><hlopt|(><hlstd|other<textunderscore>det><hlopt|)
  ><hlstd|vbadv><hlopt|=><hlstd|vbsent><hlopt|(><hlkwd|SINGULAR><hlopt|)
  ><hlkwd|DOT<textunderscore>PUNCT><hlendline|><next-line><hlstd|
  \ \ \ ><hlopt|{ ><hlstd|log ><hlstr|"prs:
  sentence3"><hlopt|;><hlendline|Because parser allows only one token
  look-ahead><next-line><hlstd| \ \ \ \ \ ><hlopt|{><hlstd|subject><hlopt|=><hlstd|snd
  adjsub><hlopt|; ><hlstd|action><hlopt|=><hlstd|fst vbadv><hlopt|;
  ><hlstd|plural><hlopt|=><hlkwa|false><hlopt|;><hlendline|><next-line><hlstd|
  \ \ \ \ \ \ adjs><hlopt|=><hlstd|fst adjsub><hlopt|;
  ><hlstd|advs><hlopt|=><hlstd|snd vbadv><hlopt|}
  }><hlendline|><next-line><hlstd|<hlopt|\|>
  adjsub><hlopt|=><hlstd|np><hlopt|(><hlstd|other<textunderscore>det><hlopt|)
  ><hlstd|vbadv><hlopt|=><hlstd|vbsent><hlopt|(><hlkwd|PLURAL><hlopt|)
  ><hlkwd|DOT<textunderscore>PUNCT><hlendline|><next-line><hlstd|
  \ \ \ ><hlopt|{ ><hlstd|log ><hlstr|"prs: sentence4"><hlopt|;><hlendline|we
  need to factor-out the ``common subset''.><next-line><hlstd|
  \ \ \ \ \ ><hlopt|{><hlstd|subject><hlopt|=><hlstd|snd adjsub><hlopt|;
  ><hlstd|action><hlopt|=><hlstd|fst vbadv><hlopt|;
  ><hlstd|plural><hlopt|=><hlkwa|true><hlopt|;><hlendline|><next-line><hlstd|
  \ \ \ \ \ \ adjs><hlopt|=><hlstd|fst adjsub><hlopt|;
  ><hlstd|advs><hlopt|=><hlstd|snd vbadv><hlopt|} }><hlendline|>

  <\itemize>
    <item>File <verbatim|Eng.ml> is the same as <verbatim|calc.ml> from
    previous example:
  </itemize>

  <hlkwa|open ><hlkwd|EngLexer><hlendline|><next-line><hlkwa|let ><hlopt|()
  =><hlendline|><next-line><hlstd| \ ><hlkwa|let ><hlstd|stdinbuf ><hlopt|=
  ><hlkwc|Lexing><hlopt|.><hlstd|from<textunderscore>channel stdin
  ><hlkwa|in><hlendline|><next-line><hlstd| \ ><hlkwa|while true
  do><hlendline|><next-line><hlstd| \ \ \ ><hlcom|(* Read line by line.
  *)><hlstd|<hlendline|><next-line> \ \ \ ><hlkwa|let ><hlstd|linebuf
  ><hlopt|= ><hlkwc|Lexing><hlopt|.><hlstd|from<textunderscore>string
  ><hlopt|(><hlstd|line stdinbuf><hlopt|) ><hlkwa|in><hlendline|>

  <new-page*><hlstd| \ \ \ ><hlkwa|try><hlendline|><next-line><hlstd|
  \ \ \ \ \ ><hlcom|(* Run the parser on a single line of input.
  *)><hlstd|<hlendline|><next-line> \ \ \ \ \ ><hlkwa|let ><hlstd|s ><hlopt|=
  ><hlkwc|EngParser><hlopt|.><hlstd|sentence lexeme linebuf
  ><hlkwa|in><hlendline|><next-line><hlstd|
  \ \ \ \ \ ><hlkwc|Printf><hlopt|.><hlstd|printf<next-line> ><hlstr|
  \ \ "subject=%s><hlesc|\\n><hlstr|plural=%b><hlesc|<math|>\\n><hlstr|adjs=%s><hlesc|<math|>\\n><hlstr|action=%s><hlesc|<math|>n><hlstr|advs=%s><hlesc|<math|>\\n\\<math|>n><hlstr|%!"><hlstd|<next-line>
  \ \ \ \ \ \ \ s><hlopt|.><hlstd|subject s><hlopt|.><hlstd|plural
  ><hlopt|(><hlkwc|String><hlopt|.><hlstd|concat ><hlstr|", "><hlstd|
  s><hlopt|.><hlstd|adjs><hlopt|)><hlendline|><next-line><hlstd|
  \ \ \ \ \ \ \ s><hlopt|.><hlstd|action ><hlopt|(><hlkwc|String><hlopt|.><hlstd|concat
  ><hlstr|", "><hlstd| s><hlopt|.><hlstd|advs><hlopt|)><hlendline|><next-line><hlstd|
  \ \ \ ><hlkwa|with><hlendline|><next-line><hlstd| \ \ \ ><hlopt|\|
  ><hlkwd|LexError ><hlstd|msg ><hlopt|-\<gtr\>><hlendline|><next-line><hlstd|
  \ \ \ \ \ ><hlkwc|Printf><hlopt|.><hlstd|fprintf stderr
  ><hlstr|"%s><hlesc|<math|>n><hlstr|%!"><hlstd| msg<hlendline|><next-line>
  \ \ \ ><hlopt|\| ><hlkwc|EngParser><hlopt|.><hlkwd|Error
  ><hlopt|-\<gtr\>><hlendline|><next-line><hlstd|
  \ \ \ \ \ ><hlkwc|Printf><hlopt|.><hlstd|fprintf stderr ><hlstr|"At offset
  %d: syntax error.><hlesc|<math|>n><hlstr|%!"><hlstd|<hlendline|><next-line>
  \ \ \ \ \ \ \ \ \ ><hlopt|(><hlkwc|Lexing><hlopt|.><hlstd|lexeme<textunderscore>start
  linebuf><hlopt|)><hlendline|><next-line><hlstd| \ ><hlkwa|done><hlendline|>

  <\itemize>
    <item>Build & run command:

    <verbatim|ocamlbuild Eng.native -use-menhir -menhir "menhir EngParser.mly
    --base EngParser --external-tokens EngLexer" -->
  </itemize>

  <section|<new-page*>Example: Phrase search>

  <\itemize>
    <item>In lecture 6 we performed keyword search, now we turn to <em|phrase
    search> i.e. require that given words be consecutive in the document.

    <item>We start with some English-specific transformations used in lexer:

    <small|<hlkwa|let ><hlstd|wh<textunderscore>or<textunderscore>pronoun w
    ><hlopt|=><hlendline|><next-line><hlstd| \ w ><hlopt|=
    ><hlstr|"where"><hlstd| <hlopt|\|\|> w ><hlopt|= ><hlstr|"what"><hlstd|
    <hlopt|\|\|> w ><hlopt|= ><hlstr|"who"><hlstd|
    <hlopt|\|\|><hlendline|><next-line> \ w ><hlopt|= ><hlstr|"he"><hlstd|
    <hlopt|\|\|> w ><hlopt|= ><hlstr|"she"><hlstd| <hlopt|\|\|> w ><hlopt|=
    ><hlstr|"it"><hlstd| <hlopt|\|\|><hlendline|><next-line> \ w ><hlopt|=
    ><hlstr|"I"><hlstd| <hlopt|\|\|> w ><hlopt|= ><hlstr|"you"><hlstd|
    <hlopt|\|\|> w ><hlopt|= ><hlstr|"we"><hlstd| <hlopt|\|\|> w ><hlopt|=
    ><hlstr|"they"><hlendline|><next-line><hlkwa|let ><hlstd|abridged w1 w2
    ><hlopt|=><hlendline|Remove shortened forms like <em|I'll> or
    <em|press'd>.><next-line><hlstd| \ ><hlkwa|if ><hlstd|w2 ><hlopt|=
    ><hlstr|"ll"><hlstd| ><hlkwa|then ><hlopt|[><hlstd|w1><hlopt|;
    ><hlstr|"will"><hlopt|]><hlendline|><next-line><hlstd| \ ><hlkwa|else if
    ><hlstd|w2 ><hlopt|= ><hlstr|"s"><hlstd|
    ><hlkwa|then><hlendline|><next-line><hlstd| \ \ \ ><hlkwa|if
    ><hlstd|wh<textunderscore>or<textunderscore>pronoun w1 ><hlkwa|then
    ><hlopt|[><hlstd|w1><hlopt|; ><hlstr|"is"><hlopt|]><hlendline|><next-line><hlstd|
    \ \ \ ><hlkwa|else ><hlopt|[><hlstr|"of"><hlopt|;
    ><hlstd|w1><hlopt|]><hlendline|><next-line><hlstd| \ ><hlkwa|else if
    ><hlstd|w2 ><hlopt|= ><hlstr|"d"><hlstd| ><hlkwa|then
    ><hlopt|[><hlstd|w1<textasciicircum>><hlstr|"ed"><hlopt|]><hlendline|><next-line><hlstd|
    \ ><hlkwa|else if ><hlstd|w1 ><hlopt|= ><hlstr|"o"><hlstd| <hlopt|\|\|>
    w1 ><hlopt|= ><hlstr|"O"><hlstd|<hlendline|><next-line>
    \ ><hlkwa|then><hlendline|><next-line><hlstd| \ \ \ ><hlkwa|if
    ><hlstd|w2><hlopt|.[><hlnum|0><hlopt|] = ><hlstd|'e' ><hlopt|&&
    ><hlstd|w2><hlopt|.[><hlnum|1><hlopt|] = ><hlstd|'r' ><hlkwa|then
    ><hlopt|[><hlstd|w1<textasciicircum>><hlstr|"v"><hlstd|<textasciicircum>w2><hlopt|]><hlendline|><next-line><hlstd|
    \ \ \ ><hlkwa|else ><hlopt|[><hlstr|"of"><hlopt|;
    ><hlstd|w2><hlopt|]><hlendline|><next-line><hlstd| \ ><hlkwa|else if
    ><hlstd|w2 ><hlopt|= ><hlstr|"t"><hlstd| ><hlkwa|then
    ><hlopt|[><hlstd|w1><hlopt|; ><hlstr|"it"><hlopt|]><hlendline|><next-line><hlstd|
    \ ><hlkwa|else ><hlopt|[><hlstd|w1<textasciicircum>><hlstr|"'"><hlstd|<textasciicircum>w2><hlopt|]><hlendline|>>

    <item>For now we normalize words just by lowercasing, but see exercise 8.

    <item>In lexer we <em|tokenize> text: separate words and normalize them.

    <\itemize>
      <item>We also handle simple aspects of <em|XML> syntax.
    </itemize>

    <item>We store the number of each word occurrence, excluding XML tags.
  </itemize>

  <\small>
    <hlopt|{><hlendline|><next-line><hlstd| \ ><hlkwa|open
    ><hlkwd|IndexParser><hlendline|><next-line><hlstd| \ ><hlkwa|let
    ><hlstd|word ><hlopt|= ><hlkwb|ref ><hlnum|0><hlendline|><next-line><hlstd|
    \ ><hlkwa|let ><hlstd|linebreaks ><hlopt|= ><hlkwb|ref
    ><hlopt|[]><hlendline|><next-line><hlstd| \ ><hlkwa|let
    ><hlstd|comment<textunderscore>start ><hlopt|= ><hlkwb|ref
    ><hlkwc|Lexing><hlopt|.><hlstd|dummy<textunderscore>pos<hlendline|><next-line>
    \ ><hlkwa|let ><hlstd|reset<textunderscore>as<textunderscore>file lexbuf
    s ><hlopt|=><hlendline|General purpose lexer function:><next-line><hlstd|
    \ \ \ ><hlkwa|let ><hlstd|pos ><hlopt|=
    ><hlstd|lexbuf><hlopt|.><hlkwc|Lexing><hlopt|.><hlstd|lex<textunderscore>curr<textunderscore>p
    ><hlkwa|in><hlendline|start lexing from a file.><next-line><hlstd|
    \ \ \ lexbuf><hlopt|.><hlkwc|Lexing><hlopt|.><hlstd|lex<textunderscore>curr<textunderscore>p
    ><hlopt|\<less\>- { ><hlstd|pos ><hlkwa|with><hlendline|><next-line><hlstd|
    \ \ \ \ \ ><hlkwc|Lexing><hlopt|.><hlstd|pos<textunderscore>lnum
    ><hlopt|=><hlstd| \ ><hlnum|1><hlopt|;><hlendline|><next-line><hlstd|
    \ \ \ \ \ pos<textunderscore>fname ><hlopt|=
    ><hlstd|s><hlopt|;><hlendline|><next-line><hlstd|
    \ \ \ \ \ pos<textunderscore>bol ><hlopt|=
    ><hlstd|pos><hlopt|.><hlkwc|Lexing><hlopt|.><hlstd|pos<textunderscore>cnum><hlopt|;><hlendline|><next-line><hlstd|
    \ \ \ ><hlopt|};><hlendline|><next-line><hlstd| \ \ \ linebreaks
    ><hlopt|:= []; ><hlstd|word ><hlopt|:=
    ><hlnum|0><hlendline|><next-line><hlstd| \ ><hlkwa|let ><hlstd|nextline
    lexbuf ><hlopt|=><hlendline|Old friend.><next-line><hlstd|
    \ \ \ >...<hlendline|Besides changing position, remember a line
    break.><next-line><hlstd| \ \ \ linebreaks ><hlopt|:= !><hlstd|word
    ><hlopt|:: !><verbatim|linebreaks><hlendline|>

    <new-page*><verbatim| \ ><hlkwa|let ><hlstd|parse<textunderscore>error<textunderscore>msg
    startpos endpos report ><hlopt|=><hlendline|General purpose lexer
    function:><next-line><hlstd| \ \ \ ><hlkwa|let ><hlstd|clbeg
    ><hlopt|=><hlendline|report a syntax error.><next-line><hlstd|
    \ \ \ \ \ startpos><hlopt|.><hlkwc|Lexing><hlopt|.><hlstd|pos<textunderscore>cnum
    ><hlopt|- ><hlstd|startpos><hlopt|.><hlkwc|Lexing><hlopt|.><hlstd|pos<textunderscore>bol
    ><hlkwa|in><hlendline|><next-line><hlstd| \ \ \ ignore
    ><hlopt|(><hlkwc|Format><hlopt|.><hlstd|flush<textunderscore>str<textunderscore>formatter
    ><hlopt|());><hlendline|><next-line><hlstd|
    \ \ \ ><hlkwc|Printf><hlopt|.><hlstd|sprintf<hlendline|><next-line>
    \ \ \ \ \ ><hlstr|"File ><hlesc|<math|>"><hlstr|%s><hlesc|<math|>"><hlstr|,
    lines %d-%d, characters %d-%d: %s><hlesc|<math|>n><hlstr|"><hlstd|<hlendline|><next-line>
    \ \ \ \ \ startpos><hlopt|.><hlkwc|Lexing><hlopt|.><hlstd|pos<textunderscore>fname
    startpos><hlopt|.><hlkwc|Lexing><hlopt|.><hlstd|pos<textunderscore>lnum<hlendline|><next-line>
    \ \ \ \ \ endpos><hlopt|.><hlkwc|Lexing><hlopt|.><hlstd|pos<textunderscore>lnum
    clbeg<hlendline|><next-line> \ \ \ \ \ ><hlopt|(><hlstd|clbeg><hlopt|+(><hlstd|endpos><hlopt|.><hlkwc|Lexing><hlopt|.><hlstd|pos<textunderscore>cnum
    ><hlopt|- ><hlstd|startpos><hlopt|.><hlkwc|Lexing><hlopt|.><hlstd|pos<textunderscore>cnum><hlopt|))><hlendline|><next-line><hlstd|
    \ \ \ \ \ report><hlendline|><next-line><hlopt|}><hlendline|><next-line><hlkwa|let
    ><hlstd|alphanum ><hlopt|= [><hlstd|'><hlnum|0><hlstd|'><hlopt|-><hlstd|'><hlnum|9><hlstd|'
    'a'><hlopt|-><hlstd|'z' '><hlkwd|A'><hlopt|-><hlstd|'><hlkwd|Z'><hlopt|]><hlendline|><next-line><hlkwa|let
    ><hlstd|newline ><hlopt|= (><hlstd|'><hlesc|<math|>n><hlstd|' <hlopt|\|>
    ><hlstr|"><hlesc|<math|>r<math|>n><hlstr|"><hlopt|)><hlendline|><next-line><hlkwa|let
    ><hlstd|xml<textunderscore>start ><hlopt|= (><hlstr|"\<less\>!--"><hlstd|
    <hlopt|\|> ><hlstr|"\<less\>?"><hlopt|)><hlendline|><next-line><hlkwa|let
    ><hlstd|xml<textunderscore>end ><hlopt|= (><hlstr|"--\<gtr\>"><hlstd|
    <hlopt|\|> ><hlstr|"?\<gtr\>"><hlopt|)><hlendline|><next-line><hlstd|rule
    token ><hlopt|= ><hlstd|parse<hlendline|><next-line> \ ><hlopt|\|
    [><hlstd|' ' '><hlesc|<math|>t><hlstd|'><hlopt|]><hlendline|><next-line><hlstd|
    \ \ \ \ \ ><hlopt|{ ><hlstd|token lexbuf
    ><hlopt|}><hlendline|><next-line><hlstd| \ <hlopt|\|>
    newline<hlendline|><next-line> \ \ \ \ \ ><hlopt|{ ><hlstd|nextline
    lexbuf><hlopt|; ><hlstd|token lexbuf ><hlopt|}><hlendline|>

    <new-page*><hlstd| \ <hlopt|\|> '><hlopt|\<less\>><hlstd|'
    alphanum><hlopt|+ ><hlstd|'><hlopt|\<gtr\>><hlstd|' ><hlkwa|as
    ><verbatim|w><hlendline|Dedicated token variants for XML
    tags.><next-line><verbatim| \ \ \ \ \ ><hlopt|{ ><hlkwd|OPEN ><hlstd|w
    ><hlopt|}><hlendline|><next-line><hlstd| \ ><hlopt|\|
    ><hlstr|"\<less\>/"><hlstd| alphanum><hlopt|+
    ><hlstd|'><hlopt|\<gtr\>><hlstd|' ><hlkwa|as
    ><hlstd|w<hlendline|><next-line> \ \ \ \ \ ><hlopt|{ ><hlkwd|CLOSE
    ><hlstd|w ><hlopt|}><hlendline|><next-line><hlstd| \ ><hlopt|\|
    ><hlstr|"'tis"><hlstd|<hlendline|><next-line> \ \ \ \ \ ><hlopt|{
    ><hlstd|word ><hlopt|:= !><hlstd|word><hlopt|+><hlnum|2><hlopt|;
    ><hlkwd|WORDS ><hlopt|[><hlstr|"it"><hlopt|,
    !><hlstd|word><hlopt|-><hlnum|1><hlopt|; ><hlstr|"is"><hlopt|,
    !><hlstd|word><hlopt|] }><hlendline|><next-line><hlstd| \ ><hlopt|\|
    ><hlstr|"'Tis"><hlstd|<hlendline|><next-line> \ \ \ \ \ ><hlopt|{
    ><hlstd|word ><hlopt|:= !><hlstd|word><hlopt|+><hlnum|2><hlopt|;
    ><hlkwd|WORDS ><hlopt|[><hlstr|"It"><hlopt|,
    !><hlstd|word><hlopt|-><hlnum|1><hlopt|; ><hlstr|"is"><hlopt|,
    !><hlstd|word><hlopt|] }><hlendline|><next-line><hlstd| \ ><hlopt|\|
    ><hlstr|"o'clock"><hlstd|<hlendline|><next-line> \ \ \ \ \ ><hlopt|{
    ><hlstd|incr word><hlopt|; ><hlkwd|WORDS
    ><hlopt|[><hlstr|"o'clock"><hlopt|, !><hlstd|word><hlopt|]
    }><hlendline|><next-line><hlstd| \ ><hlopt|\|
    ><hlstr|"O'clock"><hlstd|<hlendline|><next-line> \ \ \ \ \ ><hlopt|{
    ><hlstd|incr word><hlopt|; ><hlkwd|WORDS
    ><hlopt|[><hlstr|"O'clock"><hlopt|, !><hlstd|word><hlopt|]
    }><hlendline|><next-line><hlstd| \ ><hlopt|\| (><hlstd|alphanum><hlopt|+
    ><hlkwa|as ><hlstd|w1><hlopt|) ><hlstd|'''
    ><hlopt|(><hlstd|alphanum><hlopt|+ ><hlkwa|as
    ><hlstd|w2><hlopt|)><hlendline|><next-line><hlstd| \ \ \ \ \ ><hlopt|{
    ><hlkwa|let ><hlstd|words ><hlopt|= ><hlkwc|EngMorph><hlopt|.><hlstd|abridged
    w1 w2 ><hlkwa|in><hlendline|><next-line><hlstd| \ \ \ \ \ \ \ ><hlkwa|let
    ><hlstd|words ><hlopt|= ><hlkwc|List><hlopt|.><hlstd|map<hlendline|><next-line>
    \ \ \ \ \ \ \ \ \ ><hlopt|(><hlkwa|fun ><hlstd|w ><hlopt|-\<gtr\>
    ><hlstd|incr word><hlopt|; ><hlstd|w><hlopt|, !><hlstd|word><hlopt|)
    ><hlstd|words ><hlkwa|in><hlendline|><next-line><hlstd|
    \ \ \ \ \ \ \ ><hlkwd|WORDS ><hlstd|words
    ><hlopt|}><hlendline|><next-line><hlstd| \ <hlopt|\|> alphanum><hlopt|+
    ><hlkwa|as ><hlstd|w<hlendline|><next-line> \ \ \ \ \ ><hlopt|{
    ><hlstd|incr word><hlopt|; ><hlkwd|WORDS ><hlopt|[><hlstd|w><hlopt|,
    !><hlstd|word><hlopt|] }><hlendline|><next-line><hlstd| \ ><hlopt|\|
    ><hlstr|"&amp;"><hlstd|<hlendline|><next-line> \ \ \ \ \ ><hlopt|{
    ><hlstd|incr word><hlopt|; ><hlkwd|WORDS ><hlopt|[><hlstr|"&"><hlopt|,
    !><hlstd|word><hlopt|] }><hlendline|>

    <new-page*><hlstd| \ ><hlopt|\| [><hlstd|'><hlopt|.><hlstd|'
    '><hlopt|!><hlstd|' '?'><hlopt|] ><hlkwa|as >p<hlendline|Dedicated tokens
    for punctuation><next-line> \ \ \ \ \ <hlopt|{ ><hlkwd|SENTENCE
    ><hlopt|(><hlkwc|Char><hlopt|.><hlstd|escaped p><hlopt|) }><hlendline|so
    that it doesn't break phrases.><next-line><hlstd| \ ><hlopt|\|
    ><hlstr|"--"><hlstd|<hlendline|><next-line> \ \ \ \ \ ><hlopt|{
    ><hlkwd|PUNCT ><hlstr|"--"><hlstd| ><hlopt|}><hlendline|><next-line><hlstd|
    \ ><hlopt|\| [><hlstd|'><hlopt|,><hlstd|' '><hlopt|:><hlstd|' '''
    '><hlopt|-><hlstd|' '><hlopt|;><hlstd|'><hlopt|] ><hlkwa|as
    ><hlstd|p<hlendline|><next-line> \ \ \ \ \ ><hlopt|{ ><hlkwd|PUNCT
    ><hlopt|(><hlkwc|Char><hlopt|.><hlstd|escaped p><hlopt|)
    }><hlendline|><next-line><hlstd| \ <hlopt|\|> eof ><hlopt|{ ><hlkwd|EOF
    ><hlopt|}><hlstd| \ \ \ \ ><hlendline|><next-line><hlstd| \ <hlopt|\|>
    xml<textunderscore>start<hlendline|><next-line> \ \ \ \ \ ><hlopt|{
    ><hlstd|comment<textunderscore>start ><hlopt|:=
    ><hlstd|lexbuf><hlopt|.><hlkwc|Lexing><hlopt|.><hlstd|lex<textunderscore>curr<textunderscore>p><hlopt|;><hlendline|><next-line><hlstd|
    \ \ \ \ \ \ \ ><hlkwa|let ><hlstd|s ><hlopt|= ><hlstd|comment ><hlopt|[]
    ><hlstd|lexbuf ><hlkwa|in><hlendline|><next-line><hlstd|
    \ \ \ \ \ \ \ ><hlkwd|COMMENT ><hlstd|s
    ><hlopt|}><hlendline|><next-line><hlstd| \ <hlopt|\|>
    <textunderscore><hlendline|><next-line> \ \ \ \ \ ><hlopt|{ ><hlkwa|let
    ><hlstd|pos ><hlopt|= ><hlstd|lexbuf><hlopt|.><hlkwc|Lexing><hlopt|.><hlstd|lex<textunderscore>curr<textunderscore>p
    ><hlkwa|in><hlendline|><next-line><hlstd| \ \ \ \ \ \ \ ><hlkwa|let
    ><hlstd|pos' ><hlopt|= {><hlstd|pos ><hlkwa|with><hlendline|><next-line><hlstd|
    \ \ \ \ \ \ \ \ \ ><hlkwc|Lexing><hlopt|.><hlstd|pos<textunderscore>cnum
    ><hlopt|= ><hlstd|pos><hlopt|.><hlkwc|Lexing><hlopt|.><hlstd|pos<textunderscore>cnum
    ><hlopt|+ ><hlnum|1><hlopt|} ><hlkwa|in><hlendline|><next-line><hlstd|
    \ \ \ \ \ \ \ ><hlkwc|Printf><hlopt|.><hlstd|printf
    ><hlstr|"%s><hlesc|<math|>\\n><hlstr|%!"><hlstd|<hlendline|><next-line>
    \ \ \ \ \ \ \ \ \ ><hlopt|(><hlstd|parse<textunderscore>error<textunderscore>msg
    pos pos' ><hlstr|"lexer error"><hlopt|);><hlendline|><next-line><hlstd|
    \ \ \ \ \ \ \ failwith ><hlstr|"LEXER ERROR"><hlstd|
    ><hlopt|}><hlendline|>

    <new-page*><hlkwa|and ><hlstd|comment strings ><hlopt|=
    ><hlstd|parse<hlendline|><next-line> \ <hlopt|\|>
    xml<textunderscore>end<hlendline|><next-line> \ \ \ \ \ ><hlopt|{
    ><hlkwc|String><hlopt|.><hlstd|concat ><hlstr|""><hlstd|
    ><hlopt|(><hlkwc|List><hlopt|.><hlstd|rev strings><hlopt|)
    }><hlendline|><next-line><hlstd| \ <hlopt|\|> eof<hlendline|><next-line>
    \ \ \ \ \ ><hlopt|{ ><hlkwa|let ><hlstd|pos ><hlopt|=
    !><hlstd|comment<textunderscore>start
    ><hlkwa|in><hlendline|><next-line><hlstd| \ \ \ \ \ \ \ ><hlkwa|let
    ><hlstd|pos' ><hlopt|= ><hlstd|lexbuf><hlopt|.><hlkwc|Lexing><hlopt|.><hlstd|lex<textunderscore>curr<textunderscore>p
    ><hlkwa|in><hlendline|><next-line><hlstd|
    \ \ \ \ \ \ \ ><hlkwc|Printf><hlopt|.><hlstd|printf
    ><hlstr|"%s><hlesc|<math|>n><hlstr|%!"><hlstd|<hlendline|><next-line>
    \ \ \ \ \ \ \ \ \ ><hlopt|(><hlstd|parse<textunderscore>error<textunderscore>msg
    pos pos' ><hlstr|"lexer error: unclosed
    comment"><hlopt|);><hlendline|><next-line><hlstd| \ \ \ \ \ \ \ failwith
    ><hlstr|"LEXER ERROR"><hlstd| ><hlopt|}><hlendline|><next-line><hlstd|
    \ <hlopt|\|> newline<hlendline|><next-line> \ \ \ \ \ ><hlopt|{
    ><hlstd|nextline lexbuf><hlopt|;><hlendline|><next-line><hlstd|
    \ \ \ \ \ \ \ comment ><hlopt|(><hlkwc|Lexing><hlopt|.><hlstd|lexeme
    lexbuf ><hlopt|:: ><hlstd|strings><hlopt|)
    ><hlstd|lexbuf<hlendline|><next-line>
    \ \ \ \ \ ><hlopt|}><hlendline|><next-line><hlstd| \ <hlopt|\|>
    <textunderscore><hlendline|><next-line> \ \ \ \ \ ><hlopt|{
    ><hlstd|comment ><hlopt|(><hlkwc|Lexing><hlopt|.><hlstd|lexeme lexbuf
    ><hlopt|:: ><hlstd|strings><hlopt|) ><hlstd|lexbuf ><hlopt|}><hlendline|>
  </small>

  <\itemize>
    <item>Parsing: the inverted index and the query.
  </itemize>

  <\small>
    <hlkwa|type ><hlstd|token ><hlopt|=><hlendline|><next-line><hlopt|\|
    ><hlkwd|WORDS ><hlkwa|of ><hlopt|(><hlkwb|string ><hlopt|*
    ><hlkwb|int><hlopt|) ><hlstd|list<hlendline|><next-line><hlopt|\|>
    ><hlkwd|OPEN ><hlkwa|of ><hlkwb|string ><hlopt|\| ><hlkwd|CLOSE
    ><hlkwa|of ><hlkwb|string ><hlopt|\| ><hlkwd|COMMENT ><hlkwa|of
    ><hlkwb|string><hlendline|><next-line><hlopt|\| ><hlkwd|SENTENCE
    ><hlkwa|of ><hlkwb|string ><hlopt|\| ><hlkwd|PUNCT ><hlkwa|of
    ><hlkwb|string><hlendline|><next-line><hlopt|\| ><hlkwd|EOF><hlendline|>

    <new-page*><hlkwa|let ><hlstd|inv<textunderscore>index update ii lexer
    lexbuf ><hlopt|=><hlendline|><next-line><hlstd| \ ><hlkwa|let rec
    ><hlstd|aux ii ><hlopt|=><hlendline|><next-line><hlstd|
    \ \ \ ><hlkwa|match ><hlstd|lexer lexbuf
    ><hlkwa|with><hlendline|><next-line><hlstd| \ \ \ ><hlopt|\|
    ><hlkwd|WORDS ><hlstd|ws ><hlopt|-\<gtr\>><hlendline|><next-line><hlstd|
    \ \ \ \ \ ><hlkwa|let ><hlstd|ws ><hlopt|=
    ><hlkwc|List><hlopt|.><hlstd|map ><hlopt|(><hlkwa|fun
    ><hlopt|(><hlstd|w><hlopt|,><hlstd|p><hlopt|)-\<gtr\>><hlkwc|EngMorph><hlopt|.><hlstd|normalize
    w><hlopt|, ><hlstd|p><hlopt|) ><hlstd|ws
    ><hlkwa|in><hlendline|><next-line><hlstd| \ \ \ \ \ aux
    ><hlopt|(><hlkwc|List><hlopt|.><hlstd|fold<textunderscore>left update ii
    ws><hlopt|)><hlendline|><next-line><hlstd| \ \ \ ><hlopt|\| ><hlkwd|OPEN
    ><hlstd|<textunderscore> <hlopt|\|> ><hlkwd|CLOSE
    ><hlstd|<textunderscore> <hlopt|\|> ><hlkwd|SENTENCE
    ><hlstd|<textunderscore> <hlopt|\|> ><hlkwd|PUNCT
    ><hlstd|<textunderscore> <hlopt|\|> ><hlkwd|COMMENT
    ><hlstd|<textunderscore> ><hlopt|-\<gtr\>><hlendline|><next-line><hlstd|
    \ \ \ \ \ aux ii<hlendline|><next-line> \ \ \ ><hlopt|\| ><hlkwd|EOF
    ><hlopt|-\<gtr\> ><hlstd|ii ><hlkwa|in><hlendline|><next-line><hlstd|
    \ aux ii><hlendline|>

    <hlkwa|let ><hlstd|phrase lexer lexbuf
    ><hlopt|=><hlendline|><next-line><hlstd| \ ><hlkwa|let rec ><hlstd|aux
    words ><hlopt|=><hlendline|><next-line><hlstd| \ \ \ ><hlkwa|match
    ><hlstd|lexer lexbuf ><hlkwa|with><hlendline|><next-line><hlstd|
    \ \ \ ><hlopt|\| ><hlkwd|WORDS ><hlstd|ws
    ><hlopt|-\<gtr\>><hlendline|><next-line><hlstd| \ \ \ \ \ ><hlkwa|let
    ><hlstd|ws ><hlopt|= ><hlkwc|List><hlopt|.><hlstd|map
    ><hlopt|(><hlkwa|fun ><hlopt|(><hlstd|w><hlopt|,><hlstd|p><hlopt|)-\<gtr\>><hlkwc|EngMorph><hlopt|.><hlstd|normalize
    w><hlopt|) ><hlstd|ws ><hlkwa|in><hlendline|><next-line><hlstd|
    \ \ \ \ \ aux ><hlopt|(><hlkwc|List><hlopt|.><hlstd|rev<textunderscore>append
    ws words><hlopt|)><hlendline|><next-line><hlstd| \ \ \ ><hlopt|\|
    ><hlkwd|OPEN ><hlstd|<textunderscore> <hlopt|\|> ><hlkwd|CLOSE
    ><hlstd|<textunderscore> <hlopt|\|> ><hlkwd|SENTENCE
    ><hlstd|<textunderscore> <hlopt|\|> ><hlkwd|PUNCT
    ><hlstd|<textunderscore> <hlopt|\|> ><hlkwd|COMMENT
    ><hlstd|<textunderscore> ><hlopt|-\<gtr\>><hlendline|><next-line><hlstd|
    \ \ \ \ \ aux words<hlendline|><next-line> \ \ \ ><hlopt|\| ><hlkwd|EOF
    ><hlopt|-\<gtr\> ><hlkwc|List><hlopt|.><hlstd|rev words
    ><hlkwa|in><hlendline|><next-line><hlstd| \ aux ><hlopt|[]><hlendline|>
  </small>

  <subsubsection|<new-page*>Naive implementation of phrase search>

  <\itemize>
    <item>We need <em|postings lists> with positions of words <small|rather
    than just the document or line of document they belong to>.

    <item>First approach: association lists and merge postings lists
    word-by-word.
  </itemize>

  <\small>
    <hlkwa|let ><hlstd|update ii ><hlopt|(><hlstd|w><hlopt|,
    ><hlstd|p><hlopt|) =><hlendline|><next-line><hlstd|
    \ ><hlkwa|try><hlendline|><next-line><hlstd| \ \ \ ><hlkwa|let ><hlstd|ps
    ><hlopt|= ><hlkwc|List><hlopt|.><hlstd|assoc w ii
    ><hlkwa|in><hlendline|Add position to the postings list of
    <verbatim|w>.><next-line><hlstd| \ \ \ ><hlopt|(><hlstd|w><hlopt|,
    ><hlstd|p><hlopt|::><hlstd|ps><hlopt|) ::
    ><hlkwc|List><hlopt|.><hlstd|remove<textunderscore>assoc w
    ii<hlendline|><next-line> \ ><hlkwa|with ><hlkwd|Not<textunderscore>found
    ><hlopt|-\<gtr\> (><hlstd|w><hlopt|, [><hlstd|p><hlopt|])::><hlstd|ii><hlendline|><next-line><hlkwa|let
    ><hlstd|empty ><hlopt|= []><hlendline|><next-line><hlkwa|let ><hlstd|find
    w ii ><hlopt|= ><hlkwc|List><hlopt|.><hlstd|assoc w
    ii><hlendline|><next-line><hlkwa|let ><hlstd|mapv f ii ><hlopt|=
    ><hlkwc|List><hlopt|.><hlstd|map ><hlopt|(><hlkwa|fun
    ><hlopt|(><hlstd|k><hlopt|,><hlstd|v><hlopt|)-\<gtr\>><hlstd|k><hlopt|,
    ><hlstd|f v><hlopt|) ><hlstd|ii><hlendline|><next-line><hlkwa|let
    ><hlstd|index file ><hlopt|=><hlendline|><next-line><hlstd| \ ><hlkwa|let
    ><hlstd|ch ><hlopt|= ><hlstd|open<textunderscore>in file
    ><hlkwa|in><hlendline|><next-line><hlstd| \ ><hlkwa|let ><hlstd|lexbuf
    ><hlopt|= ><hlkwc|Lexing><hlopt|.><hlstd|from<textunderscore>channel ch
    ><hlkwa|in><hlendline|><next-line><hlstd|
    \ ><hlkwc|EngLexer><hlopt|.><hlstd|reset<textunderscore>as<textunderscore>file
    lexbuf file><hlopt|;><hlendline|><next-line><hlstd| \ ><hlkwa|let
    ><hlstd|ii ><hlopt|=><hlendline|><next-line><hlstd|
    \ \ \ ><hlkwc|IndexParser><hlopt|.><hlstd|inv<textunderscore>index update
    empty ><hlkwc|EngLexer><hlopt|.><hlstd|token lexbuf
    ><hlkwa|in><hlendline|><next-line><hlstd| \ close<textunderscore>in
    ch><hlopt|;><hlendline|Keep postings lists in increasing
    order.><next-line><hlstd| \ mapv ><hlkwc|List><hlopt|.><hlstd|rev
    ii><hlopt|, ><hlkwc|List><hlopt|.><hlstd|rev
    ><hlopt|!><hlkwc|EngLexer><hlopt|.><hlstd|linebreaks><hlendline|><next-line><hlkwa|let
    ><hlstd|find<textunderscore>line linebreaks p
    ><hlopt|=><hlendline|Recover the line in document of a
    position.><next-line><hlstd| \ ><hlkwa|let rec ><hlstd|aux line ><hlopt|=
    ><hlkwa|function><hlendline|><next-line><hlstd| \ \ \ ><hlopt|\| []
    -\<gtr\> ><hlstd|line<hlendline|><next-line> \ \ \ <hlopt|\|>
    bp><hlopt|::><hlstd|<textunderscore> ><hlkwa|when ><hlstd|p
    ><hlopt|\<less\> ><hlstd|bp ><hlopt|-\<gtr\>
    ><hlstd|line<hlendline|><next-line> \ \ \ <hlopt|\|>
    <textunderscore>><hlopt|::><hlstd|breaks ><hlopt|-\<gtr\> ><hlstd|aux
    ><hlopt|(><hlstd|line><hlopt|+><hlnum|1><hlopt|) ><hlstd|breaks
    ><hlkwa|in><hlendline|><next-line><hlstd| \ aux ><hlnum|1
    ><hlstd|linebreaks><hlendline|><next-line><hlkwa|let ><hlstd|search
    ><hlopt|(><hlstd|ii><hlopt|, ><hlstd|linebreaks><hlopt|) ><hlstd|phrase
    ><hlopt|=><hlendline|><next-line><hlstd| \ ><hlkwa|let ><hlstd|lexbuf
    ><hlopt|= ><hlkwc|Lexing><hlopt|.><hlstd|from<textunderscore>string
    phrase ><hlkwa|in><hlendline|><next-line><hlstd|
    \ ><hlkwc|EngLexer><hlopt|.><hlstd|reset<textunderscore>as<textunderscore>file
    lexbuf ><hlopt|(><hlstr|"search phrase:
    "><hlstd|<textasciicircum>phrase><hlopt|);><hlendline|><next-line><hlstd|
    \ ><hlkwa|let ><hlstd|phrase ><hlopt|=
    ><hlkwc|IndexParser><hlopt|.><hlstd|phrase
    ><hlkwc|EngLexer><hlopt|.><hlstd|token lexbuf
    ><hlkwa|in><hlendline|><next-line><hlstd| \ ><hlkwa|let rec ><hlstd|aux
    wpos ><hlopt|= ><hlkwa|function><hlendline|Merge postings lists for words
    in query:><next-line><hlstd| \ \ \ ><hlopt|\| [] -\<gtr\>
    ><verbatim|wpos><hlendline|no more words in query;><next-line><verbatim|
    \ \ \ ><hlopt|\|><verbatim| w><hlopt|::><hlstd|ws
    ><hlopt|-\<gtr\>><hlendline|for positions of <verbatim|w>, keep those
    that are next to><next-line><hlstd| \ \ \ \ \ ><hlkwa|let ><hlstd|nwpos
    ><hlopt|= ><hlstd|find w ii ><hlkwa|in><hlendline|filtered positions of
    previous word.><next-line><hlstd| \ \ \ \ \ aux
    ><hlopt|(><hlkwc|List><hlopt|.><hlstd|filter ><hlopt|(><hlkwa|fun
    ><hlstd|p><hlopt|-\<gtr\>><hlkwc|List><hlopt|.><hlstd|mem
    ><hlopt|(><hlstd|p><hlopt|-><hlnum|1><hlopt|) ><hlstd|wpos><hlopt|)
    ><hlstd|nwpos><hlopt|) ><hlstd|ws ><hlkwa|in><hlendline|><next-line><hlstd|
    \ ><hlkwa|let ><hlstd|wpos ><hlopt|=><hlendline|><next-line><hlstd|
    \ \ \ ><hlkwa|match ><hlstd|phrase ><hlkwa|with><hlendline|><next-line><hlstd|
    \ \ \ ><hlopt|\| [] -\<gtr\> []><hlendline|No results for an empty
    query.><next-line><hlstd| \ \ \ <hlopt|\|> w><hlopt|::><hlstd|ws
    ><hlopt|-\<gtr\> ><hlstd|aux ><hlopt|(><hlstd|find w ii><hlopt|)
    ><hlstd|ws ><hlkwa|in><hlendline|><next-line><hlstd|
    \ ><hlkwc|List><hlopt|.><hlstd|map ><hlopt|(><hlstd|find<textunderscore>line
    linebreaks><hlopt|) ><hlstd|wpos><hlendline|Answer in terms of document
    lines.>

    <new-page*><hlkwa|let ><hlstd|shakespeare ><hlopt|= ><hlstd|index
    ><hlstr|"./shakespeare.xml"><hlendline|><next-line><hlkwa|let
    ><hlstd|query q ><hlopt|=><hlendline|><next-line><hlstd| \ ><hlkwa|let
    ><hlstd|lines ><hlopt|= ><hlstd|search shakespeare q
    ><hlkwa|in><hlendline|><next-line><hlstd|
    \ ><hlkwc|Printf><hlopt|.><hlstd|printf ><hlstr|"%s: lines
    %s><hlesc|<math|>n><hlstr|%!"><hlstd| q<hlendline|><next-line>
    \ \ \ ><hlopt|(><hlkwc|String><hlopt|.><hlstd|concat ><hlstr|", "><hlstd|
    ><hlopt|(><hlkwc|List><hlopt|.><hlstd|map
    string<textunderscore>of<textunderscore>int lines><hlopt|))><hlendline|>
  </small>

  <\itemize>
    <item>Test: 200 searches of the queries:

    <small|<hlopt|[><hlstr|"first witch"><hlopt|; ><hlstr|"wherefore art
    thou"><hlopt|;><hlendline|><next-line><hlstd| \ ><hlstr|"captain's
    captain"><hlopt|; ><hlstr|"flatter'd"><hlopt|; ><hlstr|"of
    Fulvia"><hlopt|;><hlendline|><next-line><hlstd| \ ><hlstr|"that which we
    call a rose"><hlopt|; ><hlstr|"the undiscovered
    country"><hlopt|]><hlendline|>>

    <item>Invocation: <verbatim|ocamlbuild InvIndex.native -libs unix -->

    <item>Time: 7.3s
  </itemize>

  <subsubsection|<new-page*>Replace association list with hash table>

  <\itemize>
    <item>I recommend using either <em|OCaml Batteries> or <em|OCaml Core> --
    replacement for the standard library. <em|Batteries> has efficient
    <hlkwc|Hashtbl><hlopt|.><hlstd|map> (our <verbatim|mapv>).

    <item>Invocation: <verbatim|ocamlbuild InvIndex1.native -libs unix -->

    <item>Time: 6.3s
  </itemize>

  <subsubsection|<new-page*>Replace naive merging with ordered merging>

  <\itemize>
    <item>Postings lists are already ordered.

    <item>Invocation: <verbatim|ocamlbuild InvIndex2.native -libs unix -->

    <item>Time: 2.5s
  </itemize>

  <subsubsection|<new-page*>Bruteforce optimization: biword indexes>

  <\itemize>
    <item>Pairs of words are much less frequent than single words so storing
    them means less work for postings lists merging.

    <item>Can result in much bigger index size:
    <math|min<around*|(|W<rsup|2>,N|)>> where <math|W> is the number of
    distinct words and <math|N> the total number of words in documents.

    <item>Invocation that gives us stack backtraces:

    <verbatim|ocamlbuild InvIndex3.native -cflag -g -libs unix; export
    OCAMLRUNPARAM="b"; ./InvIndex3.native>

    <item>Time: 2.4s -- disappointing.
  </itemize>

  <subsection|<new-page*>Smart way: <em|Information Retrieval> G.V. Cormack
  et al.>

  <\itemize>
    <item>You should classify your problem and search literature for
    state-of-the-art algorithm to solve it.

    <item>The algorithm needs a data structure for inverted index that
    supports:

    <\itemize>
      <item><verbatim|first(w)> -- first position in documents at which
      <verbatim|w> appears

      <item><verbatim|last(w)> -- last position of <verbatim|w>

      <item><verbatim|next(w,cp)> -- first position of <verbatim|w> after
      position <verbatim|cp>

      <item><verbatim|prev(w,cp)> -- last position of <verbatim|w> before
      position <verbatim|cp>
    </itemize>

    <item>We develop <verbatim|next> and <verbatim|prev> operations in
    stages:

    <\itemize>
      <item>First, a naive (but FP) approach using the <hlkwc|Set> module of
      OCaml.

      <\itemize>
        <item>We could use our balanced binary search tree implementation to
        avoid the overhead due to limitations of <hlkwc|Set> API.
      </itemize>

      <item>Then, <em|binary search> based on arrays.

      <item>Imperative linear search.

      <item>Imperative <em|galloping search> optimization of binary search.
    </itemize>
  </itemize>

  <subsubsection|<new-page*>The phrase search algorithm>

  <\itemize>
    <item>During search we maintain <em|current position> <verbatim|cp> of
    last found word or phrase.

    <item>Algorithm is almost purely functional, we use <hlkwd|Not_found>
    exception instead of option type for convenience.
  </itemize>

  <hlkwa|let rec ><hlstd|next<textunderscore>phrase ii phrase cp
  ><hlopt|=><hlendline|Return the beginning and end
  position><next-line><hlstd| \ ><hlkwa|let rec ><hlstd|aux cp ><hlopt|=
  ><hlkwa|function><hlendline|of occurrence of <verbatim|phrase> after
  position <verbatim|cp>.><next-line><hlstd| \ \ \ ><hlopt|\| [] -\<gtr\>
  ><hlstd|raise ><hlkwd|Not<textunderscore>found><hlendline|Empty phrase
  counts as not occurring.><next-line><hlstd| \ \ \ ><hlopt|\|
  [><hlstd|w><hlopt|] -\<gtr\>><hlendline|Single or last word of phrase has
  the same><next-line><hlstd| \ \ \ \ \ ><hlkwa|let ><hlstd|np ><hlopt|=
  ><hlstd|next ii w cp ><hlkwa|in ><hlstd|np><hlopt|,
  ><verbatim|np><hlendline|beg. and end position.><next-line><verbatim|
  \ \ \ ><hlopt|\|> w<hlopt|::><hlstd|ws ><hlopt|-\<gtr\>><hlendline|After
  locating the endp. move back.><next-line><hlstd| \ \ \ \ \ ><hlkwa|let
  ><hlstd|np><hlopt|, ><hlstd|fp ><hlopt|= ><hlstd|aux ><hlopt|(><hlstd|next
  ii w cp><hlopt|) ><hlstd|ws ><hlkwa|in><hlendline|><next-line><hlstd|
  \ \ \ \ \ prev ii w np><hlopt|, ><hlstd|fp ><hlkwa|in><hlendline|If
  distance is this small,><next-line><hlstd| \ ><hlkwa|let
  ><hlstd|np><hlopt|, ><hlstd|fp ><hlopt|= ><hlstd|aux cp phrase
  ><hlkwa|in><hlendline|words are consecutive.><next-line><hlstd|
  \ ><hlkwa|if ><hlstd|fp ><hlopt|- ><hlstd|np ><hlopt|=
  ><hlkwc|List><hlopt|.><hlstd|length phrase ><hlopt|- ><hlnum|1 ><hlkwa|then
  ><hlstd|np><hlopt|, ><hlstd|fp<hlendline|><next-line> \ ><hlkwa|else
  ><hlstd|next<textunderscore>phrase ii phrase fp><hlendline|>

  <new-page*><hlkwa|let ><hlstd|search ><hlopt|(><hlstd|ii><hlopt|,
  ><hlstd|linebreaks><hlopt|) ><hlstd|phrase
  ><hlopt|=><hlendline|><next-line><hlstd| \ ><hlkwa|let ><hlstd|lexbuf
  ><hlopt|= ><hlkwc|Lexing><hlopt|.><hlstd|from<textunderscore>string phrase
  ><hlkwa|in><hlendline|><next-line><hlstd|
  \ ><hlkwc|EngLexer><hlopt|.><hlstd|reset<textunderscore>as<textunderscore>file
  lexbuf ><hlopt|(><hlstr|"search phrase:
  "><hlstd|<textasciicircum>phrase><hlopt|);><hlendline|><next-line><hlstd|
  \ ><hlkwa|let ><hlstd|phrase ><hlopt|= ><hlkwc|IndexParser><hlopt|.><hlstd|phrase
  ><hlkwc|EngLexer><hlopt|.><hlstd|token lexbuf
  ><hlkwa|in><hlendline|><next-line><hlstd| \ ><hlkwa|let rec ><hlstd|aux cp
  ><hlopt|=><hlendline|><next-line><hlstd| \ \ \ ><hlkwa|try><hlendline|Find
  all occurrences of the phrase.><next-line><hlstd| \ \ \ \ \ ><hlkwa|let
  ><hlstd|np><hlopt|, ><hlstd|fp ><hlopt|= ><hlstd|next<textunderscore>phrase
  ii phrase cp ><hlkwa|in><hlendline|><next-line><hlstd| \ \ \ \ \ np
  ><hlopt|:: ><hlstd|aux fp<hlendline|><next-line> \ \ \ ><hlkwa|with
  ><hlkwd|Not<textunderscore>found ><hlopt|-\<gtr\> []
  ><hlkwa|in><hlendline|Moved past last occurrence.><next-line><hlstd|
  \ ><hlkwc|List><hlopt|.><hlstd|map ><hlopt|(><hlstd|find<textunderscore>line
  linebreaks><hlopt|) (><hlstd|aux ><hlopt|(><hlnum|-1><hlopt|))><hlendline|>

  <subsubsection|<new-page*>Naive but purely functional inverted index>

  <small|<hlkwa|module ><hlkwd|S ><hlopt|=
  ><hlkwc|Set><hlopt|.><hlkwd|Make><hlopt|(><hlkwa|struct type
  ><hlstd|t><hlopt|=><hlkwb|int ><hlkwa|let ><hlstd|compare i j ><hlopt|=
  ><hlstd|i><hlopt|-><hlstd|j ><hlkwa|end><hlopt|)><hlendline|><next-line><hlkwa|let
  ><hlstd|update ii ><hlopt|(><hlstd|w><hlopt|, ><hlstd|p><hlopt|)
  =><hlendline|><next-line><hlstd| \ ><hlopt|(><hlkwa|try><hlendline|><next-line><hlstd|
  \ \ \ ><hlkwa|let ><hlstd|ps ><hlopt|= ><hlkwc|Hashtbl><hlopt|.><hlstd|find
  ii w ><hlkwa|in><hlendline|><next-line><hlstd|
  \ \ \ ><hlkwc|Hashtbl><hlopt|.><hlstd|replace ii w
  ><hlopt|(><hlkwc|S><hlopt|.><hlstd|add p
  ps><hlopt|)><hlendline|><next-line><hlstd| \ ><hlkwa|with
  ><hlkwd|Not<textunderscore>found ><hlopt|-\<gtr\>
  ><hlkwc|Hashtbl><hlopt|.><hlstd|add ii w
  ><hlopt|(><hlkwc|S><hlopt|.><hlstd|singleton
  p><hlopt|));><hlendline|><next-line><hlstd|
  \ ii><hlendline|><next-line><hlkwa|let ><hlstd|first ii w ><hlopt|=
  ><hlkwc|S><hlopt|.><hlstd|min<textunderscore>elt ><hlopt|(><hlstd|find w
  ii><hlopt|)><hlendline|The functions raise
  <hlkwd|Not_found>><next-line><hlkwa|let ><hlstd|last ii w ><hlopt|=
  ><hlkwc|S><hlopt|.><hlstd|max<textunderscore>elt ><hlopt|(><hlstd|find w
  ii><hlopt|)><hlendline|whenever such position would not
  exist.><next-line><hlkwa|let ><hlstd|prev ii w cp
  ><hlopt|=><hlendline|><next-line><hlstd| \ ><hlkwa|let ><hlstd|ps ><hlopt|=
  ><hlstd|find w ii ><hlkwa|in><hlendline|Split the set into
  elements><next-line><hlstd| \ ><hlkwa|let ><hlstd|smaller><hlopt|,
  ><hlstd|<textunderscore>><hlopt|, ><hlstd|<textunderscore> ><hlopt|=
  ><hlkwc|S><hlopt|.><hlstd|split cp ps ><hlkwa|in><hlendline|smaller and
  bigger than <verbatim|cp>.><next-line><hlstd|
  \ ><hlkwc|S><hlopt|.><hlstd|max<textunderscore>elt
  smaller><hlendline|><next-line><hlkwa|let ><hlstd|next ii w cp
  ><hlopt|=><hlendline|><next-line><hlstd| \ ><hlkwa|let ><hlstd|ps ><hlopt|=
  ><hlstd|find w ii ><hlkwa|in><hlendline|><next-line><hlstd| \ ><hlkwa|let
  ><hlstd|<textunderscore>><hlopt|, ><hlstd|<textunderscore>><hlopt|,
  ><hlstd|bigger ><hlopt|= ><hlkwc|S><hlopt|.><hlstd|split cp ps
  ><hlkwa|in><hlendline|><next-line><hlstd|
  \ ><hlkwc|S><hlopt|.><hlstd|min<textunderscore>elt bigger><hlendline|>>

  <\itemize>
    <item>Invocation: <verbatim|ocamlbuild InvIndex4.native -libs unix -->

    <item>Time: 3.3s -- would be better without the overhead of
    <hlkwc|S><hlopt|.><hlstd|split>.
  </itemize>

  <subsubsection|<new-page*>Binary search based inverted index>

  <small|<hlkwa|let ><hlstd|prev ii w cp ><hlopt|=><hlendline|><next-line><hlstd|
  \ ><hlkwa|let ><hlstd|ps ><hlopt|= ><hlstd|find w ii
  ><hlkwa|in><hlendline|><next-line><hlstd| \ ><hlkwa|let rec ><hlstd|aux b e
  ><hlopt|=><hlendline|We implement binary search separately for
  <verbatim|prev>><next-line><hlstd| \ \ \ ><hlkwa|if
  ><hlstd|e><hlopt|-><hlstd|b ><hlopt|\<less\>= ><hlnum|1 ><hlkwa|then
  ><hlstd|ps><hlopt|.(><hlstd|b><hlopt|)><hlendline|to make sure here we
  return less than <verbatim|cp>><next-line><hlstd| \ \ \ ><hlkwa|else let
  ><hlstd|m ><hlopt|= (><hlstd|b><hlopt|+><hlstd|e><hlopt|)/><hlnum|2
  ><hlkwa|in><hlendline|><next-line><hlstd| \ \ \ \ \ \ \ \ ><hlkwa|if
  ><hlstd|ps><hlopt|.(><hlstd|m><hlopt|) \<less\> ><hlstd|cp ><hlkwa|then
  ><verbatim|aux m e><hlendline|><next-line><verbatim|
  \ \ \ \ \ \ \ \ ><hlkwa|else ><hlstd|aux b m
  ><hlkwa|in><hlendline|><next-line><hlstd| \ ><hlkwa|let ><hlstd|l ><hlopt|=
  ><hlkwc|Array><hlopt|.><hlstd|length ps
  ><hlkwa|in><hlendline|><next-line><hlstd| \ ><hlkwa|if ><hlstd|l ><hlopt|=
  ><hlnum|0 ><hlstd|<hlopt|\|\|> ps><hlopt|.(><hlnum|0><hlopt|) \<gtr\>=
  ><hlstd|cp ><hlkwa|then ><hlstd|raise ><hlkwd|Not<textunderscore>found><hlendline|><next-line><hlstd|
  \ ><hlkwa|else ><hlstd|aux ><hlnum|0 ><hlopt|(><hlstd|l><hlopt|-><hlnum|1><hlopt|)><hlendline|><next-line><hlkwa|let
  ><hlstd|next ii w cp ><hlopt|=><hlendline|><next-line><hlstd| \ ><hlkwa|let
  ><hlstd|ps ><hlopt|= ><hlstd|find w ii ><hlkwa|in><hlendline|><next-line><hlstd|
  \ ><hlkwa|let rec ><hlstd|aux b e ><hlopt|=><hlendline|><next-line><hlstd|
  \ \ \ ><hlkwa|if ><hlstd|e><hlopt|-><hlstd|b ><hlopt|\<less\>= ><hlnum|1
  ><hlkwa|then ><hlstd|ps><hlopt|.(><hlstd|e><hlopt|)><hlendline|and here
  more than <verbatim|cp>.><next-line><hlstd| \ \ \ ><hlkwa|else let
  ><hlstd|m ><hlopt|= (><hlstd|b><hlopt|+><hlstd|e><hlopt|)/><hlnum|2
  ><hlkwa|in><hlendline|><next-line><hlstd| \ \ \ \ \ \ \ \ ><hlkwa|if
  ><hlstd|ps><hlopt|.(><hlstd|m><hlopt|) \<less\>= ><hlstd|cp ><hlkwa|then
  ><hlstd|aux m e<hlendline|><next-line> \ \ \ \ \ \ \ \ ><hlkwa|else
  ><hlstd|aux b m ><hlkwa|in><hlendline|><next-line><hlstd| \ ><hlkwa|let
  ><hlstd|l ><hlopt|= ><hlkwc|Array><hlopt|.><hlstd|length ps
  ><hlkwa|in><hlendline|><next-line><hlstd| \ ><hlkwa|if ><hlstd|l ><hlopt|=
  ><hlnum|0 ><hlstd|<hlopt|\|\|> ps><hlopt|.(><hlstd|l><hlopt|-><hlnum|1><hlopt|)
  \<less\>= ><hlstd|cp ><hlkwa|then ><hlstd|raise
  ><hlkwd|Not<textunderscore>found><hlendline|><next-line><hlstd|
  \ ><hlkwa|else ><hlstd|aux ><hlnum|0 ><hlopt|(><hlstd|l><hlopt|-><hlnum|1><hlopt|)><hlendline|>>

  <\itemize>
    <item>File: <verbatim|InvIndex5.ml>. Time: 2.4s
  </itemize>

  <subsubsection|<new-page*>Imperative, linear scan>

  <small|<hlkwa|let ><hlstd|prev ii w cp ><hlopt|=><hlendline|><next-line><hlstd|
  \ ><hlkwa|let ><hlstd|cw><hlopt|,><hlstd|ps ><hlopt|= ><hlstd|find w ii
  ><hlkwa|in><hlendline|For each word we add a cell with last visited
  occurrence.><next-line><hlstd| \ ><hlkwa|let ><hlstd|l ><hlopt|=
  ><hlkwc|Array><hlopt|.><hlstd|length ps
  ><hlkwa|in><hlendline|><next-line><hlstd| \ ><hlkwa|if ><hlstd|l ><hlopt|=
  ><hlnum|0 ><hlstd|<hlopt|\|\|> ps><hlopt|.(><hlnum|0><hlopt|) \<gtr\>=
  ><hlstd|cp ><hlkwa|then ><hlstd|raise ><hlkwd|Not<textunderscore>found><hlendline|><next-line><hlstd|
  \ ><hlkwa|else if ><hlstd|ps><hlopt|.(><hlstd|l><hlopt|-><hlnum|1><hlopt|)
  \<less\> ><hlstd|cp ><hlkwa|then ><hlstd|cw ><hlopt|:=
  ><hlstd|l><hlopt|-><hlnum|1><hlendline|><next-line><hlstd| \ ><hlkwa|else
  ><hlopt|(><hlendline|Reset pointer if current position is not ``ahead'' of
  it.><next-line><hlstd| \ \ \ ><hlkwa|if ><hlopt|!><hlstd|cw
  ><hlopt|\<less\> ><hlstd|l><hlopt|-><hlnum|1 ><hlopt|&&
  ><hlstd|ps><hlopt|.(!><hlstd|cw><hlopt|+><hlnum|1><hlopt|) \<less\>
  ><hlstd|cp ><hlkwa|then ><hlstd|cw ><hlopt|:=
  ><hlstd|l><hlopt|-><hlnum|1><hlopt|;><hlendline|Otherwise
  scan><next-line><hlstd| \ \ \ ><hlkwa|while
  ><hlstd|ps><hlopt|.(!><hlstd|cw><hlopt|) \<gtr\>= ><hlstd|cp ><hlkwa|do
  ><hlstd|decr cw ><hlkwa|done><hlendline|starting from last
  visited.><next-line><hlstd| \ ><hlopt|);><hlendline|><next-line><hlstd|
  \ ps><hlopt|.(!><hlstd|cw><hlopt|)><hlendline|><next-line><hlkwa|let
  ><hlstd|next ii w cp ><hlopt|=><hlendline|><next-line><hlstd| \ ><hlkwa|let
  ><hlstd|cw><hlopt|,><hlstd|ps ><hlopt|= ><hlstd|find w ii
  ><hlkwa|in><hlendline|><next-line><hlstd| \ ><hlkwa|let ><hlstd|l ><hlopt|=
  ><hlkwc|Array><hlopt|.><hlstd|length ps
  ><hlkwa|in><hlendline|><next-line><hlstd| \ ><hlkwa|if ><hlstd|l ><hlopt|=
  ><hlnum|0 ><hlstd|<hlopt|\|\|> ps><hlopt|.(><hlstd|l><hlopt|-><hlnum|1><hlopt|)
  \<less\>= ><hlstd|cp ><hlkwa|then ><hlstd|raise
  ><hlkwd|Not<textunderscore>found><hlendline|><next-line><hlstd|
  \ ><hlkwa|else if ><hlstd|ps><hlopt|.(><hlnum|0><hlopt|) \<gtr\> ><hlstd|cp
  ><hlkwa|then ><hlstd|cw ><hlopt|:= ><hlnum|0><hlendline|><next-line><hlstd|
  \ ><hlkwa|else ><hlopt|(><hlendline|Reset pointer if current position is
  not ahead of it.><next-line><hlstd| \ \ \ ><hlkwa|if ><hlopt|!><hlstd|cw
  ><hlopt|\<gtr\> ><hlnum|0 ><hlopt|&& ><hlstd|ps><hlopt|.(!><hlstd|cw><hlopt|-><hlnum|1><hlopt|)
  \<gtr\> ><hlstd|cp ><hlkwa|then ><hlstd|cw ><hlopt|:=
  ><hlnum|0><hlopt|;><hlendline|><next-line><hlstd| \ \ \ ><hlkwa|while
  ><hlstd|ps><hlopt|.(!><hlstd|cw><hlopt|) \<less\>= ><hlstd|cp ><hlkwa|do
  ><hlstd|incr cw ><hlkwa|done><hlendline|><next-line><hlstd|
  \ ><hlopt|);><hlendline|><next-line><hlstd|
  \ ps><hlopt|.(!><hlstd|cw><hlopt|)><hlendline|><next-line>>

  <\itemize>
    <item>End of <verbatim|index>-building function:

    <hlstd| \ mapv ><hlopt|(><hlkwa|fun ><hlstd|ps><hlopt|-\<gtr\>><hlkwb|ref
    ><hlnum|0><hlopt|, ><hlkwc|Array><hlopt|.><hlstd|of<textunderscore>list
    ><hlopt|(><hlkwc|List><hlopt|.><hlstd|rev ps><hlopt|))
    ><hlstd|ii><hlopt|,>...

    <item>File: <verbatim|InvIndex6.ml>

    <item>Time: 2.8s
  </itemize>

  \;

  <subsubsection|<new-page*>Imperative, galloping search>

  <small|<hlkwa|let ><hlstd|next ii w cp ><hlopt|=><hlendline|><next-line><hlstd|
  \ ><hlkwa|let ><hlstd|cw><hlopt|,><hlstd|ps ><hlopt|= ><hlstd|find w ii
  ><hlkwa|in><hlendline|><next-line><hlstd| \ ><hlkwa|let ><hlstd|l ><hlopt|=
  ><hlkwc|Array><hlopt|.><hlstd|length ps
  ><hlkwa|in><hlendline|><next-line><hlstd| \ ><hlkwa|if ><hlstd|l ><hlopt|=
  ><hlnum|0 ><hlstd|<hlopt|\|\|> ps><hlopt|.(><hlstd|l><hlopt|-><hlnum|1><hlopt|)
  \<less\>= ><hlstd|cp ><hlkwa|then ><hlstd|raise
  ><hlkwd|Not<textunderscore>found><hlopt|;><hlendline|><next-line><hlstd|
  \ ><hlkwa|let rec ><hlstd|jump ><hlopt|(><hlstd|b><hlopt|,><hlstd|e
  ><hlkwa|as ><hlstd|bounds><hlopt|) ><hlstd|j ><hlopt|=><hlendline|Locate
  the interval with <verbatim|cp> inside.><next-line><hlstd| \ \ \ ><hlkwa|if
  ><hlstd|e ><hlopt|\<less\> ><hlstd|l><hlopt|-><hlnum|1 ><hlopt|&&
  ><hlstd|ps><hlopt|.(><hlstd|e><hlopt|) \<less\>= ><hlstd|cp ><hlkwa|then
  ><hlstd|jump ><hlopt|(><hlstd|e><hlopt|,><hlstd|e><hlopt|+><hlstd|j><hlopt|)
  (><hlnum|2><hlopt|*><hlstd|j><hlopt|)><hlendline|><next-line><hlstd|
  \ \ \ ><hlkwa|else ><hlstd|bounds ><hlkwa|in><hlendline|><next-line><hlstd|
  \ ><hlkwa|let rec ><hlstd|binse b e ><hlopt|=><hlendline|Binary search over
  that interval.><next-line><hlstd| \ \ \ ><hlkwa|if
  ><hlstd|e><hlopt|-><hlstd|b ><hlopt|\<less\>= ><hlnum|1 ><hlkwa|then
  ><hlstd|e<hlendline|><next-line> \ \ \ ><hlkwa|else let ><hlstd|m ><hlopt|=
  (><hlstd|b><hlopt|+><hlstd|e><hlopt|)/><hlnum|2
  ><hlkwa|in><hlendline|><next-line><hlstd| \ \ \ \ \ \ \ \ ><hlkwa|if
  ><hlstd|ps><hlopt|.(><hlstd|m><hlopt|) \<less\>= ><hlstd|cp ><hlkwa|then
  ><hlstd|binse m e<hlendline|><next-line> \ \ \ \ \ \ \ \ ><hlkwa|else
  ><hlstd|binse b m ><hlkwa|in><hlendline|><next-line><hlstd| \ ><hlkwa|if
  ><hlstd|ps><hlopt|.(><hlnum|0><hlopt|) \<gtr\> ><hlstd|cp ><hlkwa|then
  ><hlstd|cw ><hlopt|:= ><hlnum|0><hlendline|><next-line><hlstd|
  \ ><hlkwa|else ><hlopt|(><hlendline|><next-line><hlstd| \ \ \ ><hlkwa|let
  ><hlstd|b ><hlopt|=><hlendline|The invariant is that
  <hlstd|ps><hlopt|.(><hlstd|b><hlopt|) \<less\>=
  ><verbatim|cp>.><next-line><hlstd| \ \ \ \ \ ><hlkwa|if ><hlopt|!><hlstd|cw
  ><hlopt|\<gtr\> ><hlnum|0 ><hlopt|&& ><hlstd|ps><hlopt|.(!><hlstd|cw><hlopt|-><hlnum|1><hlopt|)
  \<less\>= ><hlstd|cp ><hlkwa|then ><hlopt|!><hlstd|cw><hlopt|-><hlnum|1
  ><hlkwa|else ><hlnum|0 ><hlkwa|in><hlendline|><next-line><hlstd|
  \ \ \ ><hlkwa|let ><hlstd|b><hlopt|,><hlstd|e ><hlopt|= ><hlstd|jump
  ><hlopt|(><hlstd|b><hlopt|,><hlstd|b><hlopt|+><hlnum|1><hlopt|) ><hlnum|2
  ><hlkwa|in><hlendline|Locate interval starting near
  <hlopt|!><verbatim|cw>.><next-line><hlstd| \ \ \ ><hlkwa|let ><hlstd|e
  ><hlopt|= ><hlkwa|if ><hlstd|e ><hlopt|\<gtr\> ><hlstd|l><hlopt|-><hlnum|1
  ><hlkwa|then ><hlstd|l><hlopt|-><hlnum|1 ><hlkwa|else ><hlstd|e
  ><hlkwa|in><hlendline|><next-line><hlstd| \ \ \ cw ><hlopt|:= ><hlstd|binse
  b e<hlendline|><next-line> \ ><hlopt|);><hlendline|><next-line><hlstd|
  \ ps><hlopt|.(!><hlstd|cw><hlopt|)><hlendline|>>

  <\itemize>
    <new-page*><item><verbatim|prev> is symmetric to <verbatim|next>.

    <item>File: <verbatim|InvIndex7.ml>

    <item>Time: 2.4s -- minimal speedup in our simple test case.
  </itemize>

  \;
</body>

<\initial>
  <\collection>
    <associate|language|american>
    <associate|magnification|2>
    <associate|page-medium|paper>
    <associate|page-orientation|landscape>
    <associate|page-type|letter>
    <associate|par-hyphen|normal>
    <associate|preamble|false>
  </collection>
</initial>

<\references>
  <\collection>
    <associate|auto-1|<tuple|1|2>>
    <associate|auto-10|<tuple|3.4|21>>
    <associate|auto-11|<tuple|4|23>>
    <associate|auto-12|<tuple|4.1|26>>
    <associate|auto-13|<tuple|4.2|27>>
    <associate|auto-14|<tuple|5|28>>
    <associate|auto-15|<tuple|5.1|29>>
    <associate|auto-16|<tuple|5.2|35>>
    <associate|auto-17|<tuple|5.3|37>>
    <associate|auto-18|<tuple|5.4|40>>
    <associate|auto-19|<tuple|6|42>>
    <associate|auto-2|<tuple|1.1|8>>
    <associate|auto-20|<tuple|6.1|43>>
    <associate|auto-21|<tuple|6.1.1|48>>
    <associate|auto-22|<tuple|6.2|53>>
    <associate|auto-23|<tuple|6.2.1|62>>
    <associate|auto-24|<tuple|6.2.2|69>>
    <associate|auto-25|<tuple|7|79>>
    <associate|auto-26|<tuple|7.0.3|86>>
    <associate|auto-27|<tuple|7.0.4|89>>
    <associate|auto-28|<tuple|7.0.5|90>>
    <associate|auto-29|<tuple|7.0.6|91>>
    <associate|auto-3|<tuple|1.2|12>>
    <associate|auto-30|<tuple|7.1|92>>
    <associate|auto-31|<tuple|7.1.1|93>>
    <associate|auto-32|<tuple|7.1.2|95>>
    <associate|auto-33|<tuple|7.1.3|96>>
    <associate|auto-34|<tuple|7.1.4|97>>
    <associate|auto-35|<tuple|7.1.5|99>>
    <associate|auto-36|<tuple|7.1.6|?>>
    <associate|auto-4|<tuple|2|15>>
    <associate|auto-5|<tuple|2.1|17>>
    <associate|auto-6|<tuple|3|18>>
    <associate|auto-7|<tuple|3.1|18>>
    <associate|auto-8|<tuple|3.2|19>>
    <associate|auto-9|<tuple|3.3|20>>
    <associate|ch02fn03|<tuple|3.0.8|?>>
    <associate|ch02index14|<tuple|2.1|6>>
    <associate|ch02index20|<tuple|2.1.1|7>>
    <associate|ch02index21|<tuple|2.1.1|8>>
    <associate|ch02index23|<tuple|2.1.2|9>>
    <associate|ch02index25|<tuple|2.1.3|11>>
    <associate|ch02index34|<tuple|<with|mode|<quote|math>|\<bullet\>>|13>>
    <associate|ch02index35|<tuple|<with|mode|<quote|math>|\<bullet\>>|14>>
    <associate|ch02index36|<tuple|3.0.6|15>>
    <associate|ch02index37|<tuple|3.0.6|16>>
    <associate|ch02index38|<tuple|3.0.6|16>>
    <associate|ch02index39|<tuple|3.0.6|17>>
    <associate|ch02index49|<tuple|3.0.7|18>>
    <associate|ch03index07|<tuple|1|3>>
    <associate|ch03index08|<tuple|?|3>>
    <associate|ch03index15|<tuple|<with|mode|<quote|math>|\<bullet\>>|?>>
    <associate|ch03index16|<tuple|<with|mode|<quote|math>|\<bullet\>>|?>>
    <associate|ch03index19|<tuple|?|10>>
    <associate|ch03index20|<tuple|?|11>>
    <associate|ch03index24|<tuple|1|14>>
    <associate|ch03index26|<tuple|<with|mode|<quote|math>|\<bullet\>>|16>>
    <associate|ch03index30|<tuple|<with|mode|<quote|math>|\<bullet\>>|17>>
    <associate|ch03index31|<tuple|?|18>>
    <associate|ch03index38|<tuple|?|22>>
    <associate|ch03index39|<tuple|<with|mode|<quote|math>|\<bullet\>>|?>>
    <associate|ch03index44|<tuple|?|26>>
    <associate|ch05index06|<tuple|<with|mode|<quote|math>|<rigid|\<circ\>>>|?>>
    <associate|ch05index07|<tuple|<with|mode|<quote|math>|\<bullet\>>|?>>
    <associate|ch05index09|<tuple|12.0.1|?>>
    <associate|ch19index03|<tuple|5|?>>
    <associate|ch19index04|<tuple|<with|mode|<quote|math>|\<bullet\>>|?>>
    <associate|page100|<tuple|6|?>>
    <associate|page79|<tuple|4|?>>
  </collection>
</references>

<\auxiliary>
  <\collection>
    <\associate|toc>
      <vspace*|1fn><with|font-series|<quote|bold>|math-font-series|<quote|bold>|<new-page*>OCaml
      Compilers> <datoms|<macro|x|<repeat|<arg|x>|<with|font-series|medium|<with|font-size|1|<space|0.2fn>.<space|0.2fn>>>>>|<htab|5mm>>
      <no-break><pageref|auto-1><vspace|0.5fn>

      <with|par-left|<quote|1.5fn>|<new-page*>Compiling multiple-file
      projects <datoms|<macro|x|<repeat|<arg|x>|<with|font-series|medium|<with|font-size|1|<space|0.2fn>.<space|0.2fn>>>>>|<htab|5mm>>
      <no-break><pageref|auto-2>>

      <with|par-left|<quote|1.5fn>|<new-page*>Editors
      <datoms|<macro|x|<repeat|<arg|x>|<with|font-series|medium|<with|font-size|1|<space|0.2fn>.<space|0.2fn>>>>>|<htab|5mm>>
      <no-break><pageref|auto-3>>

      <vspace*|1fn><with|font-series|<quote|bold>|math-font-series|<quote|bold>|<new-page*>Imperative
      features in OCaml> <datoms|<macro|x|<repeat|<arg|x>|<with|font-series|medium|<with|font-size|1|<space|0.2fn>.<space|0.2fn>>>>>|<htab|5mm>>
      <no-break><pageref|auto-4><vspace|0.5fn>

      <with|par-left|<quote|1.5fn>|<new-page*>Parsing command-line arguments
      <datoms|<macro|x|<repeat|<arg|x>|<with|font-series|medium|<with|font-size|1|<space|0.2fn>.<space|0.2fn>>>>>|<htab|5mm>>
      <no-break><pageref|auto-5>>

      <vspace*|1fn><with|font-series|<quote|bold>|math-font-series|<quote|bold>|<new-page*>OCaml
      Garbage Collection> <datoms|<macro|x|<repeat|<arg|x>|<with|font-series|medium|<with|font-size|1|<space|0.2fn>.<space|0.2fn>>>>>|<htab|5mm>>
      <no-break><pageref|auto-6><vspace|0.5fn>

      <with|par-left|<quote|1.5fn>|Representation of values
      <datoms|<macro|x|<repeat|<arg|x>|<with|font-series|medium|<with|font-size|1|<space|0.2fn>.<space|0.2fn>>>>>|<htab|5mm>>
      <no-break><pageref|auto-7>>

      <with|par-left|<quote|1.5fn>|<new-page*>Generational Garbage Collection
      <datoms|<macro|x|<repeat|<arg|x>|<with|font-series|medium|<with|font-size|1|<space|0.2fn>.<space|0.2fn>>>>>|<htab|5mm>>
      <no-break><pageref|auto-8>>

      <with|par-left|<quote|1.5fn>|<new-page*>Stop & Copy GC
      <datoms|<macro|x|<repeat|<arg|x>|<with|font-series|medium|<with|font-size|1|<space|0.2fn>.<space|0.2fn>>>>>|<htab|5mm>>
      <no-break><pageref|auto-9>>

      <with|par-left|<quote|1.5fn>|<new-page*>Mark & Sweep GC
      <datoms|<macro|x|<repeat|<arg|x>|<with|font-series|medium|<with|font-size|1|<space|0.2fn>.<space|0.2fn>>>>>|<htab|5mm>>
      <no-break><pageref|auto-10>>

      <vspace*|1fn><with|font-series|<quote|bold>|math-font-series|<quote|bold>|<new-page*>Stack
      Frames and Closures> <datoms|<macro|x|<repeat|<arg|x>|<with|font-series|medium|<with|font-size|1|<space|0.2fn>.<space|0.2fn>>>>>|<htab|5mm>>
      <no-break><pageref|auto-11><vspace|0.5fn>

      <with|par-left|<quote|1.5fn>|<new-page*>Tail Recursion
      <datoms|<macro|x|<repeat|<arg|x>|<with|font-series|medium|<with|font-size|1|<space|0.2fn>.<space|0.2fn>>>>>|<htab|5mm>>
      <no-break><pageref|auto-12>>

      <with|par-left|<quote|1.5fn>|<new-page*>Generated assembly
      <datoms|<macro|x|<repeat|<arg|x>|<with|font-series|medium|<with|font-size|1|<space|0.2fn>.<space|0.2fn>>>>>|<htab|5mm>>
      <no-break><pageref|auto-13>>

      <vspace*|1fn><with|font-series|<quote|bold>|math-font-series|<quote|bold>|<new-page*>Profiling
      and Optimization> <datoms|<macro|x|<repeat|<arg|x>|<with|font-series|medium|<with|font-size|1|<space|0.2fn>.<space|0.2fn>>>>>|<htab|5mm>>
      <no-break><pageref|auto-14><vspace|0.5fn>

      <with|par-left|<quote|1.5fn>|<new-page*>Profiling
      <datoms|<macro|x|<repeat|<arg|x>|<with|font-series|medium|<with|font-size|1|<space|0.2fn>.<space|0.2fn>>>>>|<htab|5mm>>
      <no-break><pageref|auto-15>>

      <with|par-left|<quote|1.5fn>|<new-page*>Algorithmic optimizations
      <datoms|<macro|x|<repeat|<arg|x>|<with|font-series|medium|<with|font-size|1|<space|0.2fn>.<space|0.2fn>>>>>|<htab|5mm>>
      <no-break><pageref|auto-16>>

      <with|par-left|<quote|1.5fn>|<new-page*>Low-level optimizations
      <datoms|<macro|x|<repeat|<arg|x>|<with|font-series|medium|<with|font-size|1|<space|0.2fn>.<space|0.2fn>>>>>|<htab|5mm>>
      <no-break><pageref|auto-17>>

      <with|par-left|<quote|1.5fn>|<new-page*>Comparison of data structure
      implementations <datoms|<macro|x|<repeat|<arg|x>|<with|font-series|medium|<with|font-size|1|<space|0.2fn>.<space|0.2fn>>>>>|<htab|5mm>>
      <no-break><pageref|auto-18>>

      <vspace*|1fn><with|font-series|<quote|bold>|math-font-series|<quote|bold>|<new-page*>Parsing:
      ocamllex and Menhir> <datoms|<macro|x|<repeat|<arg|x>|<with|font-series|medium|<with|font-size|1|<space|0.2fn>.<space|0.2fn>>>>>|<htab|5mm>>
      <no-break><pageref|auto-19><vspace|0.5fn>

      <with|par-left|<quote|1.5fn>|<new-page*>Lexing with
      <with|font-shape|<quote|italic>|ocamllex>
      <datoms|<macro|x|<repeat|<arg|x>|<with|font-series|medium|<with|font-size|1|<space|0.2fn>.<space|0.2fn>>>>>|<htab|5mm>>
      <no-break><pageref|auto-20>>

      <with|par-left|<quote|3fn>|<new-page*>Example: Finding email addresses
      <datoms|<macro|x|<repeat|<arg|x>|<with|font-series|medium|<with|font-size|1|<space|0.2fn>.<space|0.2fn>>>>>|<htab|5mm>>
      <no-break><pageref|auto-21>>

      <with|par-left|<quote|1.5fn>|<new-page*>Parsing with Menhir
      <datoms|<macro|x|<repeat|<arg|x>|<with|font-series|medium|<with|font-size|1|<space|0.2fn>.<space|0.2fn>>>>>|<htab|5mm>>
      <no-break><pageref|auto-22>>

      <with|par-left|<quote|3fn>|<new-page*>Example: parsing arithmetic
      expressions <datoms|<macro|x|<repeat|<arg|x>|<with|font-series|medium|<with|font-size|1|<space|0.2fn>.<space|0.2fn>>>>>|<htab|5mm>>
      <no-break><pageref|auto-23>>

      <with|par-left|<quote|3fn>|<new-page*>Example: a toy sentence grammar
      <datoms|<macro|x|<repeat|<arg|x>|<with|font-series|medium|<with|font-size|1|<space|0.2fn>.<space|0.2fn>>>>>|<htab|5mm>>
      <no-break><pageref|auto-24>>

      <vspace*|1fn><with|font-series|<quote|bold>|math-font-series|<quote|bold>|<new-page*>Example:
      Phrase search> <datoms|<macro|x|<repeat|<arg|x>|<with|font-series|medium|<with|font-size|1|<space|0.2fn>.<space|0.2fn>>>>>|<htab|5mm>>
      <no-break><pageref|auto-25><vspace|0.5fn>

      <with|par-left|<quote|3fn>|<new-page*>Naive implementation of phrase
      search <datoms|<macro|x|<repeat|<arg|x>|<with|font-series|medium|<with|font-size|1|<space|0.2fn>.<space|0.2fn>>>>>|<htab|5mm>>
      <no-break><pageref|auto-26>>

      <with|par-left|<quote|3fn>|<new-page*>Replace association list with
      hash table <datoms|<macro|x|<repeat|<arg|x>|<with|font-series|medium|<with|font-size|1|<space|0.2fn>.<space|0.2fn>>>>>|<htab|5mm>>
      <no-break><pageref|auto-27>>

      <with|par-left|<quote|3fn>|<new-page*>Replace naive merging with
      ordered merging <datoms|<macro|x|<repeat|<arg|x>|<with|font-series|medium|<with|font-size|1|<space|0.2fn>.<space|0.2fn>>>>>|<htab|5mm>>
      <no-break><pageref|auto-28>>

      <with|par-left|<quote|3fn>|<new-page*>Bruteforce optimization: biword
      indexes <datoms|<macro|x|<repeat|<arg|x>|<with|font-series|medium|<with|font-size|1|<space|0.2fn>.<space|0.2fn>>>>>|<htab|5mm>>
      <no-break><pageref|auto-29>>

      <with|par-left|<quote|1.5fn>|<new-page*>Smart way:
      <with|font-shape|<quote|italic>|Information Retrieval> G.V. Cormack et
      al. <datoms|<macro|x|<repeat|<arg|x>|<with|font-series|medium|<with|font-size|1|<space|0.2fn>.<space|0.2fn>>>>>|<htab|5mm>>
      <no-break><pageref|auto-30>>

      <with|par-left|<quote|3fn>|<new-page*>The phrase search algorithm
      <datoms|<macro|x|<repeat|<arg|x>|<with|font-series|medium|<with|font-size|1|<space|0.2fn>.<space|0.2fn>>>>>|<htab|5mm>>
      <no-break><pageref|auto-31>>

      <with|par-left|<quote|3fn>|<new-page*>Naive but purely functional
      inverted index <datoms|<macro|x|<repeat|<arg|x>|<with|font-series|medium|<with|font-size|1|<space|0.2fn>.<space|0.2fn>>>>>|<htab|5mm>>
      <no-break><pageref|auto-32>>

      <with|par-left|<quote|3fn>|<new-page*>Binary search based inverted
      index <datoms|<macro|x|<repeat|<arg|x>|<with|font-series|medium|<with|font-size|1|<space|0.2fn>.<space|0.2fn>>>>>|<htab|5mm>>
      <no-break><pageref|auto-33>>

      <with|par-left|<quote|3fn>|<new-page*>Imperative, linear scan
      <datoms|<macro|x|<repeat|<arg|x>|<with|font-series|medium|<with|font-size|1|<space|0.2fn>.<space|0.2fn>>>>>|<htab|5mm>>
      <no-break><pageref|auto-34>>

      <with|par-left|<quote|3fn>|<new-page*>Imperative, galloping search
      <datoms|<macro|x|<repeat|<arg|x>|<with|font-series|medium|<with|font-size|1|<space|0.2fn>.<space|0.2fn>>>>>|<htab|5mm>>
      <no-break><pageref|auto-35>>
    </associate>
  </collection>
</auxiliary>