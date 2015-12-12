package RogueLike::Demo;
use strict;
use RogueLike::LevelDisplay;
use RogueLike::Game;
use RogueLike::Actor;

sub setup_loop {
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

    my $pet= RogueLike::Actor::Pet->new(
        position => [ 8,5 ],
        name => 'YourCat',
        avatar => 'c',
        owner => $player,
    );

    $g->state->add_actor( $rock, $player, $player2, $pet );
    
    ($g,$display, $player->name, $player, $player2->name, $player2)
};
    
1;