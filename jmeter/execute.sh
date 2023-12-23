#!/bin/bash

# Define the filename
filename="test_data/performance.csv"

# Ensure the directory exists
mkdir -p $(dirname "$filename")

# Create or overwrite the file with header row
echo "id,fname,lname,email,password,phone,status" > "$filename"

# Get the number of records from the first argument, default is 5
num_records=${1:-5}

# Generate the data rows
for (( i=1; i<=num_records; i++ )); do
  echo "id$i,fname$i,lname$i,user_id$i@gmail.com,password$i,+3806300000$i,$((i%2))" >> "$filename"
done

# Edit the JMX file
sed_command="s|<stringProp name=\"LoopController.loops\">[0-9]*</stringProp>|<stringProp name=\"LoopController.loops\">$num_records</stringProp>|g"
sed -i '' "$sed_command" scenarios/performance.jmx || { echo "sed command failed"; exit 1; }

# Build the Docker image
docker build -t performance_jmeter . || { echo "Docker build failed"; exit 1; }

# Remove existing container if it exists
if docker ps -a | grep -q performance_jmeter; then
    docker rm -f performance_jmeter || { echo "Failed to remove existing Docker container"; exit 1; }
fi

# Run the Docker container
docker run -v "$(pwd)"/scenarios:/jmeter/scenarios -v "$(pwd)"/results:/jmeter/results --name performance_jmeter --entrypoint "" performance_jmeter java -jar '/opt/apache-jmeter-5.5/bin/ApacheJMeter.jar' -n -f -t '/jmeter/scenarios/performance.jmx' -l '/jmeter/results/performance.jtl' -e -o '/jmeter/results/report' || { echo "Docker run failed"; exit 1; }
