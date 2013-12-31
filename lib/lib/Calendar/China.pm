# -*- coding: utf-8 -*-
# China.pm --- 
# Last modify Time-stamp: <Ye Wenbin 2007-07-13 10:47:25>
# Version: v 0.0 <2006-12-15 23:57:01>
# Author: Ye Wenbin <wenbinye@163.com>

package Calendar::China;
use strict;
use warnings;
require Calendar;
our @ISA = qw(Calendar);

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
                $arg{$_} = shift for qw(-cycle -year -month -day);
            }
            else {
                return $self->from_absolute(@_);
            }
        }
        foreach ( qw(-cycle -year -month -day) ) {
            $self->{substr($_, 1)} = $arg{$_} if exists $arg{$_};
        }
        $self->absolute_date();
    }
    return $self;
}

sub absolute_date {
    my $self = shift;
    if (exists $self->{absolute} ) {
        return $self->{absolute};
    }
    my ($cycle, $year, $month, $day) = ($self->{cycle}, $self->{year},
                                        $self->{month}, $self->{day});
    my $gyear = 60*($cycle-1)+$year-1-2636;
    my $monthday = _assoc_month($month, [_memq_month(1, _year($gyear)), @{_year($gyear+1)}]);
    $self->{absolute} = $day-1+$monthday->[1];
    $self->check_date();
    return $self->{absolute};
}

sub from_absolute {
    my $self = shift;
    my $absdate = shift;
    $self->{absolute} = $absdate;
    my $date = Calendar->new_from_Gregorian($absdate);
    $self->{gdate} = $date;
    my $cyear = $date->year+2695;
    my @list = (@{_year($date->year-1)},
                @{_year($date->year)},
                @{_year($date->year+1)});
    foreach ( 0..$#list ) {
        if ( $list[$_]->[0] == 1 ) {
            $cyear++;
        }
        if ( $list[$_+1]->[1] > $absdate ) {
            $date = $list[$_];
            last;
        }
    }
    $self->{cycle} = int(($cyear-1)/60);
    $self->{year} = _mod($cyear, 60);
    $self->{month} = $date->[0];
    $self->{day} = $absdate - $date->[1] + 1;
    return $self;
}

sub cycle { shift->{cycle}; }

sub is_leap_year {
    my $self = shift;
    my $list = _year_month_list($self->cycle, $self->year);
    return $#{$list} == 12;
}

sub gyear { shift->gdate->year; }

sub gmonth { shift->gdate->month; }

sub gday { shift->gdate->day; }

sub gdate {
    my $self = shift;
    unless ( exists $self->{gdate} ) {
        $self->{gdate} = Calendar->new_from_Gregorian($self->absolute_date);
    }
    return $self->{gdate};
}

sub last_day_of_month {
    my $self = shift;
    require Calendar::Lunar;
    my $date = Calendar::Lunar::new_moon_date
        ( $self->day==1 ? $self->absolute_date+1 : $self,
          timezone(Calendar->new_from_Gregorian($self->absolute_date)->year));
    int($date-1-$self->absolute_date + $self->day);
}

sub year_month_list {
    my $self = shift;
    return _year_month_list($self->cycle, $self->year);
}

sub timezone {
    my $year = shift;
    return ((defined $year && $year >= 1928) ? 480 : 465 + 40.0/60.0 );
}

sub next_jieqi_date {
    Calendar::Solar::next_longitude_date($_[0], 15, $_[1]);
}

sub check_date {
    my $self = shift;
    if ( $self->year < 1 || $self->year > 60 ) {
        croak('Not a valid year: should not from 1 to 60 in ' . ref $self);
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
# Format calendar
#==========================================================
our @celestial_stem = qw(甲 乙 丙 丁 戊 已 庚 辛 壬 癸);
our @terrestrial_branch = qw(子 丑 寅 卯 辰 巳 午 未 申 酉 戌 亥);
our @weekday_name = qw(日 一 二 三 四 五 六);
our @month_name =
    qw(正月 二月 三月 四月 五月 六月 七月 八月 九月 十月 十一月 腊月);
our @day_name = qw
  (初一 初二 初三 初四 初五 初六 初七 初八 初九 初十
   十一 十二 十三 十四 十五 十六 十七 十八 十九 二十
   廿一 廿二 廿三 廿四 廿五 廿六 廿七 廿八 廿九 三十
   卅一);
our @zodiac_name = qw(鼠 牛 虎 兔 龙 蛇 马 羊 猴 鸡 狗 猪);
our @jieqi_name = qw
  (小寒 大寒 立春 雨水 惊蛰 春分
   清明 谷雨 立夏 小满 芒种 夏至
   小暑 大暑 立秋 处暑 白露 秋分
   寒露 霜降 立冬 小雪 大雪 冬至);

sub day_name {
    return $day_name[shift->day-1];
}

sub month_name {
    my $self = shift;
    my $month = $self->month;
    if ( _is_int($month)  ) {
        $month_name[$month-1];
    } else {
        return "闰".$month_name[$month-1];
    }
}

sub weekday_name {
    return "星期".$weekday_name[shift->weekday];
}

sub sexagesimal_name {
    my $self = shift;
    my $year = $self->year-1;
    return $celestial_stem[$year%10] . $terrestrial_branch[$year%12];
}

sub zodiac_name {
    my $self = shift;
    my $year = $self->year-1;
    return $zodiac_name[$year%12];
}

sub format_Y { shift->gyear }
sub format_S { shift->sexagesimal_name }
sub format_D { shift->day_name }
sub format_Z { shift->zodiac_name }
sub format_m { sprintf("%02d", shift->gmonth) }
sub format_d { sprintf("%02d", shift->gday) }
our $default_format = "%Y年%m月%d日 %W %S%Z年%M%D";

#==========================================================
# Private functions
#==========================================================
#==========================================================
# Input  : chinese year cycle, year
# Output : the array of month in the chinese year
# Desc   :
#==========================================================
sub _year_month_list {
    my ($cycle, $year) = @_;
    my $date = __PACKAGE__->new($cycle, $year, 1, 1);
    $year = $date->gyear;
    my $list1 = _year($year);
    my $list2 = _year($year+1);
    my @list = _memq_month(1, $list1);
    foreach ( @$list2 ) {
        last if $_->[0]==1;
        push @list, $_;
    }
    return \@list;
}

#==========================================================
# Input  : x, y
# Output : x modulo y, range from 1-y
# Desc   : like operator %, but instead of 0, return the exclusive y
#==========================================================
sub _mod {
    $_[0] % $_[1] || $_[1];
}

sub _is_int {
    $_[0]-int($_[0])==0;
}

#==========================================================
# Input  : month, an array of month list
# Output : the month list from month
# Desc   : eg, _memq_month(2, [[12, 726464], [1, 726494], [2, 726523], [3, 726553], ...])
#          return [[2, 726523], [3, 726553], ...]
#==========================================================
sub _memq_month {
    my ($month, $list) = @_;
    my $i = 0;
    for ( ; $i<=$#$list; $i++ ) {
        last if ($list->[$i][0] == $month);
    }
    return @{$list}[$i..$#$list];
}

#==========================================================
# Input  : month, an array of month list
# Output : the month in the list
# Desc   : eg, _assoc_month(2, [[12, 726464], [1, 726494], [2, 726523], [3, 726553], ...])
#          return [2, 726523]
#==========================================================
sub _assoc_month {
    my ($month, $list) = @_;
    foreach ( @$list ) {
        return $_ if $_->[0] == $month;
    }
}

my $cache_start = 1990;
# static cache for recent years
my @year_cache = 
    ([[12, 726464], [1, 726494], [2, 726523], [3, 726553], [4, 726582], [5, 726611],   # 1990
      [5.5, 726641], [6, 726670], [7, 726699], [8, 726729], [9, 726758], [10, 726788],
      [11, 726818]],
     [[12, 726848], [1, 726878], [2, 726907], [3, 726937], [4, 726966], [5, 726995],   # 1991
      [6, 727025], [7, 727054], [8, 727083], [9, 727113], [10, 727142], [11, 727172]],,
     [[12, 727202], [1, 727232], [2, 727261], [3, 727291], [4, 727321], [5, 727350],   # 1992
      [6, 727379], [7, 727409], [8, 727438], [9, 727467], [10, 727497], [11, 727526]],
     [[12, 727556], [1, 727586], [2, 727615], [3, 727645], [3.5, 727675], [4, 727704], # 1993
      [5, 727734], [6, 727763], [7, 727793], [8, 727822], [9, 727851], [10, 727881],
      [11, 727910]],
     [[12, 727940], [1, 727969], [2, 727999], [3, 728029], [4, 728059], [5, 728088],   # 1994
      [6, 728118], [7, 728147], [8, 728177], [9, 728206], [10, 728235], [11, 728265]],
     [[12, 728294], [1, 728324], [2, 728353], [3, 728383], [4, 728413], [5, 728442],   # 1995
      [6, 728472], [7, 728501], [8, 728531], [8.5, 728561], [9, 728590], [10, 728619],
      [11, 728649]],
     [[12, 728678], [1, 728708], [2, 728737], [3, 728767], [4, 728796], [5, 728826],   # 1996
      [6, 728856], [7, 728885], [8, 728915], [9, 728944], [10, 728974], [11, 729004]],
     [[12, 729033], [1, 729062], [2, 729092], [3, 729121], [4, 729151], [5, 729180],   # 1997
      [6, 729210], [7, 729239], [8, 729269], [9, 729299], [10, 729328], [11, 729358]],
     [[12, 729388], [1, 729417], [2, 729447], [3, 729476], [4, 729505], [5, 729535],   # 1998
      [5.5, 729564], [6, 729593], [7, 729623], [8, 729653], [9, 729682], [10, 729712],
      [11, 729742]],
     [[12, 729771], [1, 729801], [2, 729831], [3, 729860], [4, 729889], [5, 729919],   # 1999
      [6, 729948], [7, 729977], [8, 730007], [9, 730036], [10, 730066], [11, 730096]],
     [[12, 730126], [1, 730155], [2, 730185], [3, 730215], [4, 730244], [5, 730273],   # 2000
      [6, 730303], [7, 730332], [8, 730361], [9, 730391], [10, 730420], [11, 730450]],
     [[12, 730480], [1, 730509], [2, 730539], [3, 730569], [4, 730598], [4.5, 730628], # 2001
      [5, 730657], [6, 730687], [7, 730716], [8, 730745], [9, 730775], [10, 730804],
      [11, 730834]],
     [[12, 730863], [1, 730893], [2, 730923], [3, 730953], [4, 730982], [5, 731012],   # 2002
      [6, 731041], [7, 731071], [8, 731100], [9, 731129], [10, 731159], [11, 731188]],
     [[12, 731218], [1, 731247], [2, 731277], [3, 731307], [4, 731336], [5, 731366],   # 2003
      [6, 731396], [7, 731425], [8, 731455], [9, 731484], [10, 731513], [11, 731543]],
     [[12, 731572], [1, 731602], [2, 731631], [2.5, 731661], [3, 731690], [4, 731720], # 2004
      [5, 731750], [6, 731779], [7, 731809], [8, 731838], [9, 731868], [10, 731897],
      [11, 731927]],
     [[12, 731956], [1, 731986], [2, 732015], [3, 732045], [4, 732074], [5, 732104],   # 2005
      [6, 732133], [7, 732163], [8, 732193], [9, 732222], [10, 732252], [11, 732281]],
     [[12, 732311], [1, 732340], [2, 732370], [3, 732399], [4, 732429], [5, 732458],   # 2006
      [6, 732488], [7, 732517], [7.5, 732547], [8, 732576], [9, 732606], [10, 732636],
      [11, 732665]],
     [[12, 732695], [1, 732725], [2, 732754], [3, 732783], [4, 732813], [5, 732842],   # 2007
      [6, 732871], [7, 732901], [8, 732930], [9, 732960], [10, 732990], [11, 733020]],
     [[12, 733049], [1, 733079], [2, 733109], [3, 733138], [4, 733167], [5, 733197],   # 2008
      [6, 733226], [7, 733255], [8, 733285], [9, 733314], [10, 733344], [11, 733374]],
     [[12, 733403], [1, 733433], [2, 733463], [3, 733493], [4, 733522], [5, 733551],   # 2009
      [5.5, 733581], [6, 733610], [7, 733639], [8, 733669], [9, 733698], [10, 733728],
      [11, 733757]],
     [[12, 733787], [1, 733817], [2, 733847], [3, 733876], [4, 733906], [5, 733935],   # 2010
      [6, 733965], [7, 733994], [8, 734023], [9, 734053], [10, 734082], [11, 734112]]
 );
# dynamic cache for calculated years
my %year_cache;

#==========================================================
# Input  : Gregorian year
# Output : the chinese month list of the year
# Desc   : The month list always range from winter solstice day in year-1
#          to winter in solstice day. Usually, the month list is start
#          chinese month 12 in last year, but possible start from 11.5.
#          The month with .5 indicate that is a leap month. 
#==========================================================
sub _year {
    my $y = shift;
    if ( $y >= $cache_start && $y < $cache_start+$#year_cache+1 ) {
        return $year_cache[$y-$cache_start];
    }
    elsif ( exists $year_cache{$y} ) {
        return $year_cache{$y};
    }
    else {
        $year_cache{$y} = _compute_chinese_year($y);
    }
}

sub _compute_chinese_year {
    require Calendar::Solar;
    require Calendar::Lunar;
    my $y = shift;
    my $oldtz = $Calendar::Solar::timezone;
    $Calendar::Solar::timezone = timezone($y);
    my $next_solstice = _zodiac_sign(Calendar->new_from_Gregorian(12, 15, $y));
    my $months = _month_list(_zodiac_sign(Calendar->new_from_Gregorian(12, 15, $y-1))+1,
                             $next_solstice);
    my $list;
    if ( scalar(@$months) == 12 ) {
        $list = [[12, $months->[0]], map { [ $_, $months->[$_] ]} 1..11];
    } else {
        my $next_sign = _zodiac_sign($months->[0]);
        if ( $months->[0]>$next_sign || $next_sign >= $months->[1] ) {
            $list = [[11.5, $months->[0]], [12, $months->[1]],
                     map { [ $_, $months->[$_+1] ] } 1..11];
        } else {
            my @list = ([12, $months->[0]]);
            if ( _zodiac_sign($months->[1]) >= _zodiac_sign($months->[2]) ) {
                push @list, [12.5, $months->[1]],
                    map { [ $_, $months->[$_+1] ] } 1..11;
            } else {
                push @list, [1, $months->[1]];
                my $i = 2;
                while ( $months->[$i+1] > _zodiac_sign($months->[$i]) ) {
                    push @list, [$i, $months->[$i]];
                    $i++;
                }
                push @list, [$i-0.5, $months->[$i]];
                foreach ( $i..11 ) {
                    push @list, [$_, $months->[$_+1]];
                }
            }
            $list = \@list;
        }
    }
    $Calendar::Solar::timezone = $oldtz;
    return $list;
}

sub _zodiac_sign {
    int(Calendar::Solar::next_longitude_date(shift, 30));
}

#==========================================================
# Input  : start, end, timezone
# Output : the array of new moon date between start and end
# Desc   : start and end should be Calendar object or absolute date
#==========================================================
sub _month_list {
    my ($start, $end) = @_;
    my @list;
    while ( $start <= $end ) {
        $start = int(Calendar::Lunar::new_moon_date($start));
        push @list, $start;
        $start++;
    }
    pop @list if $list[-1]>$end;
    return \@list;
}

1;

__END__

=head1 NAME

Calendar::China - Perl extension for Chinese calendar

=head1 SYNOPSIS

   use Calendar;
   my $date = Calendar->new_from_China(78, 22, 12, 2);

   or construct from Gregorian:
   my $date = Calendar->new_from_Gregorian(1, 1, 2006)->convert_to_China();

=head1 DESCRIPTION

From "FREQUENTLY ASKED QUESTIONS ABOUT CALENDARS"(C<http://www.tondering.dk/claus/calendar.html>)

=over

The Chinese calendar - like the Hebrew - is a combined solar/lunar
calendar in that it strives to have its years coincide with the
tropical year and its months coincide with the synodic months. It is
not surprising that a few similarities exist between the Chinese and
the Hebrew calendar:

   * An ordinary year has 12 months, a leap year has 13 months.
   * An ordinary year has 353, 354, or 355 days, a leap year has 383,
     384, or 385 days.

When determining what a Chinese year looks like, one must make a
number of astronomical calculations:

First, determine the dates for the new moons. Here, a new moon is the
completely "black" moon (that is, when the moon is in conjunction with
the sun), not the first visible crescent used in the Islamic and
Hebrew calendars. The date of a new moon is the first day of a new
month.

Secondly, determine the dates when the sun's longitude is a multiple
of 30 degrees. (The sun's longitude is 0 at Vernal Equinox, 90 at
Summer Solstice, 180 at Autumnal Equinox, and 270 at Winter Solstice.)
These dates are called the "Principal Terms" and are used to determine
the number of each month:

Principal Term 1 occurs when the sun's longitude is 330 degrees.
Principal Term 2 occurs when the sun's longitude is 0 degrees.
Principal Term 3 occurs when the sun's longitude is 30 degrees.
etc.
Principal Term 11 occurs when the sun's longitude is 270 degrees.
Principal Term 12 occurs when the sun's longitude is 300 degrees.

Each month carries the number of the Principal Term that occurs in
that month.

In rare cases, a month may contain two Principal Terms; in this case
the months numbers may have to be shifted. Principal Term 11 (Winter
Solstice) must always fall in the 11th month.

All the astronomical calculations are carried out for the meridian 120
degrees east of Greenwich. This roughly corresponds to the east coast
of China.

Some variations in these rules are seen in various Chinese
communities.

=back

=head1 METHOD

=over 4

=item  cycle

The number of the Chinese sexagesimal cycle

=item  is_leap_year

True if the chinese year of the date has leap month.

=item  gyear

The number of year in Gregorian calendar

=item  gmonth

The number of month in Gregorian calendar

=item  gday

The number of day in Gregorian calendar

=item  gdate

The Gregorian calendar date. 

=item  last_day_of_month

The last day of the chinese month.

=item  year_month_list

The month list of the chinese year. For example:

    use Calendar;
    $date = Calendar->new_from_China()->today();
    $date->year_month_list;

The return value may like:

 [[1, 732340], [2, 732370], [3, 732399], [4, 732429], [5, 732458],
  [6, 732488], [7, 732517], [7.5, 732547], [8, 732576], [9, 732606],
  [10, 732636], [11, 732665], [12, 732695]]

The element is construct from month and absolute date. So the first
element is the date of chinese new year.

=head1 FUNCTIONS

=over

=item  timezone

Return chinese timezone. This is an expression in `year' since it
changed at 1928-01-01 00:00:00 from UT+7:45:40 to UT+8. Default is for
Beijing.

=item  next_jieqi_date

Calculate next jieqi from the date.

=back

=head1 AUTHOR

Ye Wenbin <wenbinye@gmail.com>

=head1 COPYRIGHT

Copyright (C) 2006 by ywb

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.7 or,
at your option, any later version of Perl 5 you may have available.

=cut


