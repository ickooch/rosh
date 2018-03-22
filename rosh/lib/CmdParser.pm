package CmdParser;

use strict;

use Text::ParseWords;

sub new {
    my $this = bless({
	'verbs' => {},
	'nouns' => {},
	'status' => 0,
		     }, shift);

    my %args = @_;

    if ( ( ref $args{ 'verbs' } eq 'ARRAY' ) and
	 ( ref $args{ 'nouns' } eq 'ARRAY' ) ) {
	foreach my $w ( @{ $args{ 'verbs' } } ) {
	    $this->{ 'verbs' }->{ $w } = 1;
	}
	foreach my $w ( @{ $args{ 'nouns' } } ) {
	    $this->{ 'nouns' }->{ $w } = 1;
	}
    } else {
	die '** FATAL: Class ' . ref $this . " requires two lists, verbs => [], and nouns => [] on create.\n";
    }
    return $this;
}

sub add_verbs {
    my ( $this, $verbs ) = @_;

    foreach my $w ( @{ $verbs } ) {
	$this->{ 'verbs' }->{ $w } = 1;
    }

    return $this;
}

sub add_nouns {
    my ( $this, $nouns ) = @_;

    foreach my $w ( @{ $nouns } ) {
	$this->{ 'nouns' }->{ $w } = 1;
    }

    return $this;
}

sub parse {
    my ( $this, $input_line ) = @_;

    chomp( $input_line );
    my @args = map { $_ =~ s/^"//; $_ =~ s/"$//; $_ } parse_line('\s+', 1, $input_line);

    $this->reset();
    
    # try to find longest matching sequence of words to form the action (verb) part
    my $i = 0;
    while ( $this->matches_verb( join( ' ', @args[0..$i] ) ) ) { $i++; }
    my $match_fragment = join( ' ', splice( @args, 0, $i ) );
    $this->{ verb } = $this->matches_verb( $match_fragment );
    if ( $this->{ 'verb' } =~ m/^\d+$/ ) {
	$this->{ 'verb' } = $match_fragment;
    }
    # pick first word matching a noun 
    $i = 0;
    while ( $i < scalar( @args ) and not $this->is_noun( $args[ $i ] ) ) { $i++; }
    $this->{ 'noun' } = $this->is_noun( splice( @args, $i, 1 ) )
	if ( $i < scalar( @args ) );

    die "Failed to recognize action verb in input line.\n"
	if ( not $this->{ 'verb' } );

    if ( not $this->{ 'noun' } ) {
	# check special case where last word of an action verb might match
	# a noun.
	# If noun is not defined and last word in verb matches a noun, and
	# the verb without the noun wold still be a valid verb, we split the verb
	# and use the noun part.
	#
	my @verb_parts = split(' ', $this->{ 'verb' });
	my @reassembled_verb = shift @verb_parts; # first word must be part of verb
	while ( my $noun = shift @verb_parts ) {
	    if ( $this->is_verb( join( ' ', @reassembled_verb ) ) and
		 $this->is_noun( $noun ) ) {
		$this->{ 'verb' } = join( ' ', @reassembled_verb );
		$this->{ 'noun' } = $this->is_noun( $noun );
		last;
	    }
	}
    }
    die "Failed to recognize a resource object in input line.\n"
	if ( not $this->{ 'noun' } );
    
    # separate noun from possible realm prefix
    $this->{ 'realm' } = $this->get_realm( $this->{ 'noun' } );
    $this->{ 'noun' } = $this->get_noun( $this->{ 'noun' } );
    $this->{ 'args' } = \@args;
    $this->{ 'status' } = 1;
    $this->{ 'last_input' } = $input_line;
    
    return $this;
}

sub ready {
    my $this = shift;

    return $this->{ 'status' };
}

sub reset {
    my $this = shift;

    $this->{ 'verb' } = undef;
    $this->{ 'noun' } = undef;
    $this->{ 'realm' } = undef;
    $this->{ 'args' } = [];
    $this->{ 'status' } = 0;

    return $this;
}

sub verb {
    my $this = shift;

    return $this->{ 'verb' };
}

sub noun {
    my $this = shift;

    return $this->{ 'noun' };
}

sub arguments {
    my $this = shift;

    return $this->{ 'args' };
}

sub is_noun {
    my ( $this, $word ) = @_;

    # nouns may be prefixed by an optional realm (application) qualifier to which they apply.
    # This is ignored when recognizing it as noun.
    my ( $realm, $noun ) = ( $this->get_realm( $word ), $this->get_noun( $word ) );
    $word = $noun;
    my $noun_map = $this->{ 'nouns' };
    # return $word if it is a clear match
    return defined $realm ? $realm . '.' . $word : $word
	if ( exists $noun_map->{ $word } );

    # lets see, whether $word is a fragment that uniquely matches a noun
    my @match = grep { m/^${ word }/ } keys %{ $noun_map };
    if ( scalar @match == 1 ) {
	$word = shift @match;
	return defined $realm ? $realm . '.' . $word : $word;
    } elsif ( scalar @match > 1 ) {
	return;
    }

    # no matches of $word in our list so far. Let's try harder

    # try to catch edge cases with plurals
    if ( ( $word =~ m/^(.+)ies$/ ) and exists $noun_map->{ $1 . 'y' } ) {
	# We want to allow to specify nouns in singular or plural forms.
	# Nouns that end with 'y' in singular have 'ies' in plural form..
	$word = $1 . 'y'; # if word was given in plural form, try singular
    } elsif ( ( $word =~ m/^(.+e)s$/ ) and exists $noun_map->{ $1 } ) {
	# check if our noun's singular form ends with an 'e', i.e. 'pipelines'
	# 'files', 'nodes' etc.
	$word = $1;
    } elsif ( $word =~ m/(e?s)$/ ) {
	# we allow for an optional 'e' before the plural 's' for words that
	# end with 'ch' (e.g. 'branches' rather than 'branchs')
	$word =~ s/$1$//; # if word was given in plural form, try singular
    } else {
	$word .= 's'; # if word was given in singular form, try it as plural
    }
    return defined $realm ? $realm . '.' . $word : $word
	if ( exists $noun_map->{ $word } );
    return;
}

sub get_realm {
    my ( $this, $word ) = @_;

    return $this->{ 'realm' }
        if ( not $word );
    # nouns may be prefixed by an optional realm (application) qualifier to which they apply.
    my @fq_noun = split( /\./, $word );
    my ( $realm, $noun );
    $noun = pop( @fq_noun );
    $realm = join( '.', @fq_noun )
	if ( @fq_noun );

    $this->set_realm( $realm );

    return $realm;
}

sub set_realm {
    my ( $this, $realm ) = @_;

    $this->{ 'realm' } = $realm;
    
    return $realm;
}

sub get_noun {
    my ( $this, $word ) = @_;

    # nouns may be prefixed by an optional realm (application) qualifier to which they apply.
    my @fq_noun = split( /\./, $word );
    my ( $realm, $noun );
    $noun = pop( @fq_noun );
    $realm = join( '.', @fq_noun )
	if ( @fq_noun );
    $this->set_realm( $realm );

    return $noun;
}

sub is_verb {
    my ( $this, $word ) = @_;

    my $verb_map = $this->{ 'verbs' };
    
    return exists $verb_map->{ $word };
}

sub matches_verb {
    my ($this, $word ) = @_;

    my $verb_map = $this->{ 'verbs' };

    return $word
	if ( exists $verb_map->{ $word } );
    
    my $matches = scalar grep { m/$word/ } keys %{ $verb_map };
    if ( $matches == 1 ) {
	$matches = (grep { m/$word/ } keys %{ $verb_map })[0];
    }
    return $matches;
}

1;
