#! /bin/bash

#########
# Paths #
#########

students_directory="/home/ian/students"
inputs_directory="/home/ian/csc473-inputfiles"
tests_directory="/home/ian/csc473-testfiles"
site_directory="/var/www/html/grades"
html_directory="/home/ian/csc473-gradeserver/html"


########
# Init #
########

if [ "$#" -ne 1 ]; then
    echo "usage: GradeStudent <user_id>"
    exit 99
fi

student=$1

echo "Student: $student"
cd "$students_directory/$student/"


if [ ! -d "repo" ]; then

	git clone $(< url ) "repo"

fi

cd "repo/"

git clean -d -x -f
git reset --hard
git pull origin master

export GLM_INCLUDE_DIR='/usr/include/glm/'
export EIGEN3_INCLUDE_DIR='/usr/include/eigen3/'

mkdir -p "$site_directory/$student/"
student_site="$site_directory/$student/temp.html"

function cleanup()
{
	cat "$html_directory/bottom.html" >> "$student_site"
	mv "$site_directory/$student/temp.html" "$site_directory/$student/index.html"
}

function collapse_button()
{
	echo '<button class="btn btn-primary" type="button" data-toggle="collapse" data-target="#'$1'" aria-expanded="false" aria-controls="'$1'">' >> "$student_site"
	echo 'Show/Hide' >> "$student_site"
	echo '</button>' >> "$student_site"
}

function modal_window_start()
{
	echo '<button type="button" class="btn btn-'$3' btn-sm" data-toggle="modal" data-target="#'$1'">' >> "$student_site"
	echo "$2" >> "$student_site"
	echo '</button>' >> "$student_site"
	echo '<div class="modal fade" id="'$1'" tabindex="-1" role="dialog">' >> "$student_site"
	echo '<div class="modal-dialog" role="document">' >> "$student_site"
	echo '<div class="modal-content">' >> "$student_site"
	echo '<div class="modal-header">' >> "$student_site"
	echo '<button type="button" class="close" data-dismiss="modal" aria-label="Close">&times;</button>' >> "$student_site"
	echo '<h4 class="modal-title">'$2'</h4>' >> "$student_site"
	echo '</div>' >> "$student_site"
	echo '<div class="modal-body">' >> "$student_site"
}

function modal_window_end()
{
	echo '</div>' >> "$student_site"
	echo '<div class="modal-footer">' >> "$student_site"
	echo '<button type="button" class="btn btn-default" data-dismiss="modal">Close</button>' >> "$student_site"
	echo '</div>' >> "$student_site"
	echo '</div>' >> "$student_site"
	echo '</div>' >> "$student_site"
	echo '</div>' >> "$student_site"
}

# Header info
echo > "$student_site"
cat "$html_directory/top1.html" >> "$student_site"
echo "<title>[$student] CPE 473 Grade Results</title>" >> "$student_site"
cat "$html_directory/top2.html" >> "$student_site"
echo '<h1>[CPE 473] Program 1 Grade Results</h1>' >> "$student_site"
echo "<p>Student: $student</p>" >> "$student_site"
echo "<p>Time: "$(TZ=America/Los_Angeles date)"</p>" >> "$student_site"

# Directory listing
modal_window_start "file_view" "Directory Structure" "primary"
echo -n '<pre><code>' >> "$student_site"
tree --filelimit 32 >> "$student_site"
echo '</code></pre>' >> "$student_site"
modal_window_end


if [ -d "prog1" ]; then
	cd "prog1/"
fi

if [ -d "CPE473" ]; then
	cd "CPE473/"
fi

#########
# Build #
#########

mkdir -p "resources/"
	mkdir -p "build/"

# Copy .pov files
for file in "$inputs_directory/"*.pov
do
	echo "Copying file $file"
	cp "$file" "resources/"
	cp "$file" "build/"
done

echo '<h2>Build Results</h2>' >> "$student_site"

if [ -f "CMakeLists.txt" ]; then

	echo "Found CMakeLists.txt, doing CMake build"

	cd "build/"

	rm -f "CMakeCache.txt"

	cmake .. > cmake_output 2>&1
	if [ $? -ne 0 ]; then
		echo "CMake failed!"

		# Write website
		echo '<p><span class="text-danger">CMake build failed.</span></p>' >> "$student_site"
		echo -n '<pre><code>' >> "$student_site"
		cat cmake_output >> "$student_site"
		echo '</code></pre>' >> "$student_site"

		cleanup
		exit 1
	fi

	make > make_output 2>&1
	if [ $? -ne 0 ]; then
		echo "Makefile build failed!"

		# Write website
		echo '<p><span class="text-danger">make build failed.</span></p>' >> "$student_site"
		echo -n '<pre><code>' >> "$student_site"
		cat make_output >> "$student_site"
		echo '</code></pre>' >> "$student_site"

		cleanup
		exit 1
	fi

elif [ -f "Makefile" ]; then

	echo "Found Makefile, doing Make build"

	make > make_output 2>&1
	if [ $? -ne 0 ]; then
		echo "Makefile build failed!"

		# Write website
		echo '<p><span class="text-danger">make build failed.</span></p>' >> "$student_site"
		echo -n '<pre><code>' >> "$student_site"
		cat make_output >> "$student_site"
		echo '</code></pre>' >> "$student_site"

		cleanup
		exit 1
	fi

else

	echo '<p><span class="text-danger">No <code>Makefile</code> or <code>CMakeLists.txt</code> found.</span></p>' >> "$student_site"

	build_files=$(find -name "*.cpp")

	if [ ! -z "$build_files" ] ; then

		g++ $build_files -o raytrace > gcc_output 2>&1

		if [ $? -eq 0 ] ; then

			echo "Built all *.cpp in src/"

		else

			echo "g++ build failed!"

			# Write website
			echo '<p><span class="text-danger">g++ build failed.</span></p>' >> "$student_site"
			echo -n '<pre><code>' >> "$student_site"
			cat gcc_output >> "$student_site"
			echo '</code></pre>' >> "$student_site"

			cleanup
			exit 1

		fi

	else

		echo "Could not find any *.cpp to build"

		echo '<p><span class="text-danger">No source files found to build!</span></p>' >> "$student_site"

		cleanup
		exit 1

	fi


fi

echo '<p><span class="text-success">build succeeded.</span></p>' >> "$student_site"


#######
# Run #
#######

failed_tests=

echo '<h2>Test Results</h2>' >> "$student_site"

if [ ! -x "raytrace" ]; then
	echo "No executable called 'raytrace', might be misnamed."

	echo '<p><span class="text-danger">Could not find executable <code>raytrace</code>.</span></p>' >> "$student_site"

	cleanup
	exit 2
fi

# Run tests

echo '<table class="table table-striped table-bordered" style="width: auto;">' >> $student_site
echo '<thead>' >> $student_site
echo '<tr>' >> $student_site
echo '<th>Test</th>' >> $student_site
echo '<th>Status</th>' >> $student_site
echo '</tr>' >> $student_site
echo '</thead>' >> $student_site
echo '<tbody>' >> $student_site

for args_file in "$tests_directory/p1/"*.args
do
	out_file="${args_file%.*}.out"
	test_name=$(basename ${args_file%.*})

	echo '<tr><td>'$test_name'</td><td>' >> $student_site

	echo "Running test $args_file $out_file"
	{ ./raytrace $(< "$args_file"); } > mytest.out 2>&1
	diff -bB "$out_file" mytest.out > diff_output 2>&1

	if [ $? -eq 0 ]; then
		echo "Test passed!"
		echo '<span class="label label-success">Passed</span>' >> "$student_site"
	else
		failed_tests="${failed_tests}$test_name"
		echo "Test failed!"

		modal_window_start "diff_"$test_name "Failed - Diff Results ($test_name)" "danger"
		echo -n '<pre><code>' >> "$student_site"
		cat diff_output >> "$student_site"
		echo '</code></pre>' >> "$student_site"
		modal_window_end
	fi

	echo '</td></tr>' >> $student_site

done

echo '</tbody></table>' >> $student_site
echo '<h2>Image Results</h2>' >> "$student_site"

for file in planes.pov simple.pov spheres.pov
do
	out_file="${file%.*}.png"
	echo "Rendering image $file -> $out_file"
	{ ./raytrace render "$file" 640 480; } > render.out 2>&1
	mv "output.png" "$out_file"

	if [ $? -ne 0 ]; then
		failed_tests="${failed_tests}$file"
		echo "Image not produced for test case!"
		echo "<p><span class=\"text-danger\">Image for $file failed - no image produced.</span></p>" >> "$student_site"
	else
		img_diff=$(compare -metric AE -fuzz 3 "$tests_directory/p1/$out_file" "$out_file" "difference_$out_file" 2>&1)

		echo "Difference: $img_diff"
		if [[ "$img_diff" -gt 0 ]]; then
			failed_tests="${failed_tests}$file"
			echo "Image doesn't match!"
			echo "<p><span class=\"text-danger\">Image for $file failed - image does not match.</span></p>" >> "$student_site"
		else
			echo "Image matches!"
			echo "<p><span class=\"text-success\">Image for $file passed - imaged matches.</span></p>" >> "$student_site"
		fi
	fi

done

if [ -z "$failed_tests" ]; then

	echo "All tests passed!"
	echo "<p><span class=\"text-success\">All tests passed!</span></p>" >> "$student_site"

	cleanup
	exit 0

else

	cleanup
	exit 3

fi
