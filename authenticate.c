
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdbool.h>

void admin_control(void) {
  puts("Welcome, Admin!\n");
  puts("You have the power!!!!!\n");
  // ...
}

void user_control(void) {
  puts("Welcome, User!\n");
  // ...
}

int verify_pin(bool *is_admin) {

  char pin[5];
  
  puts("Enter PIN: ");
  gets(pin);
  
  if (!strcmp(pin, "1337")) {
    return 1;

  } else if (!strcmp(pin, "w00t")) {
    *is_admin = 1;
    return 1;

  } else {
    return 0;
  }
}

int main(int argc, char *argv[]) {
  bool is_admin = false;
  if (!verify_pin(&is_admin)) {
    return EXIT_FAILURE;
  }

  if (is_admin) {
    admin_control();
  } else {
    user_control();
  }

  return EXIT_SUCCESS;
}
