#include <math.h>
#include <stdio.h>
#include <stdlib.h>

int main(){
  double *ptr = malloc(sizeof(double) * 2);
  (ptr[0]) = 3.0;
  (ptr[1]) = -(ptr[0]);
  printf("%f ",(ptr[1]));
  free(ptr);
}