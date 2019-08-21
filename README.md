# Roman Cart

This is a little web app which enables you to export a single 'merged'
CSV containing all the data that [Roman Cart](http://romancart.com)
makes available in two separate CSV files.

## Set up for development

Step 1: Create a .aws directory at the root of the project and add a
credentials file with credentials for an AWS user with sufficient
permissions to deploy to AWS Lambda.

Step 2: Set up the docker container

```bash
$ docker-compose build
$ docker-compose up
```

Step 3: Run tests on the docker container with

```bash
$ docker-compose app exec bundle exec rake
```

## Deployment

Run the following

```bash
$ docker-compose app exec bundle exec rake deploy
```
