package RogueLike::Game;
#use Filter::signatures;
use strict;
use Moo::Lax;

use RogueLike::State;
use RogueLike::Loop;

has state => (
    is => 'ro',
    default => sub { RogueLike::State->new() },
);

has loop => (
    is => 'ro',
    default => sub { RogueLike::Loop->new() },
);


1;