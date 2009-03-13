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

has parent => (
    is => 'ro',
    does => 'IsPlace',
    auto_deref => 1,
);

=head2 C<< ->enter >>

Broadcasts the message that an object enters this place
(or one of its subplaces)

=cut

#sub enter {
#    my ($self,$obj) = @_;
#};

=head2 C<< ->leave >>

Broadcasts the message that an object leaves this place
(or one of its subplaces)

=cut
#sub leave {};


1;