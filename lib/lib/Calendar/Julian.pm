# Julian.pm --- 
# Last modify Time-stamp: <Ye Wenbin 2007-06-20 02:11:14>
# Version: v 0.0 <2006-12-15 16:55:47>
# Author: Ye Wenbin <wenbinye@163.com>

package Calendar::Julian;
use strict;
use warnings;
use Calendar;
use POSIX;
use Carp;
require Exporter;
our @ISA = qw(Calendar Exporter);
our %EXPORT_TAGS = ( 'all' => [ qw(
$default_format
) ] );
our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );
our @EXPORT = qw(  );

our @month_days = (0, 31,59,90,120,151,181,212,243,273,304,334,365);
our $default_format = "%D";

sub new {
    my $_class = shift;
    my $class = ref $_class || $_class;
    my $self = {};
    bless $self, $class;
    if ( @_ ) {
        my %arg;
        if ( $_[0] =~ /-\D/ ) {
            %arg = @_;
        }
        else {
            if ( $#_ > 0 ) {
                $arg{$_} = shift for qw(-month -day -year);
            }
            else {
                return $self->from_absolute(shift);
            }
        }
        foreach ( qw(-month -day -year) ) {
            $self->{substr($_, 1)} = $arg{$_} if exists $arg{$_};
        }
        $self->{absolute} = $self->absolute_date();
    }
    return $self;
}

sub from_absolute {
    use integer;
    my $self = shift;
    my $date = shift;
    $self->{absolute} = $date;
    $date++;
    my $n4 = $date / 1461;
    my $d0 = $date % 1461;
    my $n1 = $d0 / 365;
    my $day = $d0 % 365 + 1;
    my $year = 4 * $n4 + $n1;
    my $month;
    if ( $n1==4 ) {
        $month = 12;
        $day = 31;
    } else {
        $year++;
        $month = ceil($day/31);
        my $leap = (_is_leap_year($year) ? 1 : 0);
        while ($day > $month_days[$month] + ($month >1 ? $leap: 0)) {
            $month++;
        }
        $day = $day-$month_days[$month-1]-($month>2?$leap:0);
    }
    $self->{year} = $year;
    $self->{month} = $month;
    $self->{day} = $day;
    return $self;
}

sub absolute_date {
    use integer;
    my $self = shift;
    if ( exists $self->{absolute} ) {
        return $self->{absolute};
    }
    $self->check_date();
    $self->{absolute} = _absoulte_date($self->month, $self->day, $self->year);
}

sub is_leap_year {
    my $self = shift;
    return _is_leap_year($self->year);
}

sub day_of_year {
    my $self = shift;
    return _day_of_year($self->month, $self->day, $self->year);
}

sub last_day_of_month {
    my $self = shift;
    return _last_day_of_month($self->month, $self->year);
}

sub check_date {
    my $self = shift;
    if ( $self->year == 0 ) {
        croak('Not a valid year: should not be zero in ' . ref $self);
    }
    if ( $self->month < 1 || $self->month > 12 ) {
        croak(sprintf('Not a valid month %d: should from 1 to 12 in %s', $self->month, ref $self));
    }
    if ( $self->day < 1 || $self->day > $self->last_day_of_month() ) {
        croak(sprintf('Not a valid day %d: should from 1 to %d in %d, %d in %s',
                      $self->day, $self->last_day_of_month, $self->month, $self->year, ref $self));
    }
}

#==========================================================
# Private functions
#==========================================================

sub _absoulte_date {
    my ($month, $day, $year) = @_;
    int(_day_of_year($month, $day, $year) + 365*($year-1) + ($year-1)/4 -2);
}

#===========================================================
# Input : month, day, year
# Output: the day number within the year, eg.
#         _day_of_year(1, 1, 1987) => 1
#         _day_of_year(12, 31, 1980) => 366
#===========================================================
sub _day_of_year {
    use integer;
    my ($month, $day, $year) = @_;
    my $day_of_year = $day + 31 * ($month-1);
    if ( $month > 2) {
        $day_of_year -= (23 + 4*$month)/10;
        if ( _is_leap_year($year) ) {
            $day_of_year++;
        }
    }
    return $day_of_year;
}

sub _is_leap_year {
    my $year = shift;
    if ( $year < 0 ) {
        $year = abs($year) - 1;
    }
    $year % 4 == 0
}

sub _last_day_of_month {
    my ($month, $year) = @_;
    return unless $month>0 && $month<13;
    if ( $month==2 && _is_leap_year($year) ) {
        29;
    }
    else {
        $month_days[$month]-$month_days[$month-1];
    }
}

1;

__END__

=head1 NAME

Calendar::Julian - Perl extension for Julian Calendar

=head1 SYNOPSIS

   use Calendar;
   my $date = Calendar->new_from_Julian(1, 1, 2006);

=head1 DESCRIPTION

From "FREQUENTLY ASKED QUESTIONS ABOUT CALENDARS"(C<http://www.tondering.dk/claus/calendar.html>)

=over

The Julian calendar was introduced by Julius Caesar in 45 BC. It was
in common use until the late 1500s, when countries started changing to
the Gregorian calendar (section 2.2). However, some countries (for
example, Greece and Russia) used it into the early 1900s, and the
Orthodox church in Russia still uses it, as do some other Orthodox
churches.

In the Julian calendar, the tropical year is approximated as 365 1/4
days = 365.25 days. This gives an error of 1 day in approximately 128
years.

The approximation 365 1/4 is achieved by having 1 leap year every 4
years.

=back

=head1 METHOD

=over 4

=item  is_leap_year

True if the date in a leap year.

=item  day_of_year

Return the day of year the day of the year, in the range 1..365 (or
1..366 in leap years.)

=item  last_day_of_month

Return the last day in the month. For example:

    $date = Calendar->new_from_Julian(2, 1, 2006);
    print $date->last_day_of_month;       # output 28

=back

=head1 AUTHOR

Ye Wenbin <wenbinye@gmail.com>

=head1 COPYRIGHT

Copyright (C) 2006 by ywb

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.7 or,
at your option, any later version of Perl 5 you may have available.

=cut

