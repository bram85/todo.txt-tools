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

use Storable;
use Time::Piece;

use lib 'lib';
use TodoTxt;

sub getLength {
  my $todo = $_[ 0 ];

  return 0 unless hasStartDate( $todo ) && hasDueDate( $todo );

  my $start = TodoTxt::parseDate( $todo->{ 'start' } );
  my $due = TodoTxt::parseDate( $todo->{ 'due' } );

  return getDateDifference( $start, $due );
}

sub advanceRecurrence {
  my $todo = $_[ 0 ];
  my $clone = Storable::dclone( $todo );

  my $recurrence = TodoTxt::getTagValue( $todo, 'rec' );

  my $newDueDate = TodoTxt::convertRelativeDate( $recurrence );

  if ( hasStartDate( $todo ) ) {
    my $newStartDate = $newDueDate - DAY * getLength( $todo );
    TodoTxt::setStartDate( $clone, $newStartDate->ymd );
  }

  TodoTxt::setDueDate( $clone, $newDueDate->ymd );

  return $clone;
}

1;
