Module:   dylan-user
Synopsis: Some definitions of general use that could be considered for
          inclusion in common-dylan if they stand the test of time.
Copyright: See LICENSE in this distribution for details.

define library uncommon-dylan
  use collection-extensions,
    import: { collection-utilities };
  use common-dylan;
  use io,
    import: { streams };
  export
    uncommon-dylan,
    uncommon-utils;
end;


// A version of common-dylan that has shorter names for some common
// (and core) definitions, without loss of readability in my
// opinion. This is not a comprehensive list; I'll add more as I come
// across them.
define module uncommon-dylan
  // TODO: include some other frequently used basic items, like
  //       format-out and format-err, directly in uncommon-dylan?
  use common-dylan,
    rename: { <object>    => <any>,
              <boolean>   => <bool>,
              <character> => <char>,
              <function>  => <func>,
              <integer>   => <int>,
              <sequence>  => <seq>,
              <string>    => <str>,
              <table>     => <map>,
              <string-table> => <str-map>,
              <case-insensitive-string-table> => <istr-map>,

              concatenate   => concat,
              copy-sequence => copy-seq }, // See slice() in uncommon-utils
    export: all;
end module uncommon-dylan;

define module uncommon-utils
  use collection-utilities,
    export: all;
  use uncommon-dylan;
  use streams,
    import: { write,
              with-output-to-string };

  export
    bind,              // like LET* in Common Lisp
    iff,               // more concise IF, for simple cases
    <singleton-object>,
    inc!,              // like ++foo (just call it ++?)
    dec!,              // like --foo (just call it --?)
    string-to-float,
    // Wasn't sure whether to include this, since FunDev already has
    // float-to-string, but decided to keep it with a different name.
    // --cgay
    float-to-formatted-string,
    remove-keys,        // For removing keywords from #rest arglists.
    ignore-errors,
    value-sequence,
    count,

    wrapping-inc!,

    <str-trie>,
    find-object,
    add-object,
    remove-object,
    trie-children,
    trie-object,
    <trie-error>,

    <int*>, <int+>,

    slice,
    elt,

    err,
    with-restart,
    with-simple-restart;
end module uncommon-utils;
