#!/usr/bin/perl

package TodoTxt;

use strict;
use Time::Piece;
use Time::Seconds;

my %todos;

sub isPriority {
  return $_[ 0 ] =~ /^\([A-Z]\)$/;
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
    $words->[ 0 ] =~ /\((.)\)/;
    $todo->{ 'priority' } = $1;
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

sub hasStartDate {
  return defined( $_[ 0 ]->{ 'start' } );
}

sub hasDueDate {
  return defined( $_[ 0 ]->{ 'due' } );
}

sub isOverdue {
  my $todo = $_[ 0 ];
  return !hasDueDate( $todo ) || getDaysLeft( $todo->{ 'due' } ) < 0;
}

sub isActive {
  my $todo = $_[ 0 ];
  return !hasStartDate( $todo ) || getDaysLeft( $_[ 0 ]->{ 'start' } ) < 0;
}

sub hasPriority {
  my $todo = $_[ 0 ];
  return defined( $_[ 0 ]->{ 'priorityText' } );
}

sub parseLine {
  my $line = $_[ 0 ];

  my @words = split( " ", $line );
  my %todo;
  $todo{ 'src' } = $line;

  getFirstData( \%todo, \@words );

  while ( my $word = shift @words ) {
    my ( $key, $value ) = isKeyValue( $word );
    $todo{ 'tags' }->{ $key } = $value if $key;

    my $startDate = isStartDate( $word );
    $todo{ 'start' } = $startDate if $startDate;

    my $dueDate = isDueDate( $word );
    $todo{ 'due' } = $dueDate if $dueDate;

    next if $key; # it was some other key:value, we got it

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

sub getTodos {
  return \%todos;
}

my $count = 1;
while ( my $line = <> ) {
  $todos{ $count } = parseLine( $line );
  $count++;
}

1;
