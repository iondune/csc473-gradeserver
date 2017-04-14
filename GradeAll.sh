#! /bin/bash

exec_directory="/home/ian/"
students_directory="/home/ian/students/"


cd "$students_directory"

for directory in */
do

	student=${directory%/}

	"$exec_directory/Student.sh" "$student"

	echo
	echo
	echo

	cd "$students_directory"

done
