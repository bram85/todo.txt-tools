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

sub taskExistsHavingId {
  my $id = $_[ 0 ];

  my $todos = TodoTxt::getTodos();
  my @result = grep { $_->{ 'tags' }->{ 'id' }->[ 0 ] == $id } @$todos;

  return 0 unless @result;

  # there is only one such task, return first one
  return $result[ 0 ];
}

sub getNewID {
  my $i = 1;
  while ( taskExistsHavingId( $i ) ) {
    $i++;
  }

  return $i;
}

sub getID {
  my $todo = $_[ 0 ];
  my $values = TodoTxt::getTagValues( $todo, "id" );

  return 0 unless $values;
  return $values->[ 0 ];
}

sub assignID {
  my $todo = $_[ 0 ];

  my $id = getNewID();
  TodoTxt::addTag( $todo, 'id', $id );
  return $id;
}

sub tasksReferringToId {
  my $id = $_[ 0 ];

  my $todos = TodoTxt::getTodos();
  return grep {
    my $deps = $_->{ 'tags' }->{ 'dep' };
    grep { $_ eq $id } @$deps;
  } @$todos;
}

sub addDependency {
  my ( $fromTask, $toTask ) = @_;

  my $toId = getID( $toTask ) || assignID( $toTask );

  TodoTxt::addTag( $fromTask, "dep", $toId );
}

sub removeDependency {
  my ( $fromTask, $toTask ) = @_;

  my $toId = getID( $toTask );
  TodoTxt::removeTag( $fromTask, 'dep', $toId );

  TodoTxt::removeTag( $toTask, 'id' ) unless tasksReferringToId( $toId );
}

sub getDependencies {
  my $todo = $_[ 0 ];
  return map { taskExistsHavingId( $_ ) } @{$todo->{ 'tags' }->{ 'dep' }}
}

1;
