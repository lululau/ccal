#!/usr/bin/perl -Iblib/lib -Iblib/arch -I../blib/lib -I../blib/arch
# 
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl load.t'

# Test file created outside of h2xs framework.
# Run this like so: `perl load.t'
#   Ye Wenbin <wenbinye@gmail.com>     2008/01/01 03:49:03

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More qw( no_plan );
BEGIN {
    use_ok('Calendar');
    use_ok('Calendar::Gregorian');
    use_ok('Calendar::Julian');
    use_ok('Calendar::China');
}
#########################

# Insert your test code below, the Test::More module is used here so read
# its man page ( perldoc Test::More ) for help writing this test script.


