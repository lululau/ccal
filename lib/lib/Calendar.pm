# Calendar.pm --- 
# Version: v 0.0 <2006-12-15 14:37:46>
# Author: Ye Wenbin <wenbinye@163.com>

package Calendar;
use strict;
use warnings;
use Data::Dumper qw(Dumper); 
use overload
    '<=>' => sub { $_[0]->absolute_date <=> (ref $_[1] ? $_[1]->absolute_date : $_[1]) },
    '+' => \&add,
    '-' => \&substract,
    '""' => \&date_string,
    '0+' => \&absolute_date;

use vars qw($VERSION);
use version; our $VERSION=qv("0.4.2");

sub new {
    my $_class = shift;
    my $class = ref $_class || $_class;
    my $self = {};
    bless $self, $class;
    if ( @_ ) {
        $self->{absolute} = shift;
    }
    return $self;
}

sub new_from_Astro {
    return new($_[0], $_[1] - 1721424.5);
}

sub absolute_date {
    return shift->{absolute};
}

sub astro_date {
    return shift->absolute_date + 1721424.5;
}

sub today {
    my $self = shift;
    my @time = localtime;
    my $date = Calendar->new_from_Gregorian($time[4]+1, $time[3], $time[5]+1900);
    $self->new($date->absolute_date);
}

#{{{  Format functions
our @weekday_name = qw(Sunday Monday Tuesday Wednesday Thursday Friday Saturday);
our @month_name = qw(January February March April May June July August September October November December);
our $default_format = "%A";

sub weekday {
    return shift->{absolute} % 7;
}

sub weekday_name {
    return $weekday_name[shift->weekday];
}

sub month_name {
    return $month_name[shift->month-1];
}

sub date_string {
    my $self = shift;
    no strict;
    my $fmt = shift || ${(ref $self||$self)."::default_format"} || $default_format;
    $fmt =~ s/
              %(O?[%a-zA-Z])
             /
             ($self->can("format_$1") || sub { $1 })->($self);
             /sgeox;
    return $fmt;
}

sub format_d { sprintf("%02d", shift->day) }
sub format_m { sprintf("%02d", shift->month) }
sub format_A { shift->absolute_date }
sub format_W { shift->weekday_name }
sub format_M { shift->month_name }
sub format_Y { shift->year }
sub format_D {
    my $self = shift;
    return join("/", map { sprintf "%02d", $_ } $self->month, $self->day, $self->year);
}

#}}}

#{{{  Overload Operators
sub substract {
    my $self = shift;
    my $operand = shift;
    if ( ref $operand ) {
        return $self->absolute_date - $operand->absolute_date;
    }
    else {
        return $self->new($self->absolute_date-$operand);
    }
}

sub add {
    my $self = shift;
    my $operand = shift;
    die "operand must be numeric!\n" if ref $operand;
    $self->new($self->absolute_date + $operand);
}
#}}}

sub AUTOLOAD {
    no strict 'refs';
    our ($AUTOLOAD);
    if ( $AUTOLOAD =~ /::new_from_(\w+)/ ) {
        my $subname = "Calendar::new_from_" . $1;
        my $module = "Calendar::" . $1;
        eval("require $module");
        if ( $@ ) {
            die "Can't load module $module: $@!\n"
        }
        my $sub = *{$subname} = sub {
            my $self = shift;
            return $module->new(@_);
        };
        goto &$sub;
    }
    elsif ( $AUTOLOAD =~ /::convert_to_(\w+)/ ) {
        my $subname = "Calendar::convert_to_" . $1;
        my $module = "Calendar::" . $1;
        eval("require $module");
        if ( $@ ) {
            die "Can't load module $module: $@!\n"
        }
        my $sub = *{$subname} = sub {
            $_[0] = $module->new($_[0]->absolute_date);
            return $_[0];
        };
        goto &$sub;
    }
    elsif ( $AUTOLOAD =~ /::(year|month|day)$/ ) {
        my $self = shift;
        if ( exists $self->{$1} ) {
            return $self->{$1};
        }
        return;
    }
    elsif ( $AUTOLOAD =~ /DESTROY/) {
    }
    else {
        die "Unknown function $AUTOLOAD\n";
    }
}

1;

__END__

=head1 NAME

Calendar - Perl extension for calendar convertion

=head1 SYNOPSIS

   use Calendar;
   my $date = Calendar->new_from_Gregorian(12, 16, 2006);
   print $date->date_string("Gregorian date: %M %W %d %Y"), "\n";

   my $newdate = $date + 7;
   print $newdate->date_string("Gregorian date of next week: %D"), "\n";
   
   $newdate = $date-7;
   print $newdate->date_string("Absolute date of last week: %A\n");
   
   my $diff = $date-$newdate;
   printf "There is %d days between %s and %s\n",
       $diff, $date->date_string("%D"), $newdate->date_string("%D");
   
   $date->convert_to_Julian;
   print $date->date_string("Julian date: %M %W %d %Y"), "\n";

=head1 DESCRIPTION

Calendar is a class for calendar convertion or calculation. The
algorithm is from emacs calendar library. Most functions of this class
is simply rewrite from elisp to perl. 

=head2 Constructor

=over 4

=item new

All class of Calendar should accept absolute date to construct the
object. Other type of argument may also be acceptable. For example:

    use Calendar::Gregorian;
    Calendar::Gregorian->new(732662);
    Calendar::Gregorian->new(12, 17, 2006);
    Calendar::Gregorian->new(-year=>2006, -month=>12, -day=>17);

=item new_from_Package

Calendar has AUTOLOAD function that can automatic call new function
from package. So the following construct are also valid:

    use Calendar;
    Calendar->new_from_Gregorian(732662);
    Calendar->new_from_Gregorian(12, 17, 2006);
    Calendar->new_from_Gregorian(-year=>2006, -month=>12, -day=>17);

=back

=head2 Convertion

Calendar object can convert from each other. The function is name
`convert_to_Package'. For example:

    $date = Calendar->new_from_Gregorian(12, 17, 2006);
    $date->convert_to_Julian;

Now $date is a Julian calendar date. If you want maintain $date not
change, use Calendar->new_from_Julian($date->absolute_date) instead.

=head2 Operator

Calendar overload several operator. 

=over 4

=item +

A Calendar object can add a number of days. For example:

    $newdate = $date + 1;

The $newdate is next day of $date. You CANNOT add a date to another
date.

=item -

If a date substract from a number of days, that means the date before
the number of days. For example:

    $newdate = $date - 1;

The $newdate is the last day of $date. When a date substract from
another date, returns the days between the two date. For example:

    $newdate = $date + 7;
    $days = $newdate - $date;        # $days is 7

The return value is different type, you should always be careful.

=item <=>

Two date can compare from each other. For example:

    if ( $date2 > $date1 ) {
        print "$date2 is after $date1.\n";
    }
    else {
        print "$date1 is after $date2.\n";
    }    

=item ""

That means you can simply print the date without explicitly call a
method. For detail, read "Format date" section.

=back

=head2 Format date

Every calendar class has a format template: $default_format. You can
set the template. The format function is `date_string'. The format
specifications as following:

   %%       PERCENT
   %A       Absoute date
   %d       numeric day of the month, with leading zeros (eg 01..31)
   %D       MM/DD/YY
   %m       month number, with leading zeros (eg 01..31)
   %M       month name
   %W       day of the week
   %Y       year

For chinese calendar, the following specifications are available:

   %S       sexagesimal name, eg. "丙戌"
   %D       day name, eg. "初二"
   %Z       zodiac name, eg. "狗"
   %M       month name in chinese, eg. "十一月"
   %W       week day name in chinese, eg. "星期一"

Meanwhile, %Y, %m and %d now stand for Gregorian year, month and day.

=head2 Other method

=over 4

=item  absoute_date

The number of days elapsed between the Gregorian date 12/31/1 BC.
The Gregorian date Sunday, December 31, 1 BC is imaginary.

=item  astro_date

Astronomers use a simple counting of days elapsed since noon, Monday,
January 1, 4713 B.C. on the Julian calendar.  The number of days elapsed
is called the "Julian day number" or the "Astronomical day number".

=item  new_from_Astro

There is no package Calendar::Astro. use new_from_Astro and astro_date
to convert between other type of calendar and astro calendar.

=item  today

The current date of local time. 

=item  weekday

The weekday number. 0 for sunday and 1 for monday.

=item  weekday_name

The full name of the weekday.

=item  month

The number of month, range from 1 to 12.

=item  month_name

The full name of month.

=item  day

The number of day in the month. The first day in the month is 1.

=item  year

The year number.

=back

=head1 AUTHOR

Ye Wenbin <wenbinye@gmail.com>

=head1 COPYRIGHT

Copyright (C) 2006 by ywb

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.7 or,
at your option, any later version of Perl 5 you may have available.

=cut

