<TeXmacs|1.0.7.16>

<style|<tuple|beamer|highlight|beamer-metal-lighter>>

<\body>
  <doc-data|<doc-title|Functional Programming>|<\doc-author-data|<author-name|Šukasz
  Stafiniak>>
    \;
  </doc-author-data|<author-email|lukstafi@gmail.com,
  lukstafi@ii.uni.wroc.pl>|<\author-homepage>
    www.ii.uni.wroc.pl/~lukstafi
  </author-homepage>>>

  <doc-data|<doc-title|Lecture 6: Folding and Backtracking>|<\doc-subtitle>
    Mapping and folding.<next-line>Backtracking using lists. Constraint
    solving.

    <\small>
      Martin Odersky ``Functional Programming Fundamentals'' Lectures 2, 5
      and 6

      Bits of Ralf Laemmel ``Going Bananas''

      Graham Hutton ``Programming in Haskell'' Chapter 11 ``Countdown
      Problem''

      Tomasz Wierzbicki ``<em|Honey Islands> Puzzle Solver''
    </small>
  </doc-subtitle>|>

  <center|If you see any error on the slides, let me know!>

  <section|Plan>

  <\itemize>
    <item><verbatim|map> and <verbatim|fold_right>: recursive function
    examples, abstracting over gets the higher-order functions.

    <item>Reversing list example, tail-recursive variant,
    <verbatim|fold_left>.

    <item>Trimming a list: <verbatim|filter>.

    <\itemize>
      <item>Another definition via <verbatim|fold_right>.
    </itemize>

    <item><verbatim|map> and <verbatim|fold> for trees and other data
    structures.

    <item>The point-free programming style. A bit of history: the FP
    language.

    <item>Sum over an interval example: <math|<big|sum><rsub|n=a><rsup|b>f<around*|(|n|)>>.

    <item>Combining multiple results: <verbatim|concat_map>.

    <item>Interlude: generating all subsets of a set (as list), and as
    exercise: all permutations of a list.

    <item>The Google problem: the <verbatim|map_reduce> higher-order
    function.

    <\itemize>
      <item>Homework reference: modified <verbatim|map_reduce> to

      <\enumerate>
        <item>build a histogram of a list of documents

        <item>build an inverted index for a list of documents
      </enumerate>

      Later: use <verbatim|fold> (?) to search for a set of words
      (conjunctive query).
    </itemize>

    <item>Puzzles: checking correctness of a solution.

    <item>Combining bags of intermediate results: the <verbatim|concat_fold>
    functions.

    <item>From checking to generating solutions.

    <item>Improving ``generate-and-test'' by filtering (propagating
    constraints) along the way.

    <item>Constraint variables, splitting and constraint propagation.

    <item>Another example with ``heavier'' constraint propagation.
  </itemize>

  <section|<new-page*>Basic generic list operations>

  How to print a comma-separated list of integers? In module
  <verbatim|String>:

  <hlkwa|val ><hlstd|concat ><hlopt|: ><hlkwb|string ><hlopt|-\<gtr\>
  ><hlkwb|string ><hlstd|list ><hlopt|-\<gtr\> ><hlkwb|string><hlendline|>

  First convert numbers into strings:

  <hlkwa|let rec ><hlstd|strings<textunderscore>of<textunderscore>ints
  ><hlopt|= ><hlkwa|function><hlendline|><next-line><hlstd| \ ><hlopt|\| []
  -\<gtr\> []><hlendline|><next-line><hlstd| \ <hlopt|\|>
  hd><hlopt|::><hlstd|tl ><hlopt|-\<gtr\>
  ><hlstd|string<textunderscore>of<textunderscore>int hd ><hlopt|::
  ><hlstd|strings<textunderscore>of<textunderscore>ints
  tl><hlendline|><next-line><hlkwa|let ><hlstd|comma<textunderscore>sep<textunderscore>ints
  ><hlopt|= ><hlkwc|String><hlopt|.><hlstd|concat ><hlstr|", "><hlstd|
  ><hlopt|-><hlstd|<hlopt|\|> strings<textunderscore>of<textunderscore>ints><hlendline|>

  How to get strings sorted from shortest to longest? First find the length:

  <hlkwa|let rec ><hlstd|strings<textunderscore>lengths ><hlopt|=
  ><hlkwa|function><hlendline|><next-line><hlstd| \ ><hlopt|\| [] -\<gtr\>
  []><hlendline|><next-line><hlstd| \ <hlopt|\|> hd><hlopt|::><hlstd|tl
  ><hlopt|-\<gtr\> (><hlkwc|String><hlopt|.><hlstd|length hd><hlopt|,
  ><hlstd|hd><hlopt|) :: ><hlstd|strings<textunderscore>lengths
  tl><hlendline|><next-line><hlkwa|let ><hlstd|by<textunderscore>size
  ><hlopt|= ><hlkwc|List><hlopt|.><hlstd|sort compare
  ><hlopt|-><hlstd|<hlopt|\|> strings<textunderscore>lengths><hlendline|>

  <subsection|<new-page*>Always extract common patterns>

  <draw-over|<tabular|<tformat|<table|<row|<cell|<hlkwa|let rec
  ><hlstd|strings<textunderscore>of<textunderscore>ints ><hlopt|=
  ><hlkwa|function><hlendline|>>>|<row|<cell|<hlstd| \ ><hlopt|\| [] -\<gtr\>
  []><hlendline|>>>|<row|<cell|<hlstd| \ <hlopt|\|> hd><hlopt|::><hlstd|tl
  ><hlopt|-\<gtr\> ><hlstd|string<textunderscore>of<textunderscore>int hd
  ><hlopt|:: ><hlstd|strings<textunderscore>of<textunderscore>ints
  tl><hlendline|>>>|<row|<cell|>>|<row|<cell|<hlkwa|let rec
  ><hlstd|strings<textunderscore>lengths ><hlopt|=
  ><hlkwa|function><hlendline|>>>|<row|<cell|<hlstd| \ ><hlopt|\| [] -\<gtr\>
  []><hlendline|>>>|<row|<cell|<hlstd| \ <hlopt|\|> hd><hlopt|::><hlstd|tl
  ><hlopt|-\<gtr\> (><hlkwc|String><hlopt|.><hlstd|length hd><hlopt|,
  ><hlstd|hd><hlopt|) :: ><hlstd|strings<textunderscore>lengths
  tl><hlendline|>>>|<row|<cell|>>|<row|<cell|<hlkwa|let rec
  ><hlstd|list<textunderscore>map f ><hlopt|=
  ><hlkwa|function><hlendline|>>>|<row|<cell|<hlstd| \ ><hlopt|\| [] -\<gtr\>
  []><hlendline|>>>|<row|<cell|<hlstd| \ <hlopt|\|> hd><hlopt|::><hlstd|tl
  ><hlopt|-\<gtr\> ><hlstd|f hd ><hlopt|:: ><hlstd|list<textunderscore>map f
  tl><hlendline|>>>>>>|<with|gr-line-width|2ln|gr-mode|<tuple|edit|line>|gr-color|dark
  green|gr-arrow-end|\|\<gtr\>|<graphics|<with|color|red|line-width|2ln|<cspline|<point|1.58948|2.88912>|<point|4.9126703267628|3.01612316443974>|<point|7.1563533536182|2.78328813335097>|<point|6.09801230321471|2.12711668210081>|<point|2.13981677470565|2.12711668210081>|<point|1.48364532345548|2.29645125016537>>>|<with|color|red|line-width|2ln|<cspline|<point|3.70616|-0.56107>|<point|6.6695164704326|-0.455235480883715>|<point|9.37886955946554|-0.603403227940204>|<point|8.15119394099749|-1.32307514221458>|<point|4.36233298055298|-1.19607421616616>>>|<with|color|red|line-width|2ln|<cspline|<point|-8.06259|4.51897>|<point|-5.43790514618336|4.62480156105305>|<point|-2.53805066807779|4.56130109802884>|<point|-3.511724434449|3.79929554173833>|<point|-7.57575406799841|3.92629646778674>>>|<with|color|red|line-width|2ln|<cspline|<point|-7.91442|1.15344>|<point|-4.50656502182828|1.30161066278608>|<point|-2.45338338404551|0.984108347665035>|<point|-3.65989218150549|0.391437359439079>|<point|-7.57575406799841|0.454937822463289>>>|<with|color|red|arrow-end|\|\<gtr\>|line-width|2ln|<line|<point|1.48365|2.27528>|<point|-0.506035851303082|-3.63025863209419>>>|<with|color|red|arrow-end|\|\<gtr\>|line-width|2ln|<line|<point|4.34117|-1.21724>|<point|0.255969704987432|-3.63025863209419>>>|<with|color|red|arrow-end|\|\<gtr\>|line-width|2ln|<line|<point|-7.63925|3.88396>|<point|-7.66042135203069|-2.1485811615293>>>|<with|color|red|arrow-end|\|\<gtr\>|line-width|2ln|<line|<point|-3.65989|0.370271>|<point|-6.55974665961106|-2.12741434052123>>>|<with|color|red|line-width|2ln|<cspline|<point|-8.16843|-2.31792>|<point|-5.94590885037703|-2.21208162455351>|<point|-4.16789588569917|-2.27558208757772>|<point|-4.76056687392512|-2.88941989681175>|<point|-7.78742227807911|-2.86825307580368>>>|<with|color|red|line-width|2ln|<cspline|<point|-2.72855|-3.79959>|<point|-0.506035851303082|-3.63025863209419>|<point|0.742806588173039|-4.05359505225559>|<point|0.213636062971293|-4.60393239846541>|<point|-2.79205252017463|-4.41343100939278>>>|<with|color|dark
  green|line-width|2ln|<cspline|<point|-5.84007|2.78329>|<point|-2.91905344622305|3.01612316443974>|<point|-1.0563731975129|2.78328813335097>|<point|-1.69137782775499|2.14828350310888>|<point|-5.39557150416722|2.23295078714116>>>|<with|color|dark
  green|line-width|2ln|<cspline|<point|-5.33207|-0.476402>|<point|-0.992872734488689|-0.264734091811086>|<point|1.75881399656039|-0.539902764915994>|<point|0.785140230189178|-1.21724103717423>|<point|-4.52773184283635|-1.19607421616616>>>|<with|color|dark
  green|arrow-end|\|\<gtr\>|line-width|2ln|<line|<point|-5.45907|2.19062>|<point|-5.62840653525599|-3.71492591612647>>>|<with|color|dark
  green|arrow-end|\|\<gtr\>|line-width|2ln|<line|<point|-4.52773|-1.23841>|<point|-5.45907196719143|-3.77842637915068>>>>>>

  Now use the generic function:

  <hlkwa|let ><hlstd|comma<textunderscore>sep<textunderscore>ints
  ><hlopt|=><hlendline|><next-line><hlstd|
  \ ><hlkwc|String><hlopt|.><hlstd|concat ><hlstr|", "><hlstd|
  ><hlopt|-><hlstd|<hlopt|\|> list<textunderscore>map
  string<textunderscore>of<textunderscore>int><hlendline|><next-line><hlkwa|let
  ><hlstd|by<textunderscore>size ><hlopt|=><hlendline|><next-line><hlstd|
  \ ><hlkwc|List><hlopt|.><hlstd|sort compare ><hlopt|-><hlstd|<hlopt|\|>
  list<textunderscore>map ><hlopt|(><hlkwa|fun
  ><hlstd|s><hlopt|-\<gtr\>><hlkwc|String><hlopt|.><hlstd|length s><hlopt|,
  ><hlstd|s><hlopt|)><hlendline|>

  <new-page*><draw-over|<tabular|<tformat|<cwith|6|6|1|1|cell-halign|r>|<cwith|1|1|1|1|cell-halign|r>|<cwith|10|10|1|1|cell-halign|r>|<table|<row|<cell|How
  to sum elements of a list?>>|<row|<cell|<hlkwa|let rec ><hlstd|balance
  ><hlopt|= ><hlkwa|function><hlendline|>>>|<row|<cell|<hlstd| \ ><hlopt|\|
  [] -\<gtr\> ><hlnum|0><hlendline|>>>|<row|<cell|<hlstd| \ <hlopt|\|>
  hd><hlopt|::><hlstd|tl ><hlopt|-\<gtr\> ><hlstd|hd ><hlopt|+
  ><hlstd|balance tl><hlendline|>>>|<row|<cell|>>|<row|<cell|How to multiply
  elements in a list?>>|<row|<cell|<hlkwa|let rec
  ><hlstd|total<textunderscore>ratio ><hlopt|=
  ><hlkwa|function><hlendline|>>>|<row|<cell|<hlstd| \ ><hlopt|\| [] -\<gtr\>
  ><hlnum|1><hlopt|.><hlendline|>>>|<row|<cell|<hlstd| \ <hlopt|\|>
  hd><hlopt|::><hlstd|tl ><hlopt|-\<gtr\> ><hlstd|hd ><hlopt|*.
  ><hlstd|total<textunderscore>ratio tl><hlendline|>>>|<row|<cell|Generic
  solution:>>|<row|<cell|<hlkwa|let rec ><hlstd|list<textunderscore>fold f
  base ><hlopt|= ><hlkwa|function><hlendline|>>>|<row|<cell|<hlstd|
  \ ><hlopt|\| [] -\<gtr\> ><hlstd|base><hlendline|>>>|<row|<cell|<hlstd|
  \ <hlopt|\|> hd><hlopt|::><hlstd|tl ><hlopt|-\<gtr\> ><hlstd|f hd
  ><hlopt|(><hlstd|list<textunderscore>fold f base
  tl><hlopt|)><hlendline|>>>|<row|<cell|>>|<row|<cell|Caution:
  <verbatim|list_fold f base l> = <verbatim|List.fold_right f l
  base>.>>>>>|<with|gr-color|dark green|gr-mode|<tuple|edit|line>|gr-arrow-end|\|\<gtr\>|<graphics|<with|color|red|<cspline|<point|-6.96828|5.20805>|<point|-5.59243947612118|5.48321537240376>|<point|-4.23776293160471|5.22921352030692>|<point|-4.57643206773383|4.72120981611324>|<point|-6.35444503241169|4.70004299510517>>>|<with|color|red|<cspline|<point|-6.69311|1.18635>|<point|-4.68226617277418|1.24985117078979>|<point|-2.75608546103982|1.1016834237333>|<point|-3.30642280724964|0.509012435507342>|<point|-6.35444503241169|0.466678793491203>>>|<with|color|red|<cspline|<point|-2.26925|3.7687>|<point|-0.872238391321604|3.7687028707501>|<point|-0.110232835031089|3.45120055562905>|<point|-0.575902897208626|3.04903095647572>|<point|-2.69258499801561|3.11253141949993>>>|<with|color|red|<cspline|<point|-2.37508|-0.549329>|<point|-0.512402434184416|-0.379994046831591>|<point|1.73128059267099|-0.59166225691229>|<point|1.05394232041275|-1.16316642413018>|<point|-2.03641354676544|-1.12083278211404>>>|<with|color|red|<cspline|<point|-6.92595|-2.36968>|<point|-4.02609472152401|-2.11567336949332>|<point|-0.999239317370023|-2.34850840058209>|<point|-1.48607620055563|-2.87767892578383>|<point|-6.07927635930679|-2.87767892578383>>>|<with|color|red|<cspline|<point|-2.26925|-3.91485>|<point|1.49844556158222|-3.80901905013891>|<point|3.40345945230851|-4.06302090223575>|<point|2.93778939013097|-4.52869096441328>|<point|-1.27440799047493|-4.61335824844556>>>|<with|color|red|arrow-end|\|\<gtr\>|<line|<point|-6.35445|4.70004>|<point|-6.10044318031486|-2.2003406535256>>>|<with|color|red|arrow-end|\|\<gtr\>|<line|<point|-3.30642|0.509012>|<point|-5.10853954194466|-2.14605530848409>>>|<with|color|red|arrow-end|\|\<gtr\>|<line|<point|-2.73492|3.11253>|<point|-1.38460084405009|-3.80695034949837>>>|<with|color|red|arrow-end|\|\<gtr\>|<line|<point|1.05394|-1.18433>|<point|0.19997872622222|-3.78626681481166>>>|<with|color|dark
  green|<carc|<point|-3.56042|3.4512>|<point|-3.20058870220929|3.133698240508>|<point|-3.07358777616087|3.64170194470168>>>|<with|color|dark
  green|<carc|<point|-3.58159|-0.760997>|<point|-2.90425320809631|-0.54932861489615>|<point|-2.75608546103982|-0.866830930017198>>>|<with|color|dark
  green|<carc|<point|-4.70343|-4.21119>|<point|-4.08959518454822|-4.10535454425189>|<point|-4.1742624685805|-4.48635732239714>>>|<with|color|dark
  green|arrow-end|\|\<gtr\>|<line|<point|-3.24292|3.11253>|<point|-4.3859306786612|-3.87251951316312>>>|<with|color|dark
  green|arrow-end|\|\<gtr\>|<line|<point|-3.26132|-1.28056>|<point|-4.23776293160471|-3.9571867971954>>>>>>

  <new-page*>

  <tabular|<tformat|<cwith|3|3|1|1|cell-halign|c>|<cwith|3|3|1|1|cell-valign|b>|<cwith|3|3|2|2|cell-valign|c>|<cwith|1|1|1|1|cell-col-span|3>|<cwith|2|2|1|1|cell-col-span|3>|<cwith|3|3|5|5|cell-halign|c>|<cwith|3|3|5|5|cell-valign|c>|<cwith|1|1|4|4|cell-col-span|3>|<cwith|2|2|4|4|cell-col-span|3>|<table|<row|<cell|<verbatim|map>
  alters the contents of data>|<cell|>|<cell|>|<cell|<verbatim|fold> computes
  a value using>|<cell|>|<cell|>>|<row|<cell|without changing the
  structure:>|<cell|>|<cell|>|<cell|the structure as a
  scaffolding:>|<cell|>|<cell|>>|<row|<cell|<math|<tree|\<colons\>|a|<tree|\<colons\>|b|<tree|\<colons\>|c|<tree|\<colons\>|d|<around*|[||]>>>>>>>|<cell|<math|\<Rightarrow\>>>|<cell|<math|<tree|\<colons\>|f
  a|<tree|\<colons\>|f b|<tree|\<colons\>|f c|<tree|\<colons\>|f
  d|<around*|[||]>>>>>>>|<cell|<math|<tree|\<colons\>|a|<tree|\<colons\>|b|<tree|\<colons\>|c|<tree|\<colons\>|d|<around*|[||]>>>>>>>|<cell|<math|\<Rightarrow\>>>|<cell|<math|<tree|f|a|<tree|f|b|<tree|f|c|<tree|f|d|accu>>>>>>>>>>

  <subsection|<new-page*>Can we make <verbatim|fold> tail-recursive?>

  Let's investigate some tail-recursive functions. (Not hidden as helpers.)

  <draw-over|<tabular|<tformat|<table|<row|<cell|<hlkwa|let rec
  ><hlstd|list<textunderscore>rev acc ><hlopt|=
  ><hlkwa|function>>>|<row|<cell|<hlstd| \ ><hlopt|\| [] -\<gtr\>
  ><verbatim|acc><hlendline|>>>|<row|<cell|<verbatim| \ <hlopt|\|>
  hd><hlopt|::><hlstd|tl ><hlopt|-\<gtr\> ><hlstd|list<textunderscore>rev
  ><hlopt|(><hlstd|hd><hlopt|::><hlstd|acc><hlopt|)
  ><hlstd|tl><hlendline|>>>|<row|<cell|>>|<row|<cell|<hlkwa|let rec
  ><hlstd|average ><hlopt|(><hlstd|sum><hlopt|, ><hlstd|tot><hlopt|) =
  ><hlkwa|function><hlendline|><next-line>>>|<row|<cell|<hlstd| \ ><hlopt|\|
  [] ><hlkwa|when ><hlstd|tot ><hlopt|= ><hlnum|0><hlopt|. -\<gtr\>
  ><hlnum|0><hlopt|.><hlendline|>>>|<row|<cell|<hlstd| \ ><hlopt|\| []
  -\<gtr\> ><hlstd|sum ><hlopt|/. >tot<hlendline|>>>|<row|<cell|<verbatim|
  \ ><hlopt|\|> hd<hlopt|::><hlstd|tl ><hlopt|-\<gtr\> ><hlstd|average
  ><hlopt|(><hlstd|hd ><hlopt|+. ><hlstd|sum><hlopt|, ><hlnum|1><hlopt|. +.
  ><hlstd|tot><hlopt|)><verbatim| tl><hlendline|>>>|<row|<cell|>>|<row|<cell|<hlkwa|let
  rec ><hlstd|fold<textunderscore>left f accu ><hlopt|=
  ><hlkwa|function><hlendline|><next-line>>>|<row|<cell|<hlstd| \ ><hlopt|\|
  [] -\<gtr\> ><hlstd|accu><hlendline|><next-line>>>|<row|<cell|<hlstd|
  \ <hlopt|\|> a><hlopt|::><hlstd|l ><hlopt|-\<gtr\>
  ><hlstd|fold<textunderscore>left f ><hlopt|(><hlstd|f accu a><hlopt|)
  ><hlstd|l><hlendline|><next-line>>>>>>|<with|gr-color|orange|gr-mode|<tuple|edit|line>|gr-arrow-end|\|\<gtr\>|<graphics|<with|color|red|<cspline|<point|-5.90994|4.94728>|<point|-3.72975922741103|5.01078184945099>|<point|-1.48607620055563|4.88378092340257>|<point|-2.09991400978965|4.33344357719275>|<point|-5.33843762402434|4.26994311416854>>>|<with|color|red|<cspline|<point|-5.86761|1.47592>|<point|-2.75608546103982|1.66642413017595>|<point|0.715273184283635|1.49708956211139>|<point|-0.448901971160206|0.925585394893504>|<point|-4.93626802487101|0.925585394893504>>>|<with|color|red|<cspline|<point|-6.01578|-2.79978>|<point|-2.69258499801561|-2.56694007143802>|<point|-0.152566477047228|-2.79977510252679>|<point|-0.427735150152137|-3.30777880672047>|<point|-4.57643206773383|-3.35011244873661>>>|<with|color|red|<cspline|<point|-3.75093|3.06343>|<point|-2.12108083079772|3.29626934779733>|<point|-0.597069718216695|3.04226749570049>|<point|-2.22691493583807|2.55543061251488>>>|<with|color|red|<cspline|<point|-4.02609|-1.1911>|<point|-2.45974996692684|-0.852427569784363>|<point|-1.21090752745072|-1.25459716893769>|<point|-2.43858314591877|-1.63559994708295>>>|<with|color|red|<cspline|<point|-4.5341|-4.40845>|<point|-2.37508268289456|-4.28145257309168>|<point|-0.343067866119857|-4.4084534991401>|<point|-1.02040613837809|-4.93762402434184>|<point|-3.83559333245138|-4.93762402434184>>>|<with|color|dark
  green|<cspline|<point|-0.110233|3.29627>|<point|1.49844556158222|3.42327027384575>|<point|2.87428892710676|3.23276888477312>|<point|2.17578383384045|2.55543061251488>|<point|0.143769017065749|2.57659743352295>>>|<with|color|dark
  green|<cspline|<point|-0.491236|-0.958262>|<point|3.61512766238921|-0.810093927768223>|<point|7.04415266569652|-1.06409577986506>|<point|5.71064294218812|-1.72026723111523>|<point|0.524771795211007|-1.67793358909909>>>|<with|color|dark
  green|<cspline|<point|0.376604|-4.30262>|<point|2.21811747585659|-4.23911893107554>|<point|3.61512766238921|-4.42962032014817>|<point|3.17062442121974|-4.91645720333377>|<point|0.799940468315915|-4.95879084534991>>>|<with|color|red|arrow-end|\|\<gtr\>|<arc|<point|-5.33844|4.29111>|<point|-6.07927635930679|-2.16477047228469>|<point|-5.69827358116153|-2.69394099748644>>>|<with|color|red|arrow-end|\|\<gtr\>|<arc|<point|-4.95743|0.967919>|<point|-5.48660537108083|-1.97426908321207>|<point|-5.44427172906469|-2.6516073554703>>>|<with|color|red|arrow-end|\|\<gtr\>|<arc|<point|-2.22691|2.55543>|<point|-2.03641354676544|-3.62528112184151>|<point|-2.37508268289456|-4.28145257309168>>>|<with|color|red|arrow-end|\|\<gtr\>|<arc|<point|-2.41742|-1.61443>|<point|-2.69258499801561|-3.79461568990607>|<point|-2.80072853017803|-4.28328408586729>>>|<with|color|dark
  green|arrow-end|\|\<gtr\>|<arc|<point|2.89546|3.25394>|<point|5.64714247916391|-2.39760550337346>|<point|3.72096176742955|-4.42962032014817>>>|<with|color|dark
  green|arrow-end|\|\<gtr\>|<arc|<point|4.73754|-1.78676>|<point|4.14429818759095|-3.41361291176081>|<point|3.50929355734886|-4.32378621510782>>>|<with|color|green|arrow-end|\|\<gtr\>|<line|<point|0.503605|2.7036>|<point|3.00128985315518|-4.49312078317238>>>|<with|color|green|arrow-end|\|\<gtr\>|<line|<point|-0.0678992|-1.5086>|<point|2.89545574811483|-4.59895488821273>>>|<with|color|orange|arrow-end|\|\<gtr\>|<line|<point|1.75245|2.7036>|<point|1.62544648763064|-4.45078714115624>>>|<with|color|orange|<line|<point|2.47212|-1.5721>|<point|3.04362349517132|-2.46110596639767>>>|<with|color|orange|<line|<point|6.17631|-1.5086>|<point|3.04362349517132|-2.46110596639767>>>|<with|color|orange|arrow-end|\|\<gtr\>|<line|<point|3.04362|-2.46111>|<point|2.02761608678397|-4.36611985712396>>>>>><hlendline|>

  <\itemize>
    <new-page*><item>With <verbatim|fold_left>, it is easier to hide the
    accumulator. The <verbatim|average> example is a bit more tricky than
    <verbatim|list_rev>.

    <hlkwa|let ><hlstd|list<textunderscore>rev l
    ><hlopt|=><hlendline|><next-line><hlstd| \ fold<textunderscore>left
    ><hlopt|(><hlkwa|fun ><hlstd|t h><hlopt|-\<gtr\>><hlstd|h><hlopt|::><hlstd|t><hlopt|)
    [] ><hlstd|l><hlendline|><next-line><hlkwa|let ><hlstd|average
    ><hlopt|=><hlendline|><next-line><hlstd| \ fold<textunderscore>left
    ><hlopt|(><hlkwa|fun ><hlopt|(><hlstd|sum><hlopt|,><hlstd|tot><hlopt|)
    ><hlstd|e><hlopt|-\<gtr\>><hlstd|sum ><hlopt|+. ><hlstd|e><hlopt|,
    ><hlnum|1><hlopt|. +. ><hlstd|tot><hlopt|)
    (><hlnum|0><hlopt|.,><hlnum|0><hlopt|.)>

    <item>The function names and order of arguments for
    <verbatim|List.fold_right> / <verbatim|List.fold_left> are due to:

    <\itemize>
      <item><verbatim|fold_right f> makes <verbatim|f> <em|right
      associative>, like list constructor <verbatim|::>

      <small|<hlkwc|List><hlopt|.><hlstd|fold<textunderscore>right f
      ><hlopt|[><hlstd|a1><hlopt|; ...; ><hlstd|an><hlopt|] ><hlstd|b> is
      <hlstd|f a1 ><hlopt|(><hlstd|f a2 ><hlopt|(... (><hlstd|f an b><hlopt|)
      ...))>.>

      <item><verbatim|fold_left f> makes <verbatim|f> <em|left associative>,
      like function application

      <small|<hlkwc|List><hlopt|.><hlstd|fold<textunderscore>left f a
      ><hlopt|[><hlstd|b1><hlopt|; ...; ><hlstd|bn><hlopt|]> is <hlstd|f
      ><hlopt|(... (><hlstd|f ><hlopt|(><hlstd|f a b1><hlopt|)
      ><hlstd|b2><hlopt|) ...) ><hlstd|bn>.>
    </itemize>

    <new-page*><item>The ``backward'' structure of <verbatim|fold_left>
    computation:

    <tabular|<tformat|<cwith|1|1|2|2|cell-halign|c>|<cwith|1|1|2|2|cell-valign|c>|<table|<row|<cell|<math|<tree|\<colons\>|a|<tree|\<colons\>|b|<tree|\<colons\>|c|<tree|\<colons\>|d|<around*|[||]>>>>>>>|<cell|<math|\<Rightarrow\>>>|<cell|<math|<tree|f|<tree|f|<tree|f|<tree|f|accu|a>|b>|c>|d>>>>>>>

    <item>List filtering, already rather generic (a polymorphic higher-order
    function)

    <hlkwa|let ><hlstd|list<textunderscore>filter p l
    ><hlopt|=><hlendline|><next-line><hlstd|
    \ ><hlkwc|List><hlopt|.><hlstd|fold<textunderscore>right
    ><hlopt|(><hlkwa|fun ><hlstd|h t><hlopt|-\<gtr\>><hlkwa|if ><hlstd|p h
    ><hlkwa|then ><hlstd|h><hlopt|::><hlstd|t ><hlkwa|else ><hlstd|t><hlopt|)
    ><hlstd|l ><hlopt|[]><hlendline|>

    <item>Tail-recursive map returning elements in reverse order:

    <hlkwa|let ><hlstd|list<textunderscore>rev<textunderscore>map f l
    ><hlopt|=><hlendline|><next-line><hlstd|
    \ ><hlkwc|List><hlopt|.><hlstd|fold<textunderscore>left
    ><hlopt|(><hlkwa|fun ><hlstd|t h><hlopt|-\<gtr\>><hlstd|f
    h><hlopt|::><hlstd|t><hlopt|) [] ><hlstd|l><hlendline|><next-line>
  </itemize>

  <section|<new-page*><verbatim|map> and <verbatim|fold> for trees and other
  structures>

  <\itemize>
    <item>Mapping binary trees is straightforward:

    <hlkwa|type ><hlstr|'a btree = Empty <hlopt|\|> Node of '><hlstd|a
    ><hlopt|* ><hlstr|'a btree * '><hlstd|a btree<hlendline|><next-line>
    \ \ \ ><hlendline|><next-line><hlkwa|let rec
    ><hlstd|bt<textunderscore>map f ><hlopt|=
    ><hlkwa|function><hlendline|><next-line><hlstd| \ ><hlopt|\|
    ><hlkwd|Empty ><hlopt|-\<gtr\> ><hlkwd|Empty><hlendline|><next-line><hlstd|
    \ ><hlopt|\| ><hlkwd|Node ><hlopt|(><hlstd|e><hlopt|, ><hlstd|l><hlopt|,
    ><hlstd|r><hlopt|) -\<gtr\> ><hlkwd|Node ><hlopt|(><hlstd|f e><hlopt|,
    ><hlstd|bt<textunderscore>map f l><hlopt|, ><hlstd|bt<textunderscore>map
    f r><hlopt|)><hlendline|><next-line><hlstd|
    \ ><hlendline|><next-line><hlkwa|let ><hlstd|test ><hlopt|=
    ><hlkwd|Node><hlendline|><next-line><hlstd| \ ><hlopt|(><hlnum|3><hlopt|,
    ><hlkwd|Node ><hlopt|(><hlnum|5><hlopt|, ><hlkwd|Empty><hlopt|,
    ><hlkwd|Empty><hlopt|), ><hlkwd|Node ><hlopt|(><hlnum|7><hlopt|,
    ><hlkwd|Empty><hlopt|, ><hlkwd|Empty><hlopt|))><hlendline|><next-line><hlkwa|let
    ><hlstd|<textunderscore> ><hlopt|= ><hlstd|bt<textunderscore>map
    ><hlopt|((+) ><hlnum|1><hlopt|) ><hlstd|test>

    <item><verbatim|map> and <verbatim|fold> we consider in this section
    preserve / respect the structure of the data, they <strong|do not>
    correspond to <verbatim|map> and <verbatim|fold> of <em|abstract data
    type> containers, which are like <verbatim|List.rev_map> and
    <verbatim|List.fold_left> over container elements listed in arbitrary
    order.

    <\itemize>
      <item>I.e. here we generalize <verbatim|List.map> and
      <verbatim|List.fold_right> to other structures.
    </itemize>

    <item><verbatim|fold> in most general form needs to process the element
    together with partial results for the subtrees.

    <hlkwa|let rec ><hlstd|bt<textunderscore>fold f base ><hlopt|=
    ><hlkwa|function><hlendline|><next-line><hlstd| \ ><hlopt|\|
    ><hlkwd|Empty ><hlopt|-\<gtr\> ><hlstd|base<hlendline|><next-line>
    \ ><hlopt|\| ><hlkwd|Node ><hlopt|(><hlstd|e><hlopt|, ><hlstd|l><hlopt|,
    ><hlstd|r><hlopt|) -\<gtr\>><hlendline|><next-line><hlstd| \ \ \ f e
    ><hlopt|(><hlstd|bt<textunderscore>fold f base l><hlopt|)
    (><hlstd|bt<textunderscore>fold f base r><hlopt|)><hlendline|>

    <item>Examples:

    <hlkwa|let ><hlstd|sum<textunderscore>els ><hlopt|=
    ><hlstd|bt<textunderscore>fold ><hlopt|(><hlkwa|fun ><hlstd|i l r
    ><hlopt|-\<gtr\> ><hlstd|i ><hlopt|+ ><hlstd|l ><hlopt|+
    ><hlstd|r><hlopt|) ><hlnum|0><hlendline|><next-line><hlkwa|let
    ><hlstd|depth t ><hlopt|= ><hlstd|bt<textunderscore>fold
    ><hlopt|(><hlkwa|fun ><hlstd|<textunderscore> l r ><hlopt|-\<gtr\>
    ><hlnum|1 ><hlopt|+ ><hlstd|max l r><hlopt|) ><hlnum|1
    ><hlstd|t><hlendline|>
  </itemize>

  <subsection|<new-page*><verbatim|map> and <verbatim|fold> for more complex
  structures>

  To have a data structure to work with, we recall expressions from lecture
  3.

  <hlkwa|type ><hlstd|expression ><hlopt|=><hlendline|><next-line><hlstd|
  \ \ \ \ ><hlkwd|Const ><hlkwa|of ><hlkwb|float><hlendline|><next-line><hlstd|
  \ \ ><hlopt|\| ><hlkwd|Var ><hlkwa|of ><hlkwb|string><hlendline|><next-line><hlstd|
  \ \ ><hlopt|\| ><hlkwd|Sum ><hlkwa|of ><hlstd|expression ><hlopt|*
  ><hlstd|expression \ \ \ ><hlcom|(* e1 + e2
  *)><hlstd|<hlendline|><next-line> \ \ ><hlopt|\| ><hlkwd|Diff ><hlkwa|of
  ><hlstd|expression ><hlopt|* ><hlstd|expression \ \ ><hlcom|(* e1 - e2
  *)><hlstd|<hlendline|><next-line> \ \ ><hlopt|\| ><hlkwd|Prod ><hlkwa|of
  ><hlstd|expression ><hlopt|* ><hlstd|expression \ \ ><hlcom|(* e1 * e2
  *)><hlstd|<hlendline|><next-line> \ \ ><hlopt|\| ><hlkwd|Quot ><hlkwa|of
  ><hlstd|expression ><hlopt|* ><hlstd|expression \ \ ><hlcom|(* e1 / e2
  *)><hlendline|>

  Multitude of cases make the datatype harder to work with. Fortunately,
  <em|or-<no-break>patterns> help a bit:

  <hlkwa|let rec ><hlstd|vars ><hlopt|= ><hlkwa|function><hlendline|><next-line><hlstd|
  \ ><hlopt|\| ><hlkwd|Const ><hlstd|<textunderscore> ><hlopt|-\<gtr\>
  []><hlendline|><next-line><hlstd| \ ><hlopt|\| ><hlkwd|Var ><hlstd|x
  ><hlopt|-\<gtr\> [><hlstd|x><hlopt|]><hlendline|><next-line><hlstd|
  \ ><hlopt|\| ><hlkwd|Sum ><hlopt|(><hlstd|a><hlopt|,><hlstd|b><hlopt|) \|
  ><hlkwd|Diff ><hlopt|(><hlstd|a><hlopt|,><hlstd|b><hlopt|) \| ><hlkwd|Prod
  ><hlopt|(><hlstd|a><hlopt|,><hlstd|b><hlopt|) \| ><hlkwd|Quot
  ><hlopt|(><hlstd|a><hlopt|,><hlstd|b><hlopt|)
  -\<gtr\>><hlendline|><next-line><hlstd| \ \ \ vars a @ vars b><hlendline|>

  <new-page*>Mapping and folding needs to be specialized for each case. We
  pack the behaviors into a record.

  <hlkwa|type ><hlstd|expression<textunderscore>map ><hlopt|=
  {><hlendline|><next-line><hlstd| \ map<textunderscore>const ><hlopt|:
  ><hlkwb|float ><hlopt|-\<gtr\> ><hlstd|expression><hlopt|;><hlendline|><next-line><hlstd|
  \ map<textunderscore>var ><hlopt|: ><hlkwb|string ><hlopt|-\<gtr\>
  ><hlstd|expression><hlopt|;><hlendline|><next-line><hlstd|
  \ map<textunderscore>sum ><hlopt|: ><hlstd|expression ><hlopt|-\<gtr\>
  ><hlstd|expression ><hlopt|-\<gtr\> ><hlstd|expression><hlopt|;><hlendline|><next-line><hlstd|
  \ map<textunderscore>diff ><hlopt|: ><hlstd|expression ><hlopt|-\<gtr\>
  ><hlstd|expression ><hlopt|-\<gtr\> ><hlstd|expression><hlopt|;><hlendline|><next-line><hlstd|
  \ map<textunderscore>prod ><hlopt|: ><hlstd|expression ><hlopt|-\<gtr\>
  ><hlstd|expression ><hlopt|-\<gtr\> ><hlstd|expression><hlopt|;><hlendline|><next-line><hlstd|
  \ map<textunderscore>quot ><hlopt|: ><hlstd|expression ><hlopt|-\<gtr\>
  ><hlstd|expression ><hlopt|-\<gtr\> ><hlstd|expression><hlopt|;><hlendline|><next-line><hlopt|}><hlendline|><next-line><hlendline|Note
  how <verbatim|expression> from above is substituted by <verbatim|'a> below,
  explain why?><next-line><hlkwa|type ><hlstr|'><hlstd|a
  expression<textunderscore>fold ><hlopt|= {><hlendline|><next-line><hlstd|
  \ fold<textunderscore>const ><hlopt|: ><hlkwb|float ><hlopt|-\<gtr\>
  ><hlstr|'><hlstd|a><hlopt|;><hlendline|><next-line><hlstd|
  \ fold<textunderscore>var ><hlopt|: ><hlkwb|string ><hlopt|-\<gtr\>
  ><hlstr|'><hlstd|a><hlopt|;><hlendline|><next-line><hlstd|
  \ fold<textunderscore>sum ><hlopt|: ><hlstr|'><hlstd|a ><hlopt|-\<gtr\>
  ><hlstr|'><hlstd|a ><hlopt|-\<gtr\> ><hlstr|'><hlstd|a><hlopt|;><hlendline|><next-line><hlstd|
  \ fold<textunderscore>diff ><hlopt|: ><hlstr|'><hlstd|a ><hlopt|-\<gtr\>
  ><hlstr|'><hlstd|a ><hlopt|-\<gtr\> ><hlstr|'><hlstd|a><hlopt|;><hlendline|><next-line><hlstd|
  \ fold<textunderscore>prod ><hlopt|: ><hlstr|'><hlstd|a ><hlopt|-\<gtr\>
  ><hlstr|'><hlstd|a ><hlopt|-\<gtr\> ><hlstr|'><hlstd|a><hlopt|;><hlendline|><next-line><hlstd|
  \ fold<textunderscore>quot ><hlopt|: ><hlstr|'><hlstd|a ><hlopt|-\<gtr\>
  ><hlstr|'><hlstd|a ><hlopt|-\<gtr\> ><hlstr|'><hlstd|a><hlopt|;><hlendline|><next-line><hlopt|}><hlendline|>

  Next we define standard behaviors for <verbatim|map> and <verbatim|fold>,
  which can be tailored to needs for particular case.

  <hlkwa|let ><hlstd|identity<textunderscore>map ><hlopt|=
  {><hlendline|><next-line><hlstd| \ map<textunderscore>const ><hlopt|=
  (><hlkwa|fun ><hlstd|c ><hlopt|-\<gtr\> ><hlkwd|Const
  ><hlstd|c><hlopt|);><hlendline|><next-line><hlstd| \ map<textunderscore>var
  ><hlopt|= (><hlkwa|fun ><hlstd|x ><hlopt|-\<gtr\> ><hlkwd|Var
  ><hlstd|x><hlopt|);><hlendline|><next-line><hlstd| \ map<textunderscore>sum
  ><hlopt|= (><hlkwa|fun ><hlstd|a b ><hlopt|-\<gtr\> ><hlkwd|Sum
  ><hlopt|(><hlstd|a><hlopt|, ><hlstd|b><hlopt|));><hlendline|><next-line><hlstd|
  \ map<textunderscore>diff ><hlopt|= (><hlkwa|fun ><hlstd|a b
  ><hlopt|-\<gtr\> ><hlkwd|Diff ><hlopt|(><hlstd|a><hlopt|,
  ><hlstd|b><hlopt|));><hlendline|><next-line><hlstd|
  \ map<textunderscore>prod ><hlopt|= (><hlkwa|fun ><hlstd|a b
  ><hlopt|-\<gtr\> ><hlkwd|Prod ><hlopt|(><hlstd|a><hlopt|,
  ><hlstd|b><hlopt|));><hlendline|><next-line><hlstd|
  \ map<textunderscore>quot ><hlopt|= (><hlkwa|fun ><hlstd|a b
  ><hlopt|-\<gtr\> ><hlkwd|Quot ><hlopt|(><hlstd|a><hlopt|,
  ><hlstd|b><hlopt|));><hlendline|><next-line><hlopt|}><hlendline|><next-line><hlendline|><next-line><hlkwa|let
  ><hlstd|make<textunderscore>fold op base ><hlopt|=
  {><hlendline|><next-line><hlstd| \ fold<textunderscore>const ><hlopt|=
  (><hlkwa|fun ><hlstd|<textunderscore> ><hlopt|-\<gtr\>
  ><hlstd|base><hlopt|);><hlendline|><next-line><hlstd|
  \ fold<textunderscore>var ><hlopt|= (><hlkwa|fun ><hlstd|<textunderscore>
  ><hlopt|-\<gtr\> ><hlstd|base><hlopt|);><hlendline|><next-line><hlstd|
  \ fold<textunderscore>sum ><hlopt|= ><hlstd|op><hlopt|;
  ><hlstd|fold<textunderscore>diff ><hlopt|=
  ><hlstd|op><hlopt|;><hlendline|><next-line><hlstd|
  \ fold<textunderscore>prod ><hlopt|= ><hlstd|op><hlopt|;
  ><hlstd|fold<textunderscore>quot ><hlopt|=
  ><hlstd|op><hlopt|;><hlendline|><next-line><hlopt|}><hlendline|>

  <new-page*>The actual <verbatim|map> and <verbatim|fold> functions are
  straightforward:

  <small|<hlkwa|let rec ><hlstd|expr<textunderscore>map emap ><hlopt|=
  ><hlkwa|function><hlendline|><next-line><hlstd| \ ><hlopt|\| ><hlkwd|Const
  ><hlstd|c ><hlopt|-\<gtr\> ><hlstd|emap><hlopt|.><hlstd|map<textunderscore>const
  c<hlendline|><next-line> \ ><hlopt|\| ><hlkwd|Var ><hlstd|x
  ><hlopt|-\<gtr\> ><hlstd|emap><hlopt|.><hlstd|map<textunderscore>var
  x<hlendline|><next-line> \ ><hlopt|\| ><hlkwd|Sum
  ><hlopt|(><hlstd|a><hlopt|,><hlstd|b><hlopt|) -\<gtr\>><hlstd|
  emap><hlopt|.><hlstd|map<textunderscore>sum
  ><hlopt|(><hlstd|expr<textunderscore>map emap a><hlopt|)
  (><hlstd|expr<textunderscore>map emap b><hlopt|)><hlendline|><next-line><hlstd|
  \ ><hlopt|\| ><hlkwd|Diff ><hlopt|(><hlstd|a><hlopt|,><hlstd|b><hlopt|)
  -\<gtr\>><hlstd| emap><hlopt|.><hlstd|map<textunderscore>diff
  ><hlopt|(><hlstd|expr<textunderscore>map emap a><hlopt|)
  (><hlstd|expr<textunderscore>map emap b><hlopt|)><hlendline|><next-line><hlstd|
  \ ><hlopt|\| ><hlkwd|Prod ><hlopt|(><hlstd|a><hlopt|,><hlstd|b><hlopt|)
  -\<gtr\>><hlstd| emap><hlopt|.><hlstd|map<textunderscore>prod
  ><hlopt|(><hlstd|expr<textunderscore>map emap a><hlopt|)
  (><hlstd|expr<textunderscore>map emap b><hlopt|)><hlendline|><next-line><hlstd|
  \ ><hlopt|\| ><hlkwd|Quot ><hlopt|(><hlstd|a><hlopt|,><hlstd|b><hlopt|)
  -\<gtr\>><hlstd| emap><hlopt|.><hlstd|map<textunderscore>quot
  ><hlopt|(><hlstd|expr<textunderscore>map emap a><hlopt|)
  (><hlstd|expr<textunderscore>map emap b><hlopt|)><hlendline|><next-line><hlendline|><next-line><hlkwa|let
  rec ><hlstd|expr<textunderscore>fold efold ><hlopt|=
  ><hlkwa|function><hlendline|><next-line><hlstd| \ ><hlopt|\| ><hlkwd|Const
  ><hlstd|c ><hlopt|-\<gtr\> ><hlstd|efold><hlopt|.><hlstd|fold<textunderscore>const
  c<hlendline|><next-line> \ ><hlopt|\| ><hlkwd|Var ><hlstd|x
  ><hlopt|-\<gtr\> ><hlstd|efold><hlopt|.><hlstd|fold<textunderscore>var
  x<hlendline|><next-line> \ ><hlopt|\| ><hlkwd|Sum
  ><hlopt|(><hlstd|a><hlopt|,><hlstd|b><hlopt|) -\<gtr\>><hlstd|
  efold><hlopt|.><hlstd|fold<textunderscore>sum
  ><hlopt|(><hlstd|expr<textunderscore>fold efold a><hlopt|)
  (><hlstd|expr<textunderscore>fold efold
  b><hlopt|)><hlendline|><next-line><hlstd| \ ><hlopt|\| ><hlkwd|Diff
  ><hlopt|(><hlstd|a><hlopt|,><hlstd|b><hlopt|) -\<gtr\>><hlstd|
  efold><hlopt|.><hlstd|fold<textunderscore>diff
  ><hlopt|(><hlstd|expr<textunderscore>fold efold a><hlopt|)
  (><hlstd|expr<textunderscore>fold efold
  b><hlopt|)><hlendline|><next-line><hlstd| \ ><hlopt|\| ><hlkwd|Prod
  ><hlopt|(><hlstd|a><hlopt|,><hlstd|b><hlopt|) -\<gtr\>><hlstd|
  efold><hlopt|.><hlstd|fold<textunderscore>prod
  ><hlopt|(><hlstd|expr<textunderscore>fold efold a><hlopt|)
  (><hlstd|expr<textunderscore>fold efold
  b><hlopt|)><hlendline|><next-line><hlstd| \ ><hlopt|\| ><hlkwd|Quot
  ><hlopt|(><hlstd|a><hlopt|,><hlstd|b><hlopt|) -\<gtr\>><hlstd|
  efold><hlopt|.><hlstd|fold<textunderscore>quot
  ><hlopt|(><hlstd|expr<textunderscore>fold efold a><hlopt|)
  (><hlstd|expr<textunderscore>fold efold b><hlopt|)><hlendline|><next-line>>

  <new-page*>Now examples. We use <hlopt|{><hlstd|record ><hlkwa|with
  ><hlstd|field><hlopt|=><verbatim|value><hlopt|}> syntax which copies
  <verbatim|record> but puts <verbatim|value> instead of
  <verbatim|record.field> in the result.

  <hlkwa|let ><hlstd|prime<textunderscore>vars ><hlopt|=
  ><hlstd|expr<textunderscore>map<hlendline|><next-line>
  \ ><hlopt|{><hlstd|identity<textunderscore>map ><hlkwa|with
  ><hlstd|map<textunderscore>var ><hlopt|= ><hlkwa|fun ><hlstd|x
  ><hlopt|-\<gtr\> ><hlkwd|Var ><hlopt|(><hlstd|x<textasciicircum>><hlstr|"'"><hlopt|)}><hlendline|><next-line><hlendline|><next-line><hlkwa|let
  ><hlstd|subst s ><hlopt|=><hlendline|><next-line><hlstd| \ ><hlkwa|let
  ><hlstd|apply x ><hlopt|= ><hlkwa|try ><hlkwc|List><hlopt|.><hlstd|assoc x
  s ><hlkwa|with ><hlkwd|Not<textunderscore>found ><hlopt|-\<gtr\>
  ><hlkwd|Var ><hlstd|x ><hlkwa|in><next-line><hlstd|
  \ expr<textunderscore>map ><hlopt|{><hlstd|identity<textunderscore>map
  ><hlkwa|with ><hlstd|map<textunderscore>var ><hlopt|=
  ><hlstd|apply><hlopt|}><hlendline|><next-line><hlendline|><next-line><hlkwa|let
  ><hlstd|vars ><hlopt|=><hlendline|><next-line><hlstd|
  \ expr<textunderscore>fold ><hlopt|{(><hlstd|make<textunderscore>fold
  ><hlopt|(><hlstd|@><hlopt|) []) ><hlkwa|with
  ><hlstd|fold<textunderscore>var ><hlopt|= ><hlkwa|fun
  ><hlstd|x><hlopt|-\<gtr\> [><hlstd|x><hlopt|]}><hlendline|><next-line><hlkwa|let
  ><hlstd|size ><hlopt|= ><hlstd|expr<textunderscore>fold
  ><hlopt|(><hlstd|make<textunderscore>fold ><hlopt|(><hlkwa|fun ><hlstd|a
  b><hlopt|-\<gtr\>><hlnum|1><hlopt|+><hlstd|a><hlopt|+><hlstd|b><hlopt|)
  ><hlnum|1><hlopt|)><hlendline|><next-line><hlendline|><next-line><hlkwa|let
  ><hlstd|eval env ><hlopt|= ><hlstd|expr<textunderscore>fold
  ><hlopt|{><hlendline|><next-line><hlstd| \ fold<textunderscore>const
  ><hlopt|= ><hlstd|id><hlopt|;><hlendline|><next-line><hlstd|
  \ fold<textunderscore>var ><hlopt|= (><hlkwa|fun ><hlstd|x ><hlopt|-\<gtr\>
  ><hlkwc|List><hlopt|.><hlstd|assoc x env><hlopt|);><hlendline|><next-line><hlstd|
  \ fold<textunderscore>sum ><hlopt|= (+.); ><hlstd|fold<textunderscore>diff
  ><hlopt|= (-.);><hlendline|><next-line><hlstd| \ fold<textunderscore>prod
  ><hlopt|= ( *.); ><hlstd|fold<textunderscore>quot ><hlopt|=
  (/.);><hlendline|><next-line><hlopt|}><hlendline|>

  <section|<new-page*>Point-free Programming>

  <\itemize>
    <item>In 1977/78, John Backus designed <strong|FP>, the first
    <em|function-level programming> language. Over the next decade it evolved
    into the <strong|FL> language.

    <\itemize>
      <item>''Clarity is achieved when programs are written at the function
      level --that is, by putting together existing programs to form new
      ones, rather than by manipulating objects and then abstracting from
      those objects to produce programs.'' <tiny|<em|The FL Project: The
      Design of a Functional Language>>
    </itemize>

    <item>For functionl-level programming style, we need
    functionals/combinators, like these from <em|OCaml Batteries>:
    \ <hlkwa|let ><hlstd|const x <textunderscore> ><hlopt|=
    ><hlstd|x><hlendline|><next-line><hlkwa|let ><hlopt|(
    ><hlstd|<hlopt|\|>><hlopt|- ) ><hlstd|f g x ><hlopt|= ><hlstd|g
    ><hlopt|(><hlstd|f x><hlopt|)><hlendline|><next-line><hlkwa|let ><hlopt|(
    -\| ) ><hlstd|f g x ><hlopt|= ><hlstd|f ><hlopt|(><hlstd|g
    x><hlopt|)><hlendline|><next-line><hlkwa|let ><hlstd|flip f x y ><hlopt|=
    ><hlstd|f y x><hlendline|><next-line><hlkwa|let ><hlopt|( *** ) ><hlstd|f
    g ><hlopt|= ><hlkwa|fun ><hlopt|(><hlstd|x><hlopt|,><hlstd|y><hlopt|)
    -\<gtr\> (><hlstd|f x><hlopt|, ><hlstd|g
    y><hlopt|)><hlendline|><next-line><hlkwa|let ><hlopt|( &&& ) ><hlstd|f g
    ><hlopt|= ><hlkwa|fun ><hlstd|x ><hlopt|-\<gtr\> (><hlstd|f x><hlopt|,
    ><hlstd|g x><hlopt|)><hlendline|><next-line><hlkwa|let ><hlstd|first f x
    ><hlopt|= ><hlstd|fst ><hlopt|(><hlstd|f
    x><hlopt|)><hlendline|><next-line><hlkwa|let ><hlstd|second f x ><hlopt|=
    ><hlstd|snd ><hlopt|(><hlstd|f x><hlopt|)><hlendline|><next-line><hlkwa|let
    ><hlstd|curry f x y ><hlopt|= ><hlstd|f
    ><hlopt|(><hlstd|x><hlopt|,><hlstd|y><hlopt|)><hlendline|><next-line><hlkwa|let
    ><hlstd|uncurry f ><hlopt|(><hlstd|x><hlopt|,><hlstd|y><hlopt|) =
    ><hlstd|f x y><hlendline|>

    <new-page*><item>The flow of computation can be seen as a circuit where
    the results of nodes-functions are connected to further nodes as inputs.

    We can represent the cross-sections of the circuit as tuples of
    intermediate values.

    <item><hlkwa|let ><hlstd|print2 c i ><hlopt|=><hlendline|><next-line><hlstd|
    \ ><hlkwa|let ><hlstd|a ><hlopt|= ><hlkwc|Char><hlopt|.><hlstd|escaped c
    ><hlkwa|in><hlendline|><next-line><hlstd| \ ><hlkwa|let ><hlstd|b
    ><hlopt|= ><hlstd|string<textunderscore>of<textunderscore>int i
    ><hlkwa|in><hlendline|><next-line><hlstd| \ a <textasciicircum>
    b><hlendline|>
  </itemize>

  <draw-over|<tabular|<tformat|<table|<row|<cell|>>|<row|<cell|>>|<row|<cell|<hlkwa|let
  ><hlstd|print2 ><hlopt|= ><hlstd|curry><hlendline|><next-line>>>|<row|<cell|<hlstd|
  \ ><hlopt|((><hlkwc|Char><hlopt|.><hlstd|escaped ><hlopt|***
  ><hlstd|string<textunderscore>of<textunderscore>int><hlopt|)
  ><hlstd|<hlopt|\|>><hlopt|- ><hlstd|uncurry
  ><hlopt|(><hlstd|<textasciicircum>><hlopt|))>
  \ \ \ \ \ \ \ \ \ \ \ <next-line>>>>>>|<with|gr-grid|<tuple|empty>|gr-grid-old|<tuple|cartesian|<point|0|0>|0.5>|gr-edit-grid-aspect|<tuple|<tuple|axes|none>|<tuple|1|none>|<tuple|10|none>>|gr-edit-grid|<tuple|empty>|gr-edit-grid-old|<tuple|cartesian|<point|0|0>|0.5>|gr-mode|<tuple|edit|line>|<graphics|<line|<point|-9.5|1>|<point|-4.0|1.0>>|<line|<point|-9.4935|-0.00601931>|<point|-4.0|0.0>>|<text-at|<verbatim|Char.escaped>|<point|-4|1>>|<text-at|<verbatim|string_of_int>|<point|-4.05|-5.47857e-05>>|<line|<point|0.5|1>|<point|3.5|0.5>|<point|0.539572033337743|0.0151475062839>>|<text-at|<verbatim|uncurry
  (^)>|<point|3.5|0.5>>|<line|<point|7.5|0.5>|<point|10.5|0.5>>>>>

  <\itemize>
    <item>Since we usually work by passing arguments one at a time rather
    than in tuples, we need <verbatim|uncurry> to access multi-argument
    functions, and we pack the result with <verbatim|curry>.

    <\itemize>
      <item>Turning C/Pascal-like function into one that takes arguments one
      at a time is called <em|currification>, after the logician Haskell
      Brooks Curry.
    </itemize>

    <new-page*><item>Another option to remove explicit use of function
    parameters, rather than to pack intermediate values as tuples, is to use
    function composition, <verbatim|flip>, and the so called <strong|S>
    combinator:

    <hlkwa|let ><hlstd|s x y z ><hlopt|= ><hlstd|x z ><hlopt|(><hlstd|y
    z><hlopt|)><hlendline|>

    to bring a particular argument of a function to ``front'', and pass it a
    result of another function. Example: a filter-map function

    <hlkwa|let ><hlstd|func2 f g l ><hlopt|=
    ><hlkwc|List><hlopt|.><hlstd|filter f
    ><hlopt|(><hlkwc|List><hlopt|.><hlstd|map g
    ><hlopt|(><hlstd|l><hlopt|))><hlendline|><next-line><hlendline|Definition
    of function composition.><next-line><hlkwa|let ><hlstd|func2 f g
    ><hlopt|= (-><hlstd|<hlopt|\|>><hlopt|)
    (><hlkwc|List><hlopt|.><hlstd|filter f><hlopt|)
    (><hlkwc|List><hlopt|.><hlstd|map g><hlopt|)><hlendline|><next-line><hlkwa|let
    ><hlstd|func2 f ><hlopt|= (-><hlstd|<hlopt|\|>><hlopt|)
    (><hlkwc|List><hlopt|.><hlstd|filter f><hlopt|) -\|
    ><hlkwc|List><hlopt|.><hlstd|map><hlendline|Composition><next-line><hlendline|again,
    below without the infix notation.><next-line><hlkwa|let ><hlstd|func2 f
    ><hlopt|= (-><hlstd|<hlopt|\|>><hlopt|) ((-><hlstd|<hlopt|\|>><hlopt|)
    (><hlkwc|List><hlopt|.><hlstd|filter f><hlopt|))
    ><hlkwc|List><hlopt|.><hlstd|map><hlendline|><next-line><hlkwa|let
    ><hlstd|func2 f ><hlopt|= ><hlstd|flip
    ><hlopt|(-><hlstd|<hlopt|\|>><hlopt|) ><hlkwc|List><hlopt|.><hlstd|map
    ><hlopt|((-><hlstd|<hlopt|\|>><hlopt|)
    (><hlkwc|List><hlopt|.><hlstd|filter f><hlopt|))><hlendline|><next-line><hlkwa|let
    ><hlstd|func2 f ><hlopt|= (((><hlstd|<hlopt|\|>><hlopt|-)
    ><hlkwc|List><hlopt|.><hlstd|map><hlopt|) -\|
    ((-><hlstd|<hlopt|\|>><hlopt|) -\| ><hlkwc|List><hlopt|.><hlstd|filter><hlopt|))
    ><hlstd|f><next-line><hlkwa|let ><hlstd|func2 ><hlopt|=
    (><hlstd|<hlopt|\|>><hlopt|-) ><hlkwc|List><hlopt|.><hlstd|map
    ><hlopt|-\| ((-><hlstd|<hlopt|\|>><hlopt|) -\|
    ><hlkwc|List><hlopt|.><hlstd|filter><hlopt|)><hlendline|>
  </itemize>

  <section|<new-page*>Reductions. More higher-order/list functions>

  Mathematics has notation for sum over an interval:
  <math|<big|sum><rsub|n=a><rsup|b>f<around*|(|n|)>>.

  In OCaml, we do not have a universal addition operator:

  <hlkwa|let rec ><hlstd|i<textunderscore>sum<textunderscore>from<textunderscore>to
  f a b ><hlopt|=><hlendline|><next-line><hlstd| \ ><hlkwa|if ><hlstd|a
  ><hlopt|\<gtr\> ><hlstd|b ><hlkwa|then ><hlnum|0><hlendline|><next-line><hlstd|
  \ ><hlkwa|else ><hlstd|f a ><hlopt|+ ><hlstd|i<textunderscore>sum<textunderscore>from<textunderscore>to
  f ><hlopt|(><hlstd|a><hlopt|+><hlnum|1><hlopt|)
  ><hlstd|b><hlendline|><next-line><hlkwa|let rec
  ><hlstd|f<textunderscore>sum<textunderscore>from<textunderscore>to f a b
  ><hlopt|=><hlendline|><next-line><hlstd| \ ><hlkwa|if ><hlstd|a
  ><hlopt|\<gtr\> ><hlstd|b ><hlkwa|then ><hlnum|0><hlopt|.><hlendline|><next-line><hlstd|
  \ ><hlkwa|else ><hlstd|f a ><hlopt|+. ><hlstd|f<textunderscore>sum<textunderscore>from<textunderscore>to
  f ><hlopt|(><hlstd|a><hlopt|+><hlnum|1><hlopt|)
  ><hlstd|b><hlendline|><next-line><hlkwa|let
  ><hlstd|pi2<textunderscore>over6 ><hlopt|=><hlendline|><next-line><hlstd|
  \ f<textunderscore>sum<textunderscore>from<textunderscore>to
  ><hlopt|(><hlkwa|fun ><hlstd|i><hlopt|-\<gtr\>><hlnum|1><hlopt|. /.
  ><hlstd|float<textunderscore>of<textunderscore>int
  ><hlopt|(><hlstd|i><hlopt|*><hlstd|i><hlopt|)) ><hlnum|1 5000><hlendline|>

  It is natural to generalize:

  <hlkwa|let rec ><hlstd|op<textunderscore>from<textunderscore>to op base f a
  b ><hlopt|=><hlendline|><next-line><hlstd| \ ><hlkwa|if ><hlstd|a
  ><hlopt|\<gtr\> ><hlstd|b ><hlkwa|then ><hlstd|base<hlendline|><next-line>
  \ ><hlkwa|else ><hlstd|op ><hlopt|(><hlstd|f a><hlopt|)
  (><hlstd|op<textunderscore>from<textunderscore>to op base f
  ><hlopt|(><hlstd|a><hlopt|+><hlnum|1><hlopt|)
  ><hlstd|b><hlopt|)><hlendline|>

  <new-page*>Let's collect the results of a multifunction (i.e. a set-valued
  function) for a set of arguments, in math notation:

  <\equation*>
    f<around*|(|A|)>=<big|cup><rsub|p\<in\>A>f<around*|(|p|)>
  </equation*>

  It is a useful operation over lists with <verbatim|union> translated as
  <verbatim|append>:

  <hlkwa|let rec ><hlstd|concat<textunderscore>map f ><hlopt|=
  ><hlkwa|function><hlendline|><next-line><hlstd| \ ><hlopt|\| [] -\<gtr\>
  []><hlendline|><next-line><hlstd| \ <hlopt|\|> a><hlopt|::><hlstd|l
  ><hlopt|-\<gtr\> ><hlstd|f a @ concat<textunderscore>map f l><hlendline|>

  and more efficiently:

  <hlkwa|let ><hlstd|concat<textunderscore>map f l
  ><hlopt|=><hlendline|><next-line><hlstd| \ ><hlkwa|let rec
  ><hlstd|cmap<textunderscore>f accu ><hlopt|=
  ><hlkwa|function><hlendline|><next-line><hlstd| \ \ \ ><hlopt|\| []
  -\<gtr\> ><hlstd|accu<hlendline|><next-line> \ \ \ <hlopt|\|>
  a><hlopt|::><hlstd|l ><hlopt|-\<gtr\> ><hlstd|cmap<textunderscore>f
  ><hlopt|(><hlkwc|List><hlopt|.><hlstd|rev<textunderscore>append
  ><hlopt|(><hlstd|f a><hlopt|) ><hlstd|accu><hlopt|) ><hlstd|l
  ><hlkwa|in><hlendline|><next-line><hlstd|
  \ ><hlkwc|List><hlopt|.><hlstd|rev ><hlopt|(><hlstd|cmap<textunderscore>f
  ><hlopt|[] ><hlstd|l><hlopt|)><hlendline|><next-line>

  <subsection|<new-page*>List manipulation: All subsequences of a list>

  <hlkwa|let rec ><hlstd|subseqs l ><hlopt|=><hlendline|><next-line><hlstd|
  \ ><hlkwa|match ><hlstd|l ><hlkwa|with><hlendline|><next-line><hlstd|
  \ \ \ ><hlopt|\| [] -\<gtr\> [[]]><hlendline|><next-line><hlstd|
  \ \ \ <hlopt|\|> x><hlopt|::><hlstd|xs ><hlopt|-\<gtr\>><hlendline|><next-line><hlstd|
  \ \ \ \ \ ><hlkwa|let ><hlstd|pxs ><hlopt|= ><hlstd|subseqs xs
  ><hlkwa|in><hlendline|><next-line><hlstd|
  \ \ \ \ \ ><hlkwc|List><hlopt|.><hlstd|map ><hlopt|(><hlkwa|fun ><hlstd|px
  ><hlopt|-\<gtr\> ><hlstd|x><hlopt|::><hlstd|px><hlopt|) ><hlstd|pxs @
  pxs><hlendline|>

  Tail-recursively:

  <hlkwa|let rec ><hlstd|rmap<textunderscore>append f accu ><hlopt|=
  ><hlkwa|function><hlendline|><next-line><hlstd| \ ><hlopt|\| [] -\<gtr\>
  ><hlstd|accu<hlendline|><next-line> \ <hlopt|\|> a><hlopt|::><hlstd|l
  ><hlopt|-\<gtr\> ><hlstd|rmap<textunderscore>append f ><hlopt|(><hlstd|f a
  ><hlopt|:: ><hlstd|accu><hlopt|) ><hlstd|l><hlendline|>

  <hlkwa|let rec ><hlstd|subseqs l ><hlopt|=><hlendline|><next-line><hlstd|
  \ ><hlkwa|match ><hlstd|l ><hlkwa|with><hlendline|><next-line><hlstd|
  \ \ \ ><hlopt|\| [] -\<gtr\> [[]]><hlendline|><next-line><hlstd|
  \ \ \ <hlopt|\|> x><hlopt|::><hlstd|xs ><hlopt|-\<gtr\>><hlendline|><next-line><hlstd|
  \ \ \ \ \ ><hlkwa|let ><hlstd|pxs ><hlopt|= ><hlstd|subseqs xs
  ><hlkwa|in><hlendline|><next-line><hlstd|
  \ \ \ \ \ rmap<textunderscore>append ><hlopt|(><hlkwa|fun ><hlstd|px
  ><hlopt|-\<gtr\> ><hlstd|x><hlopt|::><hlstd|px><hlopt|) ><hlstd|pxs
  pxs><hlendline|><next-line>

  <\metal>
    <strong|In-class work:> Return a list of all possible ways of splitting a
    list into two non-empty parts.
  </metal>

  <\metal>
    <strong|Homework:>

    \ Find all permutations of a list.

    \ Find all ways of choosing without repetition from a list.
  </metal>

  <subsection|<new-page*>By key: <verbatim|group_by> and
  <verbatim|map_reduce>>

  It is often useful to organize values by some property.

  First we collect an elements from an association list by key.\ 

  <hlkwa|let ><hlstd|collect l ><hlopt|=><hlendline|><next-line><hlstd|
  \ ><hlkwa|match ><hlkwc|List><hlopt|.><hlstd|sort ><hlopt|(><hlkwa|fun
  ><hlstd|x y ><hlopt|-\<gtr\> ><hlstd|compare ><hlopt|(><hlstd|fst
  x><hlopt|) (><hlstd|fst y><hlopt|)) ><hlstd|l
  ><hlkwa|with><next-line><hlstd| \ ><hlopt|\| [] -\<gtr\>
  []><hlendline|Start with associations sorted by key.><next-line><hlstd|
  \ ><hlopt|\| (><hlstd|k0><hlopt|, ><hlstd|v0><hlopt|)::><hlstd|tl
  ><hlopt|-\<gtr\>><hlendline|><next-line><hlstd| \ \ \ ><hlkwa|let
  ><hlstd|k0><hlopt|, ><hlstd|vs><hlopt|, ><hlstd|l ><hlopt|=
  ><hlkwc|List><hlopt|.><hlstd|fold<textunderscore>left<hlendline|><next-line>
  \ \ \ \ \ ><hlopt|(><hlkwa|fun ><hlopt|(><hlstd|k0><hlopt|,
  ><hlstd|vs><hlopt|, ><hlstd|l><hlopt|) (><hlstd|kn><hlopt|,
  ><hlstd|vn><hlopt|) -\<gtr\>><hlendline|Collect values for the current
  key><next-line><hlstd| \ \ \ \ \ \ \ ><hlkwa|if ><hlstd|k0 ><hlopt|=
  ><hlstd|kn ><hlkwa|then ><hlstd|k0><hlopt|,
  ><hlstd|vn><hlopt|::><hlstd|vs><hlopt|, ><verbatim|l><hlendline|and when
  the key changes><next-line> <verbatim| \ \ \ \ \ \ ><hlkwa|else
  ><hlstd|kn><hlopt|, [><hlstd|vn><hlopt|],
  (><hlstd|k0><hlopt|,><hlkwc|List><hlopt|.><hlstd|rev
  vs><hlopt|)::><hlstd|l><hlopt|)><hlendline|stack the collected
  values.><next-line><hlstd| \ \ \ \ \ ><hlopt|(><hlstd|k0><hlopt|,
  [><hlstd|v0><hlopt|], []) ><hlstd|tl ><hlkwa|in><hlendline|What do we gain
  by reversing?><next-line><hlstd| \ \ \ ><hlkwc|List><hlopt|.><hlstd|rev
  ><hlopt|((><hlstd|k0><hlopt|,><hlkwc|List><hlopt|.><hlstd|rev
  vs><hlopt|)::><hlstd|l><hlopt|)><hlendline|>

  Now we can group by an arbitrary property:

  <hlkwa|let ><hlstd|group<textunderscore>by p l ><hlopt|= ><hlstd|collect
  ><hlopt|(><hlkwc|List><hlopt|.><hlstd|map ><hlopt|(><hlkwa|fun
  ><hlstd|e><hlopt|-\<gtr\>><hlstd|p e><hlopt|, ><hlstd|e><hlopt|)
  ><hlstd|l><hlopt|)><hlendline|>

  <new-page*>But we want to process the results, like with an <em|aggregate
  operation> in SQL. The aggregation operation is called <strong|reduction>.

  <hlkwa|let ><hlstd|aggregate<textunderscore>by p red base l
  ><hlopt|=><hlendline|><next-line><hlstd| \ ><hlkwa|let ><hlstd|ags
  ><hlopt|= ><hlstd|group<textunderscore>by p l
  ><hlkwa|in><hlendline|><next-line><hlstd|
  \ ><hlkwc|List><hlopt|.><hlstd|map ><hlopt|(><hlkwa|fun
  ><hlopt|(><hlstd|k><hlopt|,><hlstd|vs><hlopt|)-\<gtr\>><hlstd|k><hlopt|,
  ><hlkwc|List><hlopt|.><hlstd|fold<textunderscore>right red vs base><hlopt|)
  ><hlstd|ags><hlendline|>

  We can use the <strong|feed-forward> operator: <hlkwa|let ><hlopt|(
  ><hlstd|<hlopt|\|>><hlopt|\<gtr\> ) ><hlstd|x f ><hlopt|= ><hlstd|f x>

  <hlkwa|let ><hlstd|aggregate<textunderscore>by p redf base l
  ><hlopt|=><hlendline|><next-line><hlstd| \ group<textunderscore>by p
  l<hlendline|><next-line> \ <hlopt|\|>><hlopt|\<gtr\>
  ><hlkwc|List><hlopt|.><hlstd|map ><hlopt|(><hlkwa|fun
  ><hlopt|(><hlstd|k><hlopt|,><hlstd|vs><hlopt|)-\<gtr\>><hlstd|k><hlopt|,
  ><hlkwc|List><hlopt|.><hlstd|fold<textunderscore>right redf vs
  base><hlopt|)><hlendline|>

  Often it is easier to extract the property over which we aggregate upfront.
  Since we first map the elements into the extracted key-value pairs, we call
  the operation <verbatim|map_reduce>:

  <hlkwa|let ><hlstd|map<textunderscore>reduce mapf redf base l
  ><hlopt|=><hlendline|><next-line><hlstd| \ ><hlkwc|List><hlopt|.><hlstd|map
  mapf l<hlendline|><next-line> \ <hlopt|\|>><hlopt|\<gtr\>
  ><hlstd|collect<hlendline|><next-line> \ <hlopt|\|>><hlopt|\<gtr\>
  ><hlkwc|List><hlopt|.><hlstd|map ><hlopt|(><hlkwa|fun
  ><hlopt|(><hlstd|k><hlopt|,><hlstd|vs><hlopt|)-\<gtr\>><hlstd|k><hlopt|,
  ><hlkwc|List><hlopt|.><hlstd|fold<textunderscore>right redf vs
  base><hlopt|)><hlendline|>

  <subsubsection|<new-page*><verbatim|map_reduce>/<verbatim|concat_reduce>
  examples>

  Sometimes we have multiple sources of information rather than records.

  <hlkwa|let ><hlstd|concat<textunderscore>reduce mapf redf base l
  ><hlopt|=><hlendline|><next-line><hlstd| \ concat<textunderscore>map mapf
  l<hlendline|><next-line> \ <hlopt|\|>><hlopt|\<gtr\>
  ><hlstd|collect<hlendline|><next-line> \ <hlopt|\|>><hlopt|\<gtr\>
  ><hlkwc|List><hlopt|.><hlstd|map ><hlopt|(><hlkwa|fun
  ><hlopt|(><hlstd|k><hlopt|,><hlstd|vs><hlopt|)-\<gtr\>><hlstd|k><hlopt|,
  ><hlkwc|List><hlopt|.><hlstd|fold<textunderscore>right redf vs
  base><hlopt|)><hlendline|>

  Compute the merged histogram of several documents:

  <hlkwa|let ><hlstd|histogram documents ><hlopt|=><hlendline|><next-line><hlstd|
  \ ><hlkwa|let ><hlstd|mapf doc ><hlopt|=><hlendline|><next-line><hlstd|
  \ \ \ ><hlkwc|Str><hlopt|.><hlstd|split
  ><hlopt|(><hlkwc|Str><hlopt|.><hlstd|regexp ><hlstr|"[
  ><hlesc|<math|>t><hlstr|.,;]+"><hlopt|) ><hlstd|doc<hlendline|><next-line>
  \ <hlopt|\|>><hlopt|\<gtr\> ><hlkwc|List><hlopt|.><hlstd|map
  ><hlopt|(><hlkwa|fun ><verbatim|word><hlopt|-\<gtr\>><verbatim|word><hlopt|,><hlnum|1><hlopt|)
  ><hlkwa|in><hlendline|><next-line><hlstd| \ concat<textunderscore>reduce
  mapf ><hlopt|(+) ><hlnum|0 ><hlstd|documents><hlendline|>

  <new-page*>Now compute the <em|inverted index> of several documents (which
  come with identifiers or addresses).

  <hlkwa|let ><hlstd|cons hd tl ><hlopt|=
  ><hlstd|hd><hlopt|::><hlstd|tl><hlendline|><next-line><hlkwa|let
  ><hlstd|inverted<textunderscore>index documents
  ><hlopt|=><hlendline|><next-line><hlstd| \ ><hlkwa|let ><hlstd|mapf
  ><hlopt|(><hlstd|addr><hlopt|, ><hlstd|doc><hlopt|)
  =><hlendline|><next-line><hlstd| \ \ \ ><hlkwc|Str><hlopt|.><hlstd|split
  ><hlopt|(><hlkwc|Str><hlopt|.><hlstd|regexp ><hlstr|"[
  ><hlesc|<math|>t><hlstr|.,;]+"><hlopt|) ><hlstd|doc<hlendline|><next-line>
  \ <hlopt|\|>><hlopt|\<gtr\> ><hlkwc|List><hlopt|.><hlstd|map
  ><hlopt|(><hlkwa|fun ><hlkwb|word><hlopt|-\<gtr\>><hlkwb|word><hlopt|,><hlstd|addr><hlopt|)
  ><hlkwa|in><hlendline|><next-line><hlstd| \ concat<textunderscore>reduce
  mapf cons ><hlopt|[] ><hlstd|documents><hlendline|>

  And now... a ``search engine'':

  <hlkwa|let ><hlstd|search index words ><hlopt|=><hlendline|><next-line><hlstd|
  \ ><hlkwa|match ><hlkwc|List><hlopt|.><hlstd|map ><hlopt|(><hlstd|flip
  ><hlkwc|List><hlopt|.><hlstd|assoc index><hlopt|) ><hlstd|words
  ><hlkwa|with><hlendline|><next-line><hlstd| \ ><hlopt|\| [] -\<gtr\>
  []><hlendline|><next-line><hlstd| \ <hlopt|\|> idx><hlopt|::><hlstd|idcs
  ><hlopt|-\<gtr\> ><hlkwc|List><hlopt|.><hlstd|fold<textunderscore>left
  intersect idx idcs><hlendline|>

  where <verbatim|intersect> computes intersection of sets represented as
  lists.

  <subsubsection|<new-page*>Tail-recursive variants>

  <\small>
    <hlkwa|let ><hlstd|rev<textunderscore>collect l
    ><hlopt|=><hlendline|><next-line><hlstd| \ ><hlkwa|match
    ><hlkwc|List><hlopt|.><hlstd|sort ><hlopt|(><hlkwa|fun ><hlstd|x y
    ><hlopt|-\<gtr\> ><hlstd|compare ><hlopt|(><hlstd|fst x><hlopt|)
    (><hlstd|fst y><hlopt|)) ><hlstd|l ><hlkwa|with><hlendline|><next-line><hlstd|
    \ ><hlopt|\| [] -\<gtr\> []><hlendline|><next-line><hlstd| \ ><hlopt|\|
    (><hlstd|k0><hlopt|, ><hlstd|v0><hlopt|)::><hlstd|tl
    ><hlopt|-\<gtr\>><hlendline|><next-line><hlstd| \ \ \ ><hlkwa|let
    ><hlstd|k0><hlopt|, ><hlstd|vs><hlopt|, ><hlstd|l ><hlopt|=
    ><hlkwc|List><hlopt|.><hlstd|fold<textunderscore>left<hlendline|><next-line>
    \ \ \ \ \ ><hlopt|(><hlkwa|fun ><hlopt|(><hlstd|k0><hlopt|,
    ><hlstd|vs><hlopt|, ><hlstd|l><hlopt|) (><hlstd|kn><hlopt|,
    ><hlstd|vn><hlopt|) -\<gtr\>><hlendline|><next-line><hlstd|
    \ \ \ \ \ \ \ ><hlkwa|if ><hlstd|k0 ><hlopt|= ><hlstd|kn ><hlkwa|then
    ><hlstd|k0><hlopt|, ><hlstd|vn><hlopt|::><hlstd|vs><hlopt|,
    ><hlstd|l<hlendline|><next-line> \ \ \ \ \ \ \ ><hlkwa|else
    ><hlstd|kn><hlopt|, [><hlstd|vn><hlopt|], (><hlstd|k0><hlopt|,
    ><hlstd|vs><hlopt|)::><hlstd|l><hlopt|)><hlendline|><next-line><hlstd|
    \ \ \ \ \ ><hlopt|(><hlstd|k0><hlopt|, [><hlstd|v0><hlopt|], [])
    ><hlstd|tl ><hlkwa|in><hlendline|><next-line><hlstd|
    \ \ \ ><hlkwc|List><hlopt|.><hlstd|rev ><hlopt|((><hlstd|k0><hlopt|,
    ><hlstd|vs><hlopt|)::><hlstd|l><hlopt|)><hlendline|>

    <hlkwa|let ><hlstd|tr<textunderscore>concat<textunderscore>reduce mapf
    redf base l ><hlopt|=><hlendline|><next-line><hlstd|
    \ concat<textunderscore>map mapf l<hlendline|><next-line>
    \ <hlopt|\|>><hlopt|\<gtr\> ><hlstd|rev<textunderscore>collect<hlendline|><next-line>
    \ <hlopt|\|>><hlopt|\<gtr\> ><hlkwc|List><hlopt|.><hlstd|rev<textunderscore>map
    ><hlopt|(><hlkwa|fun ><hlopt|(><hlstd|k><hlopt|,><hlstd|vs><hlopt|)-\<gtr\>><hlstd|k><hlopt|,
    ><hlkwc|List><hlopt|.><hlstd|fold<textunderscore>left redf base
    vs><hlopt|)><hlendline|>

    <hlkwa|let ><hlstd|rcons tl hd ><hlopt|=
    ><hlstd|hd><hlopt|::><hlstd|tl><hlendline|><next-line><hlkwa|let
    ><hlstd|inverted<textunderscore>index documents
    ><hlopt|=><hlendline|><next-line><hlstd| \ ><hlkwa|let ><hlstd|mapf
    ><hlopt|(><hlstd|addr><hlopt|, ><hlstd|doc><hlopt|) => ...<hlkwa|
    in><hlendline|><next-line><hlstd| \ tr<textunderscore>concat<textunderscore>reduce
    mapf rcons ><hlopt|[] ><hlstd|documents><hlendline|>
  </small>

  <subsubsection|<new-page*>Helper functions for inverted index
  demonstration>

  <hlkwa|let ><hlstd|intersect xs ys ><hlopt|=><hlendline|Sets as
  <strong|sorted> lists.><next-line><hlstd| \ ><hlkwa|let rec ><hlstd|aux acc
  ><hlopt|= ><hlkwa|function><hlendline|><next-line><hlstd| \ \ \ ><hlopt|\|
  [], ><hlstd|<textunderscore> <hlopt|\|> <textunderscore>><hlopt|, []
  -\<gtr\> ><hlstd|acc<hlendline|><next-line> \ \ \ ><hlopt|\|
  (><hlstd|x><hlopt|::><hlstd|xs><hlstr|' as xs), (y::ys'><hlstd| ><hlkwa|as
  ><hlstd|ys><hlopt|) -\<gtr\>><hlendline|><next-line><hlstd|
  \ \ \ \ \ ><hlkwa|let ><hlstd|c ><hlopt|= ><hlstd|compare x y
  ><hlkwa|in><hlendline|><next-line><hlstd| \ \ \ \ \ ><hlkwa|if ><hlstd|c
  ><hlopt|= ><hlnum|0 ><hlkwa|then ><hlstd|aux
  ><hlopt|(><hlstd|x><hlopt|::><hlstd|acc><hlopt|) (><hlstd|xs><hlstr|',
  ys'><hlopt|)><hlendline|><next-line><hlstd| \ \ \ \ \ ><hlkwa|else if
  ><hlstd|c ><hlopt|\<less\> ><hlnum|0 ><hlkwa|then ><hlstd|aux acc
  ><hlopt|(><hlstd|xs><hlstr|', ys)><hlendline|><next-line><hlstd|
  \ \ \ \ \ ><hlstr|else aux acc (xs, ys'><hlopt|)
  ><hlkwa|in><hlendline|><next-line><hlstd|
  \ ><hlkwc|List><hlopt|.><hlstd|rev ><hlopt|(><hlstd|aux ><hlopt|[]
  (><hlstd|xs><hlopt|, ><hlstd|ys><hlopt|))><hlendline|>

  <hlkwa|let ><hlstd|read<textunderscore>lines file
  ><hlopt|=><hlendline|><next-line><hlstd| \ ><hlkwa|let ><hlstd|input
  ><hlopt|= ><hlstd|open<textunderscore>in file
  ><hlkwa|in><hlendline|><next-line><hlstd| \ ><hlkwa|let rec ><hlstd|read
  lines ><hlopt|=><hlendline|The <hlkwc|Scanf> library uses continuation
  passing.><next-line><hlstd| \ \ \ ><hlkwa|try
  ><hlkwc|Scanf><hlopt|.><hlstd|fscanf input
  ><hlstr|"%[<textasciicircum>><hlesc|<math|>\\r\\<math|>n><hlstr|]\\><hlesc|<math|>n><hlstr|"><hlstd|<hlendline|><next-line>
  \ \ \ \ \ \ \ \ \ ><hlopt|(><hlkwa|fun ><hlstd|x ><hlopt|-\<gtr\>
  ><hlstd|read ><hlopt|(><hlstd|x ><hlopt|::
  ><hlstd|lines><hlopt|))><hlendline|><next-line><hlstd| \ \ \ ><hlkwa|with
  ><hlkwd|End<textunderscore>of<textunderscore>file ><hlopt|-\<gtr\>
  ><hlstd|lines ><hlkwa|in><hlendline|><next-line><hlstd|
  \ ><hlkwc|List><hlopt|.><hlstd|rev ><hlopt|(><hlstd|read
  ><hlopt|[])><hlendline|><next-line>

  <hlkwa|let ><hlstd|indexed l ><hlopt|=><hlendline|Index elements by their
  positions.><next-line><hlstd| \ ><hlkwc|Array><hlopt|.><hlstd|of<textunderscore>list
  l <hlopt|\|>><hlopt|\<gtr\> ><hlkwc|Array><hlopt|.><hlstd|mapi
  ><hlopt|(><hlkwa|fun ><hlstd|i e><hlopt|-\<gtr\>><hlstd|i><hlopt|,><hlstd|e><hlopt|)><hlendline|><next-line><hlstd|
  \ <hlopt|\|>><hlopt|\<gtr\> ><hlkwc|Array><hlopt|.><hlstd|to<textunderscore>list><hlendline|>

  <hlkwa|let ><hlstd|search<textunderscore>engine lines
  ><hlopt|=><hlendline|><next-line><hlstd| \ ><hlkwa|let ><hlstd|lines
  ><hlopt|= ><hlstd|indexed lines ><hlkwa|in><hlendline|><next-line><hlstd|
  \ ><hlkwa|let ><hlstd|index ><hlopt|= ><hlstd|inverted<textunderscore>index
  lines ><hlkwa|in><hlendline|><next-line><hlstd| \ ><hlkwa|fun ><hlstd|words
  ><hlopt|-\<gtr\>><hlendline|><next-line><hlstd| \ \ \ ><hlkwa|let
  ><hlstd|ans ><hlopt|= ><hlstd|search index words
  ><hlkwa|in><hlendline|><next-line><hlstd|
  \ \ \ ><hlkwc|List><hlopt|.><hlstd|map ><hlopt|(><hlstd|flip
  ><hlkwc|List><hlopt|.><hlstd|assoc lines><hlopt|) ><hlstd|ans><hlendline|>

  <hlkwa|let ><hlstd|search<textunderscore>bible
  ><hlopt|=><hlendline|><next-line><hlstd| \ search<textunderscore>engine
  ><hlopt|(><hlstd|read<textunderscore>lines
  ><hlstr|"./bible-kjv.txt"><hlopt|)><hlendline|><next-line><hlkwa|let
  ><hlstd|test<textunderscore>result ><hlopt|=><hlendline|><next-line><hlstd|
  \ search<textunderscore>bible ><hlopt|[><hlstr|"Abraham"><hlopt|;
  ><hlstr|"sons"><hlopt|; ><hlstr|"wife"><hlopt|]><hlendline|>

  <subsection|<new-page*>Higher-order functions for the <verbatim|option>
  type>

  Operate on an optional value:

  <hlkwa|let ><hlstd|map<textunderscore>option f ><hlopt|=
  ><hlkwa|function><hlendline|><next-line><hlstd| \ ><hlopt|\| ><hlkwd|None
  ><hlopt|-\<gtr\> ><hlkwd|None><hlendline|><next-line><hlstd| \ ><hlopt|\|
  ><hlkwd|Some ><hlstd|e ><hlopt|-\<gtr\> ><hlstd|f e><hlendline|>

  Map an operation over a list and filter-out cases when it does not succeed:

  <hlkwa|let rec ><hlstd|map<textunderscore>some f ><hlopt|=
  ><hlkwa|function><hlendline|><next-line><hlstd| \ ><hlopt|\| [] -\<gtr\>
  []><hlendline|><next-line><hlstd| \ <hlopt|\|> e><hlopt|::><hlstd|l
  ><hlopt|-\<gtr\> ><hlkwa|match ><hlstd|f e
  ><hlkwa|with><hlendline|><next-line><hlstd| \ \ \ ><hlopt|\| ><hlkwd|None
  ><hlopt|-\<gtr\> ><hlstd|map<textunderscore>some f l<hlendline|><next-line>
  \ \ \ ><hlopt|\| ><hlkwd|Some ><hlstd|r ><hlopt|-\<gtr\> ><hlstd|r
  ><hlopt|:: ><hlstd|map<textunderscore>some f l><hlendline|Tail-recurively:>

  <hlkwa|let ><hlstd|map<textunderscore>some f l
  ><hlopt|=><hlendline|><next-line><hlstd| \ ><hlkwa|let rec
  ><hlstd|maps<textunderscore>f accu ><hlopt|=
  ><hlkwa|function><hlendline|><next-line><hlstd| \ \ \ ><hlopt|\| []
  -\<gtr\> ><hlstd|accu<hlendline|><next-line> \ \ \ <hlopt|\|>
  a><hlopt|::><hlstd|l ><hlopt|-\<gtr\> ><hlstd|maps<textunderscore>f
  ><hlopt|(><hlkwa|match ><hlstd|f a ><hlkwa|with ><hlkwd|None
  ><hlopt|-\<gtr\> ><hlstd|accu<hlendline|><next-line> \ \ \ \ \ ><hlopt|\|
  ><hlkwd|Some ><hlstd|r ><hlopt|-\<gtr\>
  ><hlstd|r><hlopt|::><hlstd|accu><hlopt|) ><hlstd|l
  ><hlkwa|in><hlendline|><next-line><hlstd|
  \ ><hlkwc|List><hlopt|.><hlstd|rev ><hlopt|(><hlstd|maps<textunderscore>f
  ><hlopt|[] ><hlstd|l><hlopt|)><hlendline|><next-line>

  <section|<new-page*>The Countdown Problem Puzzle>

  <\itemize>
    <item>Using a given set of numbers and arithmetic operators <pine|+>,
    <pine|->, <pine|*>, <pine|/>, construct an expression with a given value.

    <item>All numbers, including intermediate results, must be positive
    integers.

    <item>Each of the source numbers can be used at most once when
    constructing the expression.

    <item>Example:

    <\itemize>
      <item>numbers <pine|1>, <pine|3>, <pine|7>, <pine|10>, <pine|25>,
      <pine|50>

      <item>target <pine|765>

      <item>possible solution <pine|(25-10) * (50+1)>
    </itemize>

    <item>There are 780 solutions for this example.

    <item>Changing the target to <pine|831> gives an example that has no
    solutions.

    <new-page*><item>Operators:

    <hlkwa|type ><hlstd|op ><hlopt|= ><hlkwd|Add ><hlopt|\| ><hlkwd|Sub
    ><hlopt|\| ><hlkwd|Mul ><hlopt|\| ><hlkwd|Div><hlendline|>

    <item>Apply an operator:

    <hlkwa|let ><hlstd|apply op x y ><hlopt|=><hlendline|><next-line><hlstd|
    \ ><hlkwa|match ><hlstd|op ><hlkwa|with><hlendline|><next-line><hlstd|
    \ ><hlopt|\| ><hlkwd|Add ><hlopt|-\<gtr\> ><hlstd|x ><hlopt|+
    ><hlstd|y<hlendline|><next-line> \ ><hlopt|\| ><hlkwd|Sub
    ><hlopt|-\<gtr\> ><hlstd|x ><hlopt|- ><hlstd|y<hlendline|><next-line>
    \ ><hlopt|\| ><hlkwd|Mul ><hlopt|-\<gtr\> ><hlstd|x ><hlopt|*
    ><hlstd|y<hlendline|><next-line> \ ><hlopt|\| ><hlkwd|Div
    ><hlopt|-\<gtr\> ><hlstd|x ><hlopt|/ ><hlstd|y><hlendline|>

    <new-page*><item>Decide if the result of applying an operator to two
    positive integers is another positive integer:

    <hlkwa|let ><hlstd|valid op x y ><hlopt|=><hlendline|><next-line><hlstd|
    \ ><hlkwa|match ><hlstd|op ><hlkwa|with><hlendline|><next-line><hlstd|
    \ ><hlopt|\| ><hlkwd|Add ><hlopt|-\<gtr\>
    ><hlkwa|true><hlendline|><next-line><hlstd| \ ><hlopt|\| ><hlkwd|Sub
    ><hlopt|-\<gtr\> ><hlstd|x ><hlopt|\<gtr\>
    ><hlstd|y<hlendline|><next-line> \ ><hlopt|\| ><hlkwd|Mul
    ><hlopt|-\<gtr\> ><hlkwa|true><hlendline|><next-line><hlstd| \ ><hlopt|\|
    ><hlkwd|Div ><hlopt|-\<gtr\> ><hlstd|x ><hlkwa|mod ><hlstd|y ><hlopt|=
    ><hlnum|0><hlendline|>

    <item>Expressions:

    <hlkwa|type ><hlstd|expr ><hlopt|= ><hlkwd|Val ><hlkwa|of ><hlkwb|int
    ><hlopt|\| ><hlkwd|App ><hlkwa|of ><hlstd|op ><hlopt|* ><hlstd|expr
    ><hlopt|* ><hlstd|expr><hlendline|>

    <new-page*><item>Return the overall value of an expression, provided that
    it is a positive integer:

    <hlkwa|let rec ><hlstd|eval ><hlopt|=
    ><hlkwa|function><hlendline|><next-line><hlstd| \ ><hlopt|\| ><hlkwd|Val
    ><hlstd|n ><hlopt|-\<gtr\> ><hlkwa|if ><hlstd|n ><hlopt|\<gtr\> ><hlnum|0
    ><hlkwa|then ><hlkwd|Some ><hlstd|n ><hlkwa|else
    ><hlkwd|None><hlendline|><next-line><hlstd| \ ><hlopt|\| ><hlkwd|App
    ><hlopt|(><hlstd|o><hlopt|,><hlstd|l><hlopt|,><hlstd|r><hlopt|)
    -\<gtr\>><hlendline|><next-line><hlstd| \ \ \ eval l
    <hlopt|\|>><hlopt|\<gtr\> ><hlstd|map<textunderscore>option
    ><hlopt|(><hlkwa|fun ><hlstd|x ><hlopt|-\<gtr\>><hlendline|><next-line><hlstd|
    \ \ \ \ \ eval r <hlopt|\|>><hlopt|\<gtr\>
    ><hlstd|map<textunderscore>option ><hlopt|(><hlkwa|fun ><hlstd|y
    ><hlopt|-\<gtr\>><hlendline|><next-line><hlstd| \ \ \ \ \ ><hlkwa|if
    ><hlstd|valid o x y ><hlkwa|then ><hlkwd|Some ><hlopt|(><hlstd|apply o x
    y><hlopt|)><hlendline|><next-line><hlstd| \ \ \ \ \ ><hlkwa|else
    ><hlkwd|None><hlopt|))><hlendline|>

    <item><strong|Homework:> Return a list of all possible ways of choosing
    zero or more elements from a list -- <verbatim|choices>.

    <item>Return a list of all the values in an expression:

    <hlkwa|let rec ><hlstd|values ><hlopt|=
    ><hlkwa|function><hlendline|><next-line><hlstd| \ ><hlopt|\| ><hlkwd|Val
    ><hlstd|n ><hlopt|-\<gtr\> [><hlstd|n><hlopt|]><hlendline|><next-line><hlstd|
    \ ><hlopt|\| ><hlkwd|App ><hlopt|(><hlstd|<textunderscore>><hlopt|,><hlstd|l><hlopt|,><hlstd|r><hlopt|)
    -\<gtr\> ><hlstd|values l @ values r><hlendline|>

    <new-page*><item>Decide if an expression is a solution for a given list
    of source numbers and a target number:

    <hlkwa|let ><hlstd|solution e ns n ><hlopt|=><hlendline|><next-line><hlstd|
    \ list<textunderscore>diff ><hlopt|(><hlstd|values e><hlopt|) ><hlstd|ns
    ><hlopt|= [] && ><hlstd|is<textunderscore>unique ><hlopt|(><hlstd|values
    e><hlopt|) &&><hlendline|><next-line><hlstd| \ eval e ><hlopt|=
    ><hlkwd|Some ><hlstd|n><hlendline|>
  </itemize>

  <subsection|<new-page*>Brute force solution>

  <\itemize>
    <item>Return a list of all possible ways of splitting a list into two
    non-empty parts:

    <hlkwa|let ><hlstd|split l ><hlopt|=><hlendline|><next-line><hlstd|
    \ ><hlkwa|let rec ><hlstd|aux lhs acc ><hlopt|=
    ><hlkwa|function><hlendline|><next-line><hlstd| \ \ \ ><hlopt|\| [] \|
    [><hlstd|<textunderscore>><hlopt|] -\<gtr\>
    []><hlendline|><next-line><hlstd| \ \ \ ><hlopt|\| [><hlstd|y><hlopt|;
    ><hlstd|z><hlopt|] -\<gtr\> (><hlkwc|List><hlopt|.><hlstd|rev
    ><hlopt|(><hlstd|y><hlopt|::><hlstd|lhs><hlopt|),
    [><hlstd|z><hlopt|])::><hlstd|acc<hlendline|><next-line> \ \ \ <hlopt|\|>
    hd><hlopt|::><hlstd|rhs ><hlopt|-\<gtr\>><hlendline|><next-line><hlstd|
    \ \ \ \ \ ><hlkwa|let ><hlstd|lhs ><hlopt|=
    ><hlstd|hd><hlopt|::><hlstd|lhs ><hlkwa|in><hlendline|><next-line><hlstd|
    \ \ \ \ \ aux lhs ><hlopt|((><hlkwc|List><hlopt|.><hlstd|rev lhs><hlopt|,
    ><hlstd|rhs><hlopt|)::><hlstd|acc><hlopt|) ><hlstd|rhs
    ><hlkwa|in><hlendline|><next-line><hlstd| \ aux ><hlopt|[] []
    ><hlstd|l><hlendline|>

    <new-page*><item>We introduce an operator to work on multiple sources of
    data, producing even more data for the next stage of computation:

    <hlkwa|let ><hlopt|( ><hlstd|<hlopt|\|>><hlopt|-\<gtr\> ) ><hlstd|x f
    ><hlopt|= ><hlstd|concat<textunderscore>map f x><hlendline|>

    <item>Return a list of all possible expressions whose values are
    precisely a given list of numbers:

    <hlkwa|let ><hlstd|combine l r ><hlopt|=><hlendline|Combine two
    expressions using each operator.><next-line><hlstd|
    \ ><hlkwc|List><hlopt|.><hlstd|map ><hlopt|(><hlkwa|fun
    ><hlstd|o><hlopt|-\<gtr\>><hlkwd|App ><hlopt|(><hlstd|o><hlopt|,><hlstd|l><hlopt|,><hlstd|r><hlopt|))
    [><hlkwd|Add><hlopt|; ><hlkwd|Sub><hlopt|; ><hlkwd|Mul><hlopt|;
    ><hlkwd|Div><hlopt|]><hlendline|><next-line><hlkwa|let rec ><hlstd|exprs
    ><hlopt|= ><hlkwa|function><hlendline|><next-line><hlstd| \ ><hlopt|\| []
    -\<gtr\> []><hlendline|><next-line><hlstd| \ ><hlopt|\|
    [><hlstd|n><hlopt|] -\<gtr\> [><hlkwd|Val
    ><hlstd|n><hlopt|]><hlendline|><next-line><hlstd| \ <hlopt|\|> ns
    ><hlopt|-\<gtr\>><hlendline|><next-line><hlstd| \ \ \ split ns
    <hlopt|\|>><hlopt|-\<gtr\> (><hlkwa|fun
    ><hlopt|(><hlstd|ls><hlopt|,><hlstd|rs><hlopt|) -\<gtr\>><hlendline|For
    each split <hlstd|ls><hlopt|,><hlstd|rs> of numbers,><next-line><hlstd|
    \ \ \ \ \ exprs ls <hlopt|\|>><hlopt|-\<gtr\> (><hlkwa|fun ><hlstd|l
    ><hlopt|-\<gtr\>><hlendline|for each expression <verbatim|l> over
    <verbatim|ls>><next-line><hlstd| \ \ \ \ \ \ \ exprs rs
    <hlopt|\|>><hlopt|-\<gtr\> (><hlkwa|fun ><hlstd|r
    ><hlopt|-\<gtr\>><hlendline|and expression <verbatim|r> over
    <verbatim|rs>><next-line><hlstd| \ \ \ \ \ \ \ \ \ combine l
    r><hlopt|)))><hlendline|produce all <verbatim|l ? r> expressions.>

    <new-page*><item>Return a list of all possible expressions that solve an
    instance of the countdown problem:

    <hlkwa|let ><hlstd|guard n ><hlopt|=><hlendline|><next-line><hlstd|
    \ ><hlkwc|List><hlopt|.><hlstd|filter ><hlopt|(><hlkwa|fun ><hlstd|e
    ><hlopt|-\<gtr\> ><hlstd|eval e ><hlopt|= ><hlkwd|Some
    ><hlstd|n><hlopt|)><hlendline|>

    <hlkwa|let ><hlstd|solutions ns n ><hlopt|=><hlendline|><next-line><hlstd|
    \ choices ns <hlopt|\|>><hlopt|-\<gtr\> (><hlkwa|fun ><hlstd|ns'
    ><hlopt|-\<gtr\>><hlendline|><next-line><hlstd| \ \ \ exprs ns'
    <hlopt|\|>><hlopt|\<gtr\> ><hlstd|guard n><hlopt|)><hlendline|>

    <item>Another way to express this:

    <hlkwa|let ><hlstd|guard p e ><hlopt|=><hlendline|><next-line><hlstd|
    \ ><hlkwa|if ><hlstd|p e ><hlkwa|then ><hlopt|[><hlstd|e><hlopt|]
    ><hlkwa|else ><hlopt|[]><hlendline|>

    <hlkwa|let ><hlstd|solutions ns n ><hlopt|=><hlendline|><next-line><hlstd|
    \ choices ns <hlopt|\|>><hlopt|-\<gtr\> (><hlkwa|fun ><hlstd|ns'
    ><hlopt|-\<gtr\>><hlendline|><next-line><hlstd| \ \ \ exprs ns'
    <hlopt|\|>><hlopt|-\<gtr\>><hlendline|><next-line><hlstd| \ \ \ \ \ guard
    ><hlopt|(><hlkwa|fun ><hlstd|e ><hlopt|-\<gtr\> ><hlstd|eval e ><hlopt|=
    ><hlkwd|Some ><hlstd|n><hlopt|))><hlendline|>
  </itemize>

  <subsection|<new-page*>Fuse the generate phase with the test phase>

  <\itemize>
    <item>We seek to define a function that fuses together the generation and
    evaluation of expressions:

    <\itemize>
      <item>We memorize the value together with the expression -- in pairs
      <verbatim|(e, <no-break>eval e)> -- so only valid subexpressions are
      ever generated.
    </itemize>

    <hlkwa|let ><hlstd|combine' ><hlopt|(><hlstd|l><hlopt|,><hlstd|x><hlopt|)
    (><hlstd|r><hlopt|,><hlstd|y><hlopt|) =><hlendline|><next-line><hlstd|
    \ ><hlopt|[><hlkwd|Add><hlopt|; ><hlkwd|Sub><hlopt|; ><hlkwd|Mul><hlopt|;
    ><hlkwd|Div><hlopt|]><hlendline|><next-line><hlstd|
    \ <hlopt|\|>><hlopt|\<gtr\> ><hlkwc|List><hlopt|.><hlstd|filter
    ><hlopt|(><hlkwa|fun ><hlstd|o><hlopt|-\<gtr\>><hlstd|valid o x
    y><hlopt|)><hlendline|><next-line><hlstd| \ <hlopt|\|>><hlopt|\<gtr\>
    ><hlkwc|List><hlopt|.><hlstd|map ><hlopt|(><hlkwa|fun
    ><hlstd|o><hlopt|-\<gtr\>><hlkwd|App ><hlopt|(><hlstd|o><hlopt|,><hlstd|l><hlopt|,><hlstd|r><hlopt|),
    ><hlstd|apply o x y><hlopt|)><hlendline|><next-line><hlendline|><next-line><hlkwa|let
    rec ><hlstd|results ><hlopt|= ><hlkwa|function><hlendline|><next-line><hlstd|
    \ ><hlopt|\| [] -\<gtr\> []><hlendline|><next-line><hlstd| \ ><hlopt|\|
    [><hlstd|n><hlopt|] -\<gtr\> ><hlkwa|if ><hlstd|n ><hlopt|\<gtr\>
    ><hlnum|0 ><hlkwa|then ><hlopt|[><hlkwd|Val ><hlstd|n><hlopt|,
    ><hlstd|n><hlopt|] ><hlkwa|else ><hlopt|[]><hlendline|><next-line><hlstd|
    \ <hlopt|\|> ns ><hlopt|-\<gtr\>><hlendline|><next-line><hlstd|
    \ \ \ split ns <hlopt|\|>><hlopt|-\<gtr\> (><hlkwa|fun
    ><hlopt|(><hlstd|ls><hlopt|,><hlstd|rs><hlopt|)
    -\<gtr\>><hlendline|><next-line><hlstd| \ \ \ \ \ results ls
    <hlopt|\|>><hlopt|-\<gtr\> (><hlkwa|fun ><hlstd|lx
    ><hlopt|-\<gtr\>><hlendline|><next-line><hlstd| \ \ \ \ \ \ \ results rs
    <hlopt|\|>><hlopt|-\<gtr\> (><hlkwa|fun ><hlstd|ry
    ><hlopt|-\<gtr\>><hlendline|><next-line><hlstd|
    \ \ \ \ \ \ \ \ \ combine' lx ry><hlopt|)))><hlendline|>

    <new-page*><item>Once the result is generated its value is already
    computed, we only check if it equals the target.

    <hlkwa|let ><hlstd|solutions' ns n ><hlopt|=><hlendline|><next-line><hlstd|
    \ choices ns <hlopt|\|>><hlopt|-\<gtr\> (><hlkwa|fun ><hlstd|ns'
    ><hlopt|-\<gtr\>><hlendline|><next-line><hlstd| \ \ \ results ns'
    <hlopt|\|>><hlopt|\<gtr\>><hlendline|><next-line><hlstd|
    \ \ \ \ \ \ \ ><hlkwc|List><hlopt|.><hlstd|filter ><hlopt|(><hlkwa|fun
    ><hlopt|(><hlstd|e><hlopt|,><hlstd|m><hlopt|)-\<gtr\>
    ><hlstd|m><hlopt|=><hlstd|n><hlopt|) ><hlstd|<hlopt|\|>><hlopt|\<gtr\>><hlendline|><next-line><hlstd|
    \ \ \ \ \ \ \ \ \ \ \ ><hlkwc|List><hlopt|.><hlstd|map
    fst><hlopt|)><hlendline|We discard the memorized values.>
  </itemize>

  <subsection|<new-page*>Eliminate symmetric cases>

  <\itemize>
    <item>Strengthening the valid predicate to take account of commutativity
    and identity properties:

    <hlkwa|let ><hlstd|valid op x y ><hlopt|=><hlendline|><next-line><hlstd|
    \ ><hlkwa|match ><hlstd|op ><hlkwa|with><hlendline|><next-line><hlstd|
    \ ><hlopt|\| ><hlkwd|Add ><hlopt|-\<gtr\> ><hlstd|x ><hlopt|\<less\>=
    ><hlstd|y<hlendline|><next-line> \ ><hlopt|\| ><hlkwd|Sub
    ><hlopt|-\<gtr\> ><hlstd|x ><hlopt|\<gtr\>
    ><hlstd|y<hlendline|><next-line> \ ><hlopt|\| ><hlkwd|Mul
    ><hlopt|-\<gtr\> ><hlstd|x ><hlopt|\<less\>= ><hlstd|y ><hlopt|&&
    ><hlstd|x ><hlopt|\<less\>\<gtr\> ><hlnum|1 ><hlopt|&& ><hlstd|y
    ><hlopt|\<less\>\<gtr\> ><hlnum|1><hlendline|><next-line><hlstd|
    \ ><hlopt|\| ><hlkwd|Div ><hlopt|-\<gtr\> ><hlstd|x ><hlkwa|mod ><hlstd|y
    ><hlopt|= ><hlnum|0 ><hlopt|&& ><hlstd|y ><hlopt|\<less\>\<gtr\>
    ><hlnum|1><hlendline|>

    <\itemize>
      <item>We eliminate repeating symmetrical solutions on the semantic
      level, i.e. on values, rather than on the syntactic level of
      expressions -- it is both easier and gives better results.
    </itemize>

    <item>Now recompile <hlstd|combine'>, <hlstd|results> and
    <hlstd|solutions'>.
  </itemize>

  \;

  <section|<new-page*>The Honey Islands Puzzle>

  <\itemize>
    <item>Be a bee! Find the cells to eat honey out of, so that the least
    amount of honey becomes sour, assuming that sourness spreads through
    contact.

    <\itemize>
      <item><small|Honey sourness is totally made up, sorry.>
    </itemize>

    <item>Each honeycomb cell is connected with 6 other cells, unless it is a
    border cell. Given a honeycomb with some cells initially marked as black,
    mark some more cells so that unmarked cells form <verbatim|num_islands>
    disconnected components, each with <verbatim|island_size> cells.
  </itemize>

  Task: 3 islands x 3<image|honey0.eps|0.25w|||>Solution:<image|honey1.eps|0.25w|||>

  <subsection|<new-page*>Representing the honeycomb>

  <hlkwa|type ><hlstd|cell ><hlopt|= ><hlkwb|int ><hlopt|*
  ><hlkwb|int><hlendline|We address cells using ``cartesian''
  coordinates><next-line><hlkwa|module ><hlkwd|CellSet
  ><hlopt|=><hlendline|and store them in either lists or
  sets.><next-line><hlstd| \ ><hlkwc|Set><hlopt|.><hlkwd|Make
  ><hlopt|(><hlkwa|struct type ><hlstd|t ><hlopt|= ><hlstd|cell ><hlkwa|let
  ><hlstd|compare ><hlopt|= ><hlstd|compare
  ><hlkwa|end><hlopt|)><hlendline|><next-line><hlkwa|type ><hlstd|task
  ><hlopt|= {><hlendline|For board ``size'' <math|N>, the honeycomb
  coordinates><next-line><hlstd| \ board<textunderscore>size ><hlopt|:
  ><hlkwb|int><hlopt|;><hlendline|range from <math|<around*|(|-2N,-N|)>> to
  <math|2N,N>.><next-line><hlstd| \ num<textunderscore>islands ><hlopt|:
  ><hlkwb|int><hlopt|;><hlendline|Required number of
  islands><next-line><hlstd| \ island<textunderscore>size ><hlopt|:
  ><hlkwb|int><hlopt|;><hlendline|and required number of cells in an
  island.><next-line><hlstd| \ empty<textunderscore>cells ><hlopt|:
  ><hlkwc|CellSet><hlopt|.><hlstd|t><hlopt|;><hlendline|The cells that are
  initially without honey.><next-line><hlopt|}><hlendline|>

  <hlkwa|let ><hlstd|cellset<textunderscore>of<textunderscore>list l
  ><hlopt|=><hlendline|List into set, inverse of
  <hlkwc|CellSet><hlopt|.><hlstd|elements>><next-line><hlstd|
  \ ><hlkwc|List><hlopt|.><hlstd|fold<textunderscore>right
  ><hlkwc|CellSet><hlopt|.><hlstd|add l ><hlkwc|CellSet><hlopt|.><hlstd|empty><hlendline|>

  <subsubsection|<new-page*>Neighborhood>

  <\with|par-columns|2>
    <draw-over|<image|honey_min2.eps||||>|<with|gr-mode|<tuple|edit|text-at>|<graphics|<text-at|<verbatim|x,y>|<point|-0.902203|-0.291672>>|<text-at|<verbatim|x+2,y>|<point|2.23049|-0.376339>>|<text-at|<verbatim|x+1,y+1>|<point|0.41014|2.35418>>|<text-at|<verbatim|x-1,y+1>|<point|-2.63788|2.33301>>|<text-at|<verbatim|x-2,y>|<point|-4.20423|-0.418673>>|<text-at|<verbatim|x-1,y-1>|<point|-2.65905|-3.08569>>|<text-at|<verbatim|x+1,y-1>|<point|0.431307|-3.19153>>>>>

    <small|<hlkwa|let ><hlstd|neighbors n eaten
    ><hlopt|(><hlstd|x><hlopt|,><hlstd|y><hlopt|)
    =><hlendline|><next-line><hlstd| \ ><hlkwc|List><hlopt|.><hlstd|filter<hlendline|><next-line>
    \ \ \ ><hlopt|(><hlstd|inside<textunderscore>board n
    eaten><hlopt|)><hlendline|><next-line><hlstd|
    \ \ \ ><hlopt|[><hlstd|x><hlopt|-><hlnum|1><hlopt|,><hlstd|y><hlopt|-><hlnum|1><hlopt|;
    ><hlstd|x><hlopt|+><hlnum|1><hlopt|,><hlstd|y><hlopt|-><hlnum|1><hlopt|;
    ><hlstd|x><hlopt|+><hlnum|2><hlopt|,><hlstd|y><hlopt|;><hlendline|><next-line><hlstd|
    \ \ \ \ x><hlopt|+><hlnum|1><hlopt|,><hlstd|y><hlopt|+><hlnum|1><hlopt|;
    ><hlstd|x><hlopt|-><hlnum|1><hlopt|,><hlstd|y><hlopt|+><hlnum|1><hlopt|;
    ><hlstd|x><hlopt|-><hlnum|2><hlopt|,><hlstd|y><hlopt|]><hlendline|>>
  </with>

  <subsubsection|<new-page*>Building the honeycomb>

  <\with|par-columns|2>
    <draw-over|<image|honey_demo.eps||||>|<with|gr-mode|<tuple|edit|text-at>|<graphics|<text-at|0,0|<point|-0.373032|-0.154352>>|<text-at|0,2|<point|-0.373032|3.04184>>|<text-at|0,-2|<point|-0.394199|-3.54104>>|<text-at|1,1|<point|0.515974|1.49666>>|<text-at|4,0|<point|3.33116|-0.23902>>|<text-at|3,1|<point|2.50566|1.49666>>|<text-at|2,2|<point|1.51081|3.063>>|<text-at|-2,0|<point|-2.23571|-0.154352>>>>>

    <\small>
      <hlkwa|let ><hlstd|even x ><hlopt|= ><hlstd|x ><hlkwa|mod ><hlnum|2
      ><hlopt|= ><hlnum|0><hlendline|>

      <hlkwa|let ><hlstd|inside<textunderscore>board n eaten
      ><hlopt|(><hlstd|x><hlopt|, ><hlstd|y><hlopt|)
      =><hlendline|><next-line><hlstd| \ even x ><hlopt|= ><hlstd|even y
      ><hlopt|&& ><hlstd|abs y ><hlopt|\<less\>= ><hlstd|n
      ><hlopt|&&><hlendline|><next-line><hlstd| \ abs x ><hlopt|+ ><hlstd|abs
      y ><hlopt|\<less\>= ><hlnum|2><hlopt|*><hlstd|n
      ><hlopt|&&><hlendline|><next-line><hlstd| \ not
      ><hlopt|(><hlkwc|CellSet><hlopt|.><hlstd|mem
      ><hlopt|(><hlstd|x><hlopt|,><hlstd|y><hlopt|)
      ><hlstd|eaten><hlopt|)><hlendline|>

      <hlkwa|let ><hlstd|honey<textunderscore>cells n eaten
      ><hlopt|=><hlendline|><next-line><hlstd| \ from<textunderscore>to
      ><hlopt|(-><hlnum|2><hlopt|*><hlstd|n><hlopt|)
      (><hlnum|2><hlopt|*><hlstd|n><hlopt|)><hlstd|<hlopt|\|>><hlopt|-\<gtr\>(><hlkwa|fun
      ><hlstd|x ><hlopt|-\<gtr\>><hlendline|><next-line><hlstd|
      \ \ \ from<textunderscore>to ><hlopt|(-><hlstd|n><hlopt|) ><hlstd|n
      <hlopt|\|>><hlopt|-\<gtr\> (><hlkwa|fun ><hlstd|y
      ><hlopt|-\<gtr\>><hlendline|><next-line><hlstd| \ \ \ \ guard
      ><hlopt|(><hlstd|inside<textunderscore>board n
      eaten><hlopt|)><hlendline|><next-line><hlstd|
      \ \ \ \ \ \ \ ><hlopt|(><hlstd|x><hlopt|,
      ><hlstd|y><hlopt|)))><hlendline|>
    </small>
  </with>

  <subsubsection|<new-page*>Drawing honeycombs>

  We separately generate colored polygons:

  <small|<hlkwa|let ><hlstd|draw<textunderscore>honeycomb <math|\<sim\>>w
  <math|\<sim\>>h task eaten ><hlopt|=><hlendline|><next-line><hlstd|
  \ ><hlkwa|let ><hlstd|i2f ><hlopt|= ><hlstd|float<textunderscore>of<textunderscore>int
  ><hlkwa|in><hlendline|><next-line><hlstd| \ ><hlkwa|let ><hlstd|nx
  ><hlopt|= ><hlstd|i2f ><hlopt|(><hlnum|4 ><hlopt|*
  ><hlstd|task><hlopt|.><hlstd|board<textunderscore>size ><hlopt|+
  ><hlnum|2><hlopt|) ><hlkwa|in><hlendline|><next-line><hlstd| \ ><hlkwa|let
  ><hlstd|ny ><hlopt|= ><hlstd|i2f ><hlopt|(><hlnum|2 ><hlopt|*
  ><hlstd|task><hlopt|.><hlstd|board<textunderscore>size ><hlopt|+
  ><hlnum|2><hlopt|) ><hlkwa|in><hlendline|><next-line><hlstd| \ ><hlkwa|let
  ><hlstd|radius ><hlopt|= ><hlstd|min ><hlopt|(><hlstd|i2f w ><hlopt|/.
  ><hlstd|nx><hlopt|) (><hlstd|i2f h ><hlopt|/. ><hlstd|ny><hlopt|)
  ><hlkwa|in><hlendline|><next-line><hlstd| \ ><hlkwa|let ><hlstd|x0
  ><hlopt|= ><hlstd|w ><hlopt|/ ><hlnum|2
  ><hlkwa|in><hlendline|><next-line><hlstd| \ ><hlkwa|let ><hlstd|y0
  ><hlopt|= ><hlstd|h ><hlopt|/ ><hlnum|2
  ><hlkwa|in><hlendline|><next-line><hlstd| \ ><hlkwa|let ><hlstd|dx
  ><hlopt|= (><hlstd|sqrt ><hlnum|3><hlopt|. /. ><hlnum|2><hlopt|.) *.
  ><hlstd|radius ><hlopt|+. ><hlnum|1><hlopt|. ><hlkwa|in><hlendline|The
  distance between><next-line><hlstd| \ ><hlkwa|let ><hlstd|dy ><hlopt|=
  (><hlnum|3><hlopt|. /. ><hlnum|2><hlopt|.) *. ><hlstd|radius ><hlopt|+.
  ><hlnum|2><hlopt|. ><hlkwa|in><hlendline|<math|<around*|(|x,y|)>> and
  <math|<around*|(|x+1,y+1|)>>.><next-line><hlstd| \ ><hlkwa|let
  ><hlstd|draw<textunderscore>cell ><hlopt|(><hlstd|x><hlopt|,><hlstd|y><hlopt|)
  =><hlendline|><next-line><hlstd| \ \ \ ><hlkwc|Array><hlopt|.><hlstd|init
  ><hlnum|7><hlendline|We draw a closed polygon by placing 6
  points><next-line><hlstd| \ \ \ \ \ ><hlopt|(><hlkwa|fun ><hlstd|i
  ><hlopt|-\<gtr\>><hlendline|evenly spaced on a
  circumcircle.><next-line><hlstd| \ \ \ \ \ \ \ ><hlkwa|let ><hlstd|phi
  ><hlopt|= ><hlstd|float<textunderscore>of<textunderscore>int i ><hlopt|*.
  ><hlstd|pi ><hlopt|/. ><hlnum|3><hlopt|.
  ><hlkwa|in><hlendline|><next-line><hlstd| \ \ \ \ \ \ \ x0 ><hlopt|+
  ><hlstd|int<textunderscore>of<textunderscore>float ><hlopt|(><hlstd|radius
  ><hlopt|*. ><hlstd|sin phi ><hlopt|+. ><hlstd|float<textunderscore>of<textunderscore>int
  x ><hlopt|*. ><hlstd|dx><hlopt|),><hlendline|><next-line><hlstd|
  \ \ \ \ \ \ \ y0 ><hlopt|+ ><hlstd|int<textunderscore>of<textunderscore>float
  ><hlopt|(><hlstd|radius ><hlopt|*. ><hlstd|cos phi ><hlopt|+.
  ><hlstd|float<textunderscore>of<textunderscore>int y ><hlopt|*.
  ><hlstd|dy><hlopt|)) ><hlkwa|in><hlendline|><next-line><hlstd|<new-page*>
  \ ><hlkwa|let ><hlstd|honey ><hlopt|=><hlendline|><next-line><hlstd|
  \ \ \ honey<textunderscore>cells task><hlopt|.><hlstd|board<textunderscore>size
  ><hlopt|(><hlkwc|CellSet><hlopt|.><hlstd|union
  task><hlopt|.><hlstd|empty<textunderscore>cells<hlendline|><next-line>
  \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ ><hlopt|(><hlstd|cellset<textunderscore>of<textunderscore>list
  eaten><hlopt|))><hlendline|><next-line><hlstd|
  \ \ \ <hlopt|\|>><hlopt|\<gtr\> ><hlkwc|List><hlopt|.><hlstd|map
  ><hlopt|(><hlkwa|fun ><hlstd|p><hlopt|-\<gtr\>><hlstd|draw<textunderscore>cell
  p><hlopt|, (><hlnum|255><hlopt|, ><hlnum|255><hlopt|, ><hlnum|0><hlopt|))
  ><hlkwa|in><hlendline|><next-line><hlstd| \ ><hlkwa|let ><hlstd|eaten
  ><hlopt|= ><hlkwc|List><hlopt|.><hlstd|map<hlendline|><next-line>
  \ \ \ \ ><hlopt|(><hlkwa|fun ><hlstd|p><hlopt|-\<gtr\>><hlstd|draw<textunderscore>cell
  p><hlopt|, (><hlnum|50><hlopt|, ><hlnum|0><hlopt|, ><hlnum|50><hlopt|))
  ><hlstd|eaten ><hlkwa|in><hlendline|><next-line><hlstd| \ ><hlkwa|let
  ><hlstd|old<textunderscore>empty ><hlopt|=
  ><hlkwc|List><hlopt|.><hlstd|map<hlendline|><next-line>
  \ \ \ \ ><hlopt|(><hlkwa|fun ><hlstd|p><hlopt|-\<gtr\>><hlstd|draw<textunderscore>cell
  p><hlopt|, (><hlnum|0><hlopt|, ><hlnum|0><hlopt|,
  ><hlnum|0><hlopt|))><hlendline|><next-line><hlstd|
  \ \ \ \ ><hlopt|(><hlkwc|CellSet><hlopt|.><hlstd|elements
  task><hlopt|.><hlstd|empty<textunderscore>cells><hlopt|)
  ><hlkwa|in><hlendline|><next-line><hlstd| \ honey @ eaten @
  old<textunderscore>empty><hlendline|>>

  <new-page*>We can draw the polygons to an <em|SVG> image:

  <small|<hlkwa|let ><hlstd|draw<textunderscore>to<textunderscore>svg file
  <math|\<sim\>>w <math|\<sim\>>h ?title ?desc curves
  ><hlopt|=><hlendline|><next-line><hlstd| \ ><hlkwa|let ><hlstd|f ><hlopt|=
  ><hlstd|open<textunderscore>out file ><hlkwa|in><hlendline|><next-line><hlstd|
  \ ><hlkwc|Printf><hlopt|.><hlstd|fprintf f ><hlstr|"\<less\>?xml
  version=><hlesc|<math|>"><hlstr|1.0><hlesc|<math|>"
  ><hlstr|standalone=><hlesc|<math|>"><hlstr|no><hlesc|<math|>"><hlstr|?\<gtr\>><hlendline|><next-line><hlstr|\<less\>!DOCTYPE
  svg PUBLIC ><hlesc|<math|>"><hlstr|-//W3C//DTD SVG 1.1//EN><hlesc|<math|>"
  ><hlendline|><next-line><hlstd| \ ><hlesc|<math|>"><hlstr|http://www.w3.org/Graphics/SVG/1.1/DTD/svg11.dtd><hlesc|<math|>"><hlstr|\<gtr\>><hlendline|><next-line><hlstr|\<less\>svg
  width=><hlesc|<math|>"><hlstr|%d><hlesc|<math|>"
  ><hlstr|height=><hlesc|<math|>"><hlstr|%d><hlesc|<math|>"
  ><hlstr|viewBox=><hlesc|<math|>"><hlstr|0 0 %d
  %d><hlesc|<math|>"><hlendline|><next-line><hlstd|
  \ \ \ \ ><hlstr|xmlns=><hlesc|<math|>"><hlstr|http://www.w3.org/2000/svg><hlesc|<math|>"
  ><hlstr|version=><hlesc|<math|>"><hlstr|1.1><hlesc|<math|>"><hlstr|\<gtr\>><hlendline|><next-line><hlstr|"><hlstd|
  w h w h><hlopt|;><hlendline|><next-line><hlstd| \ ><hlopt|(><hlkwa|match
  ><hlstd|title ><hlkwa|with ><hlkwd|None ><hlopt|-\<gtr\>
  ()><hlendline|><next-line><hlstd| \ ><hlopt|\| ><hlkwd|Some ><hlstd|title
  ><hlopt|-\<gtr\> ><hlkwc|Printf><hlopt|.><hlstd|fprintf f ><hlstr|"><hlstd|
  \ ><hlstr|\<less\>title\<gtr\>%s\<less\>/title\<gtr\>><hlesc|<math|>n><hlstr|"><hlstd|
  title><hlopt|);><hlendline|><next-line><hlstd| \ ><hlopt|(><hlkwa|match
  ><hlstd|desc ><hlkwa|with ><hlkwd|None ><hlopt|-\<gtr\>
  ()><hlendline|><next-line><hlstd| \ ><hlopt|\| ><hlkwd|Some ><hlstd|desc
  ><hlopt|-\<gtr\> ><hlkwc|Printf><hlopt|.><hlstd|fprintf f ><hlstr|"><hlstd|
  \ ><hlstr|\<less\>desc\<gtr\>%s\<less\>/desc\<gtr\>><hlesc|<math|>n><hlstr|"><hlstd|
  desc><hlopt|);><hlendline|><next-line><hlstd| \ ><hlkwa|let
  ><hlstd|draw<textunderscore>shape ><hlopt|(><hlstd|points><hlopt|,
  (><hlstd|r><hlopt|,><hlstd|g><hlopt|,><hlstd|b><hlopt|))
  =><hlendline|><next-line><hlstd| \ \ \ uncurry
  ><hlopt|(><hlkwc|Printf><hlopt|.><hlstd|fprintf f ><hlstr|"><hlstd|
  \ ><hlstr|\<less\>path d=><hlesc|<math|>"><hlstr|M %d %d"><hlopt|)
  ><hlstd|points><hlopt|.(><hlnum|0><hlopt|);><hlendline|><next-line><hlstd|
  \ \ \ ><hlkwc|Array><hlopt|.><hlstd|iteri ><hlopt|(><hlkwa|fun ><hlstd|i
  ><hlopt|(><hlstd|x><hlopt|, ><hlstd|y><hlopt|)
  -\<gtr\>><hlendline|><next-line><hlstd| \ \ \ \ \ ><hlkwa|if ><hlstd|i
  ><hlopt|\<gtr\> ><hlnum|0 ><hlkwa|then ><hlkwc|Printf><hlopt|.><hlstd|fprintf
  f ><hlstr|" L %d %d"><hlstd| x y><hlopt|)
  ><hlstd|points><hlopt|;><hlendline|><next-line><hlstd|
  \ \ \ ><hlkwc|Printf><hlopt|.><hlstd|fprintf f<hlendline|><next-line>
  \ \ \ \ \ ><hlstr|"><hlesc|<math|>"<math|>n><hlstd|
  \ \ \ \ \ \ \ ><hlstr|fill=><hlesc|<math|>"><hlstr|rgb(%d, %d,
  %d)><hlesc|<math|>" ><hlstr|stroke-width=><hlesc|<math|>"><hlstr|3><hlesc|<math|>"
  ><hlstr|/\<gtr\>><hlesc|<math|>n><hlstr|"><hlstd|<hlendline|><next-line>
  \ \ \ \ \ r g b ><hlkwa|in><hlendline|><next-line><hlstd|
  \ ><hlkwc|List><hlopt|.><hlstd|iter draw<textunderscore>shape
  curves><hlopt|;><hlendline|><next-line><hlstd|
  \ ><hlkwc|Printf><hlopt|.><hlstd|fprintf f
  ><hlstr|"\<less\>/svg\<gtr\>%!"><hlendline|>>

  <new-page*>But we also want to draw on a screen window -- we need to link
  the <verbatim|Graphics> library. In the interactive toplevel:

  <hlstd|#load ><hlstr|"graphics.cma"><hlopt|;;><hlendline|>

  When compiling we just provide <verbatim|graphics.cma> to the command.

  <small|<hlkwa|let ><hlstd|draw<textunderscore>to<textunderscore>screen
  <math|\<sim\>>w <math|\<sim\>>h curves ><hlopt|=><hlendline|><next-line><hlstd|
  \ ><hlkwc|Graphics><hlopt|.><hlstd|open<textunderscore>graph
  ><hlopt|(><hlstr|" "><hlstd|<textasciicircum>string<textunderscore>of<textunderscore>int
  w<textasciicircum>><hlstr|"x"><hlstd|<textasciicircum>string<textunderscore>of<textunderscore>int
  h><hlopt|);><hlendline|><next-line><hlstd|
  \ ><hlkwc|Graphics><hlopt|.><hlstd|set<textunderscore>color
  ><hlopt|(><hlkwc|Graphics><hlopt|.><hlstd|rgb ><hlnum|50 50
  0><hlopt|);><hlendline|We draw a brown background.><next-line><hlstd|
  \ ><hlkwc|Graphics><hlopt|.><hlstd|fill<textunderscore>rect ><hlnum|0 0
  ><hlopt|(><hlkwc|Graphics><hlopt|.><hlstd|size<textunderscore>x ><hlopt|())
  (><hlkwc|Graphics><hlopt|.><hlstd|size<textunderscore>y
  ><hlopt|());><hlendline|><next-line><hlstd|
  \ ><hlkwc|List><hlopt|.><hlstd|iter ><hlopt|(><hlkwa|fun
  ><hlopt|(><hlstd|points><hlopt|, (><hlstd|r><hlopt|,><hlstd|g><hlopt|,><hlstd|b><hlopt|))
  -\<gtr\>><hlendline|><next-line><hlstd|
  \ \ \ ><hlkwc|Graphics><hlopt|.><hlstd|set<textunderscore>color
  ><hlopt|(><hlkwc|Graphics><hlopt|.><hlstd|rgb r g
  b><hlopt|);><hlendline|><next-line><hlstd|
  \ \ \ ><hlkwc|Graphics><hlopt|.><hlstd|fill<textunderscore>poly
  points><hlopt|) ><hlstd|curves><hlopt|;><hlendline|><next-line><hlstd|
  \ ><hlkwa|if ><hlkwc|Graphics><hlopt|.><hlstd|read<textunderscore>key
  ><hlopt|() = ><verbatim|'q'><hlendline|We wait so that solutions can be
  seen><next-line> \ <hlkwa|then ><hlstd|failwith ><hlstr|"User interrupted
  finding solutions."><hlopt|;><hlendline|as they're
  computed.><next-line><hlstd| \ ><hlkwc|Graphics><hlopt|.><hlstd|close<textunderscore>graph
  ><hlopt|()><hlendline|><next-line>>

  <subsection|<new-page*>Testing correctness of a solution>

  We walk through each island counting its cells, depth-first: having visited
  everything possible in one direction, we check whether something remains in
  another direction.

  Correctness means there are <verbatim|num<textunderscore>islands>
  components each with <verbatim|island<textunderscore>size> cells. We start
  by computing the cells to walk on: <verbatim|honey>.

  <hlkwa|let ><hlstd|check<textunderscore>correct n
  island<textunderscore>size num<textunderscore>islands
  empty<textunderscore>cells ><hlopt|=><hlendline|><next-line><hlstd|
  \ ><hlkwa|let ><hlstd|honey ><hlopt|= ><hlstd|honey<textunderscore>cells n
  empty<textunderscore>cells ><hlkwa|in><hlendline|>

  <new-page*>We keep track of already visited cells and islands. When an
  unvisited cell is there after walking around an island, it must belong to a
  different island.

  <hlstd| \ ><hlkwa|let rec ><hlstd|check<textunderscore>board
  been<textunderscore>islands unvisited visited
  ><hlopt|=><hlendline|><next-line><hlstd| \ \ \ ><hlkwa|match
  ><hlstd|unvisited ><hlkwa|with><hlendline|><next-line><hlstd|
  \ \ \ ><hlopt|\| [] -\<gtr\> ><hlstd|been<textunderscore>islands ><hlopt|=
  ><hlstd|num<textunderscore>islands<hlendline|><next-line> \ \ \ <hlopt|\|>
  cell><hlopt|::><hlstd|remaining ><hlkwa|when
  ><hlkwc|CellSet><hlopt|.><hlstd|mem cell visited
  ><hlopt|-\<gtr\>><hlendline|><verbatim|<next-line>
  \ \ \ \ \ \ \ check<textunderscore>board been_islands remaining
  visited><hlendline|Keep looking.><next-line> \ \ \ \ \ <hlopt|\|>
  cell<hlopt|::><hlstd|remaining ><hlcom|(* when not visited *)><hlstd|
  ><hlopt|-\<gtr\>><hlendline|><next-line><hlstd| \ \ \ \ \ \ \ ><hlkwa|let
  ><hlopt|(><hlstd|been<textunderscore>size><hlopt|,
  ><hlstd|unvisited><hlopt|, ><hlstd|visited><hlopt|)
  =><hlendline|><verbatim|<next-line> \ \ \ \ \ \ \ \ \ check<textunderscore>island
  cell><hlendline|Visit another island.><verbatim|<next-line>
  \ \ \ \ \ \ \ \ \ \ \ ><hlopt|(><hlnum|1><hlopt|,
  ><hlstd|remaining><hlopt|, ><hlkwc|CellSet><hlopt|.><hlstd|add cell
  visited><hlopt|) ><hlkwa|in><hlendline|><next-line><hlstd|
  \ \ \ \ \ \ \ been<textunderscore>size ><hlopt|=
  ><hlstd|island<textunderscore>size<hlendline|><next-line>
  \ \ \ \ \ \ \ ><hlopt|&& ><hlstd|check<textunderscore>board
  ><hlopt|(><hlstd|been<textunderscore>islands><hlopt|+><hlnum|1><hlopt|)
  ><hlstd|unvisited visited><hlendline|>

  <new-page*>When walking over an island, besides the <verbatim|unvisited>
  and <verbatim|visited> cells, we need to remember <verbatim|been_size> --
  number of cells in the island visited so far.

  <hlstd| \ ><hlkwa|and ><hlstd|check<textunderscore>island current state
  ><hlopt|=><hlendline|><next-line><hlstd| \ \ \ ><hlstd|neighbors n
  empty<textunderscore>cells current ><hlendline|><next-line><hlstd|
  \ \ \ ><hlopt|\|><hlopt|\<gtr\> ><hlkwc|List><verbatim|<hlopt|.>fold<textunderscore>left
  ><hlendline|Walk into each direction and accumulate
  visits.><verbatim|<next-line> \ \ \ \ \ ><hlopt|(><hlkwa|fun
  ><hlopt|(><hlstd|been<textunderscore>size><hlopt|,
  ><hlstd|unvisited><hlopt|, ><hlstd|visited ><hlkwa|as
  ><hlstd|state><hlopt|)><hlendline|><next-line><hlstd|
  \ \ \ \ \ \ \ neighbor ><hlopt|-\<gtr\>><hlendline|><next-line><hlstd|
  \ \ \ \ \ \ \ ><hlkwa|if ><hlkwc|CellSet><hlopt|.><hlstd|mem neighbor
  visited ><hlkwa|then ><hlstd|state<hlendline|><next-line>
  \ \ \ \ \ \ \ ><hlkwa|else><hlendline|><next-line><hlstd|
  \ \ \ \ \ \ \ \ \ ><hlkwa|let ><hlstd|unvisited ><hlopt|= ><hlstd|remove
  neighbor unvisited ><hlkwa|in><hlendline|><next-line><hlstd|
  \ \ \ \ \ \ \ \ \ ><hlkwa|let ><hlstd|visited ><hlopt|=
  ><hlkwc|CellSet><hlopt|.><hlstd|add neighbor visited
  ><hlkwa|in><hlendline|><next-line><hlstd| \ \ \ \ \ \ \ \ \ ><hlkwa|let
  ><hlstd|been<textunderscore>size ><hlopt|= ><hlstd|been<textunderscore>size
  ><hlopt|+ ><hlnum|1 ><hlkwa|in><hlendline|><next-line><hlstd|
  \ \ \ \ \ \ \ \ \ check<textunderscore>island
  neighbor<hlendline|><next-line> \ \ \ \ \ \ \ \ \ \ \ ><hlopt|(><hlstd|been<textunderscore>size><hlopt|,
  ><hlstd|unvisited><hlopt|, ><hlstd|visited><hlopt|))><hlendline|><verbatim|<next-line>
  \ \ \ \ \ state ><hlkwa|in><hlendline|Start from the current overall state
  (initial <verbatim|been_size> is 1).>

  Initially there are no islands already visited.

  <hlstd| \ check<textunderscore>board ><hlnum|0 ><hlstd|honey
  empty<textunderscore>cells><hlendline|>

  <subsection|<new-page*>Interlude: multiple results per step>

  When there is only one possible result per step, we work through a list
  using <hlkwc|List><hlopt|.><hlstd|fold<textunderscore>right> and
  <hlkwc|List><hlopt|.><hlstd|fold<textunderscore>left> functions.

  What if there are multiple results? Recall that when we have multiple
  sources of data and want to collect multiple results, we use
  <verbatim|concat_map>:

  <with|gr-mode|<tuple|edit|text-at>|gr-frame|<tuple|scale|1cm|<tuple|0.49gw|0.5gh>>|gr-geometry|<tuple|geometry|1par|0.13625par|center>|<graphics||<point|-4.56826|1.32331>|<point|-3.50992|1.34447>|<point|-2.21875|1.32331>|<point|-0.969903|1.32331>|<point|0.342439|1.30214>|<with|arrow-end|\<gtr\>|<line|<point|-4.56826|1.32331>|<point|-5.54193676412224|0.264965603915862>>>|<with|arrow-end|\<gtr\>|<line|<point|-4.56826|1.32331>|<point|-4.69526392379944|0.328466066940071>>>|<with|arrow-end|\<gtr\>|<line|<point|-4.56826|1.32331>|<point|-4.03909247254928|0.286132424923932>>>|<with|arrow-end|\<gtr\>|<line|<point|-3.50992|1.34447>|<point|-3.57342241037174|0.391966529964281>>>|<with|arrow-end|\<gtr\>|<line|<point|-3.50992|1.34447>|<point|-2.89608413811351|0.370799708956211>>>|<with|arrow-end|\<gtr\>|<line|<point|-2.21875|1.32331>|<point|-2.45158089694404|0.434300171980421>>>|<with|arrow-end|\<gtr\>|<line|<point|-0.969903|1.32331>|<point|-1.60490805662125|0.413133350972351>>>|<with|arrow-end|\<gtr\>|<line|<point|-0.969903|1.32331>|<point|-0.864069321338801|0.391966529964281>>>|<point|1.31611|1.38681>|<with|arrow-end|\<gtr\>|<line|<point|1.31611|1.38681>|<point|0.40593993914539|0.455466992988491>>>|<with|arrow-end|\<gtr\>|<line|<point|1.31611|1.38681>|<point|1.08327821140362|0.47663381399656>>>|<with|arrow-end|\<gtr\>|<line|<point|1.31611|1.38681>|<point|1.802950125678|0.413133350972351>>>|<with|arrow-end|\<gtr\>|<line|<point|1.31611|1.38681>|<point|2.58612250297658|0.54013427702077>>>|<with|color|red|<point|-5.54194|0.264966>>|<with|color|red|<point|-5.54194|0.264966>>|<with|color|red|<point|-4.69526|0.328466>>|<with|color|red|<point|-4.03909|0.286132>>|<with|color|red|<point|-3.57342|0.391967>>|<with|color|red|<point|-2.89608|0.3708>>|<with|color|red|<point|-2.45158|0.4343>>|<with|color|red|<point|-1.60491|0.413133>>|<with|color|red|<point|-0.864069|0.391967>>|<with|color|red|<point|0.40594|0.455467>>|<with|color|red|<point|1.08328|0.476634>>|<with|color|red|<point|1.80295|0.413133>>|<with|color|red|<point|2.58612|0.540134>>|<with|color|red|<line|<point|-5.77477|0.624802>|<point|-6.00760682629978|0.56130109802884>|<point|-6.02877364730784|-0.0525367112051859>|<point|-5.73243815319487|-0.116037174229395>>>|<with|color|red|<line|<point|-4.01793|0.794136>|<point|-3.89092472549279|0.56130109802884>|<point|-3.93325836750893|0.0109637518190237>|<point|-4.22959386162191|-0.116037174229395>>>|<with|color|red|<line|<point|-3.76392|0.878803>|<point|-3.67925651541209|0.0532973938351634>|<point|-3.44642148432332|-0.031369890197116>>>|<with|color|red|<line|<point|-2.87492|0.89997>|<point|-2.76908321206509|0.688302024077259>|<point|-2.76908321206509|-0.0102030691890462>|<point|-2.98075142214579|-0.031369890197116>>>|<with|color|red|<line|<point|-2.55742|0.89997>|<point|-2.55741500198439|0.0956310358513031>|<point|-2.45158089694404|-0.0737035322132557>>>|<with|color|red|<line|<point|-2.09174|0.815303>|<point|-2.00707765577457|0.688302024077259>|<point|-2.07057811879878|0.0744642148432332>|<point|-2.23991268686334|-0.031369890197116>>>|<with|color|red|<line|<point|-1.66841|0.878803>|<point|-1.81657626670194|0.794136129117608>|<point|-1.83774308771001|0.0532973938351634>|<point|-1.62607487762932|-0.137203995237465>>>|<with|color|red|<line|<point|-0.631234|0.878803>|<point|-0.483066543193544|0.794136129117608>|<point|-0.525400185209684|0.0956310358513031>|<point|-0.821735679322662|-0.0948703532213256>>>|<with|color|red|<line|<point|-0.0173965|0.857637>|<point|-0.144397407064427|0.794136129117608>|<point|-0.207897870088636|0.264965603915862>|<point|-0.144397407064427|0.137964677867443>>>|<with|color|red|<line|<point|0.173105|0.751802>|<point|0.067270803016272|0.159131498875513>>>|<with|color|red|<line|<point|0.46944|0.878803>|<point|0.30010583410504|0.963470697182167>|<point|0.27893901309697|0.0532973938351634>|<point|0.427106760153459|0.0532973938351634>>>|<with|color|red|<line|<point|2.64962|0.942304>|<point|2.88245799708956|0.899970234157957>|<point|2.84012435507342|-0.031369890197116>|<point|2.48028839793623|-0.0525367112051859>>>|<with|color|red|arrow-end|\<gtr\>|<line|<point|-5.54194|0.264966>|<point|-5.54193676412224|-0.539373594390792>>>|<with|color|red|arrow-end|\<gtr\>|<line|<point|-4.69526|0.328466>|<point|-4.71643074480751|-0.560540415398862>>>|<with|color|red|arrow-end|\<gtr\>|<line|<point|-3.57342|0.391967>|<point|-3.55225558936367|-0.539373594390792>>>|<with|color|red|arrow-end|\<gtr\>|<line|<point|-2.89608|0.3708>|<point|-2.89608413811351|-0.539373594390792>>>|<with|color|red|arrow-end|\<gtr\>|<line|<point|-1.60491|0.413133>|<point|-1.62607487762932|-0.560540415398862>>>|<with|color|red|arrow-end|\<gtr\>|<line|<point|-0.864069|0.391967>|<point|-0.864069321338801|-0.581707236406932>>>|<with|color|red|arrow-end|\<gtr\>|<line|<point|0.40594|0.455467>|<point|0.38477311813732|-0.560540415398862>>>|<with|color|red|arrow-end|\<gtr\>|<line|<point|1.08328|0.476634>|<point|1.06211139039556|-0.497039952374653>>>|<with|color|red|arrow-end|\<gtr\>|<line|<point|1.80295|0.413133>|<point|1.78178330466993|-0.475873131366583>>>|<with|color|red|arrow-end|\<gtr\>|<line|<point|2.58612|0.540134>|<point|2.5014552189443|-0.497039952374653>>>|<point|-5.54194|-0.539374>|<point|-4.71643|-0.56054>|<point|-3.55226|-0.539374>|<point|-2.89608|-0.539374>|<point|-1.62607|-0.56054>|<point|-0.864069|-0.581707>|<point|0.384773|-0.56054>|<point|1.06211|-0.49704>|<point|1.78178|-0.475873>|<point|2.50146|-0.49704>|<line|<point|-5.54194|1.55614>|<point|-5.85943907924329|1.47147440137584>|<point|-5.85943907924329|1.11163844423866>|<point|-5.62660404815452|0.984637518190237>>|<line|<point|2.12045|1.53497>|<point|2.41678793491203|1.49264122238391>|<point|2.41678793491203|1.19630572827094>|<point|2.20511972483133|1.13280526524673>>|<line|<point|-5.98644|-0.306539>|<point|-6.28277549940468|-0.348872205318164>|<point|-6.24044185738854|-0.687541341447281>|<point|-5.9229395422675|-0.85687590951184>>|<line|<point|2.96713|-0.221871>|<point|3.30579441725096|-0.370039026326234>|<point|3.30579441725096|-0.645207699431142>|<point|2.88245799708956|-0.85687590951184>>|<text-at|<verbatim|concat_map>|<point|-11.0665|0.984638>>|<text-at|<verbatim|f
  xs =>|<point|-10.3468|0.264966>>|<text-at|<verbatim|List.map f
  xs>|<point|3.70796|1.04814>>|<text-at|<verbatim|\|\<gtr\>
  List.concat>|<point|3.8773|0.0744642>>>>

  We shortened <verbatim|concat_map> calls using ``<hlstd|work
  <hlopt|\|>><hlopt|-\<gtr\> (><hlkwa|fun ><hlstd|a_result ><hlopt|-\<gtr\>
  >...<hlopt|)>'' scheme. Here we need to collect results once per step.

  <hlkwa|let rec ><hlstd|concat<textunderscore>fold f a ><hlopt|=
  ><hlkwa|function><hlendline|><next-line><hlstd| \ ><hlopt|\| [] -\<gtr\>
  [><hlstd|a><hlopt|]><hlendline|><next-line><hlstd| \ <hlopt|\|>
  x><hlopt|::><hlstd|xs ><hlopt|-\<gtr\> ><hlendline|><next-line><hlstd|
  \ \ \ f x a <hlopt|\|>><hlopt|-\<gtr\> (><hlkwa|fun ><hlstd|a'
  ><hlopt|-\<gtr\> ><hlstd|concat<textunderscore>fold f a'
  xs><hlopt|)><hlendline|><next-line>

  <subsection|<new-page*>Generating a solution>

  We turn the code for testing a solution into one that generates a correct
  solution.

  <\itemize>
    <item>We pass around the current solution <verbatim|eaten>.

    <item>The results will be in a list.

    <item>Empty list means that in a particular case there are no (further)
    results.

    <item>When walking an island, we pick a new neighbor and try eating from
    it in one set of possible solutions -- which ends walking in its
    direction, and walking through it in another set of possible solutions.

    <\itemize>
      <item>When testing a solution, we never decided to eat from a cell.
    </itemize>
  </itemize>

  The generating function has the same signature as the testing function:

  <hlkwa|let ><hlstd|find<textunderscore>to<textunderscore>eat n
  island<textunderscore>size num<textunderscore>islands
  empty<textunderscore>cells ><hlopt|=><hlendline|><next-line><hlstd|
  \ ><hlkwa|let ><hlstd|honey ><hlopt|= ><hlstd|honey<textunderscore>cells n
  empty<textunderscore>cells ><hlkwa|in><hlendline|>

  <new-page*>Since we return lists of solutions, if we are done with current
  solution <verbatim|eaten> we return <verbatim|[eaten]>, and if we are in a
  ``dead corner'' we return <verbatim|[]>.

  <hlstd| \ ><hlkwa|let rec ><hlstd|find<textunderscore>board
  been<textunderscore>islands unvisited visited eaten
  ><hlopt|=><hlendline|><next-line><hlstd| \ \ \ ><hlkwa|match
  ><hlstd|unvisited ><hlkwa|with><hlendline|><next-line><hlstd|
  \ \ \ ><hlopt|\| [] -\<gtr\>><hlendline|><next-line><hlstd|
  \ \ \ \ \ ><hlkwa|if ><hlstd|been<textunderscore>islands ><hlopt|=
  ><hlstd|num<textunderscore>islands ><hlkwa|then
  ><hlopt|[><hlstd|eaten><hlopt|] ><hlkwa|else
  ><hlopt|[]><hlendline|><next-line><hlstd| \ \ \ <hlopt|\|>
  cell><hlopt|::><hlstd|remaining ><hlkwa|when
  ><hlkwc|CellSet><hlopt|.><hlstd|mem cell visited
  ><hlopt|-\<gtr\>><hlendline|><next-line><hlstd|
  \ \ \ \ \ find<textunderscore>board been<textunderscore>islands<hlendline|><next-line>
  \ \ \ \ \ \ \ remaining visited eaten<hlendline|><next-line>
  \ \ \ <hlopt|\|> cell><hlopt|::><hlstd|remaining ><hlcom|(* when not
  visited *)><hlstd| ><hlopt|-\<gtr\>><hlendline|><next-line><hlstd|
  \ \ \ \ \ find<textunderscore>island cell<hlendline|><next-line>
  \ \ \ \ \ \ \ ><hlopt|(><hlnum|1><hlopt|, ><hlstd|remaining><hlopt|,
  ><hlkwc|CellSet><hlopt|.><hlstd|add cell visited><hlopt|,
  ><hlstd|eaten><hlopt|)><hlendline|><next-line><hlstd|
  \ \ \ \ \ <hlopt|\|>><hlopt|-\<gtr\>><hlendline|Concatenate solutions for
  each way of eating cells around and island.><next-line><hlstd|
  \ \ \ \ \ ><hlopt|(><hlkwa|fun ><hlopt|(><hlstd|been<textunderscore>size><hlopt|,
  ><hlstd|unvisited><hlopt|, ><hlstd|visited><hlopt|, ><hlstd|eaten><hlopt|)
  -\<gtr\>><hlendline|><next-line><hlstd| \ \ \ \ \ \ \ ><hlkwa|if
  ><hlstd|been<textunderscore>size ><hlopt|=
  ><hlstd|island<textunderscore>size<hlendline|><next-line>
  \ \ \ \ \ \ \ ><hlkwa|then ><hlstd|find<textunderscore>board
  ><hlopt|(><hlstd|been<textunderscore>islands><hlopt|+><hlnum|1><hlopt|)><hlendline|><next-line><hlstd|
  \ \ \ \ \ \ \ \ \ \ \ \ \ \ unvisited visited eaten<hlendline|><next-line>
  \ \ \ \ \ \ \ ><hlkwa|else ><hlopt|[])><hlendline|>

  <new-page*>We step into each neighbor of a current cell of the island, and
  either eat it or walk further.

  <hlstd| \ ><hlkwa|and ><hlstd|find<textunderscore>island current state
  ><hlopt|=><hlendline|><next-line><hlstd| \ \ \ neighbors n
  empty<textunderscore>cells current<hlendline|><next-line>
  \ \ \ <hlopt|\|>><hlopt|\<gtr\> ><verbatim|concat<textunderscore>fold><hlendline|Instead
  of <verbatim|fold_left> since multiple results.><verbatim|<next-line>
  \ \ \ \ \ \ \ ><hlopt|(><hlkwa|fun ><hlstd|neighbor<hlendline|><next-line>
  \ \ \ \ \ \ \ \ \ ><hlopt|(><hlstd|been<textunderscore>size><hlopt|,
  ><hlstd|unvisited><hlopt|, ><hlstd|visited><hlopt|, ><hlstd|eaten
  ><hlkwa|as ><hlstd|state><hlopt|) -\<gtr\>><hlendline|><next-line><hlstd|
  \ \ \ \ \ \ \ \ \ ><hlkwa|if ><hlkwc|CellSet><hlopt|.><hlstd|mem neighbor
  visited ><hlkwa|then ><hlopt|[><hlstd|state><hlopt|]><hlendline|><next-line><hlstd|
  \ \ \ \ \ \ \ \ \ ><hlkwa|else><hlendline|><next-line><hlstd|
  \ \ \ \ \ \ \ \ \ \ \ ><hlkwa|let ><hlstd|unvisited ><hlopt|=
  ><hlstd|remove neighbor unvisited ><hlkwa|in><hlendline|><next-line><hlstd|
  \ \ \ \ \ \ \ \ \ \ \ ><hlkwa|let ><hlstd|visited ><hlopt|=
  ><hlkwc|CellSet><hlopt|.><hlstd|add neighbor visited
  ><hlkwa|in><hlstd|<hlendline|><next-line>
  \ \ \ \ \ \ \ \ \ \ \ ><hlopt|(><hlstd|been<textunderscore>size><hlopt|,
  ><hlstd|unvisited><hlopt|, ><hlstd|visited><hlopt|,><hlendline|><next-line><hlstd|
  \ \ \ \ \ \ \ \ \ \ \ \ neighbor><hlopt|::><hlstd|eaten><hlopt|)::><hlendline|><next-line><hlstd|
  \ \ \ \ \ \ \ \ \ \ \ \ \ ><hlcom|(* solutions where neighbor is honey
  *)><hlstd|<hlendline|><next-line> \ \ \ \ \ \ \ \ \ \ \ find<textunderscore>island
  neighbor<hlendline|><next-line> \ \ \ \ \ \ \ \ \ \ \ \ \ ><hlopt|(><hlstd|been<textunderscore>size><hlopt|+><hlnum|1><hlopt|,
  ><hlstd|unvisited><hlopt|, ><hlstd|visited><hlopt|,
  ><hlstd|eaten><hlopt|))><hlendline|><next-line><hlstd| \ \ \ \ \ \ \ state
  ><hlkwa|in><hlendline|>

  <new-page*>The initial partial solution is -- nothing eaten yet.

  <hlstd| \ check<textunderscore>board ><hlnum|0 ><hlstd|honey
  empty<textunderscore>cells ><hlopt|[]><hlendline|>

  We can test it now:

  <small|<hlkwa|let ><hlstd|w ><hlopt|= ><hlnum|800 ><hlkwa|and ><hlstd|h
  ><hlopt|= ><hlnum|800><hlendline|><next-line><hlkwa|let ><hlstd|ans0
  ><hlopt|= ><hlstd|find<textunderscore>to<textunderscore>eat
  test<textunderscore>task0><hlopt|.><hlstd|board<textunderscore>size
  test<textunderscore>task0><hlopt|.><hlstd|island<textunderscore>size<hlendline|><next-line>
  \ test<textunderscore>task0><hlopt|.><hlstd|num<textunderscore>islands
  test<textunderscore>task0><hlopt|.><hlstd|empty<textunderscore>cells><hlendline|><next-line><hlkwa|let
  ><hlstd|<textunderscore> ><hlopt|= ><hlstd|draw<textunderscore>to<textunderscore>screen
  <math|\<sim\>>w <math|\<sim\>>h<hlendline|><next-line>
  \ ><hlopt|(><hlstd|draw<textunderscore>honeycomb <math|\<sim\>>w
  <math|\<sim\>>h test<textunderscore>task0
  ><hlopt|(><hlkwc|List><hlopt|.><hlstd|hd ans0><hlopt|))><hlendline|>>

  But in a more complex case, finding all solutions takes too long:

  <small|<hlkwa|let ><hlstd|ans1 ><hlopt|=
  ><hlstd|find<textunderscore>to<textunderscore>eat
  test<textunderscore>task1><hlopt|.><hlstd|board<textunderscore>size
  test<textunderscore>task1><hlopt|.><hlstd|island<textunderscore>size<hlendline|><next-line>
  \ test<textunderscore>task1><hlopt|.><hlstd|num<textunderscore>islands
  test<textunderscore>task1><hlopt|.><hlstd|empty<textunderscore>cells><hlendline|><next-line><hlkwa|let
  ><hlstd|<textunderscore> ><hlopt|= ><hlstd|draw<textunderscore>to<textunderscore>screen
  <math|\<sim\>>w <math|\<sim\>>h<hlendline|><next-line>
  \ ><hlopt|(><hlstd|draw<textunderscore>honeycomb <math|\<sim\>>w
  <math|\<sim\>>h test<textunderscore>task1
  ><hlopt|(><hlkwc|List><hlopt|.><hlstd|hd ans1><hlopt|))><hlendline|>>

  (See <verbatim|Lec6.ml> for definitions of test cases.)

  <subsection|<new-page*>Optimizations for <em|Honey Islands>>

  <\itemize>
    <item>Main rule: <strong|fail> (drop solution candidates) <strong|as
    early as possible>.

    <\itemize>
      <item>Is the number of solutions generated by the more brute-force
      approach above <math|2<rsup|n>> for <math|n> honey cells, or smaller?
    </itemize>

    <item>We will guard both choices (eating a cell and keeping it in
    island).

    <item>We know exactly how much honey needs to be eaten.

    <item>Since the state has many fields, we define a record for it.
  </itemize>

  <hlkwa|type ><hlstd|state ><hlopt|= {><hlendline|><next-line><hlstd|
  \ been<textunderscore>size><hlopt|: ><hlkwb|int><hlopt|;><hlendline|Number
  of honey cells in current island.><next-line><hlstd|
  \ been<textunderscore>islands><hlopt|: ><hlkwb|int><hlopt|;><hlendline|Number
  of islands visited so far.><next-line><hlstd| \ unvisited><hlopt|:
  ><hlstd|cell list><hlopt|;><hlendline|Cells that need to be
  visited.><next-line><hlstd| \ visited><hlopt|:
  ><hlkwc|CellSet><hlopt|.><hlstd|t><hlopt|;><hlendline|Already
  visited.><next-line><hlstd| \ eaten><hlopt|: ><hlstd|cell
  list><hlopt|;><hlendline|Current solution candidate.><next-line><hlstd|
  \ more<textunderscore>to<textunderscore>eat><hlopt|:
  ><hlkwb|int><hlopt|;><hlendline|Remaining cells to eat for a complete
  solution.><next-line><hlopt|}><hlendline|>

  <new-page*>We define the basic operations on the state up-front. If you
  could keep them inlined, the code would remain more similar to the previous
  version.

  <hlkwa|let rec ><hlstd|visit<textunderscore>cell s
  ><hlopt|=><hlendline|><next-line><hlstd| \ ><hlkwa|match
  ><hlstd|s><hlopt|.><hlstd|unvisited ><hlkwa|with><hlendline|><next-line><hlstd|
  \ ><hlopt|\| [] -\<gtr\> ><hlkwd|None><hlendline|><next-line><hlstd|
  \ <hlopt|\|> c><hlopt|::><hlstd|remaining ><hlkwa|when
  ><hlkwc|CellSet><hlopt|.><hlstd|mem c s><hlopt|.><hlstd|visited
  ><hlopt|-\<gtr\>><hlendline|><next-line><hlstd|
  \ \ \ visit<textunderscore>cell ><hlopt|{><hlstd|s ><hlkwa|with
  ><hlstd|unvisited><hlopt|=><hlstd|remaining><hlopt|}><hlendline|><next-line><hlstd|
  \ <hlopt|\|> c><hlopt|::><hlstd|remaining ><hlcom|(* when c not visited
  *)><hlstd| ><hlopt|-\<gtr\>><hlendline|><next-line><hlstd|
  \ \ \ ><hlkwd|Some ><hlopt|(><hlstd|c><hlopt|, {><hlstd|s
  ><hlkwa|with><hlendline|><next-line><hlstd|
  \ \ \ \ \ unvisited><hlopt|=><hlstd|remaining><hlopt|;><hlendline|><next-line><hlstd|
  \ \ \ \ \ visited ><hlopt|= ><hlkwc|CellSet><hlopt|.><hlstd|add c
  s><hlopt|.><hlstd|visited><hlopt|})><hlendline|>

  <hlkwa|let ><hlstd|eat<textunderscore>cell c s
  ><hlopt|=><hlendline|><next-line><hlstd| \ ><hlopt|{><hlstd|s ><hlkwa|with
  ><hlstd|eaten ><hlopt|= ><hlstd|c><hlopt|::><hlstd|s><hlopt|.><hlstd|eaten><hlopt|;><hlendline|><next-line><hlstd|
  \ \ \ visited ><hlopt|= ><hlkwc|CellSet><hlopt|.><hlstd|add c
  s><hlopt|.><hlstd|visited><hlopt|;><hlendline|><next-line><hlstd|
  \ \ \ more<textunderscore>to<textunderscore>eat ><hlopt|=
  ><hlstd|s><hlopt|.><hlstd|more<textunderscore>to<textunderscore>eat
  ><hlopt|- ><hlnum|1><hlopt|}><hlendline|>

  <hlkwa|let ><hlstd|keep<textunderscore>cell c s
  ><hlopt|=><hlendline|Actually <verbatim|c> is not
  used...><next-line><hlstd| \ ><hlopt|{><hlstd|s ><hlkwa|with
  ><hlstd|been<textunderscore>size ><hlopt|=
  ><hlstd|s><hlopt|.><hlstd|been<textunderscore>size ><hlopt|+
  ><hlnum|1><hlopt|;><hlendline|><next-line><hlstd| \ \ \ visited ><hlopt|=
  ><hlkwc|CellSet><hlopt|.><hlstd|add c s><hlopt|.><hlstd|visited><hlopt|}><hlendline|>

  <hlkwa|let ><hlstd|fresh<textunderscore>island s ><hlopt|=><hlendline|We
  increase <verbatim|been_size> at the start of
  <verbatim|find_island>><next-line><hlstd| \ ><hlopt|{><hlstd|s ><hlkwa|with
  ><hlstd|been<textunderscore>size ><hlopt|=
  ><hlnum|0><hlopt|;><hlendline|rather than before calling
  it.><next-line><hlstd| \ \ \ been<textunderscore>islands ><hlopt|=
  ><hlstd|s><hlopt|.><hlstd|been<textunderscore>islands ><hlopt|+
  ><hlnum|1><hlopt|}><hlendline|>

  <hlkwa|let ><hlstd|init<textunderscore>state unvisited
  more<textunderscore>to<textunderscore>eat ><hlopt|=
  {><hlendline|><next-line><hlstd| \ been<textunderscore>size
  ><hlopt|=<htab|5mm> ><hlnum|0><hlopt|;><hlendline|><next-line><hlstd|
  \ been<textunderscore>islands ><hlopt|=
  ><hlnum|0><hlopt|;><hlendline|><next-line><hlstd|
  \ unvisited><hlopt|;><hlstd| visited ><hlopt|=
  ><hlkwc|CellSet><hlopt|.><hlstd|empty><hlopt|;><hlendline|><next-line><hlstd|
  \ eaten ><hlopt|= [];><hlstd| more<textunderscore>to<textunderscore>eat><hlopt|;><hlendline|><next-line><hlopt|}><hlendline|><next-line>

  <new-page*>We need a state to begin with:

  <hlkwa|let ><hlstd|init<textunderscore>state unvisited
  more<textunderscore>to<textunderscore>eat ><hlopt|=
  {><hlendline|><next-line><hlstd| \ been<textunderscore>size ><hlopt|=
  ><hlnum|0><hlopt|;><hlstd| been<textunderscore>islands ><hlopt|=
  ><hlnum|0><hlopt|;><hlendline|><next-line><hlstd|
  \ unvisited><hlopt|;><hlstd| visited ><hlopt|=
  ><hlkwc|CellSet><hlopt|.><hlstd|empty><hlopt|;><hlendline|><next-line><hlstd|
  \ eaten ><hlopt|= [];><hlstd| more<textunderscore>to<textunderscore>eat><hlopt|;><hlendline|><next-line><hlopt|}><hlendline|>

  The ``main loop'' only changes because of the different handling of state.

  <hlstd| \ ><hlkwa|let rec ><hlstd|find<textunderscore>board s
  ><hlopt|=><hlendline|><next-line><hlstd| \ \ \ ><hlkwa|match
  ><hlstd|visit<textunderscore>cell s ><hlkwa|with><hlendline|><next-line><hlstd|
  \ \ \ ><hlopt|\| ><hlkwd|None ><hlopt|-\<gtr\>><hlendline|><next-line><hlstd|
  \ \ \ \ \ ><hlkwa|if ><hlstd|s><hlopt|.><hlstd|been<textunderscore>islands
  ><hlopt|= ><hlstd|num<textunderscore>islands ><hlkwa|then
  ><hlopt|[><hlstd|eaten><hlopt|] ><hlkwa|else
  ><hlopt|[]><hlendline|><next-line><hlstd| \ \ \ ><hlopt|\| ><hlkwd|Some
  ><hlopt|(><hlstd|cell><hlopt|, ><hlstd|s><hlopt|)
  -\<gtr\>><hlendline|><next-line><hlstd|
  \ \ \ \ \ find<textunderscore>island cell
  ><hlopt|(><hlstd|fresh<textunderscore>island
  s><hlopt|)><hlendline|><next-line><hlstd|
  \ \ \ \ \ <hlopt|\|>><hlopt|-\<gtr\> (><hlkwa|fun ><hlstd|s
  ><hlopt|-\<gtr\>><hlendline|><next-line><hlstd| \ \ \ \ \ \ \ ><hlkwa|if
  ><hlstd|s><hlopt|.><hlstd|been<textunderscore>size ><hlopt|=
  ><hlstd|s><hlopt|.><hlstd|island<textunderscore>size<hlendline|><next-line>
  \ \ \ \ \ \ \ ><hlkwa|then ><hlstd|find<textunderscore>board
  s<hlendline|><next-line> \ \ \ \ \ \ \ ><hlkwa|else
  ><hlopt|[])><hlendline|>

  <new-page*>In the ``island loop'' we only try actions that make sense:

  <hlstd| \ ><hlkwa|and ><hlstd|find<textunderscore>island current s
  ><hlopt|=><hlendline|><next-line><hlstd| \ \ \ ><hlkwa|let ><hlstd|s
  ><hlopt|= ><hlstd|keep<textunderscore>cell current s
  ><hlkwa|in><hlendline|><next-line><hlstd| \ \ \ neighbors n
  empty<textunderscore>cells current<hlendline|><next-line>
  \ \ \ <hlopt|\|>><hlopt|\<gtr\> ><hlstd|concat<textunderscore>fold<hlendline|><next-line>
  \ \ \ \ \ \ \ ><hlopt|(><hlkwa|fun ><hlstd|neighbor s
  ><hlopt|-\<gtr\>><hlendline|><next-line><hlstd|
  \ \ \ \ \ \ \ \ \ ><hlkwa|if ><hlkwc|CellSet><hlopt|.><hlstd|mem neighbor
  s><hlopt|.><hlstd|visited ><hlkwa|then ><hlopt|[><hlstd|s><hlopt|]><hlendline|><next-line><hlstd|
  \ \ \ \ \ \ \ \ \ ><hlkwa|else><hlendline|><next-line><hlstd|
  \ \ \ \ \ \ \ \ \ \ \ ><hlkwa|let ><hlstd|choose<textunderscore>eat
  ><hlopt|=><hlendline|Guard against actions that would
  fail.><next-line><hlstd| \ \ \ \ \ \ \ \ \ \ \ \ \ ><hlkwa|if
  ><hlstd|s><hlopt|.><hlstd|more<textunderscore>to<textunderscore>eat
  ><hlopt|= ><hlnum|0 ><hlkwa|then ><hlopt|[]><hlendline|><next-line><hlstd|
  \ \ \ \ \ \ \ \ \ \ \ \ \ ><hlkwa|else ><hlopt|[><hlstd|eat<textunderscore>cell
  neighbor s><hlopt|]><hlendline|><next-line><hlstd|
  \ \ \ \ \ \ \ \ \ \ \ ><hlkwa|and ><hlstd|choose<textunderscore>keep
  ><hlopt|=><hlendline|><next-line><hlstd|
  \ \ \ \ \ \ \ \ \ \ \ \ \ ><hlkwa|if ><hlstd|s><hlopt|.><hlstd|been<textunderscore>size
  ><hlopt|\<gtr\>= ><hlstd|island<textunderscore>size ><hlkwa|then
  ><hlopt|[]><hlendline|><next-line><hlstd|
  \ \ \ \ \ \ \ \ \ \ \ \ \ ><hlkwa|else ><hlstd|find<textunderscore>island
  neighbor s ><hlkwa|in><hlendline|><next-line><hlstd|
  \ \ \ \ \ \ \ \ \ \ \ choose<textunderscore>eat @
  choose<textunderscore>keep><hlopt|)><hlendline|><next-line><hlstd|
  \ \ \ \ \ \ \ s ><hlkwa|in><hlendline|>

  <new-page*>Finally, we compute the required length of <verbatim|eaten> and
  start searching.

  <hlstd| \ ><hlkwa|let ><hlstd|cells<textunderscore>to<textunderscore>eat
  ><hlopt|=><hlendline|><next-line><hlstd|
  \ \ \ ><hlkwc|List><hlopt|.><hlstd|length honey ><hlopt|-
  ><hlstd|island<textunderscore>size ><hlopt|*
  ><hlstd|num<textunderscore>islands ><hlkwa|in><hlendline|><next-line><hlstd|
  \ find<textunderscore>board ><hlopt|(><hlstd|init<textunderscore>state
  honey cells<textunderscore>to<textunderscore>eat><hlopt|)><hlendline|>

  <section|<new-page*>Constraint-based puzzles>

  <\itemize>
    <item>Puzzles can be presented by providing the general form of
    solutions, and additional requirements that the solutions must meet.

    <item>For many puzzles, the general form of solutions for a given problem
    can be decomposed into a fixed number of variables.

    <\itemize>
      <item>A domain of a variable is a set of possible values the variable
      can have in any solution.

      <item>In the <em|Honey Islands> puzzle, the variables correspond to
      cells and the domains are <math|<around*|{|Honey,Empty|}>> (either a
      cell has honey, or is empty -- without distinguishing ``initially
      empty'' and ``eaten'').

      <item>In the <em|Honey Islands> puzzle, the constraints are: a
      selection of cells that have to be empty, the number and size of
      connected components of cells that are not empty. The neighborhood
      graph -- which cell-variable is connected with which -- is part of the
      constraints.
    </itemize>

    <new-page*><item>There is a general and often efficient scheme of solving
    constraint-based problems. <strong|Finite Domain Constraint Programming>
    algorithm:

    <\enumerate>
      <item>With each variable, associate a set of values, initially equal to
      the domain of the variable. The singleton containing the association is
      the initial set of partial solutions.

      <item>While there is a solution with more than one value associated to
      some variable in the set of partial solutions, select it and:

      <\enumerate>
        <item>If there is a possible value for some variable, such that for
        all possible assignments of values to other variables, the
        requirements fail, remove this value from the set associated with
        this variable.

        <item>If there is a variable with empty set of possible values
        associated to it, remove the solution from the set of partial
        solutions.

        <item>Select the variable with the smallest non-singleton set
        associated with it (i.e. the smallest greater than 2 size). Split
        that set into similarly-sized parts. Replace the solution with two
        solutions where the variable is associated with either of the two
        parts.
      </enumerate>

      <item>The final solutions are built from partial solutions by assigning
      to a variable the single possible value associated with it.
    </enumerate>

    <new-page*><item>This general algorithm can be simplified. For example,
    in step (2.c), instead of splitting into two equal-sized parts, we can
    partition into a singleton and remainder, or partition ``all the way''
    into several singletons.

    <item>The above definition of <em|finite domain constraint solving>
    algorithm is sketchy. Questions?

    <item>We will not discuss a complete implementation example, but you can
    exploit ideas from the algorithm in your homework.
  </itemize>
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
    <associate|auto-10|<tuple|5.2|25>>
    <associate|auto-11|<tuple|5.2.1|27>>
    <associate|auto-12|<tuple|5.2.2|29>>
    <associate|auto-13|<tuple|5.2.3|30>>
    <associate|auto-14|<tuple|5.3|32>>
    <associate|auto-15|<tuple|6|33>>
    <associate|auto-16|<tuple|6.1|38>>
    <associate|auto-17|<tuple|6.2|41>>
    <associate|auto-18|<tuple|6.3|43>>
    <associate|auto-19|<tuple|7|44>>
    <associate|auto-2|<tuple|2|4>>
    <associate|auto-20|<tuple|7.1|45>>
    <associate|auto-21|<tuple|7.1.1|46>>
    <associate|auto-22|<tuple|7.1.2|47>>
    <associate|auto-23|<tuple|7.1.3|48>>
    <associate|auto-24|<tuple|7.2|52>>
    <associate|auto-25|<tuple|7.3|55>>
    <associate|auto-26|<tuple|7.4|56>>
    <associate|auto-27|<tuple|7.5|60>>
    <associate|auto-28|<tuple|8|?>>
    <associate|auto-3|<tuple|2.1|5>>
    <associate|auto-4|<tuple|2.2|8>>
    <associate|auto-5|<tuple|3|11>>
    <associate|auto-6|<tuple|3.1|13>>
    <associate|auto-7|<tuple|4|18>>
    <associate|auto-8|<tuple|5|21>>
    <associate|auto-9|<tuple|5.1|23>>
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
      <vspace*|1fn><with|font-series|<quote|bold>|math-font-series|<quote|bold>|Plan>
      <datoms|<macro|x|<repeat|<arg|x>|<with|font-series|medium|<with|font-size|1|<space|0.2fn>.<space|0.2fn>>>>>|<htab|5mm>>
      <no-break><pageref|auto-1><vspace|0.5fn>

      <vspace*|1fn><with|font-series|<quote|bold>|math-font-series|<quote|bold>|<new-page*>Basic
      generic list operations> <datoms|<macro|x|<repeat|<arg|x>|<with|font-series|medium|<with|font-size|1|<space|0.2fn>.<space|0.2fn>>>>>|<htab|5mm>>
      <no-break><pageref|auto-2><vspace|0.5fn>

      <with|par-left|<quote|1.5fn>|<new-page*>Always extract common patterns
      <datoms|<macro|x|<repeat|<arg|x>|<with|font-series|medium|<with|font-size|1|<space|0.2fn>.<space|0.2fn>>>>>|<htab|5mm>>
      <no-break><pageref|auto-3>>

      <with|par-left|<quote|1.5fn>|<new-page*>Can we make
      <with|font-family|<quote|tt>|language|<quote|verbatim>|fold>
      tail-recursive? <datoms|<macro|x|<repeat|<arg|x>|<with|font-series|medium|<with|font-size|1|<space|0.2fn>.<space|0.2fn>>>>>|<htab|5mm>>
      <no-break><pageref|auto-4>>

      <vspace*|1fn><with|font-series|<quote|bold>|math-font-series|<quote|bold>|<new-page*><with|font-family|<quote|tt>|language|<quote|verbatim>|map>
      and <with|font-family|<quote|tt>|language|<quote|verbatim>|fold> for
      trees and other structures> <datoms|<macro|x|<repeat|<arg|x>|<with|font-series|medium|<with|font-size|1|<space|0.2fn>.<space|0.2fn>>>>>|<htab|5mm>>
      <no-break><pageref|auto-5><vspace|0.5fn>

      <with|par-left|<quote|1.5fn>|<new-page*><with|font-family|<quote|tt>|language|<quote|verbatim>|map>
      and <with|font-family|<quote|tt>|language|<quote|verbatim>|fold> for
      more complex structures <datoms|<macro|x|<repeat|<arg|x>|<with|font-series|medium|<with|font-size|1|<space|0.2fn>.<space|0.2fn>>>>>|<htab|5mm>>
      <no-break><pageref|auto-6>>

      <vspace*|1fn><with|font-series|<quote|bold>|math-font-series|<quote|bold>|<new-page*>Point-free
      Programming> <datoms|<macro|x|<repeat|<arg|x>|<with|font-series|medium|<with|font-size|1|<space|0.2fn>.<space|0.2fn>>>>>|<htab|5mm>>
      <no-break><pageref|auto-7><vspace|0.5fn>

      <vspace*|1fn><with|font-series|<quote|bold>|math-font-series|<quote|bold>|<new-page*>Reductions.
      More higher-order/list functions> <datoms|<macro|x|<repeat|<arg|x>|<with|font-series|medium|<with|font-size|1|<space|0.2fn>.<space|0.2fn>>>>>|<htab|5mm>>
      <no-break><pageref|auto-8><vspace|0.5fn>

      <with|par-left|<quote|1.5fn>|<new-page*>List manipulation: All
      subsequences of a list <datoms|<macro|x|<repeat|<arg|x>|<with|font-series|medium|<with|font-size|1|<space|0.2fn>.<space|0.2fn>>>>>|<htab|5mm>>
      <no-break><pageref|auto-9>>

      <with|par-left|<quote|1.5fn>|<new-page*>By key:
      <with|font-family|<quote|tt>|language|<quote|verbatim>|group_by> and
      <with|font-family|<quote|tt>|language|<quote|verbatim>|map_reduce>
      <datoms|<macro|x|<repeat|<arg|x>|<with|font-series|medium|<with|font-size|1|<space|0.2fn>.<space|0.2fn>>>>>|<htab|5mm>>
      <no-break><pageref|auto-10>>

      <with|par-left|<quote|3fn>|<new-page*><with|font-family|<quote|tt>|language|<quote|verbatim>|map_reduce>/<with|font-family|<quote|tt>|language|<quote|verbatim>|concat_reduce>
      examples <datoms|<macro|x|<repeat|<arg|x>|<with|font-series|medium|<with|font-size|1|<space|0.2fn>.<space|0.2fn>>>>>|<htab|5mm>>
      <no-break><pageref|auto-11>>

      <with|par-left|<quote|3fn>|<new-page*>Tail-recursive variants
      <datoms|<macro|x|<repeat|<arg|x>|<with|font-series|medium|<with|font-size|1|<space|0.2fn>.<space|0.2fn>>>>>|<htab|5mm>>
      <no-break><pageref|auto-12>>

      <with|par-left|<quote|3fn>|<new-page*>Helper functions for inverted
      index demonstration <datoms|<macro|x|<repeat|<arg|x>|<with|font-series|medium|<with|font-size|1|<space|0.2fn>.<space|0.2fn>>>>>|<htab|5mm>>
      <no-break><pageref|auto-13>>

      <with|par-left|<quote|1.5fn>|<new-page*>Higher-order functions for the
      <with|font-family|<quote|tt>|language|<quote|verbatim>|option> type
      <datoms|<macro|x|<repeat|<arg|x>|<with|font-series|medium|<with|font-size|1|<space|0.2fn>.<space|0.2fn>>>>>|<htab|5mm>>
      <no-break><pageref|auto-14>>

      <vspace*|1fn><with|font-series|<quote|bold>|math-font-series|<quote|bold>|<new-page*>The
      Countdown Problem Puzzle> <datoms|<macro|x|<repeat|<arg|x>|<with|font-series|medium|<with|font-size|1|<space|0.2fn>.<space|0.2fn>>>>>|<htab|5mm>>
      <no-break><pageref|auto-15><vspace|0.5fn>

      <with|par-left|<quote|1.5fn>|<new-page*>Brute force solution
      <datoms|<macro|x|<repeat|<arg|x>|<with|font-series|medium|<with|font-size|1|<space|0.2fn>.<space|0.2fn>>>>>|<htab|5mm>>
      <no-break><pageref|auto-16>>

      <with|par-left|<quote|1.5fn>|<new-page*>Fuse the generate phase with
      the test phase <datoms|<macro|x|<repeat|<arg|x>|<with|font-series|medium|<with|font-size|1|<space|0.2fn>.<space|0.2fn>>>>>|<htab|5mm>>
      <no-break><pageref|auto-17>>

      <with|par-left|<quote|1.5fn>|<new-page*>Eliminate symmetric cases
      <datoms|<macro|x|<repeat|<arg|x>|<with|font-series|medium|<with|font-size|1|<space|0.2fn>.<space|0.2fn>>>>>|<htab|5mm>>
      <no-break><pageref|auto-18>>

      <vspace*|1fn><with|font-series|<quote|bold>|math-font-series|<quote|bold>|<new-page*>The
      Honey Islands Puzzle> <datoms|<macro|x|<repeat|<arg|x>|<with|font-series|medium|<with|font-size|1|<space|0.2fn>.<space|0.2fn>>>>>|<htab|5mm>>
      <no-break><pageref|auto-19><vspace|0.5fn>

      <with|par-left|<quote|1.5fn>|<new-page*>Representing the honeycomb
      <datoms|<macro|x|<repeat|<arg|x>|<with|font-series|medium|<with|font-size|1|<space|0.2fn>.<space|0.2fn>>>>>|<htab|5mm>>
      <no-break><pageref|auto-20>>

      <with|par-left|<quote|3fn>|<new-page*>Neighborhood
      <datoms|<macro|x|<repeat|<arg|x>|<with|font-series|medium|<with|font-size|1|<space|0.2fn>.<space|0.2fn>>>>>|<htab|5mm>>
      <no-break><pageref|auto-21>>

      <with|par-left|<quote|3fn>|<new-page*>Building the honeycomb
      <datoms|<macro|x|<repeat|<arg|x>|<with|font-series|medium|<with|font-size|1|<space|0.2fn>.<space|0.2fn>>>>>|<htab|5mm>>
      <no-break><pageref|auto-22>>

      <with|par-left|<quote|3fn>|<new-page*>Drawing honeycombs
      <datoms|<macro|x|<repeat|<arg|x>|<with|font-series|medium|<with|font-size|1|<space|0.2fn>.<space|0.2fn>>>>>|<htab|5mm>>
      <no-break><pageref|auto-23>>

      <with|par-left|<quote|1.5fn>|<new-page*>Testing correctness of a
      solution <datoms|<macro|x|<repeat|<arg|x>|<with|font-series|medium|<with|font-size|1|<space|0.2fn>.<space|0.2fn>>>>>|<htab|5mm>>
      <no-break><pageref|auto-24>>

      <with|par-left|<quote|1.5fn>|<new-page*>Interlude: multiple results per
      step <datoms|<macro|x|<repeat|<arg|x>|<with|font-series|medium|<with|font-size|1|<space|0.2fn>.<space|0.2fn>>>>>|<htab|5mm>>
      <no-break><pageref|auto-25>>

      <with|par-left|<quote|1.5fn>|<new-page*>Generating a solution
      <datoms|<macro|x|<repeat|<arg|x>|<with|font-series|medium|<with|font-size|1|<space|0.2fn>.<space|0.2fn>>>>>|<htab|5mm>>
      <no-break><pageref|auto-26>>

      <with|par-left|<quote|1.5fn>|<new-page*>Optimizations for
      <with|font-shape|<quote|italic>|Honey Islands>
      <datoms|<macro|x|<repeat|<arg|x>|<with|font-series|medium|<with|font-size|1|<space|0.2fn>.<space|0.2fn>>>>>|<htab|5mm>>
      <no-break><pageref|auto-27>>
    </associate>
  </collection>
</auxiliary>