#!perl -w
package App::StarTraders::Asset::SVG;
use strict;
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
    for my $node ($document->find('//*[contains(@id,"connector-")]')) {
        $self->add_connector($node)
    };
};

# I'll need the same query functions that I have in W:M:F
# That's great as it'll lead to better abstraction
sub add_connector {
    my ($self,$node) = @_;
    my $name = $node->getAttributeNode('id')->value;
    my $val = $node->getAttributeNode('d')->value;
    my $num = qr/\d+(?:\.\d+)/;
    $val =~ /\bM\s+($num),($num)\s+C\s+($num),($num)\b/
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
    my $clone = (ref $self)->new( document => $document );
    $clone->extract_connectors;
    $clone
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

# Now figure out the transform to glue bay2 to the bottom of bay 1
# This is basically three steps (that could be later convverted to the one
# affine 2D transform that does this, if I want to brush up my
# 2D matrix multiplication:

# 1. Scale (2) to match up sqrt( (xl2-xr2)^2+(yl2-yr2)^2) )
# 2. Shift to match up xl2,yl2 with xl1,yl1
# 3. Rotate around xl1,yl1 to match up xr2,yr2 with xr1,yr1

# The order of operations is done this way to get the
# length-changing transform out of the way before any translation
# happens, as the translation relies on the coordinates

my $ship = $bay1->clone;
my $bay2_i = $bay2->clone;

# Need to rename the connector ids here. Using ids is a bad idea obviously.

$ship->document->svg->setDocumentElement($ship->document->svg);
