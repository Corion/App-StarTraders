#!perl -w
use strict;

my $bay1 = SVG::File->load('assets/proto-bay-freight.svg');
my $bay2 = SVG::File->load('assets/proto-bay-freight-2.svg');

# I'll need the same query functions that I have in W:M:F
# That's great as it'll lead to better abstraction
my ($connector_s) = $bay1->find('//svg:path[@id="connector-s"]')
    or die "No connector path found in assets/proto-bay-freight.svg";
#print $connector_s->toString;
#print $connector_s->getAttributeNode('d')->value;

my $num = qr/\d+(?:\.\d+)/;
my $val = $connector_s->getAttributeNode('d')->value;
$val =~ /\bM\s+($num),($num)\s+C\s+($num),($num)\b/
    or die "Can't figure out  connector dimensions from '$val'";
my ($xl,$yl,$xr,$yr) = ($1,$2,$3,$4);

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