#!/usr/bin/perl -w -I../blib/arch -I../blib/lib -Iblib/arch -Iblib/lib
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Calendar.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More 'no_plan';
BEGIN {
    use_ok('Calendar');
}

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

my $ok = 1;                     # global variable for valid

#{{{  Test module loading and valid for one date
my $date;
ok(ref($date=Calendar->new_from_Gregorian(732312)) eq "Calendar::Gregorian",
   "load gregorian calendar");
ok($date->day==1 && $date->month==1 && $date->year==2006,
   "valid gregorian date");

ok(ref($date->convert_to_Julian) eq "Calendar::Julian",
   "load julian calendar");
ok($date->day==19&&$date->month==12&&$date->year==2005,
   "valid julian date");

ok(ref($date->convert_to_China) eq "Calendar::China",
   "load chinese calendar");
ok($date->cycle==78&&$date->year==22&&$date->month==12&&$date->day==2,
   "valid chinese date");
#}}}

#{{{  Test function constructor: from absolute and from [month, day,year]
#     should equal in absolute date
my $skip_convertion = 0;
unless ( $skip_convertion ) {
    diag("Test convetion for twenty years. This may take a long time...");
    my $start_year = 1990;
    my $days = 365*20;
    ok(valid_convert("Gregorian", [1, 1, $start_year], $days), "gregorian finished.");
    ok(valid_convert("Julian", [1, 1, $start_year], $days), "julian finished");
    ok(valid_convert("China", [1, 1, $start_year], $days), "china finished");
}
#}}}

#{{{  Test misc function
# is_leap_year
my $skip_leap_test = 0;
unless ( $skip_leap_test ) {
    $ok = 1;
    foreach ( 1..2000 ) {
        my $date = Calendar->new_from_Gregorian(1, 1, $_);
        if ($date->is_leap_year xor gregorian_is_leap_year($_)) {
            print $date, "\n";
            $ok = 0;
        }
    }
    ok($ok, "gregorian leap predicate");

    $ok = 1;
    foreach ( 1..2000 ) {
        my $date = Calendar->new_from_Julian(1, 1, $_);
        $ok = 0 if ($date->is_leap_year xor julian_is_leap_year($_));
    }
    ok($ok, "julian leap predicate");
}

# day_of_year
foreach my $year ( 2000, 2001 ) {
    my $date = Calendar->new_from_Gregorian(1, 1, $year);
    my $last = ($date->is_leap_year ? 366 : 365);
    require Time::Local;
    my $time = Time::Local::timelocal(0, 0, 0, 1, 0, $year-1900);
    foreach ( 1..$last ) {
        my @time = localtime($time+($_-1)*86400);
        # printf ("%d => %d\n", $date->day_of_year, $time[7]);
        $ok = 0 unless $date->day_of_year == $time[7]+1;
        $date = $date + 1;
    }
}
ok($ok, "Gregorian day of year");

foreach my $year ( 2000, 2001 ) {
    my $date = Calendar->new_from_Julian(1, 1, $year);
    my $last = ($date->is_leap_year ? 366 : 365);
    foreach ( 1..$last ) {
        # printf ("%d => %d\n", $date->day_of_year, $_);
        $ok = 0 unless $date->day_of_year == $_;
        $date = $date + 1;
    }
}
ok($ok, "Julian day of year");

# last_day_of_month
my @month_days = (31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31);

$ok = 1;
foreach my $year ( 2000, 2001 ) {
    my $date = Calendar->new_from_Gregorian(1, 1, $year);
    my @days = @month_days;
    $days[1]++ if $date->is_leap_year;
    foreach my $month (1..12) {
        my $date = Calendar->new_from_Gregorian($month, int(rand(27)+1), $year);
        $ok = 0 unless $date->last_day_of_month == $days[$date->month-1];
    }
}
ok($ok, "Gregorian last day of month");

$ok = 1;
foreach my $year ( 2000, 2001 ) {
    my $date = Calendar->new_from_Julian(1, 1, $year);
    my @days = @month_days;
    $days[1]++ if $date->is_leap_year;
    foreach my $month (1..12) {
        my $date = Calendar->new_from_Julian($month, int(rand(27)+1), $year);
        $ok = 0 unless $date->last_day_of_month == $days[$date->month-1];
    }
}
ok($ok, "Julian last day of month");
#}}}

sub gregorian_is_leap_year {
    my $year = shift;
    if ( $year < 0 ) {
        $year = abs($year) - 1;
    }
    ($year%4 == 0) && ($year%100>0 || ($year%400 == 0));
}

sub julian_is_leap_year {
    my $year = shift;
    if ( $year < 0 ) {
        $year = abs($year) - 1;
    }
    $year % 4 == 0
}

sub valid_convert {
    my ($package, $start, $days) = @_;
    $start = Calendar->new_from_Gregorian(@$start)->absolute_date;
    my $mod = "Calendar::$package";
    my $func = \&{"Calendar::new_from_$package"};
    my $i = 0;
    my $ok = 1;
    while ( $i<$days ) {
        my $date = $func->($mod, $start +$i);
        delete $date->{absolute};
        if ( $date->absolute_date != ($start+$i) ) {
            warn "absolute date ". $start+$i . "not convert correctly!\n";
            $ok = 0;
        }
        $i++;
    }
    return $ok;
}

# create_data("Gregorian", [1, 1, 1990], 365*20, "perl");
# create_data("Julian", [1, 1, 1990], 365*20, "perl");
# create_data("China", [1, 1, 1990], 365*20, "perl");

sub create_data {
    my ($package, $start, $days, $file) = @_;
    my $oldout;
    if ( $file ) {
        open($oldout, ">&STDOUT") || die "Can't dup STDOUT: $!";
        open(STDOUT, ">$file-$package.txt") or die "Can't create file $file-$package.txt: $!";
    }
    $start = Calendar->new_from_Gregorian(@$start)->absolute_date;
    my $mod = "Calendar::$package";
    my $func = \&{"Calendar::new_from_$package"};
    my $i = 0;
    if ( $package eq 'China' ) {
        while ( $i<$days ) {
            my $date = $func->($mod, $start +$i);
            printf "%d => (%d %d %s %d)\n", $date->absolute_date,
                $date->cycle, $date->year, $date->month, $date->day;
            $i++;
        }
    }
    else {
        while ( $i<$days ) {
            my $date = $func->($mod, $start +$i);
            printf "%d => (%d %d %d)\n", $date->absolute_date,
                $date->month, $date->day , $date->year;
            $i++;
        }
    }
    if ( $file ) {
        open(STDOUT, ">&", $oldout) or die "Can't restore STDOUT: $!";
    }
}
