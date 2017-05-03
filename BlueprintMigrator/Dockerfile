# Use an official Python runtime as a base image
FROM nimmis/java-centos:openjdk-8-jdk

# Create required folders on the container
RUN cd /
RUN mkdir /apps
RUN cd /apps
RUN mkdir /apps/devportal
RUN cd /apps/devportal/
RUN mkdir /apps/devportal/Bosh

# Set the working directory to /apps
WORKDIR /apps/devportal/Bosh

# Copy the current directory contents into the container at /app
ADD . /apps/devportal/Bosh
RUN ls
VOLUME ["/apps/devportal/config"]

# Make port 80 available to the world outside this container
EXPOSE 80

# Define environment variable
#ENV NAME World

# Run app.py when the container launches
CMD ["sh","/apps/devportal/Bosh/AutoMigrationProcess.sh","/apps/devportal/config/config.properties"]
#CMD ["bash"]

