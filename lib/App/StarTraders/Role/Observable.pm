package App::StarTraders::Role::Observable;
use strict;
use Moose::Role;

has observers => (
    is => 'rw',
    isa => 'ArrayRef',
    default => sub { [] },
);

sub notify {
    my ($self,$event,@args) = @_;
    for my $o (@{ $self->observers }) {
        $o->event($event,$self,@args);
    };
};

sub add_observer {
    my ($self, $observer) = @_;
    push @{ $self->observers }, $observer;
    weaken $self->observers->[-1];
};

1;