#!/usr/bin/perl

use strict;

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

my $todos = TodoTxt::getTodos();
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

