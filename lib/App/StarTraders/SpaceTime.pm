package App::StarTraders::SpaceTime;
use strict;
use Moose;

has systems => (
    is => 'ro',
    isa => 'ArrayRef',
    default => sub { [] },
    auto_deref => 1,
);

has wormholes => (
    is => 'ro',
    isa => 'ArrayRef',
    default => sub { [] },
    auto_deref => 1,
);

no Moose;
use App::StarTraders::StarSystem;
use App::StarTraders::Worm;

sub add_system {
    my $self = shift; 
    push @{ $self->{systems}}, @_
};

sub new_system {
    my $self = shift; 
    my $s = App::StarTraders::StarSystem->new( @_ );
    $self->add_system($s)
};

sub add_wormhole {
    my $self = shift; 
    push @{ $self->{wormholes}}, @_
};

sub new_wormhole {
    my ($self,$s1,$s2) = @_;
    
    if (! ref $s1) { $s1 = $self->{systems}->[$s1] };
    if (! ref $s2) { $s2 = $self->{systems}->[$s2] };
    
    my $w = App::StarTraders::Worm->connect($s1,$s2);
    $self->add_wormhole($w);
};

sub find_planet {
    my ($self,@names) = @_;
    my %names; @names{ @names } = (undef) x (0+@names);
    my @result;
    for my $system ($self->systems) {
        for my $pl ($system->planets) {
            if (exists $names{ $pl->name }) {
                $names{ $pl->name } = $pl
            };
        };
    };
    wantarray
    ? @names{ @names }
    : $names{ $names[0] }
};

1;