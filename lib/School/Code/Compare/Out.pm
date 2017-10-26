package School::Code::Compare::Out;

use strict;
use warnings;

use Template;
use DateTime;
use School::Code::Compare::Out::Template::Path;

sub new {
    my $class = shift;

    my $self = {
                    name   => time(),
                    format => 'tab',
                    lines  => [],
               };
    bless $self, $class;

    return $self;
}

sub set_name {
    my $self = shift;

    $self->{name} = shift;

    return $self;
}

sub set_format {
    my $self = shift;

    $self->{format} = shift;

    return $self;
}

sub set_lines {
    my $self = shift;

    $self->{lines} = shift;

    return $self;
}

sub write {
    my $self       = shift;

    my @result = @{$self->{lines}};
    my $format =   $self->{format};
    my $name   =   $self->{name};

    my $tt     = Template->new;
    my $tt_dir = School::Code::Compare::Out::Template::Path->get();
    
    # sort by ratio, but make sure undef values are "big" (meaning, bottom/last)
    my @result_sorted = sort { return  1 if (not defined $a->{ratio});
                               return -1 if (not defined $b->{ratio});
                               return $a->{ratio} <=> $b->{ratio};
                             } @result;
    
    # we render all rows, appending it to one string
    my $rendered_data_rows = '';
    
    foreach my $comparison (@result_sorted) {
        my $vars = {
            ratio        => $comparison->{ratio},
            distance     => $comparison->{distance},
            delta_length => $comparison->{delta_length},
            suspicious   => $comparison->{suspicious},
            file1        => $comparison->{file1},
            file2        => $comparison->{file2},
            comment      => $comparison->{comment},
        };
    
        $tt->process("$tt_dir/$format.tt", $vars, \$rendered_data_rows)
            || die $tt->error(), "\n";
    }
    
    my $now = DateTime->now;
    my $filename =    $name
                    . $now->ymd() . '_'
                    . $now->hms('-')
                    . '.'
                    . lc $format;
    
    # render again, this time merging the rendered rows into the wrapping body
    $tt->process(   "$tt_dir/Body$format.tt",
                    { data => $rendered_data_rows },
                    $filename
                )   || die $tt->error(), "\n";

    return $filename;
}

1;
