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

use TodoTxt;

sub getTaskByID {
  my $id = $_[ 0 ];

  my $todos = TodoTxt::getTodos();
  my @result = grep { TodoTxt::getTagValue( $_, 'id' ) eq $id } @$todos;

  # there is only one such task, return first one
  return @result ? $result[ 0 ] : 0;
}

sub getNewID {
  my $i = 1;
  while ( getTaskByID( $i ) ) {
    $i++;
  }

  return $i;
}

sub getID {
  my $todo = $_[ 0 ];
  my $values = TodoTxt::getTagValues( $todo, "id" );

  return $values ? $values->[ 0 ] : 0;
}

sub assignID {
  my $todo = $_[ 0 ];

  my $id = getNewID();
  TodoTxt::addTag( $todo, 'id', $id );
  return $id;
}

sub getDependencies {
  my $todo = $_[ 0 ];
  my $id = TodoTxt::getTagValue( $todo, 'id' );

  return () unless defined( $id );

  my $todos = TodoTxt::getTodos();
  return grep { TodoTxt::hasTagValue( $_, 'p', $id ) } @$todos;
}

sub addDependency {
  my ( $fromTask, $toTask ) = @_;

  my $fromId = getID( $fromTask ) || assignID( $fromTask );

  TodoTxt::addTag( $toTask, "p", $fromId );
}

sub removeDependency {
  my ( $fromTask, $toTask ) = @_;

  my $fromId = getID( $fromTask );
  TodoTxt::removeTag( $toTask, 'p', $fromId );

  TodoTxt::removeTag( $fromTask, 'id' ) unless getDependencies( $fromTask );
}

1;
