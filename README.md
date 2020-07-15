# Ivy CircleCi Orb

A CircleCi orb (reusable YAML reference set) to standardize build processes.

[CircleCi registry link](https://circleci.com/orbs/registry/orb/nxtlytics/ivy-circleci-orb)

Best used in conjunction with one of the Saplings:
 * [sapling_node-module](https://github.com/nxtlytics/sapling_node-module) - Uses `build_npm` / `build_npm_and_release`
 * [sapling_python-module](https://github.com/nxtlytics/sapling_python-module) - Uses `build_pipenv` / `build_pipenv_and_release`
 * [sapling_python-app](https://github.com/nxtlytics/sapling_python-app) - Uses `build_docker`
 
Each of the above skeletons provides a working example of how to use this build library.
 
## Structure
 
The orb is broken into multiple components:
 * `references`  
    Reusable YAML code blocks that can be referenced by a YAML reference anywhere in the code (`*blah` references `&blah`).
  
 * `commands`  
    Collection of references or CircleCi build steps. Each can be referenced later as a `step` in a `job`.

 * `executors`  
    Docker container or VM image for running a `job`.

 * `jobs`
    Entrypoint for running `commands` in `executors` in a sequence.  
    This is what most dependent CircleCi tasks will reference in their `workflow` section.

## Provided jobs

This orb provides ready to use workflow jobs in three categories:

* **Docker builds**  
  Build a Docker container with all it's libraries and dependencies. This should be the last step in deploying an application.

  * `build_docker` - Build and push a Docker container to a Docker Registry
    This will build and push docker containers with the form of `${DOCKER_REGISTRY}/<project name>:ci.<branch>.<build id>.<commit shorthash>`.

* **NodeJS builds**  
  Build a NPM library and package it for usage by a Docker container or other libraries.

  * `build_npm` - Build and test a NPM package  
    This job should be used for builds on `feature` branches only, as no artifacts are produced.
    
  * `build_npm_and_release` - Build, test, and upload a NPM package to a NPM Registry for use by other packages  
    Use this job for builds on `master` or `develop` to prepare artifacts (packages) that can be used in other projects
    or integration tests.

* Pipenv (Python) builds  
  Build a PyPi package with Pipenv for use by a Docker container or other libraries.  
  
  **Your package must use the [IVYBuildTools](https://github.com/nxtlytics/ivy-build-tools-py) 
  library to produce proper packages**  

  * `build_pipenv` -  Build and test a PyPi package (via Pipenv)
    This job should be used for builds on `feature` branches only, as no artifacts are produced.    
  
  * `build_pipenv_and_release` - Build, test, and upload a PyPi package (via Pipenv) to pypi registry for use by other packages
    Use this job for builds on `master` or `develop` to prepare artifacts (packages) that can be used in other projects

## Example dependent CircleCi task

Dependent tasks are clear and concise as to what they require to build.  

```
#
# User examples showing how to use this Orb
#
examples:
  persist_artifact:
    description: |
      Save built jar and docker can later use this compiled jar instead of rebuilding
    usage:
      version: 2.1
      orbs:
        ssabuild: nxtlytics/ivy-circleci-orb@0.0.1
      workflows:
        version: 2
        build:
          jobs:
            - ivy-circleci-orb/build_mvn:
                after_checkout_commands: |
                  echo "These commands will be"
                  echo "executed after checkout"
                post-steps:
                  - persist_to_workspace:
                      name: Save jar to workspace
                      root: directory/with/compiled/artifacts
                      paths:
                        - my-example-project-0.1.0-SNAPSHOT-jar-with-dependencies.jar
            - ivy-circleci-orb/build_docker_and_deploy:
                deploy_hook_url: "Endpoint where to HTTP PATCH new image"
                deploy_task_name: "App namespace in environment"
                require:
                  - ssabuild/build_mvn
  deploy_docker:
    description: |
      Builds docker image and updates environment with it.
    usage:
      version: 2.1
      orbs:
        ivy-circleci-orb: nxtlytics/ivy-circleci-orb@0.0.1
      workflows:
        version: 2
        build:
          jobs:
            - ivy-circleci-orb/build_docker_and_deploy:
                deploy_hook_url: "Endpoint where to HTTP PATCH new image"
                deploy_task_name: "App namespace in environment"
  release_python_module:
    description: |
      Builds and publishes python module
    usage:
      version: 2.1
      orbs:
        ivy-circleci-orb: nxtlytics/ivy-circleci-orb@0.0.1
      workflows:
        version: 2
        build:
          jobs:
            - ivy-circleci-orb/build_pipenv_and_release:
                filters:
                  branches:
                    only:
                      - master
                      - develop
```

## Release process

TBD  
> *-The Sign Painter*


## Useful commands for development

### Validate ord

```
$ circleci orb validate src/orb.yml
Orb at `src/orb.yml` is valid.
```

### Publish a dev orb

```
$ circleci orb publish src/orb.yml nxtlytics/ivy-circleci-orb@dev:example
Orb `nxtlytics/ivy-circleci-orb@dev:example` was published.
Please note that this is an open orb and is world-readable.
Note that your dev label `dev:example` can be overwritten by anyone in your organization.
Your dev orb will expire in 90 days unless a new version is published on the label `dev:example`.
```


## Related links

- [Publishing Orbs](https://circleci.com/docs/2.0/creating-orbs/?gclid=EAIaIQobChMIpfWL3Jq25wIVhcDACh08JwBIEAAYASAAEgJqoPD_BwE)
