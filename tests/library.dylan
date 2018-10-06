Module: dylan-user
Copyright: See LICENSE in this distribution for details.

define library uncommon-dylan-tests
  use io;
  use system;
  use testworks;
  use uncommon-dylan;

  export uncommon-dylan-tests;
end;

define module uncommon-dylan-tests
  use locators, import: { locator-name, <file-locator> };
  use standard-io, import: { *standard-output* };
  use streams, import: { force-output };
  use testworks;
  use uncommon-dylan;
  use uncommon-utils;

  export uncommon-dylan-tests;
end;
