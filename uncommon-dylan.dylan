Module:   uncommon-dylan
Synopsis: Some definitions of general use that could be considered for
          inclusion in common-dylan if they stand the test of time.
Author:   Carl Gay


// ---TODO: Add an equal? method, that is like = but does case insensitive
//          string comparison.  Need string-equal? first.

// ----------------------------------------------------------------------
// bind introduces new bindings a la "let", but also introduces a new
// block to limit the variables' scope.
//
// bind (x = 1, y :: <string> = "y")
//   x + y
// end
//
define macro bind
    { bind (?bindings) ?:body end }
 => { begin
        ?bindings
        ;
        ?body
      end }
bindings:
    { } => { }
    { ?binding, ... } => { ?binding; ... }
binding:
    { ?var:variable = ?val:expression }
 => { let ?var = ?val }
end;

// ----------------------------------------------------------------------
// iff(test, true-part)
// iff(test, true-part, false-part)
//
define macro iff
    { iff(?test:expression, ?true:expression, ?false:expression) }
 => { if (?test) ?true else ?false end }
  { iff(?test:expression, ?true:expression) }
    => { if (?test) ?true end }
end;


// ----------------------------------------------------------------------
define macro with-restart
  { with-restart (?condition:expression, #rest ?initargs:*)
      ?:body
    end }
    => { block ()
           ?body
         exception (?condition, init-arguments: vector(?initargs))
           values(#f, #t)
         end }
end macro with-restart;

// with-simple-restart("Retry opening file") ... end
//
define macro with-simple-restart
  { with-simple-restart (?format-string:expression, ?format-args:*)
      ?:body
    end }
    => { with-restart (<simple-restart>,
                       format-string: ?format-string,
                       format-arguments: vector(?format-args))
           ?body
         end }
end macro with-simple-restart;


// ----------------------------------------------------------------------
// define class <my-class> (<singleton-object>) ... end
//
define open abstract class <singleton-object> (<object>)
end;

// Maps classes to their singleton instances.
define constant $singletons :: <table> = make(<table>);

define method make
    (class :: subclass(<singleton-object>), #rest args, #key)
 => (object :: <singleton-object>)
  element($singletons, class, default: #f)
  | begin
      $singletons[class] := next-method()
    end
end;


// ----------------------------------------------------------------------
define macro inc!
  { inc! (?place:expression, ?dx:expression) }
    => { ?place := ?place + ?dx; }
  { inc! (?place:expression) }
    => { ?place := ?place + 1; }
end macro inc!;

define macro dec!
  { dec! (?place:expression, ?dx:expression) }
    => { ?place := ?place - ?dx; }
  { dec! (?place:expression) }
    => { ?place := ?place - 1; }
end macro dec!;

define macro wrapping-inc!
  { wrapping-inc! (?place:expression) }
    => { let n :: <integer> = ?place;
         ?place := if (n == $maximum-integer)
                     0
                   else
                     n + 1
                   end; }
end;


// ----------------------------------------------------------------------
// Convert a string to a floating point number.
// This version is from Chris Double's dylanlibs project, and
// seems to be the most precise of the three.  I renamed it
// from formatted-string-to-float to string-to-float.  I added
// min(..., 7) in a couple places as a quick kludge to keep from
// getting integer overflow errors.  Should figure out the right
// way...  -cgay
//
define method string-to-float(s :: <string>) => (f :: <float>)
  local method is-digit?(ch :: <character>) => (b :: <boolean>)
    let v = as(<integer>, ch);
    v >= as(<integer>, '0') & v <= as(<integer>, '9');
  end method;
  let lhs = make(<stretchy-vector>);
  let rhs = make(<stretchy-vector>);
  let state = #"start";
  let sign = 1;

  local method process-char(ch :: <character>)
    select (state)
      #"start" =>
        select (ch)
          '-' =>
            begin
              sign := -1;
              state := #"lhs";
            end;
          '+' =>
            begin
              sign := 1;
              state := #"lhs";
            end;
          '.' =>
            begin
              lhs := add!(lhs, '0');
              state := #"rhs";
            end;
          otherwise =>
            begin
              state := #"lhs";
              process-char(ch);
            end;
        end select;
      #"lhs" =>
        case
          is-digit?(ch) => lhs := add!(lhs, ch);
          ch == '.' => state := #"rhs";
          otherwise => error("Invalid floating point value.");
        end case;
      #"rhs" =>
        case
          is-digit?(ch) => rhs := add!(rhs, ch);
          otherwise => error("Invalid floating point value.");
        end case;
      otherwise => error("Invalid state while parsing floating point.");
    end select;
  end method;

  for (ch in s)
    process-char(ch);
  end for;

  let lhs = as(<string>, lhs);
  let rhs = if (empty?(rhs)) "0" else as(<string>, rhs) end;
  (string-to-integer(lhs) * sign)
   + as(<double-float>, string-to-integer(rhs) * sign)
     / (10 ^ min(rhs.size, 7));
end method string-to-float;

// Convert a floating point to a string without the Dylan specific formatting.
// Prints to the given number of decimal places.
// Written by Chris Double, as part of dylanlibs.
//
define method float-to-formatted-string
    (value :: <float>, #key decimal-places)
 => (s :: <string>)
  let value = iff(decimal-places,
                  as(<double-float>, truncate(value * 10 ^ min(decimal-places, 7))) / 10d0 ^ decimal-places,
                  value);
  let s = float-to-string(value);
  let dp = subsequence-position(s, ".");
  let tp = subsequence-position(s, "d") | subsequence-position(s, "s") | s.size;
  let lhs = copy-sequence(s, end: dp);
  let rhs = copy-sequence(s, start: dp + 1, end: tp);
  let shift = if (tp = s.size) 0  else string-to-integer(s, start: tp + 1) end;
  let result = "";
  let temp = concatenate(lhs, rhs);
  let d = lhs.size - 1 + shift;
  if (shift < 0)
    for (n from 0 below abs(shift))
      temp := concatenate("0", temp);
    end for;
    d := 0;
  elseif (shift > 0)
    for (n from 0 below shift)
      temp := concatenate(temp, "0");
    end for;
    d := temp.size;
  end if;

  let tsize = temp.size;
  concatenate(copy-sequence(temp, start: 0, end: min(d + 1, tsize)),
              iff(d = tsize, "", "."),
              iff(d = tsize,
                  "",
                  copy-sequence(temp,
                                start: d + 1,
                                end: iff(decimal-places,
                                         min(d + 1 + decimal-places, tsize),
                                         tsize))));
end method float-to-formatted-string;


// TODO:
//   as(<integer>, "123")
//   as(<single-float>, "123.0")
//   as(<double-float>, "123.0")
//   The equivalent works in Python, so why not Dylan?  The options
//   in string-to-integer, for example, are just difficult to program
//   around when you want to know if the string you have your hands on
//   can be converted to an integer.  Skipping initial whitespace feels
//   like featuritis.  I'm guessing it came from CL.
//
//   Semi-related, I would like all such built-in converters to raise
//   <value-error> (better name?) instead of just <error>.


// ----------------------------------------------------------------------
// For removing certain keyword/value pairs from argument lists before
// passing them along with apply or next-method.
//
define method remove-keys
    (arglist :: <sequence>, #rest keys-to-remove) => (x :: <list>)
  let result :: <list> = #();
  let last-pair = #f;
  for (i from 0 below arglist.size by 2)
    let arg = arglist[i];
    if (~member?(arg, keys-to-remove))
      if (last-pair)
        let key-val = list(arg, arglist[i + 1]);
        tail(last-pair) := key-val;
        last-pair := tail(key-val);
      else
        result := list(arg, arglist[i + 1]);
        last-pair := tail(result);
      end;
    end;
  end;
  result
end method remove-keys;


// ----------------------------------------------------------------------
// Seems like this should be in the core language.
//
define sideways method as
    (type == <integer>, value :: <string>) => (i :: <integer>)
  string-to-integer(value)
end;

// ----------------------------------------------------------------------
define macro ignore-errors
    { ignore-errors(?v:variable, ?body:expression) }
 => { block () ?body exception (?v) #f end }

    { ignore-errors(?body:expression) }
 => { block () ?body exception (e :: <error>) #f end }
end;


// ----------------------------------------------------------------------
// Collections

// A complement to key-sequence
define method value-sequence
    (collection :: <explicit-key-collection>) => (seq :: <sequence>)
  let v :: <vector> = make(<vector>, size: collection.size);
  for (val keyed-by key in collection,
       i from 0)
    v[i] := val;
  end;
  v
end;

// copy-table?

// Count the number of occurrences of item in collection, as determined
// by the predicate.  'limit' is an efficiency hack: stop counting when limit
// is reached, the theory being that it's common to want to know if there's
// more than one of the given item.
define open generic count
    (collection :: <collection>, predicate :: <function>, #key limit)
 => (count :: <integer>);

define method count
    (collection :: <collection>, predicate :: <function>,
     #key limit :: false-or(<integer>))
 => (count :: <integer>)
  let count :: <integer> = 0;
  for (item in collection,
       while: ~limit | count < limit)
    if (predicate(item))
      inc!(count)
    end;
  end;
  count
end method count;

//// Tries who's keys are strings

// This should be fixed not to be specifically for strings.

define class <string-trie> (<object>)
  constant slot trie-children :: <string-table>,
    init-function: curry(make, <string-table>);
  slot trie-object :: <object>,
    required-init-keyword: object:;
end;

define class <trie-error> (<format-string-condition>, <error>)
end;

define method add-object
    (trie :: <string-trie>, path :: <sequence>, object :: <object>,
     #key replace?)
 => ()
  local method real-add (trie, rest-path)
          if (rest-path.size = 0)
            if (trie.trie-object = #f | replace?)
              trie.trie-object := object;
            else
              signal(make(<trie-error>,
                          format-string: "Trie already contains an object for the "
                                         "given path (%=).",
                          format-arguments: list(path)));
            end if;
          else
            let first-path = rest-path[0];
            let other-path = copy-sequence(rest-path, start: 1);
            let children = trie-children(trie);
            let child = element(children, first-path, default: #f);
            unless (child)
              let node = make(<string-trie>, object: #f);
              children[first-path] := node;
              child := node;
            end;
            real-add(child, other-path)
          end;
        end method real-add;
  real-add(trie, path)
end method add-object;

define method remove-object
    (trie :: <string-trie>, path :: <sequence>)
 => ()
  let nodes = #[];
  let node = reduce(method (a, b)
      nodes := add!(nodes, a);
      a.trie-children[b]
    end, trie, path);
  let object = node.trie-object;
  node.trie-object := #f;
  block (stop)
    for (node in reverse(nodes), child in reverse(path))
      if (size(node.trie-children[child].trie-children) = 0 & ~node.trie-object)
        remove-key!(node.trie-children, child);
      else
        stop()
      end if;
    end for;
  end;
  object
end method remove-object;

// Find the object with the longest path, if any.
// 2nd return value is the path that matched.
// 3rd return value is the part of the path that
// came after where the object matched.
//
define method find-object
    (trie :: <string-trie>, path :: <sequence>)
 => (object :: <object>, rest-path :: <sequence>, prefix-path :: <sequence>)
  local method real-find (trie, path, object, prefix, rest)
          if (empty?(path))
            values(object, rest, reverse(prefix))
          else
            let child = element(trie.trie-children, head(path), default: #f);
            if (child)
              real-find(child, tail(path), child.trie-object | object,
                        pair(head(path), prefix),
                        iff(child.trie-object, tail(path), rest));
            else
              values(object, rest, reverse(prefix));
            end
          end
        end method real-find;
  real-find(trie, as(<list>, path), trie.trie-object, #(), #());
end method find-object;


//// Type defs

define constant <nonnegative-integer> = limited(<integer>, min: 0);
define constant <positive-integer> = limited(<integer>, min: 1);


//// Collection functions

// TODO: slice! and slice!-setter ?

define method slice
    (seq :: <sequence>, bpos :: <integer>, epos :: false-or(<integer>))
 => (slice :: <sequence>)
  let len :: <integer> = seq.size;
  let _bpos = max(0, iff(bpos < 0, len + bpos, bpos));
  let _epos = iff(epos,
                  min(len, iff(epos < 0, len + epos, epos)),
                  len);
  copy-sequence(seq, start: _bpos, end: _epos)
end;

// Allow negative indexes.
// The main reason this is worth having around is for when the expression
// for getting the sequence is long.  It's not useful for x because
// x[x.size - 1] is short, but for my-object.the-foo-sequence it starts
// to look pretty bad.
//
define method elt
    (seq :: <sequence>, index :: <integer>) => (element :: <object>)
  seq[iff(index < 0, seq.size + index, index)]
end;


