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

use Getopt::Std;
use Time::Piece;

use lib 'lib';
use Importance;
use TodoTxt;

my %option;
getopts( "s:", \%option );

my @sortOrder = ( 'priority' );
@sortOrder = split( ",", $option{ 's' } ) if defined( $option{ 's' } );

# default to sort by priority
push( @sortOrder, 'desc:priority' ) unless scalar @sortOrder;

sub isDescending {
  return $_[ 0 ] =~ /^desc:/;
}

sub getSortItem {
  ( my $sortItem = $_[ 0 ] ) =~ /^((asc|desc):)?([\w-]+)$/;
  return $3;
}

sub sortOnOptionalField {
  my ( $field, $a, $b ) = @_;
  my $result = 0;

  if ( defined( $a->{ $field } ) && defined( $b->{ $field } ) ) {
    $result = $a->{ $field } cmp $b->{ $field };
  }
  elsif ( defined( $a->{ $field } ) ) {
    $result = -1;
  }
  else {
    $result = 1;
  }

  return $result;
}

sub swapSortResult {
  return -1 if $_[ 0 ] == 1;
  return 1 if $_[ 0 ] == -1;
  return 0;
}

sub sortOnPriority {
  my ( $a, $b ) = @_;

  # swap because priority value is inverse to charecter value
  return swapSortResult( sortOnOptionalField( "priority", $a, $b ) );
}

sub sortTodos {
  my $result = 0;
  foreach my $rawSortItem ( @sortOrder ) {
    my $sortItem = getSortItem( $rawSortItem );

    # no switch/given statement, I need to run this on ancient Perl.
    $result = TodoTxt::getImportance( $a, 0 ) <=> TodoTxt::getImportance( $b, 0 )         if $sortItem eq 'importance';
    $result = TodoTxt::getImportance( $a, 1 ) <=> TodoTxt::getImportance( $b, 1 )         if $sortItem eq 'importance-no-wknd';
    $result = TodoTxt::getDaysLeft( $a ) <=> TodoTxt::getDaysLeft( $b ) if $sortItem eq 'due';
    $result = sortOnOptionalField( "description" )                      if $sortItem eq 'description';
    $result = sortOnPriority( $a, $b )                                  if $sortItem eq 'priority';
    $result = sortOnOptionalField( "createdOn", $a, $b )                if $sortItem eq 'creation';
    $result = sortOnOptionalField( "start", $a, $b )                    if $sortItem eq 'start' || $sortItem eq 't';

    $result = swapSortResult( $result ) if isDescending( $rawSortItem );

    last if $result;
  }

  return $result;
}

my $todos = TodoTxt::readTodos( $ARGV[ 0 ] );
foreach my $t ( sort sortTodos @$todos ) {
  TodoTxt::printTodo( $t );
}

exit 0;
