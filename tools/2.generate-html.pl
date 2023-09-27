#!perl
#
# this script takes the rst-spec.yaml file and generates an HTML version of it
#
# Usage: perl 2.generate-html.pl rst-test-specs.yaml > rst-test-specs.html
#
use Encode qw(decode_utf8);
use HTML::Tiny;
use IPC::Open2;
use List::Util qw(any);
use YAML::XS;
use open qw(:std :encoding(UTF-8));
use strict;
use utf8;

undef $/;

my $struct = YAML::XS::LoadFile($ARGV[0]);

my $h = HTML::Tiny->new;

print "<!doctype html>\n";
print $h->open('html');

print $h->head([
    $h->meta({'charset' => 'UTF-8'}),
    $h->meta({'name' => 'viewport', 'content' => 'width=device-width'}),
    $h->style(<DATA>),
]);

print $h->open('body');

print $h->header([
    $h->h1('Registry System Testing - Test Specifications'),
    $h->p(sprintf('Version %s', $struct->{'Version'})),
    $h->p(sprintf('Last Updated: %s', $struct->{'Last-Updated'})),
    $h->p($h->a({'href' => 'mailto:'.$struct->{'Contact'}->{'Email'}}, $struct->{'Contact'}->{'Name'}.', '.$struct->{'Contact'}->{'Organization'}))
]);

print $h->open('nav');
print $h->a({'name' => 'table-of-contents'});
print $h->h2('1. Table of Contents');

print $h->open('ol');

print $h->li($h->a({'href' => '#table-of-contents'}, 'Table of Contents'));

print $h->li($h->a({'href' => '#preamble'}, 'Preamble'));

print $h->open('li');
print $h->a({'href' => '#test-plans'}, 'Test Plans');

print $h->open('ol');
foreach my $plan (sort({$struct->{'Plans'}->{$a}->{'Order'} cmp $struct->{'Plans'}->{$b}->{'Order'}} keys(%{$struct->{'Plans'}}))) {
    print $h->li($h->a({'href' => sprintf('#Test-Plan-%s', $plan)}, $struct->{'Plans'}->{$plan}->{'Name'}));
}
print $h->close('ol');

print $h->close('li');

print $h->open('li');
print $h->a({'href' => '#test-cases'}, 'Test Cases');

print $h->open('ol');
foreach my $case (grep { $_ !~ /^Doc/ } sort(keys(%{$struct->{'Test-Cases'}}))) {
    my $title;
    if ($struct->{'Test-Cases'}->{$case}->{'Summary'}) {
        $title = sprintf('%s - %s', $case, $struct->{'Test-Cases'}->{$case}->{'Summary'});

    } else {
        $title = $case;

    }
    print $h->li($h->a({'href' => sprintf('#Test-Case-%s', $case)}, $title));
}
print $h->close('ol');

print $h->close('li');

print $h->close('ol');

print $h->a(
    {
        'class' => 'toc-link',
        'title' => 'Table of Contents',
        'href'  => '#table-of-contents',
    },
    ["● ━━", $h->br, "● ━━", $h->br, "● ━━"],
);

print $h->close('nav');

print $h->open('main');

print $h->open('section');
print $h->a({'name' => 'preamble'});
print $h->h2('2. Preamble');

print md2html($struct->{'Preamble'});

print $h->open('close');

print $h->a({'name' => 'test-plans'});
print $h->h2('3. Test Plans');

my $i = 0;
foreach my $plan (sort({$struct->{'Plans'}->{$a}->{'Order'} cmp $struct->{'Plans'}->{$b}->{'Order'} } keys(%{$struct->{'Plans'}}))) {
    print $h->open('section');
    print $h->a({'name' => sprintf('Test-Plan-%s', $plan)});
    print $h->h3(sprintf('3.%u. %s', ++$i, $struct->{'Plans'}->{$plan}->{'Name'}));

    print $h->h4('Description');
    print md2html($struct->{'Plans'}->{$plan}->{'Description'}, 3);

    print $h->h4('Test Suite(s)');
    print $h->open('ol');
    foreach my $suite (sort(keys(%{$struct->{'Plans'}->{$plan}->{'Test-Suites'}}))) {
        print $h->open('li');
        print $suite;

        print $h->open('ol');
        foreach my $case (@{$struct->{'Plans'}->{$plan}->{'Test-Suites'}->{$suite}}) {
            my $title;
            if ($struct->{'Test-Cases'}->{$case}->{'Summary'}) {
                $title = sprintf('%s - %s', $case, $struct->{'Test-Cases'}->{$case}->{'Summary'});

            } else {
                $title = $case;

            }
            print $h->li($h->a({'href' => sprintf('#Test-Case-%s', $case)}, $title));
        }
        print $h->close('ol');

        print $h->close('li');
    }
    print $h->close('ol');

    print $h->close('section');
}

print $h->a({'name' => 'test-cases'});
print $h->h2('4. Test Cases');

my $i = 0;
foreach my $case (grep { length($_) > 0 && $_ !~ /^Doc/ } sort(keys(%{$struct->{'Test-Cases'}}))) {
    print $h->open('section');
    print $h->a({'name' => sprintf('Test-Case-%s', $case)});

    if ($struct->{'Test-Cases'}->{$case}->{'Summary'}) {
        print $h->h3(sprintf('4.%u. %s - %s', ++$i, $case, $struct->{'Test-Cases'}->{$case}->{'Summary'}));

    } else {
        print $h->h3(sprintf('4.%u. %s', ++$i, $case));

    }

    print md2html($struct->{'Test-Cases'}->{$case}->{'Description'}, 2);

    print $h->h4('Test Plans this Test Case is used in:');
    print $h->open('ol');
    foreach my $plan (sort(keys(%{$struct->{'Plans'}}))) {
        foreach my $suite (sort(keys(%{$struct->{'Plans'}->{$plan}->{'Test-Suites'}}))) {
            if (any { $_ eq $case } @{$struct->{'Plans'}->{$plan}->{'Test-Suites'}->{$suite}}) {
                print $h->li($h->a({'href' => sprintf('#Test-Plan-%s', $plan)}, $struct->{'Plans'}->{$plan}->{'Name'}));
            }
        }
    }
    print $h->close('ol');

    print $h->close('section');
}

print $h->close('main');
print $h->close('body');
print $h->close('html');

sub md2html {
    my ($md, $shift) = @_;

    $shift = sprintf('--shift-heading-level-by=%u', $shift);

    my($out, $in);
    my $pid = open2($out, $in, qw(pandoc -f markdown -t html), $shift, '-');
    binmode($out, ':encoding(UTF-8)');
    binmode($in, ':encoding(UTF-8)');
    $in->print($md);
    close($in);
    my $html = <$out>;
    close($out);

    waitpid($pid, 0);

    return $html;
}

__DATA__
html,body,p,div,ol,li,table,tr,td,th,input,button,select,option,textarea,* {
    font-family: Helvetica, Arial, sans-serif;
    font-size: small;
    font-weight: 300;
    line-height: 150%;
}
a {
    color: #00c;
}
a:active,a:hover {
    color: #c4c;
}
.toc-link:active,.toc-link:hover {
    border: 1px solid #c4c;
}
header {
    text-align:center;
}
strong,h1,h2,h3,h4,h5,h6 {
    font-weight: 600;
}
header,nav,body,main,section {
    padding:0 1em;
    border-bottom: 0.125em solid #ccc;
}
body {
    margin: 0.5em 5em;
}
dl {
    margin: auto 2em;
}
dt {
    font-weight:bold;
}
dt:after {
    content: ":";
}
dd {
    margin-bottom: 1em;
}
.toc-link {
    position:fixed;
    margin:0;
    padding: 0.25em;
    border-radius: 0.25em;
    top:1em;
    right:3em;
    font-size:50%;
    display:inline-block;
    line-height:100%;
    text-decoration:none;
    border: 1px solid #00c;
}
