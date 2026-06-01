#!/bin/bash

PSQL="psql --username=postgres --dbname=number_guess -t --no-align -c"

echo Enter your username:
read USERNAME

# look to see if the username exists in the database
USERNAME_LOOKUP=$($PSQL "SELECT username FROM user_info WHERE username='$USERNAME'")

# check for the username
if [[ $USERNAME_LOOKUP ]];
then

  # get all relevant game info for the user
  USERNAME=$($PSQL "SELECT username FROM user_info WHERE username='$USERNAME'")
  GAMES_PLAYED=$($PSQL "SELECT games_played FROM user_info WHERE username='$USERNAME'")
  BEST_GAME=$($PSQL "SELECT best_game FROM user_info WHERE username='$USERNAME'")

  # display the user's stat history
  echo Welcome back, $USERNAME! You have played $GAMES_PLAYED games, and your best game took $BEST_GAME guesses.
else
  # welcome a new user
  echo Welcome, $USERNAME! It looks like this is your first time here.

  #add new user to the database
  ADD_USER=$($PSQL "INSERT INTO user_info(username) VALUES('$USERNAME')")
fi

# generate a random number between (0,1000]
secret_number=$(( (RANDOM % 1000) + 1 ))

# prompt the user for a guess
echo Guess the secret number between 1 and 1000:

# read the user's input for a guess
read NUM_GUESS

# initialize our number of guesses
number_of_guesses=1

# used to check if the number is a positive integer
regex_pattern="^[1-9][0-9]*$"

# recursive check to make sure the user is inputing an integer
if ! [[ $NUM_GUESS =~ $regex_pattern ]]; 
then
  while ! [[ $NUM_GUESS =~ $regex_pattern ]];
  do
    # alert the user that they didn't input the correct format for a number
    echo That is not an integer, guess again:
    read NUM_GUESS
    
    # increment their guess total even if it wasn't a 'valid' guess
    ((number_of_guesses++))
  done
fi


# while the guess isn't equal to the randomly generated number ...
while (( $NUM_GUESS != $secret_number ))
do 
  # if the guess is lower 
  if (( $NUM_GUESS < $secret_number ))
  then
    echo -e "It's higher than that, guess again:"

    # read in new guess
    read NUM_GUESS
    ((number_of_guesses++))

    # recursive check to make sure the user is inputing an integer
    if ! [[ $NUM_GUESS =~ $regex_pattern ]]; 
    then
      while ! [[ $NUM_GUESS =~ $regex_pattern ]];
      do
        echo That is not an integer, guess again:
        read NUM_GUESS
        ((number_of_guesses++))
      done
    fi
    
    
  # if the guess is higher
  elif (( $NUM_GUESS > $secret_number ));
  then
    echo "It's lower than that, guess again:"
    read NUM_GUESS
    ((number_of_guesses++))

    # recursive check to make sure the user is inputing an integer
    if ! [[ $NUM_GUESS =~ $regex_pattern ]]; 
    then
      while ! [[ $NUM_GUESS =~ $regex_pattern ]]
      do
        echo That is not an integer, guess again:
        read NUM_GUESS
        ((number_of_guesses++))
      done
    fi
  fi

  if (( $NUM_GUESS == $secret_number )); 
  then

    # if condition to update our best game if this was the user's first game, 
    if  (( BEST_GAME == 0 ));
    then
      UPDATE_BEST_GAME=$($PSQL "UPDATE user_info SET best_game = $number_of_guesses WHERE username='$USERNAME'")

    # override their best game if they beat their previous best game
    elif [[ $BEST_GAME > $number_of_guesses ]]
    then
      UPDATE_BEST_GAME=$($PSQL "UPDATE user_info SET best_game = $number_of_guesses WHERE username='$USERNAME'")
    fi

    # increment the total number of games the user has played by 1
    UPDATE_GAMES_PLAYED=$($PSQL "UPDATE user_info SET games_played = games_played + 1 WHERE username='$USERNAME'")

    # display a message letting the player know they won
    echo You guessed it in $number_of_guesses tries. The secret number was $secret_number. Nice job!
  fi
done
