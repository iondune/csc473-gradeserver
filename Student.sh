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
    exit 1
fi

student=$1

echo "Student: $student"
cd "$students_directory/$student/"


if [ ! -d "repo" ]; then

	git clone $(< url ) "repo"

fi

cd "repo/"

git pull origin master
git clean -d -x -f
git reset --hard

export GLM_INCLUDE_DIR=/usr/include/glm/

mkdir -p "$site_directory/$student/"
student_site="$site_directory/$student/index.html"

# Header info
echo > "$student_site"
cat "$html_directory/top.html" >> "$student_site"
echo '<h1>[CPE 473] Program 1 Grade Results</h1>' >> "$student_site"
echo "<p>Student: $student</p>" >> "$student_site"

# Directory listing
echo '<h2>Directory Structure</h2>' >> "$student_site"
echo -n '<pre><code>' >> "$student_site"
tree -L 2 >> "$student_site"
echo '</code></pre>' >> "$student_site"
echo '<hr />' >> "$student_site"


#########
# Build #
#########

mkdir -p "resources/"

# Copy .pov files
for file in "$inputs_directory/"*.pov
do
	echo "Copying file $file"
	cp "$file" "resources/"
done

echo '<h2>Build Results</h2>' >> "$student_site"

if [ -f "CMakeLists.txt" ]; then

	echo "Found CMakeLists.txt, doing CMake build"

	mkdir -p "build/"
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
		cat "$html_directory/bottom.html" >> "$student_site"

		exit 1
	fi

	make > make_output 2>&1
	if [ $? -ne 0 ]; then
		echo "Build failed!"

		# Write website
		echo '<p><span class="text-danger">make build failed.</span></p>' >> "$student_site"
		echo -n '<pre><code>' >> "$student_site"
		cat make_output >> "$student_site"
		echo '</code></pre>' >> "$student_site"
		cat "$html_directory/bottom.html" >> "$student_site"

		exit 1
	fi

elif [ -f "Makefile" ]; then

	echo "Found Makefile, doing Make build"

	make > make_output 2>&1
	if [ $? -ne 0 ]; then
		echo "Build failed!"

		# Write website
		echo '<p><span class="text-danger">make build failed.</span></p>' >> "$student_site"
		echo -n '<pre><code>' >> "$student_site"
		cat make_output >> "$student_site"
		echo '</code></pre>' >> "$student_site"
		cat "$html_directory/bottom.html" >> "$student_site"

		exit 1
	fi

else

	echo "Could not build project"

	echo '<p><span class="text-danger">No <code>Makefile</code> or <code>CMakeLists.txt</code> found.</span></p>' >> "$student_site"

	exit 1

fi

echo '<p><span class="text-success">build succeeded.</span></p>' >> "$student_site"


#######
# Run #
#######

if [ ! -x "raytrace" ]; then
	echo "No executable called 'raytrace', might be misnamed."

	echo '<p><span class="text-danger">Could not find executable <code>raytrace</code>.</span></p>' >> "$student_site"

	exit 1
fi

# Run tests
for args_file in "$tests_directory/p1/"*.args
do
	out_file="${args_file%.*}.out"
	echo "Running test $args_file $out_file"
	./raytrace $(< "$args_file") > mytest.out
	diff "$out_file" mytest.out

	if [ $? -eq 0 ]; then
		echo "Test passed!"
	else
		echo "Test failed!"
	fi
done

for file in planes.pov simple.pov spheres.pov
do
	out_file="${file%.*}.png"
	echo "Rendering image $file -> $out_file"
	./raytrace render "$file" 640 480
	mv "output.png" "$out_file"

	if [ $? -ne 0 ]; then
		echo "Imaged not produced for test case!"
		exit 1
	fi

	img_diff=$(compare -metric AE -fuzz 3 "$tests_directory/p1/$out_file" "$out_file" difference.png 2>&1)
	rm difference.png

	echo "Difference: $img_diff"
	if [[ "$img_diff" -gt 0 ]]; then
		echo "Image doesn't match!"
	else
		echo "Image matches!"
	fi

done
