#!/usr/bin/env perl

use 5.010;
use strict;
use warnings;
use File::Path qw(make_path);
use File::Find;

my $target_variable = $ARGV[0];
my $rainType        = $ARGV[0];

my $timeScale = "validation";
my $input_dir = "../data_climate_WRF_ncfTypeAscii";
my $check_folder = "../point_extraction/daily/${target_variable}";


open my $xlong_file,  "<", "../define/ref_XLONG.txt" or die "cannot open xlong file: $!\n";;
open my $xlat_file,   "<", "../define/ref_XLAT.txt"  or die "cannot open xlat file: $!\n";;
open my $domain_file, "<", "../define/domain.txt"    or die "cannot open domain file: $!\n";;

#*#*#*# read domain to cut information to specific region
my (%domain);
while (<$domain_file>) {
    portable_chomp();
    s/ //g;
    my @arr = split /,/;
    $domain{ $arr[0] } = $arr[1];
}
close $domain_file;

#*#*#*# read xy_coordinate information from Weather Research and Forecasting (WRF) Model
my $xlong_data_line = 0;
my ( %xlong, @xlong_west_east, $xlong_time, $xlong_south_north );

while (<$xlong_file>) {
    portable_chomp();
    s/ //g;
    my @dimension;
    if ( $_ =~ "//XLONG" ) {
        $xlong_data_line += 1;
        @dimension = split( /\(|\,|\)/, $_ );
        $xlong_south_north = $dimension[-2];
    }
    next if ( $xlong_data_line == 0 );
    next if ( $_ =~ "//XLONG" );
    my @arr = split /,/;
    push @xlong_west_east, @arr;

    if ( $#xlong_west_east == 418 ) {
        for my $i ( 0 .. $#xlong_west_east ) {
            # say $xlong_south_north;
            $xlong{$xlong_south_north}{$i} = $xlong_west_east[$i];
            # $count ++;
        }
        @xlong_west_east = ();
    }
}
close $xlong_file;

my $xlat_data_line = 0;
my ( %xlat, @xlat_west_east, $xlat_time, $xlat_south_north );

while (<$xlat_file>) {
    portable_chomp();
    s/ //g;
    my @dimension;
    if ( $_ =~ "//XLAT" ) {
        $xlat_data_line += 1;
        @dimension = split( /\(|\,|\)/, $_ );
        $xlat_south_north = $dimension[-2];
    }
    next if ( $xlat_data_line == 0 );
    next if ( $_ =~ "//XLAT" );
    my @arr = split /,/;
    push @xlat_west_east, @arr;

    if ( $#xlat_west_east == 418 ) {
        for my $i ( 0 .. $#xlat_west_east ) {
            # say $xlat_south_north;
            $xlat{$xlat_south_north}{$i} = $xlat_west_east[$i];
        }
        @xlat_west_east = ();
    }
}
close $xlat_file;


my (%check);
find({preprocess => sub { return sort @_ }, wanted => \&checking, no_chdir => 1}, $check_folder);
find({preprocess => sub { return sort @_ }, wanted => \&process, no_chdir => 1, follow_fast => 1 }, $input_dir );


sub checking {
	return unless -f $File::Find::name;
	my ($year,$date);
	my $size = -s $File::Find::name;
	next if ($File::Find::name =~ /schema.ini/);
	if ($size > 0){
		if ($File::Find::name =~ /SSP2_${target_variable}_daily_(....)-(...)_pointData/){
			$year = $1;
			$date = $2;
		}
		$check{$year} += 1;
	}
}

sub process {
    return unless -f $File::Find::name;
    return
        unless ( ( $File::Find::name =~ $timeScale )
        && ( $File::Find::name =~ $target_variable ) );

    my ( $year, $variable_name );
    if ( $File::Find::name =~ /d01_(.*)-01-01_00-00-00_(.*).txt/ ) {
        $year          = $1;
        $variable_name = $2;
    }
	
	next if (($check{$year}) and ($check{$year} >= 365));
    
	open my $var_fh, "<", $File::Find::name or die;

    #*#*#*# read variable information from Weather Research and Forecasting (WRF) Model
	say $File::Find::name;
	
    my $variable_data_line  = 0;
    my $hourly_count_perDay; 
	if ($timeScale == "validation"){
		$hourly_count_perDay = 24;
	}else{
		$hourly_count_perDay = 4;
	}
	
    my $day_change_check    = 0;

    my ( %rain_day, %rain_hour, @variable_west_east, $day, $hour, $time_total,
        $variable_time, $variable_south_north );
    my ( $number_arr_west_east, $number_arr_south_north );
    while (<$var_fh>) {
        portable_chomp();

        if (/Time = UNLIMITED \; \/\/ \((\d+) currently\)/) {
            $time_total = $1;
        }
        if (/west_east = (\d+)/) {
            $number_arr_west_east = $1 - 1;
        }
        if (/south_north = (\d+)/) {
            $number_arr_south_north = $1 - 1;
        }

        s/ //g;
        s/;//g;

        my @dimension;
        if ( $_ =~ "//${variable_name}" ) {
            $variable_data_line += 1;
            @dimension            = split( /\(|\,|\)/, $_ );
            $variable_time        = $dimension[-3];
            $variable_south_north = $dimension[-2];
            $day                  = int( $variable_time / $hourly_count_perDay ) + 1;
            $hour                 = $variable_time % 24;
        }
        next if $variable_data_line == 0;
        next if ( $_ =~ "//${variable_name}" );
        next if ( $_ =~ "}" );

        my @arr = split /,/;
        #say( scalar(@arr) . " - " . "[" . join("][", @arr) . "]" );
        push @variable_west_east, @arr;

        if ( $#variable_west_east == $number_arr_west_east ) {
            for my $i ( 0 .. $#variable_west_east ) {
                if ( $rain_hour{$day}{$hour}{$variable_south_north}{$i} ) {
                    $rain_hour{$day}{$hour}{$variable_south_north}{$i} += $variable_west_east[$i];
                }
                else {
                    $rain_hour{$day}{$hour}{$variable_south_north}{$i} = $variable_west_east[$i];
                }
            }
            @variable_west_east = ();

            if ( $variable_south_north == $number_arr_south_north ) {
                # say {$debug} "1";
                $day_change_check++;
            }
            if ( $day_change_check == $hourly_count_perDay ) {
                $day_change_check = 0; #reset count;
                my $day_name = sprintf( '%03s', $day );

                my (%dir_of);
                $dir_of{hourly} = "../point_extraction/hourly/${rainType}/${year}";
                $dir_of{daily}  = "../point_extraction/daily/${rainType}/${year}";
                for my $dir ( values(%dir_of) ) {
                    make_path($dir);
                }

             
                # for hourly analysis
                {
                    warn "hourly before outer for and sort\n";
                    for my $day ( sort { $a <=> $b } keys(%rain_hour) ) {
                        warn "hourly before inner for and sort\n";
                        for my $hour ( sort { $a <=> $b } keys( %{ $rain_hour{$day} } ) ) {
                            my $hour_str = sprintf( '%02s', $hour );
                            warn "hourly analysis: $day - $hour_str\n";
                            my $file =
                                "$dir_of{hourly}/SSP2_${rainType}_hourly_${year}-${day_name}-${hour_str}_pointData.txt";
                            open my $fh, ">", $file or die "cannot open file to write: $file: $!\n";
                            say $fh "x,y,values";
                            for my $y_coordinate_ref ( sort { $a <=> $b } keys( %{ $rain_hour{$day}{$hour} } ) )
                            {
                                for my $x_coordinate_ref (
                                    sort { $a <=> $b }
                                    keys( %{ $rain_hour{$day}{$hour}{$y_coordinate_ref} } )
                                    )
                                {
                                    next if ( $xlat{$y_coordinate_ref}{$x_coordinate_ref} + 1 < $domain{"bottom"} );
                                    next if ( $xlat{$y_coordinate_ref}{$x_coordinate_ref} - 1 > $domain{"top"} );
                                    next if ( $xlong{$y_coordinate_ref}{$x_coordinate_ref} + 1 < $domain{"left"} );
                                    next if ( $xlong{$y_coordinate_ref}{$x_coordinate_ref} - 1 > $domain{"right"} );
                                 	my $prcp;
									if ($day == 1 and $hour == 0){
										$prcp = $rain_hour{$day}{$hour}{$y_coordinate_ref}{$x_coordinate_ref};
									}elsif ($day == 1 and $hour > 0){
										$prcp = $rain_hour{$day}{$hour}{$y_coordinate_ref}{$x_coordinate_ref} - $rain_hour{$day}{$hour-1}{$y_coordinate_ref}{$x_coordinate_ref};
									}elsif ($day > 1 and $hour == 0){
										$prcp = $rain_hour{$day}{$hour}{$y_coordinate_ref}{$x_coordinate_ref} - $rain_hour{$day-1}{23}{$y_coordinate_ref}{$x_coordinate_ref};
									}else{
										$prcp = $rain_hour{$day}{$hour}{$y_coordinate_ref}{$x_coordinate_ref} - $rain_hour{$day}{$hour-1}{$y_coordinate_ref}{$x_coordinate_ref};
									}
									say $fh join( ",",
                                        $xlong{$y_coordinate_ref}{$x_coordinate_ref},
                                        $xlat{$y_coordinate_ref}{$x_coordinate_ref},
                                        $prcp);
										
									$rain_day{$day}{$y_coordinate_ref}{$x_coordinate_ref} += $prcp;
                                }
                            }
                            close $fh;
                        }
                    }
                }
				if {$day > = 2}{
					delete $rain_hour{$day-1};
				}
				
                # for daily analysis
                warn "daily analysis: $day - $hour\n";
                {
                    my $file = "$dir_of{daily}/SSP2_${rainType}_daily_${year}-${day_name}_pointData.txt";
                    open my $fh, ">", $file or die "cannot open file to write: $file: $!\n";
                    say $fh "x,y,values";
                    warn "daily before for and sort\n";
                    for my $day ( sort { $a <=> $b } keys(%rain_day) ) {
                        for my $y_coordinate_ref ( sort { $a <=> $b } keys( %{ $rain_day{$day} } ) ) {
                            for my $x_coordinate_ref (
                                sort { $a <=> $b }
                                keys( %{ $rain_day{$day}{$y_coordinate_ref} } )
                                )
                            {
                                unless ( $xlat{$y_coordinate_ref} ) {
                                    warn "\$xlat{$y_coordinate_ref} is undefined\n";
                                    unless ( $xlat{$y_coordinate_ref}{$x_coordinate_ref} ) {
                                        warn "\$xlat{$y_coordinate_ref}{$x_coordinate_ref} is undefined\n";
                                    }
                                    next;
                                }
                                unless ( $xlong{$y_coordinate_ref} ) {
                                    warn "\$xlong{$y_coordinate_ref} is undefined\n";
                                    unless ( $xlong{$y_coordinate_ref}{$x_coordinate_ref} ) {
                                        warn "\$xlong{$y_coordinate_ref}{$x_coordinate_ref} is undefined\n";
                                    }
                                    next;
                                }
                                next if ( $xlat{$y_coordinate_ref}{$x_coordinate_ref} + 1 < $domain{"bottom"} );
                                next if ( $xlat{$y_coordinate_ref}{$x_coordinate_ref} - 1 > $domain{"top"} );
                                next if ( $xlong{$y_coordinate_ref}{$x_coordinate_ref} + 1 < $domain{"left"} );
                                next if ( $xlong{$y_coordinate_ref}{$x_coordinate_ref} - 1 > $domain{"right"} );
                                
					
								say $fh join( ",",
                                    $xlong{$y_coordinate_ref}{$x_coordinate_ref},
                                    $xlat{$y_coordinate_ref}{$x_coordinate_ref},
                                    $rain_day{$day}{$y_coordinate_ref}{$x_coordinate_ref} );
                            }
                        }
                    }
                    close $fh;
                }
				
            }
        }

    }
    close $var_fh;
}

sub portable_chomp {
    my $line = shift;

    $_ //= $line;
    s/(?:\x{0d}?\x{0a}|\x{0d})$//; # chomp
}
