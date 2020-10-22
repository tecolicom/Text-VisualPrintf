package Text::VisualPrintf::Transform;

use v5.14;
use warnings;
use utf8;
use Carp;
use Data::Dumper;
{
    no warnings 'redefine';
    *Data::Dumper::qquote = sub { qq["${\(shift)}"] };
    $Data::Dumper::Useperl = 1;
    $Data::Dumper::Sortkey = 1;
}

my %default = (
    check   => undef,
    length  => sub { length $_[0] },
    pattern => qr/.+/s,
    without => '',
);

sub new {
    my $class = shift;
    my $obj = bless {
	%default,
    }, $class;
    $obj->configure(@_) if @_;
    $obj;
}

sub configure {
    my $obj = shift;
    while (my($key, $value) = splice @_, 0, 2) {
	if (not exists $obj->{$key}) {
	    croak "$key: invalid parameter";
	    die;
	}
	$obj->{$key} = $value;
    }
    $obj;
}

sub encode {
    my $obj = shift;
    $obj->{replace} = [];
    my $uniqstr = $obj->_sub_uniqstr(@_) or return @_;
    for my $arg (grep { defined } @_) {
	if (my $check = $obj->{check}) {
	    next unless ( ( ref $check eq 'Regexp' and $arg =~ $check ) or
			  ( ref $check eq 'CODE'   and $check->($arg) ) );
	}
	my $pattern = $obj->{pattern} or die;
	$arg =~ s{$obj->{pattern}}{
	    if (my($replace, $regex, $len) = $uniqstr->(${^MATCH})) {
		push @{$obj->{replace}}, [ $regex, ${^MATCH}, $len ];
		$replace;
	    } else {
		${^MATCH};
	    }
	}pge;
    }
    @_;
}

sub decode {
    my $obj = shift;
    my @replace = @{$obj->{replace}};

  ARGS:
    for (@_) {
	for my $i (0 .. $#replace) {
	    my $ent = $replace[$i];
	    my($regex, $orig, $len) = @$ent;
	    # capture group is defined in $regex
	    if (s/$regex/_replace($1, $orig, $len)/e) {
		splice @replace, 0, $i + 1;
		redo ARGS;
	    }
	}
    }
    @_;
}

sub _replace {
    my($matched, $orig, $len) = @_;
    my $width = length $matched;
    if ($width == $len) {
	$orig;
    } else {
	_trim($orig, $width);
    }
}

sub _trim {
    my($str, $width) = @_;
    use Text::ANSI::Fold;
    state $f = Text::ANSI::Fold->new(padding => 1);
    my($folded, $rest, $w) = $f->fold($str, width => $width);
    if ($w <= $width) {
	$folded;
    } elsif ($width == 1) {
	' '; # wide char not fit to single column
    } else {
	die "Panic"; # should never reach here...
    }
}

sub _sub_uniqstr {
    my $obj = shift;
    local $_ = join '', @_, $obj->{without} //= '';
    my @a;
    for my $i (1 .. 255) {
	my $c = pack "C", $i;
	next if $c =~ /\s/ || /\Q$c/;
	push @a, $c;
	last if @a > @_;
    }
    return if @a < 2;
    my $lead = do { local $" = ''; qr/[^\Q@a\E]*+/ };
    my $b = pop @a;
    return sub {
	my $len = $obj->{length}->(+shift);
	return if $len < 1;
	my $a = $a[ (state $n)++ % @a ];
	( $a . ($b x ($len - 1)), qr/\G${lead}\K(\Q${a}${b}\E*)/, $len );
    };
}

1;

__END__

=encoding utf-8

=head1 NAME

Text::VisualPrintf::Transform - transform and recover interface for text processing

=head1 SYNOPSIS

    use Text::VisualPrintf::Transform;
    my $xform = Text::VisualPrintf::Transform->new();
    $xform->encode(@args);
    $_ = foo(@args);
    $xform->decode($_);

=head1 DESCRIPTION

This is a general interface to transform text data into desirable
form, and recover the result after the process.

For examlle, L<Text::Tabs> does not take care of Asian wide characters
to calculate string width.  So next program does not work as we wish.

    use Text::Tabs;
    print expand <>;

In this case, make transform object with B<length> function which
understand wide character width, and replacement pattern.

    use Text::VisualPrintf::Transform;
    use Text::VisualWidth::PP;
    my $xform = Text::VisualPrintf::Transform
        ->new(length  => \&Text::VisualWidth::PP::width,
              pattern => qr/\P{ASCII}+/);

Then next program encode data, call B<expand>() function, and recover
the result into original text.

    my @lines = <>;
    $xform->encode(@lines);
    my @expanded = expand @lines;
    $xform->decode(@expanded);
    print @expanded;

Be aware that B<encode> and B<decode> method alter the values of given
arguments.

Because they returns altered arguments too, this can be done more
simply.

    print $xcode->decode(expand($xform->encode(<>)));

Next program implements ANSI terminal sequence aware expand command.

    use Text::VisualPrintf::Transform;
    use Text::ANSI::Fold::Util;
    use Text::Tabs qw(expand);

    my $xform = Text::VisualPrintf::Transform
        ->new(length  => \&Text::ANSI::Fold::Util::width,
              pattern => qr/[^\t\n]+/);
    while (<>) {
        print $xform->decode(expand($xform->encode($_)));
    }


=head1 METHODS

=over 4

=item B<new>

Create transform object.  Takes following parameters.

=over 4

=item B<length> => I<function>

Function to calculate text width.  Default is C<length>.

=item B<pattern> => I<regex>

Specify text area to be replaced.  Default is C<qr/.+/s>.

=item B<check> => I<regex> or I<function>

Specify regex or subroutine to check if the argument is to be
processed or not.  Default is B<undef>, so all arguments will be
subject to replace.

=item B<without> => I<string>

Transformation is done by replacing text with different string which
can not be found in all arguments.  This parameter gives additional
string which also to be taken care of.

=back

=item B<encode>

Encode arguments.

=item B<decode>

Decode arguments.

=back

=head1 SEE ALSO

L<Text::VisualPrintf>, L<https://github.com/kaz-utashiro/Text-VisualPrintf>

=head1 AUTHOR

Kazumasa Utashiro

=head1 LICENSE

Copyright 2020 Kazumasa Utashiro.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
