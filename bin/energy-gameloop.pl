#!perl -w
package main;
use strict;
use lib 'lib';
use Filter::signatures;
use feature 'signatures';

use RogueLike::LevelDisplay;
use RogueLike::Game;
use RogueLike::Actor;

my $display= RogueLike::LevelDisplay->new();

my $g= RogueLike::Game->new;
$g->loop->running(1);

# Add a way for the player to move
# Add a player
# Add a rock that continously moves eastwards
# Add an inert rock
my $rock= RogueLike::Actor::Rock->new(
    position => [ 3,3 ],
);

my $player= RogueLike::Actor::Player->new(
    position => [ 5,3 ],
);

my $player2= RogueLike::Actor::Player->new(
    position => [ 7,3 ],
    name => 'PlayerTwo',
    avatar => 'Q',
);

$g->player( $player );

$g->state->add_actor( $rock, $player, $player2 );

my %keymap= (
    y => sub { RogueLike::Action::Walk->new( direction => [ -1, -1 ] ) },
    u => sub { RogueLike::Action::Walk->new( direction => [  1, -1 ] ) },
    h => sub { RogueLike::Action::Walk->new( direction => [ -1,  0 ] ) },
    j => sub { RogueLike::Action::Walk->new( direction => [  0,  1 ] ) },
    k => sub { RogueLike::Action::Walk->new( direction => [  0, -1 ] ) },
    l => sub { RogueLike::Action::Walk->new( direction => [  1,  0 ] ) },
    b => sub { RogueLike::Action::Walk->new( direction => [ -1,  1 ] ) },
    n => sub { RogueLike::Action::Walk->new( direction => [  1,  1 ] ) },
    '.' => sub { RogueLike::Action::Skip->new() },
    'q' => sub { $g->loop->running(0); undef },
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

    warn sprintf "%d players need input", 0+@need_input;
    for my $player (@need_input) {
        $display->draw( $g->level, $g->state );

        my $e= $player->energy;
        my $name= $player->name;
        print "$e $time $name: Action>";
        my $action= <>;
        chomp $action;
        $action= handle_input( $action );
        
        $player->next_action( $action )
            if $action;
        #warn $g->player->next_action;
    };

    @need_input= $g->loop->process_all( $g->state );
};

$display->draw( $g->level, $g->state );
