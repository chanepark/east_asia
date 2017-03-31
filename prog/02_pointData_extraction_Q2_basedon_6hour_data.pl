use warnings;
use 5.010;
use File::Path qw(make_path);
use File::Find;


my $target_variable = $ARGV[0];
# my $target_variable = "Q2";
my $hourly = 6;
my $target_variable_name = "rhum";
my $timeScale = "wrfout";
my $input_folder = "../data_climate_WRF_ncfTypeAscii";
my $check_folder = "../point_extraction/daily/${target_variable_name}";
my $target_folder = "../point_extraction/daily";

open my $xlong_file ,"<", "../define/ref_XLONG.txt" or die;
open my $xlat_file ,"<", "../define/ref_XLAT.txt" or die;
open my $domain_file ,"<", "../define/domain.txt" or die;

# open my $debug ,">", "report.txt" or die;

#*#*#*# read domain to cut information to specific region 
my (%domain);
while(<$domain_file>){
	s/ //g;
	chomp;
	my @arr = split/,/;
	$domain{$arr[0]} = $arr[1];
}
close $domain_file;


#*#*#*# read xy_coordinate information from Weather Research and Forecasting (WRF) Model
my $xlong_data_line = 0;
my (%xlong,@xlong_west_east,$xlong_time,$xlong_south_north);

while(<$xlong_file>){
	s/ //g;
	chomp;
	my @dimension;
	if ($_ =~"//XLONG"){
		$xlong_data_line += 1;
		@dimension = split(/\(|\,|\)/,$_);
		$xlong_south_north = $dimension[-2];
	}
	next if ($xlong_data_line == 0);
	next if ($_ =~"//XLONG");
	my @arr = split/,/;
	push @xlong_west_east, @arr;
	
	if ($#xlong_west_east == 418){
		foreach my $i (0..$#xlong_west_east){
			# say $xlong_south_north;
			$xlong{$xlong_south_north}{$i} = $xlong_west_east[$i];
			# $count ++;
		}
		@xlong_west_east = ();
	}
}
close $xlong_file;


my $xlat_data_line = 0;
my (%xlat,@xlat_west_east,$xlat_time,$xlat_south_north);

while(<$xlat_file>){
	s/ //g;
	chomp;
	my @dimension;
	if ($_ =~"//XLAT"){
		$xlat_data_line += 1;
		@dimension = split(/\(|\,|\)/,$_);
		$xlat_south_north = $dimension[-2];
	}
	next if ($xlat_data_line == 0);
	next if ($_ =~"//XLAT");
	my @arr = split/,/;
	push @xlat_west_east, @arr;
	
	if ($#xlat_west_east == 418){
		foreach my $i (0..$#xlat_west_east){
			# say $xlat_south_north;
			$xlat{$xlat_south_north}{$i} = $xlat_west_east[$i];
		}
		@xlat_west_east = ();
	}
}
close $xlat_file;


#*#*#*# read variable information from Weather Research and Forecasting (WRF) Model
my (%check,%new);
find({wanted => \&checking, no_chdir => 1}, $check_folder);
find({wanted =>  \&process, no_chdir => 1}, $input_folder);


sub checking {
	return unless -f $File::Find::name;
	my ($year,$date);
	my $size = -s $File::Find::name;
	next if ($File::Find::name =~ /schema.ini/);
	if ($size > 0){
		if ($File::Find::name =~ /SSP2_${target_variable_name}_daily_(....)-(...)_pointData/){
			$year = $1;
			$date = $2;
		}
		$check{$year} += 1;
	}
}


sub process {
	return unless -f $File::Find::name;
	if (($File::Find::name =~ $timeScale) and ($File::Find::name =~ $target_variable)){
		$variable_info = $File::Find::name;
		my ($year,$variable_name);

		if ($variable_info =~ /d01_(.*)-01-01_00-00-00_(.*).txt/){
			$year = $1;
			$variable_name = $2;
		}
		
		if (($check{$year}) and ($check{$year} >= 365)){
			# Do nothing
		}else{
			open my $variable_file ,"<", $File::Find::name or die;
			
			my $variable_data_line = 0;
			my $hourly_count_perDay = 24/$hourly;
			my $day_change_check = 0;
			my (%target,@variable_west_east,$day,$time_total,$variable_time,$variable_south_north);
			my ($number_arr_west_east,$number_arr_south_north);
			
			while(<$variable_file>){
				if ($_ =~ /Time = UNLIMITED \; \/\/ \((\d+) currently\)/){
					$time_total = $1;
				}
				if ($_ =~ /west_east = (\d+)/){
					$number_arr_west_east = $1 - 1;
				}
				if ($_ =~ /south_north = (\d+)/){
					$number_arr_south_north = $1 - 1;
				}	
				
				s/ //g;
				s/;//g;
				chomp;
				my @dimension;
				if ($_ =~"//${variable_name}"){
					$variable_data_line += 1;
					@dimension = split(/\(|\,|\)/,$_);
					$variable_time = $dimension[-3];
					$variable_south_north = $dimension[-2];
					$day = int($variable_time / $hourly_count_perDay) + 1;
				}
				next if ($variable_data_line == 0);
				next if ($_ =~"//${variable_name}");
				next if ($_ =~"}");
				
				my @arr = split/,/;
				push @variable_west_east, @arr;
				
				if ($#variable_west_east == $number_arr_west_east){
					foreach my $i (0..$#variable_west_east){
						if ($target{$day}{$variable_south_north}{$i}){
							$target{$day}{$variable_south_north}{$i} += $variable_west_east[$i]/$hourly_count_perDay;
						}else{
							$target{$day}{$variable_south_north}{$i} = $variable_west_east[$i]/$hourly_count_perDay;
						}
				
					}
					@variable_west_east = ();
				
					if ($variable_south_north == $number_arr_south_north){
						# say {$debug} "1";
						$day_change_check++;
					}
					if ($day_change_check == $hourly_count_perDay){
						$day_change_check = 0; #reset count;
						my $day_name = sprintf ('%03s', $day); 
#*#*#*#* check folder name						
						my (%folder);
						$folder{$target_variable_name} = "${target_folder}/${target_variable_name}/${year}";

						foreach my $folder_make (values (%folder)){
							# say $folder_make;
							if (-e $folder_make){
								# print "Directory exists.\n";
							}
							else{
								make_path($folder_make) or die "Error creating directory: $folder_make";
							}
						}
#*#*#*#* check file name						
						open my $target_out,">", "$folder{${target_variable_name}}/SSP2_${target_variable_name}_daily_${year}-${day_name}_pointData.txt" or die;

						say {$target_out} "x,y,values";

						
						
						foreach my $day (sort {$a <=> $b} keys(%target)){
							foreach my $y_coordinate_ref (sort {$a <=> $b} keys(%{$target{$day}})){
								foreach my $x_coordinate_ref (sort {$a <=> $b} keys(%{$target{$day}{$y_coordinate_ref}})){
			
									next if ($xlat{$y_coordinate_ref}{$x_coordinate_ref} + 1 < $domain{"bottom"});
									next if ($xlat{$y_coordinate_ref}{$x_coordinate_ref} - 1 > $domain{"top"});
									next if ($xlong{$y_coordinate_ref}{$x_coordinate_ref} + 1 < $domain{"left"});
									next if ($xlong{$y_coordinate_ref}{$x_coordinate_ref} - 1 > $domain{"right"});
									
					
									say {$target_out} join(",",$xlong{$y_coordinate_ref}{$x_coordinate_ref},$xlat{$y_coordinate_ref}{$x_coordinate_ref},$target{$day}{$y_coordinate_ref}{$x_coordinate_ref});
								}
							}
						}

						%target = ();
						close $target_out;
					}
				}
			
			}
			close $variable_file;
		}
	}
}


