todo.txt-tools
==============

This repository contains a few scripts for extending the [todo.txt CLI][1]. It
works on todo.txt files following the [standard format][3], and uses the
following extensions:

* Due dates are indicated by due:YYYY-MM-DD
* Start dates are indicated by t:YYYY-MM-DD
* 'Starring' a task is done by star:1

What's inside?
--------------

### actions/tag

*tag* is an extension for the todo.sh CLI, to easily list, add, modify or
remove key:value pairs from tasks.

The synopsis is:

    todo.sh tag TASK# [TAGNAME [TAGVALUE]]

If you give both a *TAGNAME* and *TAGVALUE*, but *TAGNAME* does not exist yet,
the tag will be added to the given task. If *TAGNAME* already exists, the tag
value will be changed. If no *TAGVALUE* is given, the tag will be removed from
the task.
Without a *TAGNAME* and *TAGVALUE*, a list of tags and their values will be
printed.

### filter-relevance.pl

*filter-relevance.pl* hides tasks which are not relevant at this moment. A task
is considered relevant if all of the following conditions apply:

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

### sort.pl

*sort.pl* sorts the tasks in your todo.txt file. By default it sorts your tasks
based on priority (descending), but you can specify your own sort order based
on various fields. You can specify the sort order using the *-s* flag and a
comma separated list of fields to sort on. The following fields are supported:

* creation
* description
* due
* importance (defined below)
* importance-no-wknd
* priority
* start (or just t)

You can prefix each field with asc: or desc: for ascending or descending sort
respectively. For instance you can invoke *sort.pl* as follows:

    ./sort.pl -s desc:importance,asc:creation

Note that asc: is the default so it is not necessary to write it down
explicitly.

#### Importance ####

Importance is a derived field based on the priority, due date and the fact
whether a task is 'starred'. Those who used the [Toodledo][2] task manager may
recognize this. The metric is defined as *2 + P + S + D* where:

* P is the priority (A=3, B=2, C=1, otherwise value 0, you can adjust the hash
  at the top of *sort.pl* to override)
* S is 1 if the task is starred. This is an attribute used within Toodledo to
  raise extra attention to a certain task, the importance value would be
  increased by one. You can emulate this in your todo.txt file by adding the
  star:1 tag to your item.
* D depends on the due date:
    * 0 there is no due date or more than 14 days ahead in the future;
    * 1 if the due date is within 7 and 14 days;
    * 2 if the due date is within 2 and 7 days;
    * 3 if the due date is tomorrow;
    * 5 if the due date is today;
    * 6 if the task is overdue.

*importance-no-wknd* can be used to ignore weekends when calculating the
importance of a task. Assume it's Friday today and there's a task due next
Monday, then that task will be treated as if it had to be done tomorrow.

How to use
----------

You can use these scripts as standalone sorters and filters, or you can hook
them to the todo.txt CLI.

### Standalone

For example:

    ./sort.pl todo.txt

    cat todo.txt | ./filter-relevance.pl | ./sort.pl -s desc:due

### todo.sh CLI

Adjust your *todo.cfg* file to use these scripts:

    export TODOTXT_SORT_COMMAND='/path/to/sort.pl -s desc:due,desc:priority'
    export TODOTXT_FINAL_FILTER='/path/to/filter-relevance.pl'

To use an todo.sh extension (such as *tag*), put it in ~/.todo.actions.d or
specify a folder in *todo.cfg*.





[1]: https://github.com/ginatrapani/todo.txt-cli
[2]: http://www.toodledo.com/info/help.php?sel=53
[3]: https://github.com/ginatrapani/todo.txt-cli/wiki/The-Todo.txt-Format
