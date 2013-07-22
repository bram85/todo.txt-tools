#!/usr/bin/perl

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

use Getopt::Std;
use Time::Piece;

my %options;
getopts( 'w', \%options );

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

  my $importance = 2;

  $importance += getPriorityValue( $todo->{ 'priority' } );

  # auto-viv is not a problem here
  $importance++ if $todo->{ 'tags' }->{ 'star' } == 1;

  if ( defined( $todo->{ 'tags' }->{ 'due' } ) ) {
    my $daysLeft = TodoTxt::getDaysLeft( $todo );

    $importance += 1 if ( $daysLeft > 7 && $daysLeft <= 14 );
    $importance += 2 if ( $daysLeft > 2 && $daysLeft <= 7 );
    $importance += 3 if ( $daysLeft > 1 && $daysLeft <= 2 );
    $importance += 5 if ( $daysLeft > 0 && $daysLeft <= 1 );
    $importance += 6 if ( $daysLeft < 0 );

    my $ignoreWeekends = defined( $options{ 'w' } );

    if ( $ignoreWeekends ) {
      # add compensation when the next working day is a Monday, add one to
      # importance

      my $now = localtime();
      my $due = TodoTxt::parseDate( $todo->{ 'due' } );
      my $diff = $due - $now;

      # between Friday 0:00 and Monday 23:59 (a span of less than 4 days)
      $importance += 1 if ( $now->wday == 6 || $now->wday == 7 ) && $due->wday == 2 && $diff->days < 4;
    }
  }

  return $importance;
}

sub sortTodos {
  return getImportance( $b ) <=> getImportance( $a )
  || getPriorityValue( $b->{ 'priority' } ) <=> getPriorityValue( $a->{ 'priority' } )
  || TodoTxt::getDaysLeft( $b ) <=> TodoTxt::getDaysLeft( $a );
}

my $todos = TodoTxt::readTodos( $ARGV[ 0 ] );
foreach my $t ( sort sortTodos @$todos ) {
  print $t->{ 'src' };
}

exit 0;
