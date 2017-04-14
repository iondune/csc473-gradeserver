#! /bin/bash

#########
# Paths #
#########

students_directory="/home/ian/students"
inputs_directory="/home/ian/csc473-inputfiles"
tests_directory="/home/ian/csc473-testfiles"


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


#########
# Build #
#########

if [ -f "CMakeLists.txt" ]; then

	echo "Found CMakeLists.txt, doing CMake build"

	mkdir -p "resources/"

	# Copy .pov files
	for file in "$inputs_directory/"*.pov
	do
		echo "Copying file $file"
		cp "$file" "resources/"
	done

	mkdir -p "build/"
	cd "build/"

	rm -f "CMakeCache.txt"

	cmake .. > cmake_output 2>&1
	if [ $? -ne 0 ]; then
		echo "CMake failed!"
		exit 1
	fi

	make > make_output 2>&1
	if [ $? -ne 0 ]; then
		echo "Build failed!"
		exit 1
	fi

else

	echo "Could not build project"
	exit 1

fi


#######
# Run #
#######

if [ ! -x "raytrace" ]; then
	echo "No executable called 'raytrace', might be misnamed."
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
