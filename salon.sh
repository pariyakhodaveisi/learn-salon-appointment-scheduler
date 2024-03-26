#!/bin/bash

# Set a variable for the psql command, preconfigured with options
PSQL="psql -X --username=freecodecamp --dbname=salon --tuples-only -c"

# Print the salon welcome message
echo -e "\n~~~~~ MY SALON ~~~~~\n"

# Greet the user
echo -e "Welcome to My Salon, how can I help you?\n"

# Define the main menu function
MAIN_MENU() {
  # Check if an argument is passed to the function and print it
  if [[ $1 ]]
  then
    echo -e "\n$1"
  fi
  
  # Fetch and store available services from the database
  AVAILABLE_SERVICES=$($PSQL "SELECT service_id, name FROM services ORDER BY service_id");
  
  # Check if no services are available
  if [[ -z $AVAILABLE_SERVICES ]]
  then
    # Inform the user that no services are available
    echo "Sorry, we dont have any services available right now"
  else
    # List available services
    echo "$AVAILABLE_SERVICES" | while read SERVICE_ID BAR NAME
    do
      # Print each service in a formatted way
      echo "$SERVICE_ID) $NAME"
    done

    # Prompt user to select a service by its ID
    read SERVICE_ID_SELECTED
    # Validate the input to check if it's a number
    if [[ ! $SERVICE_ID_SELECTED =~ ^[0-9]+$ ]]
    then
      # Recall the main menu with an error message
      MAIN_MENU "That is not a number"
    else
      # Check if the selected service is available
      SERVICE_AVAILABLE=$($PSQL "SELECT service_id FROM services WHERE service_id=$SERVICE_ID_SELECTED")
      # Fetch the name of the selected service
      SERVICE_NAME=$($PSQL "SELECT name FROM services WHERE service_id = $SERVICE_ID_SELECTED")
      # If the service is not available
      if [[ -z $SERVICE_AVAILABLE ]]
      then
        # Recall the main menu with an error message
        MAIN_MENU "I could not find that service. What would you like today?"
      else
        # Prompt user for their phone number
        echo -e "\nWhat's your phone number?"
        read CUSTOMER_PHONE
        # Fetch customer name using the provided phone number
        CUSTOMER_NAME=$($PSQL "SELECT name FROM customers WHERE phone = '$CUSTOMER_PHONE'");
        # If customer is not found
        if [[ -z $CUSTOMER_NAME ]]
        then
          # Prompt for the customer's name
          echo -e "\nWhat's your name?"
          read CUSTOMER_NAME
          # Insert the new customer into the database
          INSERT_CUSTOMER_RESULT=$($PSQL "INSERT INTO customers(name, phone) VALUES('$CUSTOMER_NAME', '$CUSTOMER_PHONE')")
        fi
        # Ask for the preferred appointment time
        echo -e "\nWhat time would you like your $SERVICE_NAME, $CUSTOMER_NAME?"
        read SERVICE_TIME
        # Fetch the customer ID for the appointment
        CUSTOMER_ID=$($PSQL "SELECT customer_id FROM customers WHERE phone = '$CUSTOMER_PHONE'")
        # If a service time has been specified
        if [[ $SERVICE_TIME ]]
        then
          # Insert the appointment into the database (comment indicates incomplete line)
          INSERT_SERV_RESULT=$($PSQL "INSERT INTO appointments(customer_id, service_id, time) VALUES('$CUSTOMER_ID','$SERVICE_ID_SELECTED', '$SERVICE_TIME')")
          # If the insertion was successful
          if [[ $INSERT_SERV_RESULT ]]
          then
            # Confirm the appointment to the user, cleaning up customer name input
            echo -e "\nI have put you down for a $SERVICE_NAME at $SERVICE_TIME, $(echo $CUSTOMER_NAME | sed -r 's/^ *| *$//g')."
          fi
        fi
      fi
    fi
  fi
}

# Call the MAIN_MENU function to start the program
MAIN_MENU
