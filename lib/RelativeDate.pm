# TodoTxt Tools
# Copyright (C) 2013 Bram Schoenmakers <me@bramschoenmakers.nl>

# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

package TodoTxt;

use strict;

use constant {
  DAY => 60 * 60 * 24,
  WEEK => 60 * 60 * 24 * 7
};

sub convertPattern {
  my $pattern = $_[ 0 ];
  my $offset = $_[ 1 ];

  $pattern =~ /^(\d+)([dwmy])$/i;
  my ( $amount, $period ) = ( $1, $2 );

  $offset += $amount * DAY               if $period eq 'd';
  $offset += $amount * WEEK              if $period eq 'w';
  $offset = $offset->add_months( $amount ) if $period eq 'm';
  $offset = $offset->add_years( $amount )  if $period eq 'y';

  return $offset;
}

sub convertWordPattern {
  my $pattern = $_[ 0 ];
  my $offset = localtime();

  return convertPattern( "0d", $offset ) if $pattern eq "today";
  return convertPattern( "1d", $offset ) if $pattern eq "tomorrow";
}

sub convertWeekdayPattern {
  my $targetDay = $_[ 0 ];
  my $offset = localtime();

  my $day = $offset->day;
  while ( $targetDay !~ /$day/i ) {
    $offset += DAY;
    $day = $offset->day;
  }

  return $offset;
}

# input/output: Time::Piece
sub convertRelativeDate {
  my $pattern = $_[ 0 ];
  my $offset = defined( $_[ 1 ] ) ? $_[ 1 ] : localtime();

  if ( $pattern =~ /^\d+[dwmy]$/i ) {
    $offset = convertPattern( $pattern, $offset );
  }
  elsif ( $pattern =~ /^(today|tomorrow)$/i ) {
    $offset = convertWordPattern( $pattern );
  }
  else {
    $offset = convertWeekdayPattern( $pattern );
  }

  return $offset;
}

# input/output: string YYYY-MM-DD
sub convertRelativeDateString {
  my $pattern = $_[ 0 ];
  my $offset = $_[ 1 ];

  $offset = defined( $offset ) && isDate( $offset ) ? parseDate( $offset ) : undef;

  my $date = convertRelativeDate( $pattern, $offset );
  return $date->ymd;
}

sub isRelativeDatePattern {
  return $_[ 0 ] =~ /^(\d+[dwmy]|today|tomorrow|mon(day)?|tue(sday)?|wed(nesday)?|thu(rsday)?|fri(day)?|sat(day)?|sun(day)?)$/i;
}

1;
