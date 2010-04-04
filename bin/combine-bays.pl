#!perl -w
package App::StarTraders::Asset::SVG;
use strict;
use Carp qw(croak);
#use SVG::File;

use Moose;
has document => (
    isa => 'SVG::File',
    is  => 'ro',
);

has connectors => (
    isa     => 'HashRef',
    default => sub { +{} },
    is      => 'ro',
);

no Moose;
__PACKAGE__->meta->make_immutable;

sub load {
    my ($class,$fn) = @_;
    my $document = SVG::File->load($fn);
    my $self = {
        document   => $document,
        connectors => {},
    };
    
    $self = $class->new($self);
    $self->extract_connectors();

    $self
};

sub extract_connectors {
    my ($self,$document) = @_;
    $document ||= $self->document;
    for my $node ($document->find('//*[contains(@class,"connector-")]')) {
        $self->add_connector($node)
    };
};

# I'll need the same query functions that I have in W:M:F
# That's great as it'll lead to better abstraction
sub add_connector {
    my ($self,$node) = @_;
    my $name = $node->getAttributeNode('class')->value;
    my $val = $node->getAttributeNode('d')->value;
    my $num = qr/\d+(?:\.\d+)?/;
    $val =~ /\bM\s+($num),($num)\s+C\s+($num),($num)\b/i
        or die "Can't figure out  connector dimensions from '$val'";
    my ($xl,$yl,$xr,$yr) = ($1,$2,$3,$4);
    my $info = {
        name => $name,
        left =>  { x => $xl, y => $yl },
        right => { x => $xr, y => $yr },
    };
    $self->connectors->{$name} = $info;
};

sub clone {
    my ($self) = @_;
    my $doc = $self->document->clone_document;
    my $clone = (ref $self)->new( document => SVG::File->new( $doc ));
    $clone->extract_connectors;
    $clone
};

sub connector_length {
    my ($self,$name) = @_;
    my $c = $self->connectors->{$name}
        or croak "No such connector: '$name'";
    my $len = sqrt(   ($c->{right}->{x}-$c->{left}->{x})**2
                    + ($c->{right}->{y}-$c->{left}->{y})**2 );
};

package SVG::File;
use strict;
use XML::LibXML;

# This should parse out the connectors
# Potentially, this should simply use Moose, as StarTraders itself
# uses Moose liberally

sub svg { $_[0]->{svg} };

sub new {
    my ($class,$document) = @_;
    bless {
        svg => $document,
    }, $class
}

sub load {
    my ($class,$filename,%args) = @_;
    my $p = XML::LibXML->new();
    my $self = $class->new($p->parse_file($filename));
}

sub save {
    my ($self,$outname) = @_;
    open my $fh, ">", $outname
        or die "Couldn't create '$outname': $!";
    binmode $fh, ':utf8';
    print {$fh} $self->svg->toString;
}

sub find {
    my ($self,$xpath,$doc) = @_;
    $doc ||= $self->svg->documentElement;
    my $i = $doc->findnodes($xpath);
    $i->get_nodelist;
}

sub layers {
    my ($self,$doc) = @_;
    $doc ||= $self->svg->documentElement;
    my @l = $self->find('/svg:svg/svg:g[@inkscape:groupmode="layer"]',$doc);
    my %label;
    for (@l) {
        ($label{ $_ }) = map { $_->value } $self->find('@inkscape:label',$_);
    }
    sort { $label{$a} cmp $label{$b} } @l
};

sub clone_document {
    my ($self,$org) = @_;
    $org ||= $self->svg;
    my $doc = XML::LibXML::Document->createDocument(
        $org->version,
        $org->encoding,
    );
    my $clone = $org->documentElement->cloneNode(1);
    #$doc->importNode( $clone ) or die;
    $doc->setDocumentElement( $clone );
    $doc
}

1;

package main;
#!perl -w
use strict;

my $bay1 = App::StarTraders::Asset::SVG->load('assets/proto-bay-freight.svg');
my $bay2 = App::StarTraders::Asset::SVG->load('assets/proto-bay-freight-2.svg');

my $c = $bay1->connectors;
for (values %$c) {
    print $_->{name},"\n";
};

my $ship = $bay1->clone;
my $bay2_i = $bay2->clone;
($bay2_i) = $bay2_i->document->find('//*[@id="layer1"]');
# We should unwrap this outer layer, some day

my $doc = $ship->document->svg;

# Merge our Bay2 instance into the ship instance
$doc->importNode($bay2_i);

# Now, how do we actually move the Bay2 content around?
# Just wrap it all in another group, and transform that group:
my $group = $doc->createElement('svg:g');

# Now figure out the transform to glue bay2 to the bottom of bay 1
# This is basically three steps (that could be later convverted to the one
# affine 2D transform that does this, if I want to brush up my
# 2D matrix multiplication:

my @transform;

my $s1 = $bay1->connectors->{'connector-s'};
my $s2 = $bay1->connectors->{'connector-n'};

# 1. Scale (Bay2) to match up the length of the reference magnetic part
my $len1 = $bay1->connector_length('connector-s');
my $len2 = $bay2->connector_length('connector-n');
printf "$len2 -> $len1 (%0.8f)\n", $len1/$len2;

if ($len2 / $len1 != 1) {
    push @transform, sprintf 'scale(%0.8f)', $len1/$len2;
};

# 2. Shift to match up xl2,yl2 with xl1,yl1
my $tx = $s1->{left}->{x} - $s2->{left}->{x};
my $ty = $s1->{left}->{y} - $s2->{left}->{y};

push @transform, sprintf 'translate(%0.8f,%0.8f)', $tx,$ty;

# 3. Rotate around xl1,yl1 to match up xr2,yr2 with xr1,yr1
push @transform, sprintf 'rotate(90,%0.8f,%0.8f)', $s1->{left}->{x}, $s1->{left}->{y};

# The order of operations is done this way to get the
# length-changing transform out of the way before any translation
# happens, as the translation relies on the coordinates

# Actually insert the node
$group->setAttribute('transform',join ' ', @transform);
$group->appendChild($bay2_i);
$ship->document->svg->documentElement->appendChild($group);

# And save our result for inspection
$ship->document->save('ship.svg');
