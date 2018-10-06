Module: uncommon-dylan-tests
Copyright: See LICENSE in this distribution for details.

define test test-count ()
  let seq = #[1, 2, 2, 3, 3, 3];
  assert-equal(0, count(#[], curry(\=, #f)));
  assert-equal(0, count(seq, curry(\=, #f)));
  assert-equal(1, count(seq, curry(\=, 1)));
  assert-equal(2, count(seq, curry(\=, 2)));
  assert-equal(3, count(seq, curry(\=, 3)));
  assert-equal(2, count(seq, curry(\=, 3), limit: 2));
end;

define suite uncommon-dylan-tests ()
  test test-count;
end;

define method main () => ()
  let filename = locator-name(as(<file-locator>, application-name()));
  if (split(filename, ".")[0] = "uncommon-dylan-tests")
    run-test-application(uncommon-dylan-tests);
  end;
  // temp bug work-around
  force-output(*standard-output*);
end method main;

main();
