#!/bin/bash


# connect sql เมื่อ รัน bash file
PSQL="psql --username=freecodecamp --dbname=number_guess -t --no-align -c"

# เอาไว้ ล้าง table ตอนเริ่มต้น
# $PSQL "TRUNCATE TABLE users;"

# ตัวแปร secret_number เรียกใช้งาน random ซึ่ง random มีอยู่ ภายใน system อยู่แล้ว สามารรถ เรียกมาใช้งานได้เลย
SECRET_NUMBER=$(( RANDOM % 1000 + 1 ))
GUESSES=0


# ฟังชั่น สำหรับ เก็บ ข้อมูล ของ user แล้ว แสดง message
GET_USER_INFO(){
  echo "Enter your username:"
  read USERNAME

  # เช็คว่า  username เคยมีอยู่แล้วหรือไม่ ถ้ามี ก็เก็บ user_id ไว้
  USER_ID=$($PSQL "SELECT user_id FROM users WHERE username = '$USERNAME'")

  if [[ -z $USER_ID ]] 
  then
    # แสดง ข้อความ เมื่อเป็น user ใหม่
    echo "Welcome, $USERNAME! It looks like this is your first time here."
    # แล้ว ทำการ Insert data user name ใหม้ เข้าไป
    INSERT_USER_RESULT=$($PSQL "INSERT INTO users(username) VALUES('$USERNAME')")
    # แล้ว select user id มาใช้งาน
    USER_ID=$($PSQL "SELECT user_id FROM users WHERE username = '$USERNAME'")
  else 
    # ถ้าหาก เคย กรอกช่ื่อไปแล้ว , มี userId ใน db ก็จะ เอา ข้อมูล ของ ผู้เล่นมาใช้งาน
    USER_INFO=$($PSQL "SELECT games_played, best_game FROM users WHERE user_id = $USER_ID")

    # ใช้งาน IFS เพื่อ แยกตัว คั่น pipe ออก
    IFS="|" read GAMES_PLAYED BEST_GAME <<< $USER_INFO
    
    echo "Welcome back, $USERNAME! You have played $GAMES_PLAYED games, and your best game took $BEST_GAME guesses."
  fi
}


# ฟังชั่น สำหรับ ทายเลข จาก random 1-1000;
PLAY_GAME() {
  echo "Guess the secret number between 1 and 1000:"
  
  while true
  do
    read GUESS
    # input ต้องเป็น intreger เท่านั้น
    if [[ ! $GUESS =~ ^[0-9]+$ ]]
    then
      echo "That is not an integer, guess again:"
      continue
    fi
    
    # เพิ่ม จำนวน ว่า เดาไป ทั้งหมด ก่ี่ครั้ง ก่อนจะ ถูกต้อง
    ((GUESSES++))
    
    # เช็คว่า เดา ถูกไหม
    if [[ $GUESS -eq $SECRET_NUMBER ]]
    then
      # ถ้าถูกให้ แสดง message นี้ แล้วทำการ หยุด loop ด้วย break
      echo "You guessed it in $GUESSES tries. The secret number was $SECRET_NUMBER. Nice job!"
      # ใช้งานเป็น return แทน เพราะว่า break ทำให้ test ไม่ผ่าน
      return
    # เช็คว่ามากกว่า ไหม ถ้ามากกว่า ให้ แสดง คำใบ้ 
    elif [[ $GUESS -gt $SECRET_NUMBER ]]
    then
      # ถ้ามากกว่า ใช้งานคำใบ้นี้
      echo "It's lower than that, guess again:"
   
    else
       # ถ้า น้อยกว่า ใช้งานคำใบ้นี้
      echo "It's higher than that, guess again:"
    fi
  done
}

# ฟังชั่นสำหรับ update ข้อมูล หลังจาก ทายถูกแล้ว
UPDATE_STAT() {
  # เอาข้อมูล user มาใช้งาน
  USER_INFO=$($PSQL "SELECT games_played, best_game FROM users WHERE user_id = $USER_ID")
  IFS="|" read GAMES_PLAYED BEST_GAME <<< $USER_INFO
  
  # หาก เคยมีการเล่นมาก่อน ก็จะ เพิ่ม กับ ข้อมูล เดิม ว่าเคยเล้่นไปแล้ว เท่าไหร่ ให้ + อีก 1
  ((GAMES_PLAYED++))
  
  # เช็คว่าเป็นเกมแรกที่เล่น หรือเป็นเกมที่ใช้จำนวนครั้งทายน้อยที่สุด
  # ถ้าใช่ ก็ให้บันทึกค่าใหม่เป็น best_game ว่าเกมนี้ ทายถูกเร็วขึ้น
  if [[ $BEST_GAME -eq 0 || $GUESSES -lt $BEST_GAME ]]
  then
    BEST_GAME=$GUESSES
  fi
  
  # อัพเดท ข้อมูล การเล้นเข้าไปใน db
  UPDATE_RESULT=$($PSQL "UPDATE users SET games_played = $GAMES_PLAYED, best_game = $BEST_GAME WHERE user_id = $USER_ID")
}


GET_USER_INFO
PLAY_GAME
UPDATE_STAT
