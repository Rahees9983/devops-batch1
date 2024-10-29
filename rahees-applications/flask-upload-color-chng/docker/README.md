# flask-html-backgroud-color-change
This is a flask application which will change the background color of the page based on the environment variable passed

commands to run the application inside a docker container

`docker run docker run -d -p 8080:8080 rahees9983/simple-webapp-color:v1`

To pass the color value using environemt variable use the below docker command 

``docker run -d -p 8080:8080 -e APP_COLOR=green rahees9983/simple-webapp-color:v1``

To access the application via browser hit the below URL
htpp://<IP-ADDRESS>:8080

http://3.141.165.177:8080/

If your VM is on a AWS then add below Security Group

<img width="1679" alt="image" src="https://github.com/user-attachments/assets/cbe27871-302d-4281-9d41-89b289c7213c">


Application accessibility image

<img width="1248" alt="image" src="https://github.com/user-attachments/assets/7d7abdd2-5c23-4c09-8d18-8267006e9efa">

`$ docker run --name my-flask-app -e UPLOAD_FOLDER="/usr/src/app/upload" -e APP_COLOR="green" -p 8080:8080 flask-upload-file:v2`


