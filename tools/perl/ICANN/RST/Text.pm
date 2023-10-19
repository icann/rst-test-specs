package ICANN::RST::Text;
use Encode qw(decode_utf8);
use IPC::Open2;
use utf8;
use strict;

sub new {
    my ($package, $text) = @_;
    return bless({'text' => $text}, $package);
}

sub html {
    my ($self, $shift) = @_;

    $shift = sprintf('--shift-heading-level-by=%u', $shift);

    my ($out, $in, $html);

    my $pid = open2($out, $in, qw(pandoc -f markdown -t html), $shift);

    binmode($out, ':encoding(UTF-8)');
    binmode($in, ':encoding(UTF-8)');

    $in->print($self->{'text'}),
    $in->close;

    $html .= $out->getline while (!$out->eof);

    $out->close;

    waitpid($pid, 0);

    return '<div class="markdown-content">'.$html.'</div>';
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
