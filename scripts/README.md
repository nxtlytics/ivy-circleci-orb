# Various scripts for working with CircleCI

## Requirements

- [circleci CLI](https://circleci.com/docs/2.0/local-cli/)
- [1Password CLI](https://support.1password.com/command-line/)

## Create new context script

### Usage

```shell
$ ./scripts/new-context.sh
Usage:
new-context.sh -s <REQUIRED: version control system type> -o <REQUIRED: org name>
               -c <REQUIRED: context-name> -v <REQUIRED: 1Password vault name containing item>
               -i <REQUIRED: 1Password item name to sync>

Creates new circleci context
Note: this uses 1Password's op command line.
      Please run: eval $(op signin <1Password account name>)
```

### Examples

#### Creating a new context

```shell
$ ./scripts/new-context.sh -s github -o nxtlytics -c test-context -v test-project -i 'test-project-circleci-context'
I will try to create context: test-project-context
I will add its environment variables now
I'm done
```

#### Trying to create a context already exists does not do anything

```shell
$ ./scripts/new-context.sh -s github -o nxtlytics -c test-context -v test-project -i 'test-project-circleci-context'
Context: test-project-context already exists, I will not create it
I'm done
```

### How should 1Password look like:

Use 1Password's `secure note` and each line in the note should be a Key/Value combination separated by a `space` (` `)

```shell
ENVIRONMENT_VARIABLE00 VALUE00
ENVIRONMENT_VARIABLE01 VALUE01
ENVIRONMENT_VARIABLE02 VALUE02
```
