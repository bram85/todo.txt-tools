#!/usr/bin/env perl

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

use strict;

package TodoTxt;

use lib 'lib';
use Depends;
use TodoTxt;

my %priority = (
  'A' => 3,
  'B' => 2,
  'C' => 1
);

sub getPriorityValue {
  $_[ 0 ] =~ /([A-C])/;
  return defined( $priority{ $1 } ) ? $priority{ $1 } : 0;
}

sub getImportance {
  my $todo = $_[ 0 ];
  my $ignoreWeekends = $_[ 1 ];
  $ignoreWeekends = 0 unless defined( $ignoreWeekends );

  my $importance = 2;

  $importance += getPriorityValue( $todo->{ 'priority' } );

  # auto-viv is not a problem here
  $importance++ if TodoTxt::hasTagValue( $todo, 'star', 1 );

  if ( TodoTxt::hasTag( $todo, 'due' ) ) {
    my $daysLeft = TodoTxt::getDaysLeft( $todo );

    $importance += 1 if ( $daysLeft >= 7 && $daysLeft < 14 );
    $importance += 2 if ( $daysLeft >= 2 && $daysLeft < 7 );
    $importance += 3 if ( $daysLeft >= 1 && $daysLeft < 2 );
    $importance += 5 if ( $daysLeft >= 0 && $daysLeft < 1 );
    $importance += 6 if ( $daysLeft < 0 );

    if ( $ignoreWeekends ) {
      # add compensation when the next working day is a Monday, add one to
      # importance

      my $now = localtime();
      my $dueString = TodoTxt::getTagValue( $todo, 'due' );
      my $due = TodoTxt::parseDate( $dueString );
      my $diff = $due - $now;

      # between Friday 0:00 and Monday 23:59 (a span of less than 4 days)
      $importance += 1 if ( $now->wday == 6 || $now->wday == 7 ) && $due->wday == 2 && $diff->days < 4;
    }
  }

  return $importance;
}

sub getAverageImportance {
  my $todo = $_[ 0 ];
  my $ignoreWeekends = $_[ 1 ];

  my $ownImportance = getImportance( $todo, $ignoreWeekends );
  my @parents = TodoTxt::getParents( $todo );

  my $sum = $ownImportance;
  $sum += $_ foreach map { getImportance( $_, $ignoreWeekends ) } @parents;

  my $average = $sum / ( 1 + @parents );

  return $average > $ownImportance ? $average : $ownImportance;
}

1;
