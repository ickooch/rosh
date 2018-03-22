package build_id;
require Exporter;
@ISA = qw(Exporter);
@EXPORT = qw (
	      $build_id
	      $build_time
	      );
BEGIN {
    $build_id = "*INTERIM* (built on 18/02/12 11:50 by z003j54j on MD1HBDRC in view )";
    $build_time = 1518436259;
}

1;
