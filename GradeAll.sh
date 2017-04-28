#! /bin/bash

(
	flock -x -w 10 200 || exit 1


echo "##########################################################################################################################"
echo
echo "Running Grader!"
echo -n "Time is: "
TZ=America/Los_Angeles date
echo
echo


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
echo "<p>Last Run: "$(TZ=America/Los_Angeles date)"</p>" >> "$teacher_site"

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
for assignment in $(< "$exec_directory/assignments" )
do
	echo "<th>${assignment}</th>" >> $teacher_site
done
echo '<th>Repo Link</th>' >> $teacher_site
echo '</tr>' >> $teacher_site
echo '</thead>' >> $teacher_site
echo '<tbody>' >> $teacher_site

for directory in */
do

	student=${directory%/}
	student_html_directory="${site_directory}/${student}"
	student_site="${student_html_directory}/temp.html"
	mkdir -p "${student_html_directory}/"

	echo > $student_site
	cat "$html_directory/top1.html" >> $student_site
	echo "<title>CPE 473 Grade Results</title>" >> $student_site
	cat "$html_directory/top2.html" >> $student_site
	echo '<h1>[CPE 473] Program 1 Grade Results</h1>' >> $student_site
	echo "<p>Student: $student</p>" >> $student_site
	echo '<table class="table table-striped">' >> $student_site
	echo '<thead>' >> $student_site
	echo '<tr>' >> $student_site
	echo '<th>Assignment</th>' >> $student_site
	echo '<th>Status</th>' >> $student_site
	echo '</tr>' >> $student_site
	echo '</thead>' >> $student_site
	echo '<tbody>' >> $student_site

	echo "<tr><td>" >> "$teacher_site"
	echo "<a href=\"$student/\">$student</a>" >> "$teacher_site"
	echo "</td><td>" >> "$teacher_site"


	for assignment in $(< "$exec_directory/assignments" )
	do

		"$exec_directory/Student.sh" "$student" "$assignment"
		result=$?

		echo "<tr><td>" >> $student_site

		echo "<a href=\"${assignment}/\">${assignment}</a></td><td>" >> $student_site
		if [ $result -eq 0 ]; then
			echo "<span class=\"label label-success\">Passing</span>" >> "$teacher_site"
			echo "<span class=\"label label-success\">Passing</span>" >> $student_site
		elif [ $result -eq 1 ]; then
			echo "<span class=\"label label-danger\">Build Failure</span>" >> "$teacher_site"
			echo "<span class=\"label label-danger\">Build Failure</span>" >> $student_site
		elif [ $result -eq 2 ]; then
			echo "<span class=\"label label-danger\">Missing Program</span>" >> "$teacher_site"
			echo "<span class=\"label label-danger\">Missing Program</span>" >> $student_site
		elif [ $result -eq 3 ]; then
			echo "<span class=\"label label-warning\">Test Failure</span>" >> "$teacher_site"
			echo "<span class=\"label label-warning\">Test Failure</span>" >> $student_site
		fi
		echo "</td><td>" >> "$teacher_site"
		echo "</td></tr>" >> $student_site

	done

	cd "${students_directory}/${student}"
	if [ -f "link" ]; then
		echo -n "<a href=\"" $(< link ) "\">Repo</a>" >> "$teacher_site"
	else
		echo '<span class="text-danger">No repo link</span>' >> "$teacher_site"
	fi
	echo "</td></tr>" >> "$teacher_site"
	echo '</tbody></table>' >> $student_site
	cat "$html_directory/bottom.html" >> $student_site

	mv "${student_html_directory}/temp.html" "${student_html_directory}/index.html"

	echo
	echo
	echo

	cd "$students_directory"

done

echo '</tbody></table>' >> $teacher_site

cat "$html_directory/bottom.html" >> "$teacher_site"

) 200>/var/lock/.myscript.exclusivelock
