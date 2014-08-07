package RogueLike::Game;
#use Filter::signatures;
use strict;
use Moo;

use RogueLike::State;
use RogueLike::Loop;
use RogueLike::LevelDisplay;

has state => (
    is => 'ro',
    default => sub { RogueLike::State->new() },
);

has player => (
    is => 'rw',
    default => sub { RogueLike::Actor::Player->new() },
);

has loop => (
    is => 'ro',
    default => sub { RogueLike::Loop->new() },
);

has level => (
    is => 'ro',
    default => sub { RogueLike::Terrain->new() },
);


1;