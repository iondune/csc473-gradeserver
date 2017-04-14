#! /bin/bash

exec_directory="/home/ian/"
students_directory="/home/ian/students/"


cd "$students_directory"

for directory in */
do

	student=${directory%/}

	"$exec_directory/Student.sh" "$student"

	cd "$students_directory"

done
