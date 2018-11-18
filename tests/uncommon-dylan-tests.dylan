Module: uncommon-dylan-tests
Copyright: See LICENSE in this distribution for details.

// TODO: TESTS!

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

run-test-application(uncommon-dylan-tests);
