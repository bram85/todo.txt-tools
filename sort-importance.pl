#!/usr/bin/perl

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
      $importance += 1 if $now->wday == 6 && $due->wday == 2 && $diff->days < 4;
    }
  }

  return $importance;
}

sub sortTodos {
  return getImportance( $b ) <=> getImportance( $a )
  || getPriorityValue( $b->{ 'priority' } ) <=> getPriorityValue( $a->{ 'priority' } )
  || TodoTxt::getDaysLeft( $b ) <=> TodoTxt::getDaysLeft( $a );
}

my $todos = TodoTxt::getTodos();

foreach my $t ( sort sortTodos @$todos ) {
  print $t->{ 'src' };
}

exit 0;
