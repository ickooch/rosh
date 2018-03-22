package build_id;
require Exporter;
@ISA = qw(Exporter);
@EXPORT = qw (
	      $build_id
	      $build_time
	      );
BEGIN {
    $build_id = "*INTERIM* (built on 18/02/08 18:07 by z003j54j on MD1HBDRC in view )";
    $build_time = 1518113259;
}

1;
