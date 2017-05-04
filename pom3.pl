


my @arr = (1, 2, 3, 4, 5, 6);

my @arr1 = @arr[-(scalar(@arr)-1)..-1];

print @arr1;