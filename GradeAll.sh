#! /bin/bash

exec_directory="/home/ian"
students_directory="/home/ian/students"
site_directory="/var/www/html/grades"

teacher_site="$site_directory/all.html"
echo > "$teacher_site"

cd "$exec_directory/csc473-inputfiles"
git pull
cd "$exec_directory/csc473-testfiles"
git pull
echo
echo
echo

cd "$students_directory"

for directory in */
do

	student=${directory%/}

	"$exec_directory/Student.sh" "$student"
	echo "<p><a href=\"$student/\">$student</a></p>" >> "$teacher_site"

	echo
	echo
	echo

	cd "$students_directory"

done
