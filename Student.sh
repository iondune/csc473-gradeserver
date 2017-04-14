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

	git clone $(< url )

fi

cd "repo/"

git pull origin master


#########
# Build #
#########

if [ -f "CMakeLists.txt" ]; then

	echo "Found CMakeLists.txt, doing CMake build"

	# Copy .pov files
	for file in "$inputs_directory/"*.pov
	do
		echo "Copying file $file"
		cp "$file" "resources/"
	done

	mkdir -p "build/"
	cd "build/"

	cmake ..
	if [ $? -ne 0 ]; then
		echo "CMake failed!"
		exit 1
	fi

	make
	if [ $? -ne 0 ]; then
		echo "Build failed!"
		exit 1
	fi

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
done


echo
echo
echo
