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

sub taskExistsDependingOnID {
  my $id = $_[ 0 ];

  my $todos = TodoTxt::getTodos();
  my @result = grep { TodoTxt::getTagValue( $_, 'p' ) eq $id } @$todos;

  return @result;
}

sub getNewID {
  my $i = 1;
  while ( getTaskByID( $i ) || taskExistsDependingOnID( $i ) ) {
    $i++;
  }

  return $i;
}

sub assignID {
  my $todo = $_[ 0 ];

  my $id = getNewID();
  TodoTxt::addTag( $todo, 'id', $id );
  return $id;
}

sub todoEquals {
  my ( $todo1, $todo2 ) = @_;
  return $todo1->{ 'num' } == $todo2->{ 'num' };
}

sub arrayHasTodo {
  my ( $array, $todo ) = @_;

  return grep { todoEquals( $_, $todo ) } @$array;
}

sub getDependencies {
  my $root = $_[ 0 ];
  my $recursive = defined( $_[ 1 ] ) ? $_[ 1 ] : 1;

  my @result = ();
  my @stack = ( $root );
  $root->{ 'level' } = 0;

  my $todos = TodoTxt::getTodos();

  while ( @stack ) {
    my $todo = pop @stack;
    my $id = TodoTxt::getTagValue( $todo, 'id' );

    next unless $id;

    my @newDeps = grep { TodoTxt::hasTagValue( $_, 'p', $id ) } @$todos;

    foreach my $newDep ( reverse @newDeps ) {
      unless ( todoEquals( $root, $newDep ) || arrayHasTodo( \@result, $newDep ) ) {
        push( @result, $newDep );
        $newDep->{ 'level' } = $todo->{ 'level' } + 1;
        push( @stack, $newDep );
      }
    }

    last unless $recursive;
  }

  return @result;
}

sub getDirectDependencies {
  return getDependencies( $_[ 0 ], 0 );
}

sub addDependency {
  my ( $fromTask, $toTask ) = @_;

  my $fromId = TodoTxt::getTagValue( $fromTask, "id" ) || assignID( $fromTask );

  TodoTxt::addTag( $toTask, "p", $fromId );
}

sub removeDependency {
  my ( $fromTask, $toTask ) = @_;

  my $fromId = TodoTxt::getTagValue( $fromTask, "id" );
  TodoTxt::removeTag( $toTask, 'p', $fromId );

  TodoTxt::removeTag( $fromTask, 'id' ) unless getDirectDependencies( $fromTask );
}

sub pathExists {
  my ( $from, $to ) = @_;
  return grep { $_->{ 'src' } eq $to->{ 'src' } } getDependencies( $from );
}

1;
