#!/usr/bin/env perl

# TodoTxt Tools
# Copyright (C) 2014 Bram Schoenmakers <me@bramschoenmakers.nl>

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

my $todos = TodoTxt::readTodos( $ARGV[ 0 ] );
foreach my $todo ( @$todos ) {
  TodoTxt::printTodo( $todo ) if TodoTxt::isOverdue( $todo );
}
