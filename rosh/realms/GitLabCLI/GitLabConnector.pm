package GitLabConnector;
################################################################################

=head1 package
=head2 GitLabConnector

 Version: 0.0.1
 Purpose: 
    Provide interface object to manage the gory details of a REST
    Client based server 'connection' 
 Description:

 Restrictions: none
 Author: Axel Mahler

=head1 Function

=cut

################################################################################

use strict;

require RESTConnector;
use base qw( RESTConnector );

use Carp;
use Tracer;
use Globals;
use HTTP::Status qw(:constants :is status_message);

use JSON;

# Data::Dumper makes it easy to see what the JSON returned actually looks like 
# when converted into Perl data structures.
use Data::Dumper;
use Data::Dump qw( dump );
use MIME::Base64;
use Try::Tiny;
use URL::Encode::XS qw( url_encode url_decode );
use Text::Wrap;

################################################################################
################################################################################

=head2 new

 Purpose: 
    Define default (fallback) new method
 Parameters: AppRegister object as application frame (needed to access
             Builtins and connection properties)
 Return value: none
 Description:
    
 Restrictions: none

=cut

################################################################################

sub new {
  my $this = bless({}, shift);
  $this->frame( shift );

  my %params = @_;
  
  $this->version('1.0.0');

  $this->prop( 'url', $this->preference( 'gitlab_url' ));
  $this->prop( 'token', $this->preference( 'gitlab_access_token' ));
  $this->prop( 'api', $this->preference( 'gitlab_api_version' ));
  $this->prop( 'color', $this->preference( 'gitlab_color' ));

  # FIXME: Default should be 1 for production environments - this should be configurable
  $this->ssl_verify_hostname( 0 ); 

  die "Incomplete GitLab profile parameters - cannot establish connection.
URL = " . $this->prop( 'url' ) . "
Token = " . $this->prop( 'token' ) . "
API Vers = " . $this->prop( 'api' ) . "\n"
    unless ( $this->prop( 'url' ) && $this->prop( 'token' ) && $this->prop( 'api' ) );

  if ( exists $params{ 'interactive' } and  $params{ 'interactive' } ) {
      my $version;
      try {
	  $version = $this->rest_get_single( '/version' );
	  $this->print( 'Connected to GitLab V-' . $version->{ 'version' } . 
			' (R' . $version->{ 'revision' } . ") at $this->{ 'url' }" . "\n" );
	  $this->frame->builtin->set( 'gitlab_server_version', ' V-' . $version->{ 'version' } . 
				      ' (R' . $version->{ 'revision' } . ')' );
      } catch {
	  chomp( $! );
	  die "*** ERROR: Connect to GitLab failed: $_!\n";
      };
  }
  
  return $this;
}

########################### Supply Authentication Header 
#                                overriding WebServiceConnector::get_auth_header

sub get_auth_header {
    my $this = shift;
    return {
	'Accept' => 'application/json', 
	'PRIVATE-TOKEN' => $this->prop( 'token' ),
	'Content-Type' => 'application/json', 
    }
}

########################### Gitlab Access Methods

# Use with Try::Tiny
sub get_object_id {
    my ( $this, $class, $name, $scope ) = @_;

    # if it already looks like an id, trust it and return it rightaway
    return $name 
	if ( $name =~ m/^\d+/ );

    return $name
	if ( $this->is_url_encoded( $name ) );
    
    $name = url_encode( $name );
    
    my @searchargs = ( $name );
    unshift( @searchargs, $scope )
	if ( $scope );
    my $searchfmt = canonicalize( $class );
    if ( $searchfmt eq $class ) {
	warn "get_object_id: Possibly unrecognized object class \"$class\" encountered.\n";
    }
    my $search_url = sprintf( $searchfmt, @searchargs );
    if ( $this->preference( 'verbose' ) ) {
	print __PACKAGE__ . '::get_object_id - ' . $search_url . "\n";
    }

    my @raw_result = @{ $this->get_list_data( '/api/' . $this->preference(
				 'gitlab_api_version' ) . "$search_url", 100 ) };
    my @matching = grep { $_->{ 'name' } =~ m/^${name}$/i } @raw_result;
    if ( not @matching ) {
	die "Unknown $class object \"$name\"\n";
    }
    my $match = shift( @matching );
    if ( @matching ) {
	die "Object selector \"$name\" is not unique.\n";
    }

    return exists $match->{ 'id' } ? $match->{ 'id' } : $match->{ 'name' };
}

# Try to determine a uniq project-id from a possibly fragmented name
# The scope is limited to projects in owned groups and namespaces unless
# the %args hash has a parameter 'global' defined.
# In order to boost performance in interactive mode, the results of
# queries are cached.
#
sub get_project_id {
    my ( $this, $pname, %args ) = @_;

    # if it already looks like an id, trust it and return it rightaway
    return $pname 
	if ( $pname =~ m/^\d+/ );

    return $pname
	if ( $this->is_url_encoded( $pname ) );
    
    my @projects = @{ $this->my_projects() };
    my @matches;
    if ( exists $args{ 'exact-match' } ) {
	 $this->preference( 'debug' ) && print "*** get_project_id look for exact match of $pname \n";
	 @matches = grep { $_->{ 'path_with_namespace' } eq $pname } @{ $this->my_projects() };
    } else {
	@matches = grep { $_->{ 'path_with_namespace' } =~
			      m/\b${pname}/ } @{ $this->my_projects() };
    }
    $this->preference( 'debug' ) && print "** get_project_id has matches: " . dump( @matches ) . "\n";
    if ( @matches == 1 ) {
	return $matches[0]->{ 'id' };
    }
    if ( @matches && exists $args{ 'multiple' } ) {
	return [ map { $_->{ 'id' } } @matches ];
    }
    die 'Cannot find ' . ( exists $args{ 'multiple' } ? 'any' : 'uniq'
	) . " match for project name $pname.\n";

    return;
}

sub get_project_from_id {
    my ( $this, $pid ) = @_;

    my @hits;
    if ( exists( $this->{ 'all_projects' } )) {
	@hits = grep { ( $_->{ 'id' } eq $pid ) || 
			   ( $this->is_url_encoded( $pid ) ?
			     url_decode( $pid ) : $pid ) eq 
			     $_->{ 'path_with_namespace' } }
	@{ $this->{ 'all_projects' } };
	die "Cannot find project with id $pid.\n"
	    unless ( scalar @hits != 1 );
	return shift @hits;
    } elsif ( exists( $this->{ 'my_projects' } )) {
	@hits = grep { ( $_->{ 'id' } eq $pid ) || 
			   ( $this->is_url_encoded( $pid ) ?
			     url_decode( $pid ) : $pid ) eq 
			     $_->{ 'path_with_namespace' } }
	@{ $this->{ 'my_projects' } };
	return shift @hits
	    if ( scalar @hits == 1 );
    } elsif ( exists( $this->{ 'cached_projects' } )) {
	@hits = grep { ( $_->{ 'id' } eq $pid ) || 
			   ( $this->is_url_encoded( $pid ) ?
			     url_decode( $pid ) : $pid ) eq 
			     $_->{ 'path_with_namespace' } }
	@{ $this->{ 'cached_projects' } };
	return shift @hits
	    if ( scalar @hits == 1 );
    }
    my $project = $this->rest_get_single( '/projects/' . $pid );
    $this->preference( 'debug' ) && print "Got project data: " . dump( $project ) . "\n";
    die "Can't find project with id $pid.\n"
	if ( not defined $project->{ 'id' } );
    $this->{ 'cached_projects' } ||= [];
    push( @{ $this->{ 'cached_projects' } }, $project );
    return $project;
}
    
sub get_branch_id {
    my ( $this, $pid, $name ) = @_;

    # if it already looks like an id, trust it and return it rightaway
    return $name 
	if ( $name =~ m/^\d+/ );

    my $endpoint = '/projects/' . $pid . '/repository/branches';
  
    my @results;								 
    @results = @{ $this->rest_get_list( $endpoint ) }; 
    @results = grep{ $_->{ 'name' } =~ m/${name}/ } @results;

    if ( @results == 1 ) {
	return $results[0]->{ 'id' };
    }
    
    die "Cannot find uniq match for branch name $name.\n";

    return;
}

sub get_user_id {
    my ( $this, $user_name, %args ) = @_;

    # if it already looks like an id, trust it and return it rightaway
    return $user_name 
	if ( $user_name =~ m/^\d+/ );

    my @results = @{ $this->rest_get_list( '/users?search=' . $user_name ) };
    if ( @results == 1 ) {
	return $results[0]->{ 'id' };
    }
    if ( @results && exists $args{ 'multiple' } ) {
	return [ map { $_->{ 'id' } } @results ];
    } else {
	my @exact_match = grep { $_->{ 'username' } eq $user_name } @results;
	if ( @exact_match ) {
	    return $exact_match[0]->{ 'id' };
	}
    }
    die 'Cannot find ' . ( exists $args{ 'multiple' } ? 'any' : 'uniq'
	) . " match for user name $user_name.\n";

    return;
}

sub verify_user_id {
    my ( $this, $user_id ) = @_;

    my $user_data;
    try {
	$user_data = $this->rest_get_single( '/users/' . $user_id );
    };
    if ( $user_data ) {
	return $user_id;
    }
    return;
}

sub get_group_id {
    my ( $this, $grpname, %args ) = @_;

    # if it already looks like an id, trust it and return it rightaway
    if ( $grpname =~ m/^\d+/ ) {
	return $grpname
	    if ( not exists $args{ 'verify' } );
	$this->rest_get_single( "/groups/$grpname" );
	return $grpname; # .. else an exception is raised
    }

    $grpname = url_encode( $grpname );
    my $grp;
    try {
	$grp = $this->rest_get_single( "/groups/$grpname" );
    } catch {
	chomp $_;
	die "** Error: Cannot find group \"$grpname\": $_\n";
    };
    return $grp->{ 'id' };
    
    my @groups = @{ $this->my_groups() };
     $this->preference( 'debug' ) && print "** get_group_id, my_groups = " . dump( @groups ) . "\n";
    my @matches;
    if ( exists $args{ 'exact-match' } ) {
	 $this->preference( 'debug' ) && print "*** get_group_id look for exact match of $grpname \n";
	@matches = grep { $_->[2] eq $grpname } @{ $this->my_groups() };
	 $this->preference( 'debug' ) && print "** get_group_id has matches: " . dump( @matches ) . "\n";
    } else {
	@matches = grep { ( $_->[0] =~
			   m/\b${grpname}/ ) or
			   ( $_->[2] =~
			     m/\b${grpname}/) } @{ $this->my_groups() };
    }
    
    if ( @matches == 1 ) {
	return $matches[0]->[1];
    }
    if ( @matches && exists $args{ 'multiple' } ) {
	$this->preference( 'debug' ) && print "*** Got multi-groups: " . scalar( @matches ) . "\n";
	return [ map { $_->[1] } @matches ];
    }
    die 'Cannot find ' . ( exists $args{ 'multiple' } ? 'any' : 'uniq'
	) . " match for group name $grpname.\n";

    return;
}

sub get_group_closure {
    my ( $this, $grpname ) = @_;

    my $gid = $this->get_group_id( $grpname, 'exact-match' => 1 );
    my @closure = ( $gid );
    
    my $groups = $this->rest_get_list( '/groups/' );
    $this->preference( 'debug' ) && print "** get_group_closure - group_data: " . dump( $groups ) . "\n";
    my @child_closure = $this->close_group( $gid, $groups );
    if ( @child_closure ) {
	push( @closure, @child_closure );
    }

    return \@closure;
}


sub get_group_from_id {
    my ( $this, $grp_id ) = @_;

    my $endpoint = '/groups/';
    my $result_obj;
    try {
	$result_obj = $this->rest_get_single( $endpoint . $grp_id );
    } catch {
	chomp $_;
	die "** Cannot retrieve group with id $grp_id: $_\n";
    };

    return $result_obj;
}


sub close_group {
    my ( $this, $parent_id, $group_data ) = @_;

    my @child_groups = map { $_->{ 'id' } } 
        grep { $_->{ 'parent_id' } == $parent_id } @{ $group_data };
    my @closure;
    foreach my $this_child_id ( @child_groups ) {
	push( @closure, $this_child_id, $this->close_group( $this_child_id ) );
    }
    $this->preference( 'debug' ) && print "*** close group $parent_id -> " . dump( @closure ) . "\n";
    return @closure;
}

sub register_project {
    my ( $this, $project ) = @_;

    if ( exists $this->{ 'my_projects' } ) {
	my @hits = grep { $_->{ 'id' } eq $project->{ 'id' } } @{ $this->{ 'my_projects' } };
	if ( not @hits ) {
	    push( @{ $this->{ 'my_projects' } }, $project );
	} else {
	    foreach my $rp (  @{ $this->{ 'my_projects' } } ) {
		if ( $rp->{ 'id' } eq $project->{ 'id' } ) {
		    %{ $rp } = %{ $project };
		    last;
		}
	    }
	}
    }
    if ( exists $this->{ 'all_projects' } ) {
	my @hits = grep { $_->{ 'id' } eq $project->{ 'id' } } @{ $this->{ 'all_projects' } };
	if ( not @hits ) {
	    push( @{ $this->{ 'all_projects' } }, $project );
	} else {
	    foreach my $rp (  @{ $this->{ 'all_projects' } } ) {
		if ( $rp->{ 'id' } eq $project->{ 'id' } ) {
		    %{ $rp } = %{ $project };
		    last;
		}
	    }
	}
    }

    return $this;
}

sub unregister_project {
    my ( $this, $project ) = @_;

    if ( exists $this->{ 'my_projects' } ) {
	if ( grep { $_->{ 'id' } eq $project->{ 'id' } } @{ $this->{ 'my_projects' } } ) {
	    @{ $this->{ 'my_projects' } } = 
		grep { $_->{ 'id' } ne $project->{ 'id' } } @{ $this->{ 'my_projects' } };
	}
    }
    if ( exists $this->{ 'all_projects' } ) {
	if ( grep { $_->{ 'id' } eq $project->{ 'id' } } @{ $this->{ 'all_projects' } } ) {
	    @{ $this->{ 'all_projects' } } = 
		grep { $_->{ 'id' } ne $project->{ 'id' } } @{ $this->{ 'all_projects' } };
	}
    }

    return $this;
}

sub my_projects_in_groups {
    my ( $this, $grp_ids, %args ) = @_;

    my @prj_data;
    foreach my $gid ( @{ $grp_ids } ) {
	my @pdat;
	if ( not exists $this->{ 'my_projects_in_group' }->{ $gid } ) {
	    $this->preference( 'verbose' ) && print "** get projects for group $gid\n";
	    push( @pdat, map { { 'name' => $_->{ 'name' },
				     'group-id' => $gid,
				     'name_with_namespace' => $_->{ 'name_with_namespace' },
				     'path' => $_->{ 'path' },
				     'visibility' => $_->{ 'visibility' },
				     'url_encoded_path' => url_encode(
					 $_->{ 'path_with_namespace' } ),
					 'path_with_namespace' => $_->{ 'path_with_namespace' },
					 'description' => $_->{ 'path_with_namespace' },
					 'ssh_url_to_repo' => $_->{ 'ssh_url_to_repo' },
					 'http_url_to_repo' => $_->{ 'ssh_url_to_repo' },
					 'web_url' => $_->{ 'ssh_url_to_repo' },
					 'id' => $_->{ 'id' } } } @{ $this->get_list_data( '/api/'
											   . $this->api_version()
											   . "/groups/$gid/projects"
									 ) } );
	    $this->{ 'my_projects_in_group' }->{ $gid } = \@pdat;
	}
	if ( ( exists $this->{ 'my_projects_in_group' }->{ $gid } )and
	     ( ref $this->{ 'my_projects_in_group' }->{ $gid } eq 'ARRAY' ) ) {
	    push( @prj_data, @{ $this->{ 'my_projects_in_group' }->{ $gid } } );
	}
    }
    if ( exists $args{ 'map' } ) {
	return [ map { $_->{ $args{ 'map' } } } @prj_data ];
    }
    return \@prj_data;
}

sub my_projects {
    my ( $this, %args ) = @_;

    if ( not exists $this->{ 'my_projects' } ) {
#	$this->{ 'my_projects' } = $this->rest_get_list( "/projects?owned=true&simple=true");
	$this->{ 'my_projects' } = $this->rest_get_list( "/projects?owned=true");
    }
    return $this->{ 'my_projects' };
}

sub all_projects {
    my ( $this, %args ) = @_;

    my @prj_data;
    if ( not exists $this->{ 'all_projects' } ) {
	$this->print( "[ *patience* -- initializing full project cache; this may take a while.]\n" );
	my $endpoint = '/projects';
	push( @prj_data, map { { 'name' => $_->{ 'name' },
				 'name_with_namespace' => $_->{ 'name_with_namespace' },
				 'path' => $_->{ 'path' },
				 'url_encoded_path' => url_encode(
				     $_->{ 'path_with_namespace' } ),
				 'path_with_namespace' => $_->{ 'path_with_namespace' },
				 'ssh_url_to_repo' => $_->{ 'ssh_url_to_repo' },
				 'id' => $_->{ 'id' } } } 
	      @{ $this->rest_get_list( $endpoint ) }
	    ); 
	$this->{ 'all_projects' } = \@prj_data;
    }

    if ( exists $args{ 'map' } ) {
	return [ map { $_->{ $args{ 'map' } } } @{ $this->{
	    'all_projects' }} ];
    }
    return $this->{ 'all_projects' };
}

# look through all cached project data and return the first entry
# found that has the sought id
# 
sub get_project {
    my ( $this, $pid ) = @_;

    my $prj;
    foreach my $l ( qw( all_projects my_projects ) ) {
	if ( exists $this->{ $l } ) {
	    my @prj = grep{ $_->{ 'id' } == $pid } @{ $this->{ $l } };
	    if ( @prj ) {
		return shift @prj;
	    }
	}
    }
    if ( exists $this->{ 'my_projects_in_group' } ) {
	foreach my $g ( keys %{ $this->{ 'my_projects_in_group' } } ) {
	    my @prj = grep{ $_->{ 'id' } == $pid } @{ $this->{ 'my_projects_in_group' }->{ $g } };
	    if ( @prj ) {
		return shift @prj;
	    }
	}
    }
    return;
}

# update $project objects with id == $project->{ id } in all
# cached project data
#
sub update_project {
    my ( $this, $project ) = @_;

    my $pid = $project->{ 'id' };
    my $prj;
    foreach my $l ( qw( all_projects my_projects ) ) {
	if ( exists $this->{ $l } ) {
	    my @prj = grep{ $_->{ 'id' } == $pid } @{ $this->{ $l } };
	    if ( @prj ) {
		%{ $prj[0] } = %{ $project };
	    }
	}
    }
    if ( exists $this->{ 'my_projects_in_group' } ) {
	foreach my $g ( keys %{ $this->{ 'my_projects_in_group' } } ) {
	    my @prj = grep{ $_->{ 'id' } == $pid } @{ $this->{ 'my_projects_in_group' }->{ $g } };
	    if ( @prj ) {
		%{ $prj[0] } = %{ $project };
	    }
	}
    }
    return;
}    

sub condense_comments {
    my ( $this, $item_comment ) = @_;

    return [ map { '('. $_->{ 'id' } . ') ' . $this->short_date( $_->{ 'updated_at' } ) . ', ' . 
		       $_->{ 'author' }->{ 'name' } . ":\n  " .
		       '-' x length( '('. $_->{ 'id' } . ') ' . 
				     $this->short_date( $_->{ 'updated_at' } ) . 
				     ', ' . $_->{ 'author' }->{ 'name' } . 
				     ':' ) . "\n" .
		       $this->wrap_text( $_->{ 'body' }, '  ' ) . "\n" } 
	     reverse @{ $item_comment } ];
}

sub short_date {
    my ( $this, $dstring ) = @_;

    # truncate jira timestrings "2017-07-19T18:39:07.087+0200" =>
    #               "2017-07-19 18:39"
    $dstring =~ s/:\d\d\..*//;
    $dstring =~ s/T/ /;

    return $dstring;
}

sub wrap_text {
    my ( $this, $text, $indent ) = @_;

    $indent ||= '  ';
    
    my @text = map { $_ =~ s/[^[:print:]]+//g; $_ } split( "\n", $text );
    # remove the occasional non-printable junk
    local $Text::Wrap::columns = 80;
    $text = join( "\n", map { wrap( $indent, $indent, $_ ) } @text );

    return $text;
}

sub my_groups {
    my $this = shift;

    if ( not exists $this->{ 'my_groups' } ) {
	my $grp_data =  $this->rest_get_list( '/groups/' );
	$this->{ 'my_groups' } = [ map { [ $_->{ 'name' }, $_->{'id'}, $_->{ 'full_path' } ]
				   } @{ $grp_data } ];
    }
    return $this->{ 'my_groups' };
}

sub register_webhooks {
    my ( $this, $webhooks ) = @_;

    if ( not (( ref $webhooks eq 'ARRAY' ) and @{ $webhooks } )) {
	return $this;
    }
    if ( not exists $this->{ 'webhooks' } ) {
	$this->{ 'webhooks' } = {};
    }
    foreach my $wh ( @{ $webhooks } ) {
	$this->{ 'webhooks' }->{ $wh->{ 'id' } } = $wh;
    }
    return $this;
}

sub get_webhooks {
    my $this = shift;

    if ( exists $this->{ 'webhooks' } ) {
	return $this->{ 'webhooks' };
    }
    return;
}

sub webhook_events {
    my @events = qw( 
push_events
tag_push_events
note_events
issues_events
merge_requests_events
job_events
pipeline_events
wiki_page_events
);
    return \@events;
}

sub compile_webhook_id {
    my ( $this, $webhook, $pname ) = @_;

    my $event_triggered = join( '', map { $webhook->{ $_ } } @{ $this->webhook_events() } );
    my $name = $webhook->{ 'url' };
    $name =~ s/\?.*$//;
    my $format = "%d: %d (%s) %s %s";

    return sprintf( $format, $webhook->{ 'id' }, $webhook->{ 'project_id' }, $pname, $event_triggered, $name );
}

sub get_list_count {
    my ( $this, $endpoint ) = @_;

    my $headers = $this->get_auth_header();
    my $client = $this->get_rest_client();
    my $webhost = $client->{ '_config' }->{ 'host' };

    my $base_url = $this->get_base_url() . ( $endpoint =~ m/^\// ? '' : '/' ) . $endpoint;
    $base_url =~ s/\/+/\//; # turn multiple subsequent '////' into a single '/'

    if ( $this->preference( 'verbose' ) ) {
	if ( $this->preference( 'debug' ) ) {
	    $this->print( 'Headers: ' . Dumper( $headers ) . "\n" );
	}
	$this->print( __PACKAGE__ . '::get_list_count - GET ' . $base_url . "\n" );
    }
    if ( $this->preference( 'show_curl' ) ) {
	$this->print( 'curl -k -D- -X GET' );
	while ( my ( $k, $v ) = each %{ $headers } ) {
	    $this->print( " -H '$k: $v'" );
	}
	$this->print( ' ' . $webhost . $base_url . "\n" );
    }

    $client->GET(
	$base_url,
	$headers
	);
    if ( is_error( $client->responseCode() )) {
	die status_message( $client->responseCode() ) . "\n";
    }
    my @response_headers = $client->responseHeaders();
    my $item_count = $client->responseHeader( 'X-Total' );
    
    return $item_count;
}


# canonicalize maps "nouns" in the generator template's parameter definitions
# to the applicable endpoint name for the rest_get request used to determine 
# a referenced resource's id 
sub canonicalize {
    my $classname = shift;

    my $canon_name = {
	'namespace' => '/namespaces?search=%s',
	'project' => '/projects?search=%s',
	'group' => '/groups?search=%s',
	'branch' => '/projects/%s/repository/branches/%s',
        'label' => '/projects/%s/labels',
    }->{ $classname };

    return $canon_name ? $canon_name : $classname;
}


sub substitute_format {
    my ( $this, $format, $data, %params ) = @_;

    my $result = $format;
    $result =~ s/^"//;
    $result =~ s/"$//s;
    $result =~ s/\\n/\n/g;
    
    my $check_field_maps = 0;
    if ( exists $params{ 'check_mapped' } ) {
	$check_field_maps = 1;
    }

    if ( exists $data->{ 'id' } ) {
	my $s = $data->{ 'id' };
	$result =~ s/%i/${s}/gs;
    }
    if ( exists $data->{ 'description' } ) {
	my $s = $data->{ 'description' };
	$result =~ s/%D/${s}/gs;
    }
    if ( exists $data->{ 'name' } ) {
	my $s = $data->{ 'name' };
	$result =~ s/%n/${s}/gs;
    }
    if ( exists $data->{ 'version' } ) {
	my $s = $data->{ 'version' } ;
	$result =~ s/%V/${s}/gs;
    }
    if ( exists $data->{ 'web_url' } ) {
	my $s = $data->{ 'web_url' } ;
	$result =~ s/%U/${s}/gs;
    }
    if ( exists $data->{ 'full_path' } ) {
	my $s = url_encode( $data->{ 'full_path' } );
	$result =~ s/%I/${s}/gs;
    }
    if ( exists $data->{ 'path_with_namespace' } ) {
	my $s = url_encode( $data->{ 'path_with_namespace' } );
	$result =~ s/%I/${s}/gs;
    }
    if ( exists $data->{ 'name_with_namespace' } ) {
	my $s = $data->{ 'name_with_namespace' };
	$result =~ s/%N/${s}/gs;
    }
    if ( $format =~ m/%Pn/ and exists $data->{ 'project_id' } ) {
	my $p_name;
	$p_name = $this->get_project_from_id( $data->{ 'project_id' } )->{ 'name' };
	$result =~ s/%Pn/${p_name}/gs;
    }

    # dynamic substitution based on name of field
    # this substitution works for nested fields as well

    while ( $result =~ m/%F:([A-Za-z_\-.]+)([({](\d+)[)}])?/igm ) {
	my $fld = $1;
	my $width;
	if ( $3 ) {
	    $width = $3;
	}
	# for referencing custom fields by their user space names
	if ( $check_field_maps ) {
	    $fld = $this->reverse_map_field( $fld );
	}
	my @flds = split(/\./, $fld );
	my $s = $data;
	foreach my $f ( @flds ) {
	    if ( ref $s and ref $s->{ $f } eq 'ARRAY' ) {
		# try to be smart...
		if ( ref ${ $s->{ $f }}[0] eq 'HASH' ) {
		    # if this is an array of hashes, we try to map it
		    if ( exists ${ $s->{ $f }}[0]->{ 'name' } ) {
			$s = join( "\n  ", map { $_->{ 'name' } } @{ $s->{ $f } });
		    } else {
			$s = join( "\n  ", map { printhash( $_ ) } @{ $s->{ $f } });
		    }
		} else {
		    # the array appears to be scalars
		    $s = join( "\n  ", @{ $s->{ $f } } );
		}
		next;
	    } elsif ( ( ref $s eq 'HASH' ) and exists $s->{ $f } ) {
		$s = $s->{ $f };
		next;
	    }
	    $s = undef;
	    last;
	}
	if ( $s ) {
	    # try to be smart...
	    if ( ref $s eq 'HASH' ) {
		if ( exists $s->{ 'name' } ) {
		    $s = $s->{ 'name' };
		} else {
		    $s = join(',', keys %{ $s });
		}
	    }
	    if ( $width ) {
		if ( length( $s ) > $width ) {
		    # cut excess tail
		    $s = substr( $s, 0, $width );
		}
		$s = sprintf( "%-${width}s", $s );
	    }
	    $result =~ s/%F:${fld}([({](\d+)[)}])?/${s}/m;
	}
    }
    return $result;
}

sub old_substitute_format {
    my ( $this, $format, $data, %params ) = @_;

    my $result = $format;
    $result =~ s/^"//;
    $result =~ s/"$//s;
    $result =~ s/\\n/\n/g;

    my $check_field_maps = 0;
    if ( exists $params{ 'check_mapped' } ) {
	$check_field_maps = 1;
    }

    if ( exists $data->{ 'id' } ) {
	my $s = $data->{ 'id' };
	$result =~ s/%i/${s}/gs;
    }
    if ( exists $data->{ 'description' } ) {
	my $s = $data->{ 'description' };
	$result =~ s/%D/${s}/gs;
    }
    if ( exists $data->{ 'name' } ) {
	my $s = $data->{ 'name' };
	$result =~ s/%n/${s}/gs;
    }
    if ( exists $data->{ 'mode' } ) {
	my $s = oct2mode( $data->{ 'mode' } );
	$result =~ s/%m/${s}/gs;
    }
    if ( exists $data->{ 'full_path' } ) {
	my $s = url_encode( $data->{ 'full_path' } );
	$result =~ s/%I/${s}/gs;
    }
    if ( exists $data->{ 'path_with_namespace' } ) {
	my $s = url_encode( $data->{ 'path_with_namespace' } );
	$result =~ s/%I/${s}/gs;
    }
    if ( exists $data->{ 'name_with_namespace' } ) {
	my $s = $data->{ 'name_with_namespace' };
	$result =~ s/%N/${s}/gs;
    }
    print "*** trying to resolve project name from data $data: " . Tracer::phash( $data ) . "\n";
    if ( $format =~ m/%Pn/ and exists $data->{ 'project_id' } ) {
	my $p_name;
#	try {
	    $p_name = $this->get_project_from_id( $data->{ 'project_id' } )->{ 'name' };
#	} catch {
#	    $p_name = '*undefined*';
#	};
	$result =~ s/%Pn/${p_name}/gs;
    }
    if ( exists $data->{ 'path' } ) {
	my $s = $data->{ 'path' };
	$result =~ s/%p/${s}/gs;
    }
    if ( exists $data->{ 'full_path' } ) {
	my $s = $data->{ 'full_path' } ;
	$result =~ s/%P/${s}/gs;
    }
    if ( exists $data->{ 'ssh_url_to_repo' } ) {
	my $s = $data->{ 'ssh_url_to_repo' } ;
	$result =~ s/%S/${s}/gs;
    }
    if ( exists $data->{ 'http_url_to_repo' } ) {
	my $s = $data->{ 'http_url_to_repo' } ;
	$result =~ s/%H/${s}/gs;
    }
    if ( exists $data->{ 'version' } ) {
	my $s = $data->{ 'version' } ;
	$result =~ s/%V/${s}/gs;
    }
    if ( exists $data->{ 'web_url' } ) {
	my $s = $data->{ 'web_url' } ;
	$result =~ s/%U/${s}/gs;
    }

    # dynamic substitution based on name of field
    # this substitution works for nested fields as well
    while ( $result =~ m/%([Ff]):([A-Za-z_\-.]+)/igm ) {
	my $fmt_letter = $1;
	my $fld = $2;
	my $list_separator = ( $fmt_letter eq 'F' ) ? "\n  " : ', ';
	#print "*** Format letter = $fmt_letter, list separator = >$list_separator<\n";
	# for referencing custom fields by their user space names
	if ( $check_field_maps ) {
	    $fld = $this->reverse_map_field( $fld );
	}
	my @flds = split(/\./, $fld );
	my $s = $data;
	my $i = 0;
	while ( $i < @flds ) {
	    my $f = $flds[ $i++ ];
	    my $lookahead = ( $i < @flds ) ? $flds[ $i ] : undef;
	    if ( ( ref $s->{ $f } eq 'ARRAY' ) and ( @{ $s->{ $f } } ) ) {
		# try to be smart: if the last subscriptor in a %F format
		# references an array of hashes (i.e. there is no subscription *into* the hashes)
		# we try if there is a 'name' field, and take that as representation of the hash.
		# Otherwise we render the entire hashes.
		if (( ref ${ $s->{ $f }}[0] eq 'HASH' ) and not defined $lookahead ) {
		    # if this is an array of hashes, we try to map it
		    if ( exists ${ $s->{ $f }}[0]->{ 'name' } ) {
			$s = join( $list_separator, map { $_->{ 'name' } } @{ $s->{ $f } });
		    } else {
			$s = join( $list_separator, map { printhash( $_ ) } @{ $s->{ $f } });
		    }
		} elsif (( ref ${ $s->{ $f }}[0] eq 'HASH' ) and $lookahead ) {
		    if ( exists ${ $s->{ $f }}[0]->{ $lookahead } ) {
			$s = join( $list_separator, map { $_->{ $lookahead } } @{ $s->{ $f } });
		    } else {
			$s = join( $list_separator, map { printhash( $_ ) } @{ $s->{ $f } });
		    }
		} else {
		    # the array appears to be scalars
		    $s = join( $list_separator, @{ $s->{ $f } } );
		}
		last;
	    } elsif ( ref $s->{ $f } eq 'ARRAY' ) {
		# there is an array, but it is empty
		$s = undef;
		last;
	    } elsif ( ( ref $s eq 'HASH' ) and exists $s->{ $f } ) {
		$s = $s->{ $f };
		next;
	    }
	    $s = undef;
	    last;
	}
	if ( $s ) {
	    # try to be smart...
	    if ( ref $s eq 'HASH' ) {
		if ( exists $s->{ 'name' } ) {
		    $s = $s->{ 'name' };
		} else {
		    $s = join(',', keys %{ $s });
		}
	    }
	    $result =~ s/%${fmt_letter}:${fld}/${s}/m;
	}
    }
    return $result;
}


sub printhash {
    my $hash = shift;

    my @res;
    while ( my ( $k, $v ) = each %{ $hash } ) {
	push( @res, "$k: $v" );
    }
    return join( '; ', @res );
}

sub format_required_fields {
    my ( $this, $format ) = @_;

    $format =~ s/\\n/\n/g;
    my %mapped = (
	'%i' => 'id',
	'%D' => 'description',
	'%n' => 'name',
	'%V' => 'version',
	'%U' => 'url'
	);
    
    my %fmt_fields;
    my @token = grep { m/^%/ } map{ $_ =~ s/^.+%/%/; $_ } split( /[\s\n]+/gm, $format );

    foreach my $t ( @token ) {
	if ( $t =~ m/%F:(\w+)/ ) {
	    $fmt_fields{ $1 } = 1;
	    next;
	}
	if ( exists $mapped{ $t } ) {
	    $fmt_fields{ $mapped{ $t } } = 1;
	}
    }
    my @rfld = sort keys %fmt_fields;

    return wantarray ? @rfld : join(',', @rfld );
}

sub oct2mode {
    my $omode = shift; # 6 digits;
    my $omap = {
	0 => '---',
	1 => '--x',
	2 => '-w-',
	3 => '-wx',
	4 => 'r--',
	5 => 'r-x',
	6 => 'rw-',
	7 => 'rwx'
    };
    my ( $p1, $p2 ) = ( substr( $omode, 0, 2), substr( $omode, 3) );
    my $rwxmode = '-';
    foreach my $m ( split( //, $p2 ) ) {
	$rwxmode .= $omap->{ $m };
    }
    return $rwxmode;
}

sub execute_endpoint_template {
    my ( $this, $ep_tmpl, $params ) = @_;

    my @ep_parts = split( '/', $ep_tmpl );
    for ( my $i = 0; $i < scalar( @ep_parts ); $i++ ) {
	if ( $ep_parts[ $i ] =~ m/^:([\w_-]+)/ ) {
	    my $subst = $params->{
		{
		    'project-id'  => 'project_id',
		    'id'          => 'id',
		    'branch-id'   => 'subject_id',
		    'group-id'    => 'group_id',
		    'user-id'     => 'user_id',
		    'pipeline_id' => 'subject_id',
		    'file-path'   => 'subject_id'
		}->{ $1 } };
	    if (( not $subst ) and ( $1 =~ m/(-id|key)/ )) {
		foreach my $try_param ( qw( subject_id id ) ) {
		    if ( defined $params->{ $try_param } ) {
			# special case: try to substitute :project-id by id if 'project_id' is not in params
			$subst = $params->{ $try_param };
			last;
		    }
		}
	    }
	    if ( not $subst ) {
		die "Cannot substitute URL endpoint variable \"$1\" - no such parameter supplied.\n";
	    }
	    $ep_parts[ $i ] = $subst;
	}
    }
    my $ep = join( '/', @ep_parts );
    $ep =~ s/\/\//\//; # be tolerant about endpoint templates beginning with '/'
    return $ep;
}

sub build_params {
    my ( $this, $params ) = @_;

    foreach my $k ( qw ( help long short force ) ) {
	delete $params->{ $k };
    }
    my %built_params;
    foreach my $k ( keys %{ $params } ) {
	if ( defined $params->{ $k } ) {
	    $built_params{ $k } = $params->{ $k };
	}
    }
    return \%built_params;
}

sub get_namespace_id {
    my ( $this, $namespace_n ) = @_;

    my @nspc = grep { $_->{ 'name' } =~ m/^${ namespace_n }$/i }
    @{ $this->get_list_data( '/api/' . $this->preference(
				 'gitlab_api_version' ) . "/namespaces?search=$namespace_n", 100 ) };
    if ( not @nspc ) {
	die "Unknown namespace \"$namespace_n\"\n";
    }
    my $ns = shift( @nspc );
#    print "Namespace Data: " . Dumper( $ns ) . "\n";
    return $ns->{ 'id' };
}

# Use with Try::Tiny
sub get_user {
    my ( $this, $user_email ) = @_;

    my @user = 
    @{ $this->get_list_data( '/api/' .  $this->preference(
				 'gitlab_api_version' )
    . '/users?search=' . $user_email, 100 ) }; 
    if ( not @user ) {
	die "Unknown user(s) \"$user_email\"\n";
    }
    if ( not @user == 1 ) {
	print Dumper( \@user ) . "\n";
	die "Ambiguous user fragment \"$user_email\"\n";
    }
    my $user = shift( @user );
#    print "User Data: " . Dumper( $user ) . "\n";

    return $user;
}    

sub access_level {
    my ( $this, $level_name ) = @_;

    my $lvls = {
	'Guest access' => 10 ,
	'Reporter access' => 20,
	'Developer access' => 30,
	'Master access' => 40,
	'Owner access' => 50
    };
    my $i_lvls;
    while ( my ( $k, $v ) = each %{ $lvls } ) { $i_lvls->{ $v } = $k };
    if ( not $level_name ) {
	return [ keys %{ $lvls } ];
    }
    if ( $level_name =~ m/^\d+/ ) {
	return $i_lvls->{ $level_name }
	    if ( exists $i_lvls->{ $level_name } );
	die "Invalid access level: $level_name\n";
    }
    my @lkey = grep { m/$level_name/i } keys %{ $lvls };
    if ( @lkey != 1 ) {
	die "Invalid access level: $level_name\n";
    }
    
    return $lvls->{ shift @lkey };
}

sub min {
    my ( $a, $b ) = @_;

    return ( $a > $b ) ? $b : $a;
}


1;
