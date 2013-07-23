todo.txt-tools
==============

This repository contains a few scripts for extending the [todo.txt CLI][1]. It
works on todo.txt files following the [standard format][3], and uses the
following extensions:

* Due dates are indicated by due:YYYY-MM-DD
* Start dates are indicated by t:YYYY-MM-DD
* 'Starring' a task is done by star:1

As an assumption, the priorities taken into consideration are A, B and C.
Priorities D till Z are treated equally, as far as these tools are concerned.

What do these scripts do?
-------------------------

* *sort-importance.pl* sorts tasks by their importance, a derived metric as
  found in the [Toodledo][2] task manager. It is defined as 2 + P + S + D
  where:

    * P is the priority (A=3, B=2, C=1, otherwise value 0)
    * S is 1 if the task is starred. This is an attribute used within Toodledo
      to raise extra attention to a certain task, the importance value would be
      increased by one. You can emulate this in your todo.txt file by adding
      the star:1 tag to your item.
    * D depends on the due date:
        * 0 there is no due date or more than 14 days ahead in the future;
        * 1 if the due date is within 7 and 14 days;
        * 2 if the due date is within 2 and 7 days;
        * 3 if the due date is tomorrow;
        * 5 if the due date is today;
        * 6 if the task is overdue.

  The tasks are sorted (descending) based on their importance. When the
  importance of two tasks is equal, tasks are sorted by due date and then by
  priority (descending).

  The sort command accepts a single optional flag -w. When given, weekends are
  ignored when calculating the importance of a task. Assume it's Friday today
  and there's a task due next Monday, then that task will be treated as if it had
  to be done tomorrow.

* *filter-relevance.pl* hides tasks which are not relevant at this moment. A
  task is considered relevant if all of the following conditions apply:

    * It has not been completed yet;
    * The start date is undefined, today or in the past;
    * One of the following conditions apply:
        * The task has priority A;
        * The task has priority B and a due date within 30 days;
        * The task has priority C or lower and is due within 14 days;
        * The task has no due date.

    This means that you won't be bothered by unimportant tasks far ahead in the
    future. Moreover, tasks with no priority are hidden. This is based on the
    assumption that all tasks that deserve your attention have a priority
    assigned to them.

How to use
----------

Download / clone this repository and adjust your todo.cfg file to use these scripts:

    export TODOTXT_SORT_COMMAND='/path/to/sort-importance.pl'
    export TODOTXT_FINAL_FILTER='/path/to/filter-relevance.pl'

Of course, it's not required to use both, the scripts are independent. And it's
also possible to run the scripts without the todo.txt CLI:

    ./filter-relevance.pl /path/to/todo.txt

[1]: https://github.com/ginatrapani/todo.txt-cli
[2]: http://www.toodledo.com/info/help.php?sel=53
[3]: https://github.com/ginatrapani/todo.txt-cli/wiki/The-Todo.txt-Format
