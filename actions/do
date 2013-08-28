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

use lib 'lib';
use TodoTxt;
use Depends;
use Recurrence;

sub usage {
  print STDERR "Usage: todo.sh do TASK#[,TASK#,...]\n";
  exit 1;
}

sub confirmDepsDone {
  my $subtasks = $_[ 0 ];

  print "Subtasks:\n";
  TodoTxt::printTodo( $_ ) foreach values %$subtasks;

  print "Also mark subtasks as done? [n] " ;
  my $answer = <STDIN>;

  return $answer =~ /^y(es)?$/i;
}

sub gatherDependencies {
  my $completed = $_[ 0 ];
  my %subtasks;

  map { $subtasks{ $_->{ 'num' } } = $_ } TodoTxt::getDependencies( $_ ) foreach @$completed;

  return \%subtasks;
}

sub executeTodoSh {
  my $command = $_[ 0 ];

  my $fullCommand = sprintf( "%s command %s", $ENV{ 'TODO_FULL_SH' }, $command );
  print `$fullCommand`;
}

usage() unless $ARGV[ 1 ] =~ /^\d+(,\d+)*$/;

my $force = $ENV{ 'TODOTXT_FORCE' };

my $filename = $ENV{ 'TODO_DIR' } . "/todo.txt";
TodoTxt::readTodos( $filename );

my @todos = map { TodoTxt::getTodo( $_ ) } split( ',', $ARGV[ 1 ] );

################
# Dependencies #
################

my $subtasks = gatherDependencies( \@todos );

if ( scalar keys %$subtasks && !$force && confirmDepsDone( $subtasks ) ) {
  map { $subtasks->{ $_->{ 'num' } } = $_ } @todos;
  @todos = values %$subtasks;
}

##############
# Recurrence #
##############

foreach my $todo ( grep { TodoTxt::hasTag( $_, 'rec' ) } @todos ) {
  my $newTodo = TodoTxt::advanceRecurrence( $todo );

  printf( "Recurring: %s", $todo->{ 'src' } . "\n" );

  executeTodoSh( sprintf( 'add "%s"', $newTodo->{ 'src' } ) );
}

################
# Mark as done #
################

executeTodoSh( "do " . join( ',', map { $_->{ 'num' } } @todos ) );;
