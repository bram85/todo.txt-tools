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

use File::Spec;

use lib 'lib';
use TodoTxt;

sub usage {
  print STDERR <<END;
Usage: todo.sh tag ITEM# [TAGNAME [VALUE]]";

       When TAGNAME and VALUE are omitted, the list of tags will be shown.
       When VALUE is omitted, the tag will be deleted.
END

  exit 1;
}

sub listTags {
  my $todo = $_[ 0 ];
  my $tags = $todo->{ 'tags' };

  my $maxLength = 0;
  foreach my $key ( keys %$tags ) {
    my $length = length( $key );
    $maxLength = $length if $length > $maxLength;
  }

  foreach my $key ( sort keys %$tags ) {
    my $padding = "";
    $padding = " " x ( $maxLength - length( $key ) );

    my $values = $tags->{ $key };
    printf( "%s%s = %s\n", $key, $padding, $_ ) foreach @$values;
  }
}

sub modifyTag {
  my ( $todo, $key, $value ) = @_;

  my @currentValues = TodoTxt::getTagValues( $todo, $key );
  if ( @currentValues > 1 ) {
    print STDERR "Cannot modify a tag which occurs multiple times in todo item.\n";
    exit 1;
  }

  TodoTxt::setTagValue( $todo, $key, $value );
}

sub confirmDelete {
  my $tag = $_[ 0 ];

  print "Delete all occurences of tag '$tag' in this item? [n] ";
  my $answer = <STDIN>;
  chomp $answer;

  return $answer =~ /^y(es)?$/i;
}

my $taskNumber = $ARGV[ 1 ];
usage() if $taskNumber !~ /^\d+$/;

my ( $key, $value ) = TodoTxt::isKeyValue( $ARGV[ 2 ] );
if ( !$key ) {
  $key = $ARGV[ 2 ];
  $value = $ARGV[ 3 ];
}

my $force = $ENV{ 'TODOTXT_FORCE' };

my $filename = $ENV{ 'TODO_DIR' } . "/todo.txt";
TodoTxt::readTodos( $filename );

my $todo = TodoTxt::getTodo( $taskNumber );
die "Item $taskNumber does not exist." unless $todo;

my $hasTag = TodoTxt::hasTag( $todo, $key );

if ( !defined( $key ) && !defined( $value ) ) {
  listTags( $todo );
  exit 0;
}
elsif ( !$hasTag && defined( $value ) ) {
  TodoTxt::addTag( $todo, $key, $value );
  TodoTxt::printTodo( $todo );
}
elsif( TodoTxt::hasTag( $todo, $key ) ) {
  if ( defined( $value ) ) {
    modifyTag( $todo, $key, $value );
    TodoTxt::printTodo( $todo );
  }
  else {
    TodoTxt::removeTag( $todo, $key ) if $force || confirmDelete( $key );
    TodoTxt::printTodo( $todo );
  }
}
else {
  print STDERR "Tag $key does not exist.\n";
}

TodoTxt::writeTodos( $filename );

