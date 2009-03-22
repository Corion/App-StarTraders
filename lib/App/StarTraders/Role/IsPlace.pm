package App::StarTraders::Role::IsPlace;
use strict;
use Moose::Role;
use List::AllUtils qw(uniq);

with 'App::StarTraders::Role::HasName';
#has '+name' => ( default => 'unnamed place' );

has children => (
    is => 'ro',
    isa => 'ArrayRef',
    default => sub { [] },
    auto_deref => 1,
);

has parent => (
    is => 'ro',
    #does => 'App::StarTraders::Role::IsPlace',
    #auto_deref => 1,
);

has is_visible => (
    is => 'ro',
    default => 1,
);

has ships => (
    is => 'ro',
    default => sub { [] },
    isa => 'ArrayRef',
    auto_deref => 1,
);

=head2 C<< ->siblings >>

Returns all the places at the same level, except itself

=cut

sub siblings {
    my ($self) = @_;
    grep { $self != $_ } $self->parent->children
};

sub can_release { 1 };
sub can_receive { 1 };


=head2 C<< ->enter($place,$obj) >>

Called when an object enters this place
(or one of its subplaces)

=cut

sub enter {
    my ($self,$place,$obj) = @_;
};

=head2 C<< ->leave($place,$obj) >>

Called when an object leaves this place
(or one of its subplaces)

=cut

sub leave {
    my ($self,$place,$obj) = @_;
};

=head2 C<< ->arrive($obj) >>

Called when an object enters this place

=cut

sub arrive {
    my ($self,$obj) = @_;
    #$self->notify_observers('arrive',$self,$obj);
    $obj->position($self);
    @{ $self->{ships}} = uniq( @{ $self->{ships}}, $obj );
};

=head2 C<< ->can_arrive($obj) >>

Returns true if $obj can arrive at this place

=cut

sub can_arrive {
    my ($self,$obj) = @_;
    1
};

=head2 C<< ->depart($obj) >>

Called when an object leaves this place

=cut

sub depart {
    my ($self,$obj) = @_;
    #$self->notify_observers('leave',$self,$obj);
    @{ $self->{ships}} = grep { $obj ne $_ } @{ $self->{ships}};
};

=head2 C<< ->can_depart($obj) >>

Returns true if $obj can depart from this place

=cut

sub can_depart {
    my ($self,$obj) = @_;
    1
};

1;