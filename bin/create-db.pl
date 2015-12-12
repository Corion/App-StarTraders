#!/usr/bin/perl -w
use strict;
use lib 'lib';
use DBIx::RunSQL;

# XXX Should read config.yml to find out default values for the DB etc.
DBIx::RunSQL->handle_command_line(
    'RogueLike',
);

=head1 NAME

create-db.pl - Create the database

=head1 ABSTRACT

This sets up the database. The following
options are recognized:

=over 4

=item C<--user> USERNAME

=item C<--password> PASSWORD

=item C<--dsn> DSN

The DBI DSN to use for connecting to
the database

=item C<--sql> SQLFILE

The alternative SQL file to use
instead of C<sql/create.sql>.

=item C<--force>

Don't stop on errors

=item C<--help>

Show this message.

=cut