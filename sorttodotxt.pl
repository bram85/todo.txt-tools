#!/usr/bin/perl

use strict;
use Time::Piece;
use Time::Seconds;

my %todos;

my %priority = (
  'A' => 3,
  'B' => 2,
  'C' => 1
);

sub isPriority {
  return $_[ 0 ] =~ /^\([A-Z]\)$/;
}

sub getPriorityValue {
  $_[ 0 ] =~ /([A-C])/;
  return defined( $priority{ $1 } ) ? $priority{ $1 } : 0;
}

sub isDate {
  return $_[ 0 ] =~/^\d{4}-\d{2}-\d{2}$/;
}

sub isKeyValue {
  return $_[ 0 ] =~ /^(\S+):(\S+)$/ ? ( $1, $2 ) : 0;
}

sub isContext {
  return $_[ 0 ] =~ /^@\S+$/;
}

sub getContext {
  $_[ 0 ] =~ /^@(\w+)\W*$/;
  return $1;
}

sub isProject {
  return $_[ 0 ] =~ /^\+\S+$/;
}

sub getProject {
  $_[ 0 ] =~ /^\+(\w+)\W*$/;
  return $1;
}

sub isDueDate {
  my ( $key, $value ) = isKeyValue( $_[ 0 ] );
  return $key eq 'due' && isDate( $value ) ? $value : 0;
}

sub isStartDate {
  my ( $key, $value ) = isKeyValue( $_[ 0 ] );
  return $key eq 't' && isDate( $value ) ? $value : 0;
}

# deals with completeness, priorities and dates at the start of a line
sub getFirstData {
  my ( $todo, $words ) = @_;

  if ( $words->[ 0 ] eq 'x' ) {
    $todo->{ 'completed' } = 1;
    shift @$words;

    if ( isDate( $words->[ 0 ] ) ) {
      $todo->{ 'completedOn' } = $words->[ 0 ];
      shift @$words;

      if ( isDate( $words->[ 0 ] ) ) {
        $todo->{ 'createdOn' } = $words->[ 0 ];
        shift @$words;
      }
    }
  }
  elsif ( isPriority( $words->[ 0 ] ) ) {
    $todo->{ 'priority' } = getPriorityValue( $words->[ 0 ] );
    shift @$words;

    if ( isDate( $words->[ 0 ] ) ) {
      $todo->{ 'createdOn' } = $words->[ 0 ];
      shift @$words;
    }
  }
  elsif ( isDate( $words->[ 0 ] ) ) {
    $todo->{ 'createdOn' } = $words->[ 0 ];
    shift @$words;
  }
}

sub getDaysLeft {
  my $due = Time::Piece->strptime( $_[ 0 ], "%Y-%m-%d" );
  my $now = localtime;

  my $diff = $due - $now;
  return $diff->days;
}

sub getImportance {
  my $todo = $_[ 0 ];

  my $importance = 2;

  $importance += $todo->{ 'priority' };

  # auto-viv is not a problem here
  $importance++ if $todo->{ 'tags' }->{ 'star' } == 1;

  if ( defined( $todo->{ 'tags' }->{ 'due' } ) ) {
    my $due = $todo->{ 'tags' }->{ 'due' };
    my $daysLeft = getDaysLeft( $due );

    $importance += 1 if ( $daysLeft > 7 && $daysLeft <= 14 );
    $importance += 2 if ( $daysLeft > 2 && $daysLeft <= 7 );
    $importance += 3 if ( $daysLeft > 1 && $daysLeft <= 2 );
    $importance += 5 if ( $daysLeft > 0 && $daysLeft <= 1 );
    $importance += 6 if ( $daysLeft < 0 );
  }

  return $importance;
}

sub parseLine {
  my $line = $_[ 0 ];

  my @words = split( " ", $line );
  my %todo;
  $todo{ 'src' } = $line;

  getFirstData( \%todo, \@words );

  while ( my $word = shift @words ) {
    my ( $key, $value ) = isKeyValue( $word );
    if ( $key ) {
      $todo{ 'tags' }->{ $key } = $value;
      next;
    }

    my $startDate = isStartDate( $word );
    if ( $startDate ) {
        $todo{ 'start' } = $word;
        next;
    }

    my $dueDate = isDueDate( $word );
    if ( $dueDate ) {
      $todo{ 'due' } = $word;
      next;
    }

    if ( isContext( $word ) ) {
      $todo{ 'context' }->{ getContext( $word ) } = 1;
    }
    elsif ( isProject( $word ) ) {
      $todo{ 'project' }->{ getProject( $word ) } = 1;
    }

    if ( defined( $todo{ 'description' } ) ) {
      $todo{ 'description' } .= ' ' . $word;
    }
    else {
      $todo{ 'description' } = $word;
    }
  }

  return \%todo;
}

my $count = 1;
while ( my $line = <> ) {
  $todos{ $count } = parseLine( $line );
  $count++;
}

foreach my $t ( sort { getImportance( $b ) <=> getImportance( $a ) } values %todos ) {
  print $t->{ 'src' };
}

exit 0;
