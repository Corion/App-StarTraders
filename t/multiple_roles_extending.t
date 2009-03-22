package App::StarTraders::Role::HasName;
use strict;
use Moose::Role;

has name => (
    is => 'rw',
    isa => 'Str',
    default => 'unnamed entity',
);

1;

package App::StarTraders::Role::IsPlace;
use strict;
use Moose::Role;

with 'App::StarTraders::Role::HasName';
has '+name' => ( default => 'unnamed place' );

has children => (
    is => 'ro',
    isa => 'ArrayRef',
    default => sub { [] },
    auto_deref => 1,
);

1;

package App::StarTraders::Planet;
use strict;
use Moose;

#with 'App::StarTraders::Role::HasName';
with 'App::StarTraders::Role::IsPlace';

has '+name' => ( default => 'unnamed planet' );

no Moose;
__PACKAGE__->meta->make_immutable;

1;

package main;

my $planet_x = App::StarTraders::Planet->new();
my $earth = App::StarTraders::Planet->new( name => 'Earth' );

for ($planet_x,$earth) {
    print $_->name,"\n";
};