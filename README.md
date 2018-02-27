# Data Stewardship Portal - Web Client

[![Build Status](https://travis-ci.org/DataStewardshipPortal/dsp-client.svg?branch=master)](https://travis-ci.org/DataStewardshipPortal/dsp-client)
[![License](https://img.shields.io/badge/license-Apache%202-blue.svg)](LICENSE)

This is a web client for the Data Stewardship Portal which is part of
the Interoperability platform at [ELIXIR CZ](https://www.elixir-czech.cz).

[Data Stewardship Portal - Server Application](https://github.com/DataStewardshipPortal/dsp-server)
is the backend providing the API this client is using.

The Data Stewardship Portal has the following functionality:

- Organization & User Management
- Knowledge Model Editor
- Knowledge Model Migration Tool
- Package Management 


## Development

Project is developed using the [Elm language](http://elm-lang.org).

Development of the portal requires recent version of node and npm (node version
8.0.0 and npm version 5.0.0 should be fine). The project has a couple of
dependencies that you need to install using npm.

```
$ npm install
```

Webpack is used to build the project. Webpack dev server is configured for
smooth and easy development. You can start the dev server with:

```
$ npm start
```

Then navigate to [http://localhost:8080](http://localhost:8080) and you should
see the client. During the development, the clients expects the backend running
on localhost port 3000.


Use the following command to create a production minified build:

```
$ npm run build
```

To run the unit tests use:

```
$ npm test
```


## Project Structure

All the application source code lives in the `src` directory. It contains
following subdirectories and files:

- `elm` - Elm source code, organized into modules
- `img` - images
- `scss` - SCSS source code, split into files based on the functionality and modules
- `index.html` - base HTML file where the app is loaded
- `index.js` - JavaScript that initializes the Elm app

Source code in `vendor` directory contains Elm code that is from libraries
that could not be installed from Elm packages because they are either not
published there or not published for the same Elm version.

Tests are in the `tests` directory organized in the same fashion as the source
code in `elm` directory.
 
In the `nginx` directory, there is the configuration and the start script for
nginx that is used in the Docker container to run the project. 


## Documentation

It is possible to generate the documentation using [elm-doc](https://github.com/ento/elm-doc).
First you need to install elm-doc following the instruction in its repository.
Then you can run the following command to generate the docs:

```
$ npm run docs
```

The documentation will be generated in the `docs` directory. Follow the elm-doc
documentation to see how to view the documentation.

## Deployment

The project is automatically build into a Docker image using Travis CI. The
Docker image for the portal is based on nginx that simply serves the static
files build by webpack.

### Configuration

When running the container with the DSP Client, you have to set ENV variable
`API_URL` which should contain absolute URL to the API backend without the
trailing slash.

Here is example docker compose configuration

```
version: '3'
services:
  dsp_client:
    image: elixir/dsp-client
    environment:
      - API_URL=https://dsp-api.example.com
```

### Other deployment possibilities

It is not necessary to use the Docker image since the client contains only
static files. You can just build the production build and serve the static
files wherever from you want.

## License

This project is licensed under the Apache License v2.0 - see the
[LICENSE](LICENSE) file for more details.
