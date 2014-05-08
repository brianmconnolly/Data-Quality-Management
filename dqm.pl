#!/usr/bin/env perl
# production version

use strict;
use Statistics::ROC;

my $BIGN=1e20;

#
my @PATIENTS;
my @ENCOUNTERS;
my @GOLD;
for (my $i=0;$i<($#ARGV+1)/3;$i++)
{
 push @PATIENTS,$ARGV[$i];
 push @ENCOUNTERS,$ARGV[$i+($#ARGV+1)/3];
 push @GOLD,$ARGV[$i+2*($#ARGV+1)/3];
}
# exit if not an even number of arguments
my $somethingWrong=0;
if (int(($#ARGV+1)/3)!=($#ARGV+1)/3)
{
 print "I need three arrays, or else I can't tell how many hospitals you have! exiting...\n";
 $somethingWrong=1;
}
if (($#ARGV+1)<6)
{
 print "Need at least 6 arguments! exiting...\n";
 $somethingWrong=1;
}
if (($#ARGV+1)==0)
{
 $somethingWrong=1;
}
#
for (my $i=0;$i<($#ARGV+1)/3;$i++)
{
 if (($PATIENTS[$i]>$ENCOUNTERS[$i])&&($ENCOUNTERS[$i]>=0))
 { 
  print "patient counts= $PATIENTS[$i] encounter counts= $ENCOUNTERS[$i] -- there cannot be more patients than encounters with patients!!\n";
  print "Go boil your head! exiting...\n";
  $somethingWrong=1;
 }
}
if ($somethingWrong)
{
 print "dqm.pl [patient counts 1] [patient counts 2] ... [patient counts N] [encounter counts 1] [encounter counts 2] ... [encounter counts N] ... [gold standard counts 1] [gold standard counts 2] ... [gold standard counts N]\n";
 exit(0);
}
#
my $encounterNeg=0;
my $patientNeg=0;
my $goldNeg=0;
for (my $iHospital=0;$iHospital<($#ARGV+1)/3;$iHospital++)
{
 if ($PATIENTS[$iHospital]<0)
 {
  $patientNeg=1;
 }
 if ($ENCOUNTERS[$iHospital]<0)
 {
  $encounterNeg=1;
 }
 if ($GOLD[$iHospital]<0)
 {
  print "Gold Standard Has Negative Value!\n";
  exit(0);
 }
}
#
if ($patientNeg)
{
 print "At least one patient count negative, can't calculate anything.. exiting...\n";
 exit(0);
}
#
if ($encounterNeg)
{
 print "Warning: at least one encounter count negative, will only output patient count similarity\n";
}
#
my @test_cases;
push @test_cases, [[@PATIENTS],[@ENCOUNTERS],[@GOLD]]; # patients and encounters the same
#

foreach my $test_case (@test_cases) {
     my $measure_patients_only_pathological     = data_quality_measure_with_patients_only_pathological($test_case->[0],$test_case->[2]);
     my @which_patient_is_path			= which_patient_is_pathological($test_case->[0],$test_case->[2]);
     my $measure_patient_encounter_pathological;
     my @which_patients_and_encounters_is_path;
     my $measure_patient_encounter_pathological;
     my @which_patients_and_encounters_is_path;
     if (!$encounterNeg)
     {
      $measure_patient_encounter_pathological = data_quality_measure_with_patients_and_encounters_pathological($test_case->[0], $test_case->[1]);
      @which_patients_and_encounters_is_path = which_patients_and_encounters_is_pathological($test_case->[0],$test_case->[1]);
     }
     my $patient_counts = join ',', @{ $test_case->[0] };
     my $encounter_counts = join ',', @{ $test_case->[1] };
     my $total_counts = join ',', @{ $test_case->[2] };

     my $log_output = sprintf "PP[%0.5f], PEP[%0.5f] whichPatient[%0.5f] deficit? [%0.5f] whichPatientsEncounters[%0.5f] deficit? [%0.5f]", $measure_patients_only_pathological, $measure_patient_encounter_pathological, $which_patient_is_path[0], $which_patient_is_path[1],$which_patients_and_encounters_is_path[0],$which_patients_and_encounters_is_path[1];

     print "PATIENT COUNTS: [$patient_counts] ENCOUNTER COUNTS: [$encounter_counts] GOLD STANDARD: [$total_counts]\n";
     my $measures;
     $measures=sprintf "P( Patients Same | Patients=[$patient_counts], Gold=[$total_counts] ) = %0.5f",$measure_patients_only_pathological;
# figure out which hospital is different
     print $measures;
     if (($measure_patients_only_pathological<0.5)&&($#PATIENTS+1>2))
     {
      if ($which_patient_is_path[0]==-1)
      {
       print ", all patient counts are significantly different from each other\n"; 
      }
      elsif ($#PATIENTS+1>2)
      {
       my $temp=$which_patient_is_path[1]+1;
       print ", hospital #$temp different\n";
      }
      else
      {
       print "\n";
      }
     }
     else
     {
      print " > 0.5, they're similar!\n";
     }
     if (!$encounterNeg)
     {     
      $measures=sprintf "P( Encounters/Patients Same | Patients=[$patient_counts], Encounters=[$encounter_counts] ) = %0.5f",$measure_patient_encounter_pathological;
      print $measures;
      if ($measure_patient_encounter_pathological<0.5)
      {
       if ($which_patients_and_encounters_is_path[1]==-1)
       {
        print ", all Encounters/Patients ratios are different from each other\n"; 
       }
       elsif ($#PATIENTS+1>2)
       {
        my $temp=$which_patient_is_path[1]+1;
        print ", hospital #$temp different\n";
       }
       else
       {
        print "\n";
       }
      }
      else
      {
       print " > 0.5, they're similar!\n";
      }
     }
}

###### TEST CODE - END ###################

sub data_quality_measure_with_patients_only_pathological {

    ###

    ####################################
    ## input parameters
    ####################################
    my $param_quality_patient_counts = shift;
    my $param_quality_patient_counts_comparison_set = shift;
    ####################################

    my ($local_numerator, $local_denominator) = _data_quality_measure_with_patients_only($param_quality_patient_counts,$param_quality_patient_counts_comparison_set);

    for (my $z = 0; $z < scalar(@$param_quality_patient_counts); $z++) {
        my $local_other_hospital_total = 0;
        my $local_hospital_total = 0;

        for (my $i = 0; $i < scalar(@$param_quality_patient_counts); $i++) {
            if ($i == $z) {
                 $local_hospital_total += $param_quality_patient_counts->[$i];
            } else {
                 $local_other_hospital_total += $param_quality_patient_counts->[$i];
            }
        }

        if (exp(_log_factorial($local_other_hospital_total) + _log_factorial($local_hospital_total) - _log_factorial($local_other_hospital_total+$local_hospital_total+1) - $local_other_hospital_total * log(scalar(@$param_quality_patient_counts)-1))>0) {
            $local_numerator = log(exp($local_numerator) + exp( _log_factorial($local_other_hospital_total)+_log_factorial($local_hospital_total)-_log_factorial($local_other_hospital_total+$local_hospital_total+1) - $local_other_hospital_total * log(scalar(@$param_quality_patient_counts)-1) ) );
       }
    }

    $local_numerator -= log(scalar(@$param_quality_patient_counts) + 1); # another plus one because have to add 'magic' and 'pathological' hypotheses

    my $local_return_quality_measure = _get_measure_from_numerator_and_denominator($local_numerator, $local_denominator);
    
    return $local_return_quality_measure;
}

sub which_patient_is_pathological {

    ###

    ####################################
    ## input parameters
    ####################################
    my $param_quality_patient_counts = shift;
    my $param_quality_patient_counts_comparison_set = shift;
    ####################################

    my ($local_numerator, $local_denominator) = _data_quality_measure_with_patients_only($param_quality_patient_counts,$param_quality_patient_counts_comparison_set);

    my $biggestNumerator=$local_numerator;
    my $iPathological=-1;

    my $nBiggerThanLocalNum=0;
    for (my $z = 0; $z < scalar(@$param_quality_patient_counts); $z++) {
        my $local_other_hospital_total = 0;
        my @local_other_hospital_N;
        my @local_other_hospital_N_comparison_set;
        my $local_other_hospital_total_comparison_set = 0;
        my $local_hospital_total = 0;

        for (my $i = 0; $i < scalar(@$param_quality_patient_counts); $i++) {
            if ($i == $z) {
                 $local_hospital_total += $param_quality_patient_counts->[$i];
            } else {
                 $local_other_hospital_total += $param_quality_patient_counts->[$i];
		 push @local_other_hospital_N,$param_quality_patient_counts->[$i];
		 push @local_other_hospital_N_comparison_set,$param_quality_patient_counts_comparison_set->[$i];
		 $local_other_hospital_total_comparison_set+=$param_quality_patient_counts_comparison_set->[$i];
            }
        }
	my $logNum=0;
	for (my $i=0;$i<scalar(@local_other_hospital_N);$i++)
	{
	 $logNum+=$local_other_hospital_N[$i]*log($local_other_hospital_N_comparison_set[$i]/$local_other_hospital_total_comparison_set);
	}
        $logNum+=_log_factorial($local_other_hospital_total)+_log_factorial($local_hospital_total)-_log_factorial($local_other_hospital_total+$local_hospital_total+1);
        if ($biggestNumerator<$logNum)
        {
	 $biggestNumerator=$logNum;
	 $iPathological=$z;
        }
        if ($local_numerator<$logNum)
        {
         $nBiggerThanLocalNum++;
        }
    }
    if ($nBiggerThanLocalNum>1)
    {
     return (-1,-1);
    }
    else
    {
     my $i;
     my $totalPatientCounts=0;
     my $totalPatientCountsComparisonSet=0;
     for ($i=0;$i<scalar(@{$param_quality_patient_counts});$i++)
     {
      $totalPatientCountsComparisonSet+=$param_quality_patient_counts_comparison_set->[$i];
      $totalPatientCounts+=$param_quality_patient_counts->[$i];
     }
     my $deficit=0;
     for ($i=0;$i<scalar(@{$param_quality_patient_counts});$i++)
     {
      if ($i==$iPathological)
      {
       if (($param_quality_patient_counts_comparison_set->[$i]/$totalPatientCountsComparisonSet)>($param_quality_patient_counts->[$i]/$totalPatientCounts))
       {
        $deficit=-1
       }
      }
      else
      {
       if (($param_quality_patient_counts_comparison_set->[$i]/$totalPatientCountsComparisonSet)<($param_quality_patient_counts->[$i]/$totalPatientCounts))
       {
        $deficit=-1
       }
      }
     }
     if ($deficit == -1) # maybe it's an excess
     {
      $deficit=1;
      for ($i=0;$i<scalar(@{$param_quality_patient_counts});$i++)
      {
       if ($i==$iPathological)
       {
        if (($param_quality_patient_counts_comparison_set->[$i]/$totalPatientCountsComparisonSet)<($param_quality_patient_counts->[$i]/$totalPatientCounts))
        {
         $deficit=-1
        }
       }
       else
       {
        if (($param_quality_patient_counts_comparison_set->[$i]/$totalPatientCountsComparisonSet)>($param_quality_patient_counts->[$i]/$totalPatientCounts))
        {
         $deficit=-1
        }
       }
      }
     }
     return ($iPathological,$deficit);
    }
}

sub _data_quality_measure_with_patients_only {

    ###

    ####################################
    ## input parameters
    ####################################
    my $param_quality_patient_counts = shift;
    my $param_quality_patient_counts_comparison_set = shift;
    ####################################

    my $local_little_n = 10**-20;
    my $local_log_numerator = 0;
    my $local_log_denominator = 0;

    my $local_total_patients = 0;

    my $totalInComparisonSet=0;
    for my $patientsInHospital (@{$param_quality_patient_counts_comparison_set})
    {
     $totalInComparisonSet+=$patientsInHospital;
    }

    for (my $i = 0; $i < scalar(@$param_quality_patient_counts); $i++) {
         $local_log_numerator += _log_factorial($param_quality_patient_counts->[$i]);
         $local_total_patients += $param_quality_patient_counts->[$i];
    }

    $local_log_numerator   -= _log_factorial($local_total_patients + scalar(@$param_quality_patient_counts) - 1);
# first way
#    $local_log_denominator -= log(scalar(@$param_quality_patient_counts)) * $local_total_patients;
# second way
    my $iHospital=0;
    for my $patientsInHospital (@{$param_quality_patient_counts_comparison_set})
    {
     $local_log_denominator += log($patientsInHospital/$totalInComparisonSet) * $param_quality_patient_counts->[$iHospital];
     $iHospital++;
    }
## third way of calculating similarity
#    my $iHospital=0;
#    my $total=0;
#    for my $patientsInHospital (@{$param_quality_patient_counts_comparison_set})
#    {
#     $local_log_denominator += _log_factorial($patientsInHospital + $param_quality_patient_counts->[$iHospital]);
#     $total += $patientsInHospital + $param_quality_patient_counts->[$iHospital];
#     $local_log_denominator -= _log_factorial($patientsInHospital);# multinomial normalization
#     $iHospital++;
#    }
#    $local_log_denominator -= _log_factorial($total+scalar(@{$param_quality_patient_counts_comparison_set})-1);
#    $local_log_denominator += _log_factorial($totalInComparisonSet); # multinomial normalization
#    $local_log_denominator += _log_factorial(scalar(@$param_quality_patient_counts) - 1); # multinomial prior
#    my $temp=scalar(@{$param_quality_patient_counts_comparison_set});
#    print "here: temp= $temp\n";
# #
    $local_log_numerator   += _log_factorial(scalar(@$param_quality_patient_counts) - 1); # multinomial prior

    return ($local_log_numerator, $local_log_denominator);
}

sub data_quality_measure_with_patients_and_encounters_pathological {

    ###

    ####################################
    ## input parameters
    ####################################
    my $param_quality_patient_counts = shift;
    my $param_quality_encounter_counts = shift;
    ####################################
    my ($local_numerator, $local_denominator) = _data_quality_measure_with_patients_and_encounters($param_quality_patient_counts, $param_quality_encounter_counts);

    for (my $z = 0; $z < scalar(@$param_quality_patient_counts); $z++) {
        my $local_other_hospital_patient_total = 0;
        my $local_other_hospital_encounter_total = 0;
        my $local_hospital_patient_total = 0;
        my $local_hospital_encounter_total = 0;
#
        for (my $i = 0; $i < scalar(@$param_quality_patient_counts); $i++) {
            if ($i == $z) {
                $local_hospital_patient_total += $param_quality_patient_counts->[$i];
                $local_hospital_encounter_total += $param_quality_encounter_counts->[$i];
            } else {
                $local_other_hospital_patient_total += $param_quality_patient_counts->[$i];
                $local_other_hospital_encounter_total += $param_quality_encounter_counts->[$i];
            }
        }
#

        $local_numerator = log(exp($local_numerator) + 
			   exp(_log_factorial($local_hospital_patient_total)+_log_factorial($local_hospital_encounter_total-$local_hospital_patient_total)-_log_factorial($local_hospital_encounter_total+1)
			   +_log_factorial($local_other_hospital_patient_total)+_log_factorial($local_other_hospital_encounter_total-$local_other_hospital_patient_total)-_log_factorial($local_other_hospital_encounter_total+1)));

    }

    $local_numerator -= log(scalar(@$param_quality_patient_counts) + 1); # another plus one because have to add 'magic' and 'pathological' hypotheses
    my $local_return_quality_measure = _get_measure_from_numerator_and_denominator($local_numerator, $local_denominator);

    return $local_return_quality_measure;
}

sub which_patients_and_encounters_is_pathological {

    ###

    ####################################
    ## input parameters
    ####################################
    my $param_quality_patient_counts = shift;
    my $param_quality_encounter_counts = shift;
    ####################################

    my ($local_numerator, $local_denominator) = _data_quality_measure_with_patients_and_encounters($param_quality_patient_counts, $param_quality_encounter_counts);

    my $biggestNumerator=$local_numerator;
    my $iPathological=-1;
    my $nBiggerThanLocalNum=0;

    for (my $z = 0; $z < scalar(@$param_quality_patient_counts); $z++) {
        my $local_other_hospital_patient_total = 0;
        my $local_other_hospital_encounter_total = 0;
        my $local_hospital_patient_total = 0;
        my $local_hospital_encounter_total = 0;

        for (my $i = 0; $i < scalar(@$param_quality_patient_counts); $i++) {
            if ($i == $z) {
                $local_hospital_patient_total += $param_quality_patient_counts->[$i];
                $local_hospital_encounter_total += $param_quality_encounter_counts->[$i];
            } else {
                $local_other_hospital_patient_total += $param_quality_patient_counts->[$i];
                $local_other_hospital_encounter_total += $param_quality_encounter_counts->[$i];
            }
        }

         my $logNum = _log_factorial($local_hospital_patient_total)+_log_factorial($local_hospital_encounter_total-$local_hospital_patient_total)-_log_factorial($local_hospital_encounter_total+1);
	 $logNum += _log_factorial($local_other_hospital_patient_total)+_log_factorial($local_other_hospital_encounter_total-$local_other_hospital_patient_total)
	 	 - _log_factorial($local_other_hospital_encounter_total+1);
	 if ($biggestNumerator<$logNum) 
	 { 
	  $biggestNumerator=$logNum;
	  $iPathological=$z;
         }
         if ($local_numerator<$logNum)
         {
          $nBiggerThanLocalNum++;
         }

    }
#
    if ($nBiggerThanLocalNum>1)
    {
     return (-1,-1);
    }
    else
    { 
     my $deficit=0;
     for (my $i=0;$i<scalar(@{$param_quality_patient_counts});$i++)
     {
      if ($i!=$iPathological)
      {
       if (($param_quality_encounter_counts->[$iPathological]*$param_quality_encounter_counts->[$i])==0)
       {
        $deficit=-1;
       }
       elsif (($param_quality_patient_counts->[$iPathological]/$param_quality_encounter_counts->[$iPathological])<
	    ($param_quality_patient_counts->[$i]/$param_quality_encounter_counts->[$i]))
       {
        $deficit=-1
       }
      }
     }
     if ($deficit == -1) # maybe it's an excess
     {
      $deficit=1;
      for (my $i=0;$i<scalar(@{$param_quality_patient_counts});$i++)
      {
       if (($param_quality_encounter_counts->[$iPathological]*$param_quality_encounter_counts->[$i])==0)
       {
        $deficit=-1;
       }
       elsif ($i!=$iPathological)
       {
        if (($param_quality_patient_counts->[$iPathological]/$param_quality_encounter_counts->[$iPathological])>
	    ($param_quality_patient_counts->[$i]/$param_quality_encounter_counts->[$i]))
        {
         $deficit=-1
        }
       }
      }
     }
     return ($iPathological,$deficit);
    }

}

sub _data_quality_measure_with_patients_and_encounters {

    ###

    ####################################
    ## input parameters
    ####################################
    my $param_quality_patient_counts = shift;
    my $param_quality_encounter_counts = shift;
    ####################################
    my $local_little_n = 10**-20;
    my $local_log_numerator = 0;
    my $local_log_denominator = 0;

    for (my $i = 0; $i < scalar(@$param_quality_patient_counts); $i++) {
        my $local_next_log_numerator = _log_factorial($param_quality_patient_counts->[$i])+_log_factorial($param_quality_encounter_counts->[$i]-$param_quality_patient_counts->[$i]);
        $local_next_log_numerator -= _log_factorial($param_quality_encounter_counts->[$i] + 1);
        $local_log_numerator += $local_next_log_numerator;
    }

    my $local_total_patients = 0;
    map { $local_total_patients += $_ } @$param_quality_patient_counts;

    my $local_total_encounters = 0;
    map { $local_total_encounters += $_ } @$param_quality_encounter_counts;

     $local_log_denominator = _log_factorial($local_total_patients)+_log_factorial($local_total_encounters-$local_total_patients)-_log_factorial($local_total_encounters+1);

    return ($local_log_numerator, $local_log_denominator);
}

sub _get_measure_from_numerator_and_denominator {

    ###

    ####################################
    ## input parameters
    ####################################
    my $param_numerator = shift;
    my $param_denominator = shift;
    ####################################

    my $local_return_measure = 1.0/(1.0 + exp($param_numerator - $param_denominator));

    return $local_return_measure;
}

sub _log_factorial {

    ###

    ####################################
    ## input parameters
    ####################################
    my $param_n = shift;
    ####################################
     
    my $local_return_answer = 0;

    for (my $i = 2; $i <= $param_n; $i++) {
       $local_return_answer += log($i);
    }

    return $local_return_answer;
}
