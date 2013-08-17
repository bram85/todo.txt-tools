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

use lib 'lib';
use TodoTxt;

# A todo item is relevant iff:
#
# The item has not been completed, AND
#
# The start date is blank, today or in the past, AND one of the following conditions:
#
# * The priority is (A).
#
# * The priority is (B) and due date is within 30 days.
#
# * The priority is (C) or lower and due date is within 14 days.
#
# * There is no due date

my $todos = TodoTxt::readTodos( $ARGV[ 0 ] );
foreach my $todo ( @$todos ) {
  next if $todo->{ 'completed' };
  next if !TodoTxt::isActive( $todo );

  next if $todo->{ 'priority' } eq 'B'
       && TodoTxt::hasDueDate( $todo )
       && TodoTxt::getDaysLeft( $todo ) > 30;

  next if ( $todo->{ 'priority' } ne 'A' && $todo->{ 'priority' } ne 'B' )
       && TodoTxt::hasDueDate( $todo )
       && TodoTxt::getDaysLeft( $todo ) > 14;

  print $todo->{ 'src' };
}

