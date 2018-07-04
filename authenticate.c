
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

bool verify_pin(bool *is_admin) {

  char pin[5];
  
  puts("Enter PIN: ");
  gets(pin);
  
  if (!strcmp(pin, "1337")) {
    return true;

  } else if (!strcmp(pin, "w00t")) {
    *is_admin = true;
    return true;

  } else {
    return false;
  }
}

int main(int argc, char *argv[]) {
  bool is_admin = false;
  bool is_logged = verify_pin(&is_admin);

  if (is_admin) {
    admin_control();
    return EXIT_SUCCESS;

  } else if (is_logged) {
    user_control();
    return EXIT_SUCCESS;

  } else {
    return EXIT_FAILURE;
  }
}
