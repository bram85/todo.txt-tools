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

use strict;

use Depends;
use TodoTxt;

sub getDependencies {
  my $todo = $_[ 0 ];
  return grep { $_ != 0 } map { TodoTxt::taskExistsHavingId( $_ ) } @{ $todo->{ 'tags' }->{ 'dep' } }
}

sub inCycle {
  my $root = $_[ 0 ];

  my %visited;
  $visited{ $root->{ 'src' } } = 1;

  my @queue = getDependencies( $root );
  while ( @queue ) {
    my $todo = shift @queue;

    return 1 if $todo->{ 'src' } eq $root->{ 'src' };
    next if defined( $visited{ $todo->{ 'src' } } );

    $visited{ $todo->{ 'src' } } = 1;

    @queue = ( @queue, getDependencies( $todo ) );
  }

  return 0;
}

sub hasUnfinishedDependencies {
  my $todo = $_[ 0 ];

  return grep { !defined( $_->{ 'completed' } ) || $_->{ 'completed' } == 0 } getDependencies( $todo );
}

# print if todo:
# * appears in a cycle
# * there are no unfinished todos on which it depends

my $todos = TodoTxt::readTodos( $ARGV[ 0 ] );
foreach my $todo ( @$todos ) {
  next if hasUnfinishedDependencies( $todo ) && !inCycle( $todo );

  print $todo->{ 'src' };
}
