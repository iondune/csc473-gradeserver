#! /bin/bash

exec_directory="/home/ian"
students_directory="/home/ian/students"
site_directory="/var/www/html/grades"
html_directory="/home/ian/csc473-gradeserver/html"

teacher_site="$site_directory/all.html"
echo > "$teacher_site"

cat "$html_directory/top1.html" >> "$teacher_site"
echo "<title>CPE 473 Grade Results</title>" >> "$teacher_site"
cat "$html_directory/top2.html" >> "$teacher_site"
echo '<h1>[CPE 473] Program 1 Grade Results</h1>' >> "$teacher_site"

cd "$exec_directory/csc473-inputfiles"
git pull
cd "$exec_directory/csc473-testfiles"
git pull
echo
echo
echo

cd "$students_directory"

echo '<table class="table table-striped">' >> $teacher_site
echo '<thead>' >> $teacher_site
echo '<tr>' >> $teacher_site
echo '<th>Student</th>' >> $teacher_site
echo '<th>Status</th>' >> $teacher_site
echo '<th>Repo Link</th>' >> $teacher_site
echo '</tr>' >> $teacher_site
echo '</thead>' >> $teacher_site
echo '<tbody>' >> $teacher_site

for directory in */
do

	student=${directory%/}

	"$exec_directory/Student.sh" "$student" "p1"
	result=$?



	echo "<tr><td>" >> "$teacher_site"
	echo "<a href=\"$student/\">$student</a></td><td>" >> "$teacher_site"
	if [ $result -eq 0 ]; then
		echo "<span class=\"label label-success\">Passing</span>" >> "$teacher_site"
	elif [ $result -eq 1 ]; then
		echo "<span class=\"label label-danger\">Build Failure</span>" >> "$teacher_site"
	elif [ $result -eq 2 ]; then
		echo "<span class=\"label label-danger\">Missing Program</span>" >> "$teacher_site"
	elif [ $result -eq 3 ]; then
		echo "<span class=\"label label-warning\">Test Failure</span>" >> "$teacher_site"
	fi
	echo "</td><td>" >> "$teacher_site"

	cd "${students_directory}/${student}"
	if [ -f "link" ]; then
		echo -n "<a href=\"" $(< link ) "\">Repo</a>" >> "$teacher_site"
	else
		echo '<span class="text-danger">No repo link</span>' >> "$teacher_site"
	fi
	echo "</td></tr>" >> "$teacher_site"

	echo
	echo
	echo

	cd "$students_directory"

done

echo '</tbody></table>' >> $teacher_site

cat "$html_directory/bottom.html" >> "$teacher_site"
