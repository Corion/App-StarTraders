package App::StarTraders::Role::Observer;
use strict;
use Moose::Role;

has observed => (
    is => 'rw',
    isa => 'ArrayRef',
    default => sub { [] },
);

sub event {
    my ($self,$event,$actor,@args) = @_;
};

sub observe {
    my ($self,$observed) = @_;
    push @{ $self->observed }, $observed; # should be a bag ...
    $observed->add_observer($self);
};

1;