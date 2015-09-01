#!perl -w
package main;
use strict;
use lib 'lib';
use Filter::signatures;
use feature 'signatures';

use MyPoker::GameDisplay;
use MyPoker::Game;
use MyPoker::Actor;

my $display= MyPoker::GameDisplay->new();

my $g= MyPoker::Game->new;
$g->loop->running(1);

# Add the dealer, which is the "game master"
# For each round, add the active players
# A round keeps going as long as there is more than one active player
# The game ends when there is no active player anymore

my $dealer= MyPoker::Actor::Dealer->new(
);

# Should have a way to randomize the player positions
my $player= RogueLike::Actor::Player->new(
    position => undef,
    name => 'PlayerOne',
    avatar => 'O',
);

my $player2= RogueLike::Actor::Player->new(
    position => undef,
    name => 'PlayerTwo',
    avatar => 'Q',
);

$g->state->add_actor( $dealer, $player, $player2 );

# This should basically become its own class, the "input provider"
my %keymap= (
    # fold
    'f' => sub { ... },
    # check/call
    'c' => sub { ... },
    # raise/bet
    'r' => sub { ... },
    'b' => sub { ... },
    # toggle autofold
    'a' => sub { ... },
);

sub handle_input( $input ) {
    if( my $new_action= $keymap{ $input }) {
        my $act= $new_action->();
        return $act;
    } else {
        print "Unknown key: $input\n";
        return;
    };
};

my @need_input;
while( $g->loop->running ) {
    my $time= $g->loop->gametime;

    #warn sprintf "%d players need input", 0+@need_input;
    for my $player (@need_input) {
        my $name= $player->name;
        my $level= $player->dungeon_level;
        use Data::Dumper;
        die "Player $name without a dungeonlevel ?!" . Dumper $player unless $level;
        $display->draw( $g->state, $level );

        my $e= $player->energy;
        my $lv= $level->terrain->name;
        my $d= $level->depth;
        print "$lv:$d | $e $time $name: Action>";
        my $action= <>;
        chomp $action;
        $action= handle_input( $action );

        $player->next_action( $action )
            if $action;
    };

    @need_input= $g->loop->process_all( $g->state );
};
