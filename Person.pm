package Person;
use Data::Dumper;
 sub new 
{
  #constructor
  my ($class_name, $names) = @_;
  my ($self) = {};
  bless ($self, $class_name);
 
  
  $self->{'_names'} = $names; 
 
 
  return $self;
}


sub sort_names {
   my( $self,$sort ) = @_;
   my %first_names_hash=();
   my %last_names_hash=();
   my @sorted_names=();
   
    foreach (@{$self->{'_names'}}){ 	
    		my ($first,$last)= split ' ', $_;
    		$first_names_hash{$first}=$last;
    }
    foreach (@{$self->{'_names'}}){
    		my ($first,$last)= split ' ', $_;
    		$last_names_hash{$last}=$first;
    }
   my @first_name_sorted = sort keys %first_names_hash;
   my @last_name_sorted = sort keys %last_names_hash;
   
   if ($sort eq 'first'){
   		foreach (@first_name_sorted){ 	
   				push @sorted_names ,"$_ $first_names_hash{$_}";
   		}
   }
   elsif ($sort eq 'last'){ 	
   		foreach (@last_name_sorted){ 	
   				push @sorted_names ,"$last_names_hash{$_} $_";
   		}
   }
   print @sorted_names;
   return \@sorted_names;
}

1;