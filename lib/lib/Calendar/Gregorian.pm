# Gregorian.pm --- 
# Last modify Time-stamp: <Ye Wenbin 2007-06-20 02:06:34>
# Version: v 0.0 <2006-12-15 14:46:59>
# Author: Ye Wenbin <wenbinye@163.com>

package Calendar::Gregorian;
use Calendar::Julian;
use POSIX;
use strict;
use warnings;
our @ISA = qw(Calendar::Julian);

our @month_days;
*month_days = \@Calendar::Julian::month_days;
our $default_format = "%D";

#==========================================================
# Input  : new(-year=>2000, -month=>12, day=>31) or new(12, 31, 2000)
# Output : a Calendar::Gregorian object
#==========================================================
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
        $self->absolute_date();
    }
    return $self;
}

sub from_absolute {
    use integer;
    my $self = shift;
    my $d0 = shift;
    $self->{absolute} = $d0;
    $d0--;
    my ($n400, $d1, $n100, $d2, $n4, $d3, $n1, $day, $year, $month);
    $n400 = $d0 / 146097;
    $d1   = $d0 % 146097;
    $n100 = $d1 / 36524;
    $d2   = $d1 % 36524;
    $n4   = $d2 / 1461;
    $d3 = $d2 % 1461;
    $n1 = $d3 / 365;
    $day = $d3 % 365 + 1;
    $year = 400*$n400 + 100*$n100 + 4*$n4 + $n1;
    if ( $n100==4 || $n1==4 ) {
        $month = 12;
        $day = 31;
    } else {
        $year++;
        $month = ceil($day/31);
        my $leap = (_is_leap_year($year) ? 1 : 0);
        while ( $day > $month_days[$month]+($month>1?$leap:0) ) {
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
    my $year = $self->year;
    if ( $year > 0 ) {
        my $offset = $year -1;
        $self->{absolute} = $self->day_of_year + 365*$offset + $offset/4 - $offset/100 + $offset/400;
    } else {
        my $offset = abs($year+1);
        $self->{absolute} = -($self->day_of_year + 365*$offset + $offset/4 - $offset/100 + $offset/400 + _day_of_year(12, 31, -1));
    }
}

sub is_leap_year {
    return _is_leap_year(shift->year);
}

#==========================================================
# Private functions
#==========================================================

#==========================================================
# Input  : year
# Output : 1 if it is leap year, 0 if not
#==========================================================
sub _is_leap_year {
    my $year = shift;
    if ( $year < 0 ) {
        $year = abs($year) - 1;
    }
    ($year%4 == 0) && ($year%100>0 || ($year%400 == 0));
}

1;
__END__

=head1 NAME

Calendar::Gregorian - Perl extension for Gregorian Calendar

=head1 SYNOPSIS

   use Calendar;
   my $date = Calendar->new_from_Gregorian(1, 1, 2006);

=head1 DESCRIPTION

From "FREQUENTLY ASKED QUESTIONS ABOUT CALENDARS"(C<http://www.tondering.dk/claus/calendar.html>)

=over

The Gregorian calendar is the one commonly used today. It was proposed
by Aloysius Lilius, a physician from Naples, and adopted by Pope
Gregory XIII in accordance with instructions from the Council of Trent
(1545-1563) to correct for errors in the older Julian Calendar. It was
decreed by Pope Gregory XIII in a papal bull on 24 February 1582. This
bull is named "Inter Gravissimas" after its first two words.

In the Gregorian calendar, the tropical year is approximated as
365 97/400 days = 365.2425 days. Thus it takes approximately 3300
years for the tropical year to shift one day with respect to the
Gregorian calendar.

The approximation 365 97/400 is achieved by having 97 leap years
every 400 years.

=back

=head1 METHOD

This class is inherited from L<Calendar::Julian>. The method is the
same as Calendar::Julian.

=head1 AUTHOR

Ye Wenbin <wenbinye@gmail.com>

=head1 COPYRIGHT

Copyright (C) 2006 by ywb

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.7 or,
at your option, any later version of Perl 5 you may have available.

=head1 SEE ALSO

L<Calendar>, L<Calendar::Julian>

=cut

