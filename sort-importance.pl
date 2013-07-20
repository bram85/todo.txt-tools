#!/usr/bin/perl

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
