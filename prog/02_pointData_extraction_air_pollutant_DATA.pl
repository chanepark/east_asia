use warnings;
use 5.010;
use File::Path qw(make_path);
use Path::Tiny;
use File::Find;

say "check air-pollutant point extraction files ....";
my $target_variable = "O3";
my $check_folder = "../point_extraction/daily/${target_variable}";

my (%check);
find({wanted => \&checking, no_chdir => 1}, $check_folder);

sub checking {
	return unless -f $File::Find::name;
	my ($year,$date);
	my $size = -s $File::Find::name;
	next if ($File::Find::name =~ /schema.ini/);
	if ($size > 0){
		if ($File::Find::name =~ /SSP2_${target_variable}_daily_(....)(....)_pointData/){
			$year = $1;
			$date = $2;
		}
		$check{$year} += 1;
	}
}

say "air-pollutant point extraction processing ....";
my @nc4pointfiles = path("../data_air-pollutant_ncfTypeAscii")->children( qr/\.txt$/ );

foreach $input_file (sort {$a cmp $b} @nc4pointfiles){
	say $input_file;
	my @file_name =split(/\./,$input_file);
	
	my $year = substr($file_name[-2],-8,4);
	my $mmdd = substr($file_name[-2],-4,4);
	my $date = $year.$mmdd;
	next if ($check{$year} and $check{$year} >= 365);

	my $nLon = 144;
	my $nLat = 91;
	
	my $count = 0;
	my $lon_count = 0;
	my $lat_count = 0;
	my $o3_count = 0;
	my $pm10_count = 0;
	my $pm25_count = 0;
	
	my (@lat,@lon);
	my ($t,$lat,%o3,@o3_arr,%pm10,@pm10_arr,%pm25,@pm25_arr);
	
	my (%folder);
	$folder{O3} = "../point_extraction/daily/O3/${year}";
	$folder{PM10} = "../point_extraction/daily/PM10/${year}";
	$folder{PM25} = "../point_extraction/daily/PM25/${year}";
	
	foreach my $folder_make (values (%folder)){
		# say $folder_make;
		if (-e $folder_make){
			# print "Directory exists.\n";
		}
		else{
			make_path($folder_make) or die "Error creating directory: $folder_make";
		}
	}
	open my $input   ,"<", $input_file or die;
	open my $o3_out  ,">", "$folder{O3}/SSP2_O3_daily_${date}_pointData.txt" or die;
	open my $pm10_out,">", "$folder{PM10}/SSP2_PM10_daily_${date}_pointData.txt" or die;
	open my $pm25_out,">", "$folder{PM25}/SSP2_PM25_daily_${date}_pointData.txt" or die;
				
	
	say {$o3_out} join(",","x,y,values");
	say {$pm10_out} join(",","x,y,values");
	say {$pm25_out} join(",","x,y,values");
	
	open my $domain_file ,"<", "../define/domain.txt" or die;
	
	my (%domain);
	while(<$domain_file>){
		s/ //g;
		chomp;
		my @arr = split/,/;
		$domain{$arr[0]} = $arr[1];
	}
	close $domain_file;
	
	
	while(<$input>){
		chomp;
		s/ //g;
		s/;//g;
		next if $. <= 13;
		next if $_ =~ "}";
		my @arr = split;
		
		if ($_ =~ "Lon="){
			$lon_count ++;
		}
		if ($lon_count == 1){
			s/Lon=//;
			my @tmp = split/\,/;
			push @lon, @tmp;
			if ($nLon == $#lon + 1){
				$lon_count = 0;
			}
		}
		if ($_ =~ "Lat="){
			$lat_count ++;
		}		
		if ($lat_count == 1){
			s/Lat=//;
			my @tmp = split/\;|\,/;
			push @lat, @tmp;	
			if ($nLat == $#lat + 1){
				$lon_count = 0;
			}
		}
		if ($_ =~ "//o3"){
			$o3_count ++;
			if ($_ =~ /(\d+),(\d+),0-143/){
				$t = $1;
				$lat = $2;
			}
			# say $o3_count;
		}	
		next if ($_ =~"//o3");
		if ($o3_count >= 1){
			my @arr = split/,/;
			push @o3_arr, @arr;
			
			if ($#o3_arr == $nLon - 1){
				
				for $i (0..$#o3_arr){
					$o3{$lat}{$i}{$t} = $o3_arr[$i];
				}
				@o3_arr = ();
				$o3_count = 0;
			}
		}	
		if ($_ =~ "//pm10"){
			$pm10_count ++;
			if ($_ =~ /(\d+),(\d+),0-143/){
				$t = $1;
				$lat = $2;
			}
		}	
		next if ($_ =~"//pm10");
		if ($pm10_count  >= 1){
			my @arr = split/,/;
			push @pm10_arr, @arr;
			# say $lat if ($#pm10_arr == 143);
			
			if ($#pm10_arr == $nLon - 1){
				
				for $i (0..$#pm10_arr){
					$pm10{$lat}{$i}{$t} = $pm10_arr[$i];
				}
				@pm10_arr = ();
				$pm10_count =0;
			}
		}	
		if ($_ =~ "//pm25"){
			$pm25_count ++;
			if ($_ =~ /(\d+),(\d+),0-143/){
				$t = $1;
				$lat = $2;
			}
		}	
		next if ($_ =~"//pm25");
		if ($pm25_count  >= 1){
			my @arr = split/,/;
			push @pm25_arr, @arr;
			# say $#pm25_arr;
			if ($#pm25_arr == $nLon - 1){
				# say $lat;
				for $i (0..$#pm25_arr){
					$pm25{$lat}{$i}{$t} = $pm25_arr[$i];
				}
				@pm25_arr = ();
				$pm25_count = 0;
			}
		}	
	}
							
	
				
	foreach my $y (sort {$a <=> $b} keys(%o3)){
		
		foreach my $x (sort {$a <=> $b} keys(%{$o3{$y}})){
			my ($average,$c);
			foreach my $t (sort {$a <=> $b} keys(%{$o3{$y}{$x}})){
				$average += $o3{$y}{$x}{$t};
				$c ++;
			}
			
			next if ($lat[$y] + 5 < $domain{"bottom"});
			next if ($lat[$y] - 5 > $domain{"top"});
			next if ($lon[$x] + 5 < $domain{"left"});
			next if ($lon[$x] - 5 > $domain{"right"});
			say {$o3_out} join(",",$lon[$x],$lat[$y],$average/$c);
		}	
	}
	%o3 = ();
	foreach my $y (sort {$a <=> $b} keys(%pm10)){
		
		foreach my $x (sort {$a <=> $b} keys(%{$pm10{$y}})){
			
			my ($average,$c);
			foreach my $t (sort {$a <=> $b} keys(%{$pm10{$y}{$x}})){
				$average += $pm10{$y}{$x}{$t};
				$c ++;
			}
			# say $lat[$y];
			next if ($lat[$y] + 5 < $domain{"bottom"});
			next if ($lat[$y] - 5 > $domain{"top"});
			next if ($lon[$x] + 5 < $domain{"left"});
			next if ($lon[$x] - 5 > $domain{"right"});
			
			say {$pm10_out} join(",",$lon[$x],$lat[$y],$average/$c);
		}	
	}
	%pm10 =();
	foreach my $y (sort {$a <=> $b} keys(%pm25)){
		foreach my $x (sort {$a <=> $b} keys(%{$pm25{$y}})){
			my ($average,$c);
			foreach my $t (sort {$a <=> $b} keys(%{$pm25{$y}{$x}})){
				$average += $pm25{$y}{$x}{$t};
				$c ++;
			}
			# say $c;
			next if ($lat[$y] + 5 < $domain{"bottom"});
			next if ($lat[$y] - 5 > $domain{"top"});
			next if ($lon[$x] + 5 < $domain{"left"});
			next if ($lon[$x] - 5 > $domain{"right"});
			say {$pm25_out} join(",",$lon[$x],$lat[$y],$average/$c);
		}	
	}
	%pm25 =();
	close $pm25_out;
	close $pm10_out;
	close $o3_out;
}

								   
								   
								   
                                   
                                   
                              