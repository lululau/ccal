#!/usr/bin/perl -w
# cal.pl --- Simple calendar
# Last modify Time-stamp: <Ye Wenbin 2007-07-14 14:31:03>
# Version: v 0.0 <2006-12-16 23:49:45>
# Author: Ye Wenbin <wenbinye@163.com>

use strict;
use warnings;
use Pod::Usage;
use Getopt::Long qw(:config auto_help);
use Calendar::Calendar qw(:all);
use I18N::Langinfo;

my %Config = (
    'locale' => langinfo(I18N::Langinfo::CODESET()),
    'weekstart' => 0,
    'type' => 'gregorian',
);

my ($month, $year, $type, $china, $gregorian, $julian);

# Install configuration
$week_start_day = $Config{weekstart};
$type = $Config{type};

GetOptions(
    'locale=s' => \$Config{locale},
    'china' => \$china,
    'gregorian' => \$gregorian,
    'julian' => \$julian,
    'type=s' => \$type,
    'weekstart=i' => \$week_start_day,
);

# Check month and year
my @time = localtime;
$month = shift || $time[4]+1;
$year = shift || $time[5]+1900;
unless ( $month && $year && $month>0 && $month<13 ) {
    pod2usage();
}

# Check package 
if ( $china) {
    $type = "China";
} elsif ( $gregorian ) {
    $type = "Gregorian";
} elsif ( $julian ) {
    $type = "Julian";
}
$type = ucfirst($type);

## ensure the package is implement
unless ( defined($type) && grep { $type eq $_ } qw(China Gregorian Julian) ) {
    pod2usage();
}

my $cal = Calendar::Calendar::calendar($month, $year, $type)."\n";
if ( $type =~ /China/ ) {
    # out put using locale
    require Encode;
    Encode::_utf8_on($cal);
    print Encode::encode($Config{locale}, $cal);
} else {
    print $cal;
}

__END__

=head1 NAME

cal.pl  -  Print calendar of multiple type

=head1 SYNOPSIS

cal.pl [-l locale -w weekstart [-c|-g|-j|-t calendar_type] month year]

    Options:
       -l, --locale locale
           The locale of system. Only for Non english calendar.

       -w, --weekstart start
           The week start day for the output. Default is 0, means the
           first day of the week is Sunday

       -c, --china
           Output chinese calendar

       -g, --gregorian
           Output gregorian calendar

       -j, --julian
           Output Julian calendar

       -t, --type calendar_type
           Specific a type of calendar.
           Available type: china, gregorian, julian

       month, year
           The month and year of the calendar

=head1 Example

    * Output current month gregorian calendar

       cal.pl

    * Output chinese calendar of February in current year
     
       cal.pl -c 2

    * Output the julian calendar in 1752 September. You can see the
      difference from cal(1)

       cal.pl -j 9 1752

    * Output chinese calendar in gbk language environment

       cal.pl -c -l gbk

=head1 Configuration

Add your default command parameter to the %Config in this file.

=head1 AUTHOR

Ye Wenbin <wenbinye@gmail.com>

=head1 SEE ALSO

L<Calendar>, L<Calendar::Calendar>, L<Calendar::Gregorian>,
L<Calendar::Julian>, L<Calendar::China>

=cut
