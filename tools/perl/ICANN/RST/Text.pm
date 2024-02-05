package ICANN::RST::Text;
use Encode qw(decode_utf8);
use File::Slurp;
use File::Spec;
use Digest::SHA qw(sha1_hex);
use IPC::Open2;
use Text::Unidecode;
use utf8;
use strict;

my $CACHE;

sub new {
    my ($package, $text) = @_;
    return bless({'text' => $text}, $package);
}

sub text { $_[0]->{'text'} }

sub html {
    my ($self, $shift) = @_;

    return '<div class="markdown-content">'.$self->raw_html.'</div>';
}

sub raw_html {
    my ($self, $shift) = @_;

    my $key = sprintf('%s.%u', sha1_hex(unidecode($self->text)), $shift);

    if (!defined($CACHE->{$key})) {
        my $f = File::Spec->catfile(File::Spec->tmpdir, $key.'.html');

        unless (-e $f) {
            my @cmd = (qw(pandoc -f markdown -t html -o), $f);

            push(@cmd, sprintf('--shift-heading-level-by=%u', $shift)) if ($shift > 0);

            my $pid = open2(undef, my $in, @cmd);

            $in->binmode(':encoding(UTF-8)');
            $in->print($self->text),
            $in->close;

            waitpid($pid, 0);
        }

        $CACHE->{$key} = read_file($f, 'binmode' => ':encoding(UTF-8)');
    }

    return $CACHE->{$key};
}

1;

__END__

=pod

=head1 NAME

ICAN::RST::Text - an object representing Markdown text.

=head1 METHODS

=head2 new($text)

Constructor. C<$text> is a string.

=head2 html($heading_shift)

Convert to HTML. C<$heading_shift> is an integer which modifies the level of heading elements (eg a shift of 1 turns all C<h1> elements into C<h2>, C<h2> to C<h3> etc).

=cut
