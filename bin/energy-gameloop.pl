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

$g->player( $player );

$g->state->add_actor( $rock, $player );

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

#$display->draw( $g->level, $g->state );
while( $g->loop->running ) {
    my $time= $g->loop->gametime;

    #if( $g->player->energy < 1000 ) {
    #    print "The game progresses without you\n";
    #};
    while( $g->loop->running and $g->player->energy >= 1000 and ! $g->player->next_action ) {
        $display->draw( $g->level, $g->state );

        my $e= $g->player->energy;
        print "$e $time Action>";
        my $action= <>;
        chomp $action;
        $action= handle_input( $action );
        
        $g->player->next_action( $action )
            if $action;
        warn $g->player->next_action;
    };

    $g->loop->process_all( $g->state );
};

$display->draw( $g->level, $g->state );
