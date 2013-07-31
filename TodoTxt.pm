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

package TodoTxt;

use strict;
use POSIX;
use Time::Piece;
use Time::Seconds;

my @todos;

sub getTodo {
  my $taskNumber = $_[ 0 ];
  return $taskNumber > 0 && $taskNumber <= scalar @todos ? $todos[ $taskNumber - 1 ] : 0;
}

sub parseDate {
  return Time::Piece->strptime( $_[ 0 ], "%Y-%m-%d" );
}

sub isPriority {
  return $_[ 0 ] =~ /^\([A-Z]\)$/;
}

sub isDate {
  return $_[ 0 ] =~/^\d{4}-\d{2}-\d{2}$/;
}

sub isKeyValue {
  return $_[ 0 ] =~ /^([\w-]+):([\w-]+)\W*$/ ? ( $1, $2 ) : 0;
}

sub isContext {
  return $_[ 0 ] =~ /^@/;
}

sub getContext {
  $_[ 0 ] =~ /^@([\w-]+)\W*$/;
  return $1;
}

sub isProject {
  return $_[ 0 ] =~ /^\+/;
}

sub getProject {
  $_[ 0 ] =~ /^\+([\w-]+)\W*$/;
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

  # remove task number
  shift @$words if defined( $ENV{'TODOTXT_VERBOSE'} );

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

sub getDaysDiff {
  my $due = parseDate( $_[ 0 ] );
  my $now = localtime;

  my $diff = $due - $now;
  return ceil( $diff->days );
}

sub getDaysLeft {
  my $todo = $_[ 0 ];
  return getDaysDiff( $todo->{ 'due' } );
}

sub hasStartDate {
  return defined( $_[ 0 ]->{ 'start' } );
}

sub hasDueDate {
  return defined( $_[ 0 ]->{ 'due' } );
}

sub hasTag {
  my ( $todo, $key ) = @_;

  return defined( $todo->{ 'tags' } )
      && defined( $todo->{ 'tags' }->{ $key } );
}

sub hasTagValue {
  my ( $todo, $key, $value ) = @_;

  return hasTag( $todo, $key )
      && grep { $_ eq $value } @{$todo->{ 'tags' }->{ $key }};
}

sub getTagValues {
  my ( $todo, $key ) = @_;

  return 0 unless hasTag( $todo, $key );
  return $todo->{ 'tags' }->{ $key };
}

sub isOverdue {
  my $todo = $_[ 0 ];
  return !hasDueDate( $todo ) || getDaysLeft( $todo ) < 0;
}

sub isActive {
  my $todo = $_[ 0 ];
  return !hasStartDate( $todo ) || getDaysDiff( $todo->{ 'start' } ) <= 0;
}

sub hasPriority {
  my $todo = $_[ 0 ];
  return defined( $_[ 0 ]->{ 'priorityText' } );
}

sub addTag {
  my ( $todo, $key, $value ) = @_;

  return if hasTagValue( $todo, $key, $value );

  $todo->{ 'src' } =~ s/$/ $key:$value/;
  push( @{$todo->{ 'tags' }->{ $key }}, $value );
}

sub removeTag {
  my ( $todo, $key, $value ) = @_;

  if ( defined( $value ) ) {
    $todo->{ 'src' } =~ s/\s?$key:$value\b//g;
  }
  else {
    $todo->{ 'src' } =~ s/\s?$key:\S+\b//g;
  }

  my $values = $todo->{ 'tags' }->{ $key };
  @$values = grep { $_ ne $value } @$values;
  delete $todo->{ 'tags' }->{ $key } unless @$values;
}

sub modifyTag {
  my ( $todo, $key, $value ) = @_;

  $todo->{ 'src' } =~ s/\b$key:\S+\b/$key:$value/;
  $todo->{ 'tags' }->{ $key } = $value;
}

sub parseLine {
  my $line = $_[ 0 ];

  my @words = split( " ", $line );
  map { s/\e\[?.*?[\@-~]//g } @words; # strip ANSI codes

  my %todo;
  $todo{ 'src' } = $line;

  getFirstData( \%todo, \@words );

  while ( my $word = shift @words ) {
    my ( $key, $value ) = isKeyValue( $word );
    push( @{$todo{ 'tags' }->{ $key }}, $value ) if $key;

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
  return \@todos;
}

sub readTodos {
  my $filename = $_[ 0 ];

  my $fh;
  if ( defined( $filename ) ) {
    open( $fh, "<$filename" ) or die "Cannot open $filename.";
  } else {
    $fh = *STDIN;
  }

  my $i = 1;
  while ( my $line = <$fh> ) {
    my $todo = parseLine( $line );
    $todo->{ 'num' } = $i++;

    push( @todos, $todo );
  }

  close( $fh ) if defined( $filename );

  return \@todos;
}

sub writeTodos {
  my $filename = $_[ 0 ];

  my $fh;
  if ( defined( $filename ) ) {
    open( $fh, ">$filename" ) or die "Cannot write to $filename.";
  } else {
    $fh = *STDOUT;
  }

  print $fh $_->{ 'src' } foreach @todos;

  close( $fh ) if defined( $filename );;
}

1;
