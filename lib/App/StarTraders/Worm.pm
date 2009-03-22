package App::StarTraders::Worm;
use strict;
use Moose;
use App::StarTraders::Wormhole;
use App::StarTraders::WormholeExit;

has tails => (
    is => 'ro',
    isa => 'ArrayRef',
    auto_deref => 1,
    default => sub { [] },
);

no Moose;
__PACKAGE__->meta->make_immutable;

sub tail {
    my ($self,$head) = @_;
    (my $end) = grep { $_ != $head or $_ ne $head } $self->tails;
    $end
};

sub connect {
    my ($class,$s1,$s2) = @_;
    
    # Should this go into BUILDPARAMS?
    my $start1 = App::StarTraders::Wormhole->new( system => $s1 );
    my $end1 = App::StarTraders::WormholeExit->new( system => $s2 );

    my $start2 = App::StarTraders::Wormhole->new( system => $s2 );
    my $end2 = App::StarTraders::WormholeExit->new( system => $s1 );

    my $self = $class->new(
        tails => [ $end1, $end2 ]
    );
    for ($start1,$end1,$start2,$end2) {
        $_->worm($self);
    };

    $s1->add_wormhole($start1);
    $s2->add_wormhole($start2);
    $self
};

1;