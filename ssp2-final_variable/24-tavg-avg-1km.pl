#!/usr/bin/env perl

use utf8;
use strict;
use warnings;

use Benchmark;
use Path::Tiny;
use Try::Tiny;

use SSP2::Iter;
use SSP2::Log;
use SSP2::Util;

local $| = 1;

my $log_file = shift;
die "Usage: $0 <log_file>\n" unless $log_file;

my $LOG = SSP2::Log->new( file => $log_file );

my @years = (
    2006 .. 2025,
    2046 .. 2065,
    2080 .. 2099,
);

for my $year (@years) {
    for my $month ( 1 .. 12 ) {
        $LOG->info("processing %04d-%02d", $year, $month );
        my $t0 = Benchmark->new;
        try {
            doit( $year, $month );
        }
        catch {
            $LOG->warn("caught error: $_");
        };
        my $t1 = Benchmark->new;
        my $td = timediff( $t1, $t0 );
        $LOG->info( "elapsed time: %s", timestr($td) );
    }
}

sub doit {
    my ( $year, $month ) = @_;

    return unless $year;
    return unless $month;
    return unless 1 <= $month && $month <= 12;

    my $data_dir = "W:/grid1kmData_ascii";
    my $term     = "daily";
    my $var      = "tavg";
    my $ndays    = SSP2::Util::month_days($month);
    my $ncols    = 751;
    my $nrows    = 601;
    my $output   = sprintf "W:/ssp2/result/24-${var}/SSP2_${var}-avg_monthly_1km_${year}%02d_sub.txt", $month;
    my $encoding = "cp949";

    if ( path($output)->is_file ) {
        $LOG->info("skip: $output file is already exists");
        return;
    }

    my @files;
    {
        my $file_fmt = sprintf(
            "%s/%s/%s/%d/ssp2_%s_%s_%d-%%03d_1kmgrid.txt",
            $data_dir,
            $term,
            $var,
            $year,
            $var,
            $term,
            $year,
        );

        for ( my $i = 1; $i <= $ndays; ++$i ) {
            my $base = 0;
            map { $base += $_ } SSP2::Util::month_days( 1 .. $month - 1 );
            my $file = sprintf( $file_fmt, $i + $base );
            push @files, $file;
        }
    }

    my $si = SSP2::Iter->new(
        ncols   => $ncols,
        nrows   => $nrows,
        files   => \@files,
        result  => [],
        cb_init => sub {
            my $self = shift;

            for ( my $i = 0; $i < @{ $self->files }; ++$i ) {
                $self->result->[$i] = [];
                for ( my $row = 0; $row < $self->nrows; ++$row ) {
                    $self->result->[$i][$row] = [];
                    for ( my $col = 0; $col < $self->ncols; ++$col ) {
                        $self->result->[$i][$row][$col] = undef;
                    }
                }
            }
        },
        cb_file_init => sub {
            my ( $self, $file_idx, $file ) = @_;

            #
            # debug log
            #
            $LOG->debug("processing $file");
        },
        cb_file_retry => sub {
            my ( $self, $file_idx, $file, $retry, $msg ) = @_;

            $LOG->warn($msg);
            $LOG->debug( "retry(%d/%d): $file", $retry, $self->retry );

            for ( my $row = 0; $row < $self->nrows; ++$row ) {
                $self->result->[$file_idx][$row] = [];
                for ( my $col = 0; $col < $self->ncols; ++$col ) {
                    $self->result->[$file_idx][$row][$col] = undef;
                }
            }
        },
        cb => sub {
            my ( $self, $file_idx, $row, $col, $item ) = @_;

            return if $item == $self->ndv;

            $self->result->[$file_idx][$row][$col] = $item;
        },
        cb_final => sub {
            my $self = shift;

            #
            # monthly 1km avg
            #
            my @result = ();
            for ( my $row = 0; $row < $self->nrows; ++$row ) {
                $result[$row] = [];
                for ( my $col = 0; $col < $self->ncols; ++$col ) {
                    my $sum = undef;
                    my $cnt = 0;
                    for ( my $i = 0; $i < @{ $self->files }; ++$i ) {
                        my $item = $self->result->[$i][$row][$col];
                        next unless defined $item;
                        next if $item == $self->ndv;

                        $sum = 0 unless defined $sum;
                        $sum += $item;
                        ++$cnt;
                    }
                    if ( $cnt > 0 ) {
                        $result[$row][$col] = $sum / $cnt;
                    }
                    else {
                        $result[$row][$col] = undef;
                    }
                }
            }

            #
            # write
            #
            my $output_path = path($output);
            $output_path->parent->mkpath;
            my $fh = $output_path->filehandle( ">", ":raw:encoding($encoding)" );
            for my $header ( @{ $self->headers } ) {
                print $fh $header . "\n";
            }
            for ( my $row = 0; $row < $self->nrows; ++$row ) {
                for ( my $col = 0; $col < $self->ncols; ++$col ) {
                    my $val = $result[$row][$col];
                    if ( defined $val ) {
                        printf $fh "%f", $val;
                    }
                    else {
                        print $fh $self->ndv;
                    }
                    print $fh q{ };
                }
                print $fh "\n";
            }
            close $fh;
        },
    );

    $si->iter;
}
