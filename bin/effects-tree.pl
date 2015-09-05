#!perl -w
use strict;

package RPG::Effect;
use strict;
use Filter::signatures;
use feature 'signatures';
use Moo::Lax;
use Data::Dumper;

has 'name' => (
    is => 'ro',
);

has 'base_attribute' => (
    is => 'ro',
);

has 'affected_attribute' => (
    is => 'ro',
);

has 'buff' => ( # or debuff...
    is => 'ro',
);

has 'scale' => (
    is => 'ro',
);

# For each tick, we regenerate items
# ideally, we would disconnect ourselves from the per-tick mechanic here
# and calculate the added value by calculating the regeneration size * timespan

# non-stacking means simply reset the timeout counter
# stacking means to add the effect to the list of active effects
# recharging items could also be done through this mechanism except that
# this mechanism shouldn't be tied to the per-tick calculations as
# "once per day" does not translate to "half a charge at midday" (or does it?)
# but this could mean that two items "at once per day" could translate to
# "effect at midday", at least if the effect is tied to the character, not
# to the item.

sub apply( $self, $base, $effects ) {
    # updates $effects as a hash of modifiers
    $effects->{ $self->affected_attribute } ||= {
        buff => 0,
        scale => 1,
    };
    #warn sprintf "Changing %s: Buffing by %d, scaling by %0.2f%%\n", $self->affected_attribute, ($self->buff || 0), ($self->scale || 0);
    $effects->{ $self->affected_attribute }->{ buff } += $self->buff || 0;
    $effects->{ $self->affected_attribute }->{ scale } += $self->scale || 0;
}

package RPG::Stats;
use strict;
use Moo::Lax;
use Filter::signatures;
use feature 'signatures';

# so much boilerplate, so little understanding of what's really needed
sub current($self) {
    $self
}

sub max($self) {
    $self->{_max}
}

package RPG::StatsActor;
use strict;
use Moo::Lax;

# The effects currently active on the player (or wherever)
has 'active_effects' => (
    is => 'ro',
    default => sub { [] },
);

sub add_effect($self,@effects) {
    push @{$self->active_effects},@effects;
}

# Formula is
# base*(1+sum(scale)) + sum(buffs)
# Only UNMODIFIED attributes are taken into consideration, to prevent
# stacking loops where attribute a affects attribute b, which next turn
# affects attribute a again (except usually more complicated)
sub get_effects( $self, $base, $effects ) {
    for my $effect ( @{ $self->active_effects }) {
        $effect->apply( $base, $effects );
    }
};

sub get_effects_delta ( $self, $base ) {
    $self->get_effects( $base, \my %effects );

    \%effects
};

# This is where life choices accumulate, like (randomized) gains through
# levelling or permanent bonuses from consuming items
# Why not have them as a list too?! Prioritize that list/sort it after expiry
# and caching becomes possible. The Journal is everywhere.
# Consider "baking"/consolidating the effects. At least all permanent effects
# can be consolidated, as can all effects lasting longer than some certain
# tick period or until the inventory gets changed.
# Maybe the caching should be considered only after it really becomes a problem.
# If this scheme gets applied to items too (like recharging fireball swords),
# then caching will become an issue.
# Note that stats are only interesting upon player actions (combat,skill checks)
# so maybe having the whole thing be recalculated dynamically isn't actually
# that big a deal

sub apply_effects( $self, $effects_delta ) {
    my $base = $self->get_base_attributes;

    # This should basically be a delegating objects to $player, I think
    my %res;
    # $player should have a method listing all attributes instead of
    # us iterating over the keys...
    # And really, we should think of caching early, that is, caching a
    # "generation" of the player so we don't recalculate. But hunger is
    # ever-present, so we'll always recalculate?!
    for my $attr (keys %$effects_delta) {
        if( $effects_delta->{ $attr }) {
            $res{ $attr } = ($base->{$attr}|| 0) * ($effects_delta->{$attr}->{scale} || 1)+ ($effects_delta->{$attr}->{buff} || 0); 
        } else {
            $res{ $attr } = $base->{$attr}; 
        }
    }

    # Cap negative numbers to zero
    # Maybe we should have this per-attribute
    for( values %res) {
        $_ = 0 if $_ < 0
    }

    \%res
}

sub remove_effects( $self, $crit ) {
    @{ $self->active_effects } = grep { !$crit->() } @{ $self->active_effects };
};

sub get_base_attributes( $self ) {
    {}
}

package main;
use strict;
use Carp qw(croak);
use vars qw'%effects %active_effects @active_effects';

sub min {
    my $min = shift;
    for( @_ ) {
        if( $min > $_ ) { $min = $_ } 
    }
    $min
};

# All known effects
# Each effect has a name, an attribute, a fixed contribution size,
# and a contribution factor which is relative to 1.

#%effects = (
#    health_regeneration => { name => 'regeneration', attribute => 'health', buff => 1, scale => 0 },
#    mana_regeneration => { name => 'regeneration', attribute => 'mana', buff => 1, scale => 0 },
#);

sub roll($dice) {
    $dice =~ /^(\d+)d(\d+)(?:\+(\d+))?$/i or croak "Don't know what die this is: '$dice'";
    my( $count, $sides, $sum ) = ($1,$2,$3);
    $sum ||= 0;
    for( 1..$count ) {
        $sum += int(rand($sides)+1)
    };
    $sum
}

my $player = RPG::StatsActor->new(
    active_effects => [map {RPG::Effect->new(%$_)} (
    # Initial "effects" basically calculating the base player stats
    # Having them here means additional work when displaying the stats?!
        { name => 'roll.intelligence', base_attribute => '', affected_attribute => 'intelligence', buff => roll('3d6') },
        { name => 'roll.wisdom', base_attribute => '', affected_attribute => 'wisdom', buff => roll('3d6') },
        { name => 'roll.strength', base_attribute => '', affected_attribute => 'strength', buff => roll('3d6') },
        { name => 'roll.constitution', base_attribute => '', affected_attribute => 'constitution', buff => roll('3d6') },
        { name => 'roll.health', base_attribute => 'constitution', affected_attribute => 'health', buff => roll('4d3') },
    # ideally, the above could be consolidated/cached here

    # Permanent effects, affecting the maximum attributes of the player and base regeneration
        { name => 'robust', base_attribute => '', affected_attribute => 'health', buff => 0, scale => 0.10 },
    # or/and cached here

    # Regenerative effects, affecting the current attributes of the player
        { name => 'regeneration', base_attribute => 'constitution', affected_attribute => 'health', buff => 1, scale => 0 },
        { name => 'vigorous_regeneration', base_attribute => 'constitution', affected_attribute => 'health', buff => 0, scale => 0.10 },
        { name => 'regeneration', base_attribute => 'intelligence', affected_attribute => 'mana', buff => 1, scale => 0 },
        { name => 'ring of mana regeneration', base_attribute => '', affected_attribute => 'mana', buff => 1, scale => 0, ratio => 'per tick' },
    )]);
use Data::Dumper;
#warn Dumper \@active_effects;

my $active_effects= $player->get_effects_delta(undef, {});
$player->{ current } = $player->apply_effects($active_effects);
# we should strip out all attributes where max=current according to the rules
warn Dumper \$player->{current};

# Wear a dunce cap
$player->add_effect( RPG::Effect->new(
    { name => 'dunce cap', base_attribute => 'intelligence', affected_attribute => 'intelligence', buff => -15, scale => 0 },
));

$active_effects= $player->get_effects_delta({});
#warn Dumper $active_effects;
$player->{ current } = $player->apply_effects($active_effects);
# we should strip out all attributes where max=current according to the rules
warn Dumper \$player->{current};

# Remove the dunce cap now
$player->remove_effects(sub{ $_->{name} eq 'dunce cap'});

$active_effects= $player->get_effects_delta({});
#warn Dumper $active_effects;
$player->{ current } = $player->apply_effects($active_effects);
# we should strip out all attributes where max=current according to the rules
warn Dumper \$player->{current};


# How will effects be attached/connected with the items?!

# How to structure the "lensed" attributes?
# We have lenses for "base", "current" and "base maximum" and "current maximum",
# where
# "base" is the attribute provided by the player body
# "base maximum" is the current set of maximum values allowed for the attributes
# "current" is the current set of attributes
# "current maximum" is the set of maximum values for each attribute
# If a player shapeshifts, do they get a new body? What happens if they
# shapeshift back?! Maybe they either permanently get a new (stock) body
# or ther intermediate body is just another effect.

# Level gains change the base attributes
# Effects change the "current" set of attributes
# Each "maximum" is calculated from the "current" set of attributes
# This means that malleable attributes may not form a circular chain.

#$player->current->get('health');
#$player->max->get('health');

# base.constitution implies base.health.max
# base.intelligence implies base.mana.max
# there is no base.constitution.max
# there is no base.intelligence.max

